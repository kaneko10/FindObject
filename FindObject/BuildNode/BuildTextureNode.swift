//
//  BuildTextureNode.swift
//  FindObject
//
//  Created by 安江洸希 on 2022/11/11.
//

import SceneKit
import ARKit

class BuildTextureMeshNode: SCNNode {
    private var filename: String
    private var texImage: UIImage
    
    let decoder = JSONDecoder()
    let tex_node = SCNNode()
    
    init(filename: String, texImage: UIImage) {
        self.filename = filename
        self.texImage = texImage
        super.init()
        
        buildTexMesh()
        tex_node.name = "meshNode"
        addChildNode(tex_node)
    }
    
    func buildTexMesh() {
        
        for i in 0..<DataManagement.getDataCount(name: "\(filename)/texcoords") {
            
            let vertexData = DataManagement.getData(name: "\(filename)/vertex/vertex\(i).data")
            let normalData = DataManagement.getData(name: "\(filename)/vertex/vertex\(i).data")
            let facesData = DataManagement.getData(name: "\(filename)/faces/faces\(i).data")
            let texcoordsData = DataManagement.getData(name: "\(filename)/texcoords/texcoords\(i).data")
            
            let faces = facesData.withUnsafeBytes {
                Array(UnsafeBufferPointer<Int32>(start: $0, count: facesData.count/MemoryLayout<Int32>.size))
            }
            
            let texcoords = texcoordsData.withUnsafeBytes {
                Array(UnsafeBufferPointer<SIMD2<Float>>(start: $0, count: texcoordsData.count/MemoryLayout<SIMD2<Float>>.size))
            }
            
            let arrayCount = faces.count
            
            let verticeSource = SCNGeometrySource(
                data: vertexData,
                semantic: SCNGeometrySource.Semantic.vertex,
                vectorCount: arrayCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.size
            )
            
            let normalSource = SCNGeometrySource(
                data: normalData,
                semantic: SCNGeometrySource.Semantic.normal,
                vectorCount: arrayCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: MemoryLayout<Float>.size * 3,
                dataStride: MemoryLayout<SIMD3<Float>>.size
            )
            
            let textureCoordinates = SCNGeometrySource(textureCoordinates: texcoords)
            let faceSource = SCNGeometryElement(indices: faces, primitiveType: .triangles)

            let nodeGeometry = SCNGeometry(sources: [verticeSource, normalSource, textureCoordinates], elements: [faceSource])
            nodeGeometry.firstMaterial?.diffuse.contents = texImage
            

            let node = SCNNode(geometry: nodeGeometry)
            tex_node.addChildNode(node)
        }
        print("load完了")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

