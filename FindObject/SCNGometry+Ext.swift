//
//  SCNGometry+Ext.swift
//  FindObject
//
//  Created by 金子友南 on 2022/10/24.
//

import SceneKit
import ARKit
extension SCNGeometrySource {
    convenience init(textureCoordinates texcoord: [SIMD2<Float>]) {
        let stride = MemoryLayout<SIMD2<Float>>.stride
        let bytePerComponent = MemoryLayout<Float>.stride
        let data = Data(bytes: texcoord, count: stride * texcoord.count)
        self.init(data: data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: texcoord.count, usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: bytePerComponent, dataOffset: 0, dataStride: stride)
    }
    
}
extension SCNGeometry {
    public static func fromAnchor(meshAnchor: ARMeshAnchor) -> SCNGeometry {
        let vertices = meshAnchor.geometry.vertices
        let faces = meshAnchor.geometry.faces
        let vertexSource = SCNGeometrySource(buffer: vertices.buffer, vertexFormat: vertices.format, semantic: .vertex, vertexCount: vertices.count, dataOffset: vertices.offset, dataStride: vertices.stride)
        let faceData = Data(bytesNoCopy: faces.buffer.contents(), count: faces.buffer.length, deallocator: .none)
        let geometryElement = SCNGeometryElement(data: faceData, primitiveType: .triangles, primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        let geometry = SCNGeometry(sources: [vertexSource], elements: [geometryElement])
        let defaultMaterial = SCNMaterial()
        defaultMaterial.fillMode = .lines
        defaultMaterial.diffuse.contents = UIColor(displayP3Red:1, green:1, blue:1, alpha:0.7)
        geometry.materials = [defaultMaterial]
        return geometry;
    }
}
extension SCNGeometryPrimitiveType {
    static func of(_ type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
        switch type {
        case .line:
            return .line
        case .triangle:
            return .triangles
        @unknown default:
            return .line
        }
    }
}
extension ARMeshGeometry {
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        assert(classification.format == MTLVertexFormat.uchar, "Expected one unsigned char (one byte) per classification")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = Int(classificationPointer.assumingMemoryBound(to: CUnsignedChar.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }
}
