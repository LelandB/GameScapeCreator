//
//  Extensions.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//


import ARKit
import RealityKit
import os


extension Float {
    var degreesToRadians: Float {
        return self * .pi / 180
    }
}

/// Following two extensions used in AppModel provideHeadsetPositionAndRotation to change position of HelloWorldAttachment
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }

    var rotation: simd_float3x3 {
        return simd_float3x3(columns.0.xyz, columns.1.xyz, columns.2.xyz)
    }
}

extension simd_float4 {
    var xyz: SIMD3<Float> {
        return SIMD3(x, y, z)
    }
}

extension SIMD4 {
    /// Retrieves first 3 elements
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

struct PlaneLockComponent: Component {
    var isPlaneLocked: Bool = false
}

struct PlaneVerticesComponent: Component {
    var cubesOnVertices: Bool = false
}

//extension Entity {
//    /// Simple boolean interface backed by the presence of PlaneLockComponent
//    var isPlaneLocked: Bool {
//        get {
//            return self.components[PlaneLockComponent.self] != nil
//        }
//        set {
//            if newValue {
//                // Ensure the component exists to mark as locked
//                if self.components[PlaneLockComponent.self] == nil {
//                    self.components.set(PlaneLockComponent())
//                }
//            } else {
//                // Remove the component to mark as unlocked
//                self.components.remove(PlaneLockComponent.self)
//            }
//        }
//    }
//}

extension Entity {
    var isPlaneLocked: Bool {
        get {
            components[PlaneLockComponent.self]?.isPlaneLocked ?? false
        }
        set {
            if var comp = components[PlaneLockComponent.self] {
                comp.isPlaneLocked = newValue
                components.set(comp)
            } else if newValue {
                components.set(PlaneLockComponent(isPlaneLocked: true))
            } else {
                components.remove(PlaneLockComponent.self)
            }
        }
    }

    var cubesOnVertices: Bool {
        get {
            components[PlaneVerticesComponent.self]?.cubesOnVertices ?? false
        }
        set {
            if var comp = components[PlaneVerticesComponent.self] {
                comp.cubesOnVertices = newValue
                components.set(comp)
            } else if newValue {
                components.set(PlaneVerticesComponent(cubesOnVertices: true))
            } else {
                components.remove(PlaneVerticesComponent.self)
            }
        }
    }
}

extension ModelEntity {
    /// The geometry center of this model's faces.
    var centroid: SIMD3<Float>? {
        guard let vertices = self.model?.mesh.contents.models[0].parts[0].positions.elements else {
            return nil
        }
        guard let faces = self.model?.mesh.contents.models[0].parts[0].triangleIndices?.elements else {
            return nil
        }
        
        // Create a set of all vertices of the entity's faces.
        let uniqueFaces = Set(faces)
        
        var centroid = SIMD3<Float>()
        for vertexInFace in uniqueFaces {
            centroid += vertices[Int(vertexInFace)]
        }
        centroid /= Float(uniqueFaces.count)
        return centroid
    }
    
    /// Returns all vertices of the model's mesh as an array of `SIMD3<Float>` vectors.
    var allVertices: [SIMD3<Float>]? {
        // Ensure the mesh has valid vertex data
        guard let vertices = self.model?.mesh.contents.models[0].parts[0].positions.elements else {
            return nil
        }
        
        // Convert to an array of SIMD3<Float>
        return vertices.map { SIMD3<Float>($0.x, $0.y, $0.z) }
    }
    
    /// Returns the bottom center position of the entity in local space.
    var bottomCenterPosition: SIMD3<Float>? {
        guard let vertices = allVertices else { return nil }
        
        let minY = vertices.map { $0.y }.min() ?? 0
        let minX = vertices.map { $0.x }.min() ?? 0
        let maxX = vertices.map { $0.x }.max() ?? 0
        let minZ = vertices.map { $0.z }.min() ?? 0
        let maxZ = vertices.map { $0.z }.max() ?? 0
        
        let centerX = (minX + maxX) / 2
        let centerZ = (minZ + maxZ) / 2
        
        return SIMD3<Float>(centerX, minY, centerZ)
    }
}

extension GeometrySource {
    /// converts between ARKit and RealityKit types.
    func asArray<T>(ofType: T.Type) -> [T] {
        let bContents = self.buffer.contents()
        let offset = self.offset
        let stride = self.stride
        let count = self.count
        
        var result: [T] = Array()
        result.reserveCapacity(count)
        
        for index in 0..<count {
            result.append(bContents.advanced(by: offset + stride * index).assumingMemoryBound(to: T.self).pointee)
        }
        return result
    }
    
    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}

extension GeometryElement {
    func asIndexArray() -> [UInt32] {
        return (0..<self.count * self.primitive.indexCount).map {
            self.buffer.contents()
                .advanced(by: $0 * self.bytesPerIndex)
                .assumingMemoryBound(to: UInt32.self).pointee
        }
    }
}

extension MeshAnchor.Geometry {
    /// Creates MeshResource from geometry.
    @MainActor func asMeshResource() -> MeshResource? {
        let vertices = self.vertices.asSIMD3(ofType: Float.self)
        guard !vertices.isEmpty else {
            return nil
        }
        let faceIndexArray = self.faces.asIndexArray()
        
        var descriptor = MeshDescriptor()
        
        descriptor.positions = .init(vertices)
        descriptor.materials = .allFaces(0)
        descriptor.primitives = MeshDescriptor.Primitives.triangles(faceIndexArray)
        
        do {
            let mesh = try MeshResource.generate(from: [descriptor])
            return mesh
        } catch {
            logger.error("Error creating MeshResource with error:\(error)")
        }
        
        return nil
    }
}

extension PlaneAnchor.Geometry {
    /// Creates MeshResource from geometry.
    @MainActor func asMeshResource() -> MeshResource? {
        let vertices = self.meshVertices.asSIMD3(ofType: Float.self)
        guard !vertices.isEmpty else {
            return nil
        }
        let faceIndexArray = self.meshFaces.asIndexArray()
        
        var descriptor = MeshDescriptor()
        
        descriptor.positions = .init(vertices)
        descriptor.materials = .allFaces(0)
        descriptor.primitives = MeshDescriptor.Primitives.triangles(faceIndexArray)
        
        do {
            let mesh = try MeshResource.generate(from: [descriptor])
            return mesh
        } catch {
            logger.error("Error creating plane MeshResource with error:\(error)")
        }
        
        return nil
    }
}

extension SIMD3 where Scalar == Float {
    /// Returns a normalized vector (unit vector) of the current vector.
    var normalized: SIMD3<Float> {
        let length = simd_length(self)
        guard length > 0 else { return self } // Prevent division by zero
        return self / length
    }
}

extension simd_quatf {
    var eulerAngles: SIMD3<Float> {
        let x = self.vector.x
        let y = self.vector.y
        let z = self.vector.z
        let w = self.vector.w

        let pitch = atan2(2.0 * (w * x + y * z), 1.0 - 2.0 * (x * x + y * y))
        let yaw = asin(2.0 * (w * y - z * x))
        let roll = atan2(2.0 * (w * z + x * y), 1.0 - 2.0 * (y * y + z * z))

        return SIMD3<Float>(pitch, yaw, roll)
    }
}

extension AnchorEntity {
    var planeAnchorLocked: Bool {
        get { self.isPlaneLocked }
        set { self.isPlaneLocked = newValue }
    }
}

