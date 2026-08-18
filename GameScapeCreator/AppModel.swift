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
    var isPlaneLocked: Bool = false
    
    // Plane Detection is provided via an ARKitSession configured with a PlaneDetectionProvider
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    private let planeData = PlaneDetectionProvider(alignments: [.vertical, .horizontal])
    
    @MainActor var planeAnchors: [UUID: PlaneAnchor] = [:]
    @MainActor var entityMap: [UUID: Entity] = [:]
    @MainActor var currentFloorPlane: ModelEntity?

    @MainActor var planeModelEntityMap: [String: ModelEntity] = [:]
    
    // Root entity for all app content: plane detection the entities associated with planes
    private let contentRoot = Entity()
    
    // Entity for visually rendered content on detected planes
    private let renderPlanesRoot = Entity()
    
    // Entity for plane detection via raycasting (i.e. what plane is the user facing)
    private let colliderPlanesRoot = Entity()
    
    // Entities of the current rendered plane, possible planes to render, and the collider plane from raycasting
    private var currentRenderedPlane: ModelEntity?
    private var currentColliderPlane: ModelEntity?

    var lastSelectedPlane: ModelEntity? = nil
    
    // Basic Materials
    private let whiteMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
    private let blueMaterial = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)
    private let occlusionMaterial = OcclusionMaterial()
    
    // list of tile ModelEntities and whether or not they've been successfully loaded
    var planeGridTiles: [ModelEntity] = []
    var areGridTilesLoaded: Bool = false
    
    // size of the mazing generation tiles and distance between each to show grid
    var tileSize: Float = 0.13
    var spacingDistance: Float = 0.005
    
    // boolean value switched for plane pinch recognition
    var hasBeenPinched: Bool = false {
        didSet {
            guard let plane = currentRenderedPlane else {
                print("Could not find a rendered plane for relative positioning.")
                return
            }
            if hasBeenPinched == true {
                print("didSet true path")
                plane.model?.materials = [blueMaterial]
            } else if hasBeenPinched == false {
                print("didSet false path")
                plane.model?.materials = [whiteMaterial]
            }
        }
    }
    
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
            if anchor.surfaceClassification == .ceiling || anchor.surfaceClassification == .floor || anchor.alignment == .vertical {
                continue
            }
                
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
        // guard !isPlaneLocked else {
        //     return
        // }
        
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
        // planeEntity.name = "\(anchor.id)_plane"
        
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
            // do not updatePlane once a render plane has been generated and locked
