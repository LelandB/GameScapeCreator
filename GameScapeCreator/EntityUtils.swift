//
//  EntityUtils.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//


import RealityKit
import simd
import SwiftUI

struct EntityUtils {

    /// Computes the midpoint of two 3D points
    static func midpoint(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
        return (a + b) / 2
    }

    /// Returns the pivot point (center of bounding box) of a ModelEntity
    static func getPivotPoint(of entity: ModelEntity) -> SIMD3<Float> {
        let bounds = entity.visualBounds(relativeTo: nil)
        let min = bounds.min
        let max = bounds.max
        return (min + max) / 2
    }
    
    static func getTopLeftCorner(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        return SIMD3(bounds.min.x, bounds.max.y, bounds.min.z)
    }
    
    static func getTopRightCorner(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        return SIMD3(bounds.max.x, bounds.max.y, bounds.min.z)
    }

    /// Returns the bottom left corner of a ModelEntity
    static func getBottomLeftCorner(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }

        return SIMD3(bounds.min.x, bounds.min.y, bounds.max.z)
    }
    
    /// Returns the bottom middle left point of a ModelEntity
    static func getBottomMiddlePoint(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }

        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2

        return SIMD3(middleX, bounds.min.y, bounds.max.z)
    }

    /// Returns the bottom middle left point of a ModelEntity
    static func getBottomMiddleLeftPoint(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }

        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        let adjustedX = (minX + middleX) / 2

        return SIMD3(adjustedX, bounds.min.y, bounds.max.z)
    }
    
    /// 3/26/26 attempt at standardizing hex placement so at least everything aligns visually
    static func getCenterMiddlePoint(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        
        let minY = bounds.min.y
        let maxY = bounds.max.y
        let middleY = (minY + maxY) / 2
        
        let minZ = bounds.min.z
        let maxZ = bounds.max.z
        let middleZ = (minZ + maxZ) / 2
        
        return SIMD3(middleX, middleY, middleZ)
    }

    /// Elevated position from centroid of horizontal plane
    static func getCentroidAttachmentPosition(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }

        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        
        let minY = bounds.min.y
        let maxY = bounds.max.y
        let middleY = (minY + maxY) / 2
        
        let minZ = bounds.min.z
        let maxZ = bounds.max.z
        let middleZ = (minZ + maxZ) / 2
        
        return SIMD3(middleX, middleY + 1, middleZ)
    }
    
    /// Right panel position for store views
    static func getRightPanelPosition(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        
        let minY = bounds.min.y
        let maxY = bounds.max.y
        let middleY = (minY + maxY) / 2
        
        let minZ = bounds.min.z
        let maxZ = bounds.max.z
        let middleZ = (minZ + maxZ) / 2
        
        // visually Z axis is the Y axis, Y is the in-out axis, and X is normal
        return SIMD3(middleX+1.25, middleY+0.50, middleZ-0.30)
    }
    
    /// Left panel position for store views
    static func getLeftPanelPosition(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        
        let minY = bounds.min.y
        let maxY = bounds.max.y
        let middleY = (minY + maxY) / 2
        
        let minZ = bounds.min.z
        let maxZ = bounds.max.z
        let middleZ = (minZ + maxZ) / 2
        
        // visually Z axis is the Y axis, Y is the in-out axis, and X is normal
        return SIMD3(middleX-1.25, middleY+0.50, middleZ-0.30)
    }
    
    /// Recreates position of ThreadSpace logo for attachment placement
    static func getTSLogoPoint(of entity: ModelEntity) -> SIMD3<Float>? {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return nil
        }
        
        let minX = bounds.min.x
        let maxX = bounds.max.x
        let middleX = (minX + maxX) / 2
        
        let minY = bounds.min.y
        let maxY = bounds.max.y
        let middleY = (minY + maxY) / 2
        
        let minZ = bounds.min.z
        let maxZ = bounds.max.z
        let middleZ = (minZ + maxZ) / 2
        
        return SIMD3(middleX-0.54, middleY+0.2, middleZ-0.54)
    }
    
    static func animateEntity(_ entity: ModelEntity, yOffset: Float, duration: TimeInterval, relativeEntity: ModelEntity) {
        let currentTransform = entity.transform
        let newPosition = SIMD3<Float>(currentTransform.translation.x,
                                       currentTransform.translation.y + yOffset,
                                       currentTransform.translation.z)

        // Preserve original rotation & scale
        let newTransform = Transform(scale: currentTransform.scale, rotation: currentTransform.rotation, translation: newPosition)

        entity.move(to: newTransform, relativeTo: relativeEntity, duration: duration, timingFunction: .easeInOut)
    }
    
    static func animateEntityZ(_ entity: ModelEntity, zOffset: Float, duration: TimeInterval, relativeEntity: ModelEntity) {
        let currentTransform = entity.transform
        let newPosition = SIMD3<Float>(currentTransform.translation.x,
                                       currentTransform.translation.y,
                                       currentTransform.translation.z + zOffset)

        // Preserve original rotation & scale
        let newTransform = Transform(scale: currentTransform.scale, rotation: currentTransform.rotation, translation: newPosition)

        entity.move(to: newTransform, relativeTo: relativeEntity, duration: duration, timingFunction: .easeInOut)
    }
    
    static func createBox(color: UIColor = .blue) -> ModelEntity {
        let cubeMesh = MeshResource.generateBox(size: 0.2)
        let cubeMaterial = SimpleMaterial(color: color, isMetallic: false)
        let cubeEntity = ModelEntity(mesh: cubeMesh, materials: [cubeMaterial])
        
        let cubeShape = ShapeResource.generateBox(size: [0.2, 0.2, 0.2])
        cubeEntity.collision = CollisionComponent(shapes: [cubeShape])
        return cubeEntity
    }
    
    /// Defines which plane the grid lines should be aligned to
    enum GridPlane {
        case xy  // Lines in XY plane (perpendicular to Z axis)
        case xz  // Lines in XZ plane (perpendicular to Y axis)
        case yz  // Lines in YZ plane (perpendicular to X axis)
    }
    
    /// Creates a grid of line entities on a specified plane of a ModelEntity
    /// - Parameters:
    ///   - entity: The ModelEntity to add grid lines to
    ///   - plane: The plane on which to draw the grid (XY, XZ, or YZ)
    ///   - spacing: Distance between grid lines in meters (default: 0.25)
    ///   - lineColor: Color of the grid lines (default: white with 50% opacity)
    ///   - lineThickness: Thickness of the grid lines in meters (default: 0.002)
    /// - Returns: An array of the created line entities
    @discardableResult
    static func addGridLines(
        to entity: ModelEntity,
        plane: GridPlane = .xz,
        spacing: Float = 0.25,
        lineColor: UIColor = UIColor.white.withAlphaComponent(0.5),
        lineThickness: Float = 0.002
    ) -> [ModelEntity] {
        guard let bounds = entity.model?.mesh.bounds else {
            print("Error: ModelEntity does not have a valid bounding box.")
            return []
        }
        
        let min = bounds.min
        let max = bounds.max
        
        var lineEntities: [ModelEntity] = []
        
        switch plane {
        case .xy:
            // Lines parallel to X axis (varying Y)
            var currentY = min.y
            while currentY <= max.y {
                let start = SIMD3<Float>(min.x, currentY, min.z)
                let end = SIMD3<Float>(max.x, currentY, min.z)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentY += spacing
            }
            
            // Lines parallel to Y axis (varying X)
            var currentX = min.x
            while currentX <= max.x {
                let start = SIMD3<Float>(currentX, min.y, min.z)
                let end = SIMD3<Float>(currentX, max.y, min.z)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentX += spacing
            }
            
        case .xz:
            // Lines parallel to X axis (varying Z)
            var currentZ = min.z
            while currentZ <= max.z {
                let start = SIMD3<Float>(min.x, min.y, currentZ)
                let end = SIMD3<Float>(max.x, min.y, currentZ)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentZ += spacing
            }
            
            // Lines parallel to Z axis (varying X)
            var currentX = min.x
            while currentX <= max.x {
                let start = SIMD3<Float>(currentX, min.y, min.z)
                let end = SIMD3<Float>(currentX, min.y, max.z)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentX += spacing
            }
            
        case .yz:
            // Lines parallel to Y axis (varying Z)
            var currentZ = min.z
            while currentZ <= max.z {
                let start = SIMD3<Float>(min.x, min.y, currentZ)
                let end = SIMD3<Float>(min.x, max.y, currentZ)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentZ += spacing
            }
            
            // Lines parallel to Z axis (varying Y)
            var currentY = min.y
            while currentY <= max.y {
                let start = SIMD3<Float>(min.x, currentY, min.z)
                let end = SIMD3<Float>(min.x, currentY, max.z)
                if let line = createLine(from: start, to: end, color: lineColor, thickness: lineThickness) {
                    entity.addChild(line)
                    lineEntities.append(line)
                }
                currentY += spacing
            }
        }
        
        return lineEntities
    }
    
    /// Creates a line entity between two points
    /// - Parameters:
    ///   - start: Starting point of the line
    ///   - end: Ending point of the line
    ///   - color: Color of the line
    ///   - thickness: Thickness of the line in meters
    /// - Returns: A ModelEntity representing the line, or nil if creation fails
    static func createLine(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        color: UIColor,
        thickness: Float = 0.002
    ) -> ModelEntity? {
        let distance = simd_distance(start, end)
        
        guard distance > 0 else {
            print("Warning: Cannot create a line with zero length")
            return nil
        }
        
        // Create a thin box to represent the line
        let lineMesh = MeshResource.generateBox(width: thickness, height: thickness, depth: distance)
        let lineMaterial = SimpleMaterial(color: color, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        
        // Position the line at the midpoint
        let midpoint = (start + end) / 2
        lineEntity.position = midpoint
        
        // Calculate rotation to align the line from start to end
        let direction = normalize(end - start)
        let defaultDirection = SIMD3<Float>(0, 0, 1) // Box's depth is along Z axis
        
        // Calculate rotation quaternion
        if simd_length(cross(defaultDirection, direction)) > 0.0001 {
            let rotationAxis = normalize(cross(defaultDirection, direction))
            let angle = acos(dot(defaultDirection, direction))
            lineEntity.orientation = simd_quatf(angle: angle, axis: rotationAxis)
        } else if dot(defaultDirection, direction) < 0 {
            // 180 degree rotation needed
            lineEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        }
        
        return lineEntity
    }
}
