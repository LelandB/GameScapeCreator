//
//  AppModel.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//

import SwiftUI
import ARKit
import Foundation
import RealityKit
import simd
import os


@MainActor
@Observable
class AppModel {
    // For understanding the current state of the immersive space
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Plane Detection is provided via an ARKitSession configured with a PlaneDetectionProvider
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    private let planeData = PlaneDetectionProvider(alignments: [.vertical, .horizontal])
    
    @MainActor var planeAnchors: [UUID: PlaneAnchor] = [:]
    @MainActor var entityMap: [UUID: Entity] = [:]
    @MainActor var currentFloorPlane: ModelEntity?
    
    // Root entity for all app content: plane detection the entities associated with planes
    private let contentRoot = Entity()
    
    // Entity for visually rendered content on detected planes
    private let renderPlanesRoot = Entity()
    
    // Entity for plane detection via raycasting (i.e. what plane is the user facing)
    private let colliderPlanesRoot = Entity()
    
    // Entities of the current rendered plane, possible planes to render, and the collider plane from raycasting
    private var currentRenderedPlane: ModelEntity?
    private var currentColliderPlane: ModelEntity?
    private var wallEntryEntity: ModelEntity? // unclear what this is needed for at the moment
    
    // Basic Materials
    private let whiteMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
    private let blueMaterial = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)
    private let occlusionMaterial = OcclusionMaterial()
    
    @MainActor
    init() {
        colliderPlanesRoot.components[OpacityComponent.self] = .init(opacity: 0)
        renderPlanesRoot.components[OpacityComponent.self] = .init(opacity: 1.0)
        
        contentRoot.addChild(renderPlanesRoot)
        contentRoot.addChild(colliderPlanesRoot)
    }
    
    /// Sets up the root entity in the scene.
    func setupContentEntity() -> Entity {
        return contentRoot
    }
    
    @MainActor
    func runARKitSession() async {
        do {
            try await session.run([planeData, worldTracking])
        } catch {
            return
        }
    }
    
    @MainActor
    func processPlaneDetectionUpdates() async {
        for await anchorUpdate in planeData.anchorUpdates {
            let anchor = anchorUpdate.anchor
            
            // Skip planes that are not vertical and are not classified as floor
            if anchor.alignment == .horizontal {
                continue
            }
            
            print("Anchor alignments \(anchor.alignment)")
                
            switch anchorUpdate.event {
            case .added, .updated:
                await updatePlane(anchor)
            case .removed:
                await removePlane(anchor)
            }
        }
    }
    
    @MainActor
    func updatePlane(_ anchor: PlaneAnchor) async {
//        guard !isPlaneLocked else {
//            return
//        }
        
        // get anchor geometry and create a mesh and add material
        let anchorGeometry = anchor.geometry
        guard let planeMeshResource = anchorGeometry.asMeshResource() else {
            return
        }
        let planeEntity = ModelEntity(mesh: planeMeshResource, materials: [whiteMaterial])
        planeEntity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        
        // adding a collision component with a shape
        guard let shape = try? await ShapeResource.generateStaticMesh(from: planeMeshResource) else {
            print("Failed to create ShapeResource from planeEntity geometry.")
            return
        }
        planeEntity.collision = CollisionComponent(shapes: [shape], isStatic: true)
        planeEntity.components.set(InputTargetComponent())
        planeEntity.components.set(HoverEffectComponent())
        planeEntity.name = anchor.surfaceClassification.description
        
        guard let planeEntityBounds = planeEntity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return
        }