//            if planeModelEntityMap["\(anchor.id)_plane"] != nil {
//                if planeModelEntityMap["\(anchor.id)_plane"]?.isPlaneLocked == true {
//                    return
//                }
//            }
            
            let entityCount = entityMap.count + 1
            planeEntity.name = "Plane_\(entityCount)"

            entityMap[anchor.id] = planeEntity
            currentColliderPlane = planeEntity
            colliderPlanesRoot.addChild(planeEntity)
        }
    }
    
    // Removes a plane from the entityMap and the planeAnchors
    @MainActor
    func removePlane(_ anchor: PlaneAnchor) async {
        let anchorPlaneName = "\(anchor.id)_plane"
        
        if let aPN = planeModelEntityMap[anchorPlaneName] {
            if aPN.isPlaneLocked == true {
                print("could not remove \(anchor.id) because it is locked")
                return
            } else {
                entityMap[anchor.id]?.removeFromParent()
                entityMap.removeValue(forKey: anchor.id)
                planeAnchors.removeValue(forKey: anchor.id)
                return
            }
        }
//        entityMap[anchor.id]?.removeFromParent()
//        entityMap.removeValue(forKey: anchor.id)
//        planeAnchors.removeValue(forKey: anchor.id)
//        return
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
    private func shouldUpdatePlane(newCentroid: SIMD3<Float>, lastPlaneCentroid: SIMD3<Float>) -> Bool {
        if distance(newCentroid, lastPlaneCentroid) < 0.5 {
            return false
        } else {
            return true
        }
    }
    
    @MainActor
    /// Updates the plane in front of the person when a plane isn't in a selected state.
    func updateFacingPlane() {
        guard !isPlaneLocked else { return }
        
        guard let hitEntity = raycastForFacingPlane() else { return }
        // hitEntity.name = "currentRenderedPlane"
        
        if let floorPlane = currentFloorPlane {
            renderPlanesRoot.addChild(floorPlane)
        }
        
        // this check prevents plane updates from "unlocking" planes
        // by drawing a new plane over it/resetting planeLock and materials
        if planeModelEntityMap[hitEntity.name] != nil {
            return
        }
        
        hitEntity.generateCollisionShapes(recursive: false, static: true)
        hitEntity.components.set(InputTargetComponent())
        hitEntity.components.set(HoverEffectComponent())
        hitEntity.isPlaneLocked = false
        hitEntity.model?.materials = [whiteMaterial]
        
        // Render planes in front of the user, removing any previously rendered unlocked planes
        renderPlanesRoot.children.forEach { child in
            if child.isPlaneLocked == false {
                planeModelEntityMap[child.name]?.removeFromParent()
                planeModelEntityMap.removeValue(forKey: child.name)
            }
        }
        
        planeModelEntityMap[hitEntity.name] = hitEntity
        renderPlanesRoot.addChild(hitEntity)
    }

    // func to call from ImmersiveView when the user pinches a plane to lock it in place
    @MainActor
    func toggleRenderPlaneLock(string: String) -> Bool? {
        print("toggleRenderPlaneLock called on \(string)")
        
        if let plane = planeModelEntityMap[string] {
//            plane.isPlaneLocked = !plane.isPlaneLocked
            plane.isPlaneLocked = true
//            if plane.isPlaneLocked == true {
            plane.model?.materials = [blueMaterial]
//            } else {
//                plane.model?.materials = [whiteMaterial]
//            }

            var samePlane: Bool = false
            if let lastPlane = lastSelectedPlane {
                samePlane = lastPlane.name == plane.name ? true : false
            }
            lastSelectedPlane = plane

            return samePlane
        } else {
            return nil
        }
    }
    
    @MainActor
    func unlockPlane(planeName: String) {
        if let plane = planeModelEntityMap[planeName] {
            plane.isPlaneLocked = false
            plane.model?.materials = [whiteMaterial]
        }
    }

    @MainActor
    func placeVertexCubesOnLockedPlane(planeName: String) {
        if let plane = planeModelEntityMap[planeName] {
            plane.cubesOnVertices = !plane.cubesOnVertices
            if plane.cubesOnVertices == true {
                fillPlaneVerticesWithCubes(planeEntity: plane)
                fillPlaneWithGrid(planeEntity: plane, cubeSize: tileSize)
                
                let firstTile = planeGridTiles.filter { $0.name == "Row_1_XPos_1" }
                firstTile.forEach { child in
                    child.model?.materials = [whiteMaterial]
                }
//                if let firstTile = renderPlanesRoot.findModelEntity(named: "Row_1_XPos_1") {
//                    firstTile.model?.materials = [whiteMaterial]
//                }
            } else {
                plane.children.removeAll()
            }
        }
    }
    
    @MainActor
    func providePlaneCentroidPosition() -> (position: SIMD3<Float>, rotation: simd_quatf)? {
        // Extract the rotation of the device for viewer facing attachment
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        guard let deviceAnchor, deviceAnchor.isTracked == true else {
            return nil
        }
        let deviceAnchorTransform = deviceAnchor.originFromAnchorTransform
        let rotation = simd_quatf(deviceAnchorTransform.rotation)
        
        // Ensure we have a rendered plane
        guard let plane = currentRenderedPlane else {
            return nil
        }
        
        let position: SIMD3<Float>
        if let centroid = plane.centroid {
            position = plane.convert(position: centroid, to: nil)
        } else {
            position = SIMD3<Float>(0, 0, 0)
        }
        
        // returns plane centroid location and headset rotation
        return (position, rotation)
    }

    @MainActor
    func getElevatedAttachmentPosition() -> SIMD3<Float>? {
        guard let position = EntityUtils.getCentroidAttachmentPosition(of: lastSelectedPlane!) else {
            return nil
        }
        return lastSelectedPlane!.convert(position: position, to: nil)
    }
    
    // Function to check if two entities' bounding boxes overlap
    func checkBoundingBoxOverlap(planeEntity: ModelEntity, cubeEntity: ModelEntity) -> Bool {
        let planeBounds = planeEntity.visualBounds(relativeTo: nil)
        let cubeBounds = cubeEntity.visualBounds(relativeTo: nil)
        
        return planeBounds.intersects(cubeBounds)
    }
    
    /// Fills the current locked plane with cubes.
    func fillCurrentPlaneWithCubes() {
        guard let currentPlane = currentRenderedPlane else {
            logger.error("Failed to get the current rendered plane")
            return
        }
        
        fillPlaneVerticesWithCubes(planeEntity: currentPlane)
        fillPlaneWithGrid(planeEntity: currentPlane, cubeSize: tileSize)
        
        areGridTilesLoaded = true
    }
    
    func fillPlaneVerticesWithCubes(planeEntity: ModelEntity, cubeSize: Float = 0.1) {
        // Retrieve all vertices from the planeEntity
        guard let vertices = planeEntity.allVertices else {
            print("Error: Could not retrieve vertices from planeEntity.")
            return
        }
        
        // Iterate over the vertices and place cubes
        for vertex in vertices {
//            print("Vertex position: \(vertex)")
            
            // Create a new cube entity
            let cubeMesh = MeshResource.generateBox(size: cubeSize)
            let cubeMaterial = SimpleMaterial(color: .green, isMetallic: false)
            let cubeEntity = ModelEntity(mesh: cubeMesh, materials: [cubeMaterial])
            
            // Set the cube's position to the current vertex
//            let globalPosition = planeEntity.convert(position: vertex, to: nil)
//            cubeEntity.position = globalPosition
            cubeEntity.position = vertex
            cubeEntity.orientation = planeEntity.orientation
            
            // Add the cube to the scene
            planeEntity.addChild(cubeEntity)
            // renderPlanesRoot.addChild(cubeEntity)
        }
        
        print("Finished placing cubes at plane vertices.")
    }
    
    func fillPlaneWithGrid(planeEntity: ModelEntity, cubeSize: Float = 0.1) {
        print("fillPlaneWithGrid called")
        
        let gridPoints = generateGridPoints(for: planeEntity, cubeSize: cubeSize, spacing: spacingDistance)
        
        if gridPoints.isEmpty {
            print("No grid points were generated. Ensure the planeEntity's vertices are valid.")
            return
        }
        
        var rowCounter = 1
        var xPositionCounter = 0
        var lastSeenZValue: Float? = nil
        
        // Iterate over the grid points and place cubes
        for point in gridPoints {
            xPositionCounter += 1
            
            if lastSeenZValue == nil {
                lastSeenZValue = point.z
            } else {
                if lastSeenZValue != point.z {
                    rowCounter += 1
                    xPositionCounter = 1
                    lastSeenZValue = point.z
                }
            }
            let tileEntity = createTileAndWalls(width: cubeSize, height: 0.013, depth: cubeSize, wallThickness: 0.002, color: .blue)
            
            // Set the cube's position to the current vertex
//            let globalPosition = planeEntity.convert(position: point, to: nil)
//            tileEntity.position = globalPosition
            tileEntity.position = point
            tileEntity.name = "Row_\(rowCounter)_XPos_\(xPositionCounter)"
            print("tileEntity named : \(tileEntity.name)")
            
            // orients the tile identical to the plane for grid consistency
            // guard let planeToDrawOn = currentColliderPlane else {
            //     print("currentColliderPlane is nil.")
            //     return
            // }
            // tileEntity.orientation = planeToDrawOn.orientation
//            tileEntity.orientation = planeEntity.orientation
            
            // Add the cube to the scene
            // renderPlanesRoot.addChild(tileEntity)
            planeEntity.addChild(tileEntity)
            
            // Add the tile to the planeGridTiles array
            planeGridTiles.append(tileEntity)
        }
        
        print("Finished placing cubes at plane vertices.")
    }
    
    func generateGridPoints(for planeEntity: ModelEntity, cubeSize: Float = 0.1, spacing: Float = 0.0254) -> [SIMD3<Float>] {
//        print("generateGridPoints called")
        
        // Ensure we have all vertices
        guard let vertices = planeEntity.allVertices else {
            print("Error: Could not retrieve vertices from planeEntity.")
            return []
        }
        
        // Extract the bounds from the vertices
        let minX = vertices.map { $0.x }.min() ?? 0
        let maxX = vertices.map { $0.x }.max() ?? 0
        let minZ = vertices.map { $0.z }.min() ?? 0
        let maxZ = vertices.map { $0.z }.max() ?? 0
        let fixedY = vertices.first?.y ?? 0 // All Y values should be the same in this 2D shape
        
        // Adjust spacing to include cube size
        let adjustedSpacing = cubeSize + spacing
        
        // Generate a grid of points within the bounds
        var gridPoints: [SIMD3<Float>] = []
        var currentZ = minZ
        while currentZ <= maxZ {
            var currentX = minX
            while currentX <= maxX {
                let point = SIMD3<Float>(currentX, fixedY, currentZ)
                
                // Check if the point is inside the polygon defined by the vertices
                if isPointInsidePolygon(point, vertices: vertices) {
                    gridPoints.append(point)
                }
                
                currentX += adjustedSpacing
            }
            currentZ += adjustedSpacing
        }
        
        print("Generated \(gridPoints.count) grid points.")
        return gridPoints
    }
    
    /// Check if a 2D point (ignoring Y) is inside a polygon defined by vertices
    func isPointInsidePolygon(_ point: SIMD3<Float>, vertices: [SIMD3<Float>]) -> Bool {
        var isInside = false
        let n = vertices.count
        var j = n - 1
        
        for i in 0..<n {
            let vi = vertices[i]
            let vj = vertices[j]
            
            if ((vi.z > point.z) != (vj.z > point.z)) &&
                (point.x < (vj.x - vi.x) * (point.z - vi.z) / (vj.z - vi.z) + vi.x) {
                isInside.toggle()
            }
            j = i
        }
        
        return isInside
    }
    
    func createTile(width: Float, height: Float, depth: Float, color: UIColor = .blue) -> ModelEntity {
        let tileMesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        let tileMaterial = SimpleMaterial(color: color, isMetallic: false)
        let tileEntity = ModelEntity(mesh: tileMesh, materials: [tileMaterial])
//        tileEntity.mazeVisit = MazeVisitComponent(visited: false)
        return tileEntity
    }
    
    func createTileAndWalls(width: Float, height: Float, depth: Float,
                    wallThickness: Float = 0.05, color: UIColor = .blue,
                    wallColor: UIColor = .gray) -> ModelEntity {
        // Create the base tile
        let tileMesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        let tileMaterial = SimpleMaterial(color: color, isMetallic: false)
        let tileEntity = ModelEntity(mesh: tileMesh, materials: [tileMaterial])
//        tileEntity.mazeVisit = MazeVisitComponent(visited: false)

        // Define wall dimensions
        let wallHeight = height + wallThickness // Slightly taller than the tile
        let wallDepth = wallThickness           // Thickness of walls

        // Create wall meshes and material
        let wallMesh = MeshResource.generateBox(width: width, height: wallHeight, depth: wallDepth)
        let wallMaterial = SimpleMaterial(color: wallColor, isMetallic: false)

        // Define wall positions (relative to tile center)
        let halfWidth = width / 2
        let halfDepth = depth / 2

        // Top Wall
        let topWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
        topWall.position = [0, wallHeight / 2, -halfDepth - wallDepth / 2]
        topWall.name = "TopWall"
        tileEntity.addChild(topWall)

        // Bottom Wall
        let bottomWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
        bottomWall.position = [0, wallHeight / 2, halfDepth + wallDepth / 2]
        bottomWall.name = "BottomWall"
        tileEntity.addChild(bottomWall)

        // Left Wall
        let leftWallMesh = MeshResource.generateBox(width: wallDepth, height: wallHeight, depth: depth)
        let leftWall = ModelEntity(mesh: leftWallMesh, materials: [wallMaterial])
        leftWall.position = [-halfWidth - wallDepth / 2, wallHeight / 2, 0]
        leftWall.name = "LeftWall"
        tileEntity.addChild(leftWall)

        // Right Wall
        let rightWallMesh = MeshResource.generateBox(width: wallDepth, height: wallHeight, depth: depth)
        let rightWall = ModelEntity(mesh: rightWallMesh, materials: [wallMaterial])
        rightWall.position = [halfWidth + wallDepth / 2, wallHeight / 2, 0]
        rightWall.name = "RightWall"
        tileEntity.addChild(rightWall)

        return tileEntity
    }
}