//        let surfaceArea = (abs(planeEntityBounds.min.x) + abs(planeEntityBounds.max.x)) * (abs(planeEntityBounds.min.z) + abs(planeEntityBounds.max.z))
        
        if anchor.surfaceClassification == .floor {
            // set occlusion material on floor plane to appropriately cut off ModelEntities that would cross through it
            planeEntity.model?.materials = [whiteMaterial]
            
            colliderPlanesRoot.findEntity(named: "floor")?.removeFromParent()
            renderPlanesRoot.findEntity(named: "floor")?.removeFromParent()

            currentFloorPlane = planeEntity
            
            entityMap[anchor.id] = planeEntity
            colliderPlanesRoot.addChild(planeEntity)
            renderPlanesRoot.addChild(planeEntity)
        } else {
            planeEntity.model?.materials = [blueMaterial]
            EntityUtils.addGridLines(
                to: planeEntity,
                lineColor: UIColor.green.withAlphaComponent(0.4)
            )
            
            entityMap[anchor.id] = planeEntity
            currentColliderPlane = planeEntity
            colliderPlanesRoot.addChild(planeEntity)
            renderPlanesRoot.addChild(planeEntity)
        }
    }
    
    // Removes a plane from the entityMap and the planeAnchors
    @MainActor
    func removePlane(_ anchor: PlaneAnchor) async {
        // skips removePlane on floor plane
//        if anchor.surfaceClassification == .floor {
//            return
//        } else {
        entityMap[anchor.id]?.removeFromParent()
        entityMap.removeValue(forKey: anchor.id)
        planeAnchors.removeValue(forKey: anchor.id)
        return
//        }
    }
    
    /// Raycasts from the device position to find the nearest vertical plane.
    private func raycastForFacingPlane() -> ModelEntity? {
        let viewDistance: Float = 3
        
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        guard let deviceAnchor, deviceAnchor.isTracked == true else {
            return nil
        }
        let deviceInOriginCoordinates = deviceAnchor.originFromAnchorTransform
        
        let lookAtPointInDeviceCoordinate = SIMD4<Float>(0, 0, -viewDistance, 1)
        let lookAtPointInOriginCoordinates = deviceInOriginCoordinates * lookAtPointInDeviceCoordinate
        
        guard let scene = colliderPlanesRoot.scene else {
//            logger.error("Failed to find the scene of `colliderPlanesRoot`.")
            return nil
        }
        
        let hitPlane = scene.raycast(from: deviceInOriginCoordinates.columns.3.xyz,
                                     to: lookAtPointInOriginCoordinates.xyz,
                                     query: .nearest)
        
        guard !hitPlane.isEmpty,
              let hitEntity = hitPlane[0].entity as? ModelEntity else {
            return nil
        }
        return hitEntity
    }
    
    /// Returns true if the new centroid is far enough from the last to warrant an update.
//    private func shouldUpdatePlane(newCentroid: SIMD3<Float>) -> Bool {
//        if let lastCentroid = lastPlaneCentroid {
//            if distance(newCentroid, lastCentroid) < 0.5 {
//                return false
//            }
//        }
//        return true
//    }
    
    @MainActor
    /// Updates the plane in front of the person when a plane isn't in a selected state.
    func updateFacingPlane() {
//        guard !isPlaneLocked else { return }
        
        guard let hitEntity = raycastForFacingPlane() else { return }
        hitEntity.name = "currentRenderedPlane"
        
        if let floorPlane = currentFloorPlane {
            renderPlanesRoot.addChild(floorPlane)
        }
        
        hitEntity.generateCollisionShapes(recursive: false, static: true)
        hitEntity.model?.materials = [occlusionMaterial]
        
//        guard var planeCenter = EntityUtils.getCenterMiddlePoint(of: hitEntity) else { return }
//        let centroidGlobalPosition = hitEntity.convert(position: planeCenter, to: nil)
        
//        guard shouldUpdatePlane(newCentroid: centroidGlobalPosition) else { return }
//        lastPlaneCentroid = centroidGlobalPosition
        
        // Switch to the new plane
//        renderPlanesRoot.children.removeAll()
        renderPlanesRoot.addChild(hitEntity)
        currentRenderedPlane = hitEntity
    }
}
