//
//  EditViewController.swift
//  FindObject
//
//  Created by 安江洸希 on 2022/11/11.
//

import Foundation
import UIKit
import ARKit
import GPUTextureCalculate
import PKHUD

class EditViewController: UIViewController, ARSCNViewDelegate {
    
    var filename: String = ""
    @IBOutlet var sceneView: SCNView!
    let scene = SCNScene()
    
    var anchors: [ARMeshAnchor] = []
    
    var texImg: UIImage!
    let num = 2.0 //画像の縮尺
    var picCount: Int!
    var yoko: Float!
    var tate: Float!
    var imageWidth: CGFloat!
    var imageHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = filename
        
        sceneView.delegate = self
        sceneView.scene = scene
        
//        sceneView.scene?.rootNode.addChildNode(LightNode())
//        sceneView.scene?.rootNode.addChildNode(CameraNode())
        
        buildSetup()
        
    }
    
    func buildSetup() {
        makeMesh()
        makeTexture()
    }
    
    
    @IBAction func tapped_makeTextureModel(_ sender: UIButton) {
        HUD.show(.progress)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: { [self] in
            let GPUCalculateTexture = GPUTextureCalculate(sceneView: sceneView,
                                                          anchors: anchors,
                                                          models_dayString: filename,
                                                          models_parametaNum: picCount,
                                                          tate: Int(tate),
                                                          yoko: Int(yoko),
                                                          funcString: "textureCalculate2")
            GPUCalculateTexture.make_calcuParameta()
            
            GPUCalculateTexture.makeGPUTexture { [self] in
                delete_mesh()
                let texmeshNode = BuildTextureMeshNode(filename: filename, texImage: texImg)
                sceneView.scene?.rootNode.addChildNode(texmeshNode)
                HUD.hide()
            }
        })
        
    }
    
    func delete_mesh() {
        if let node = sceneView.scene!.rootNode.childNode(withName: "meshNode", recursively: false) {
            print("delete mesh")
            node.removeFromParentNode()
        }
    }
    
    func makeMesh() {
        //mesh読み取り
        for i in 0..<DataManagement.getDataCount(name: "\(filename)/mesh") {
            
            let meshData = DataManagement.getData(name: "\(filename)/mesh/mesh\(i).data")
            if let meshAnchor = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARMeshAnchor.self, from: meshData) {
                anchors.append(meshAnchor)
            }
        }
        
        let meshNode = BuildMeshNode(anchors: anchors)
        meshNode.name = "meshNode"
        sceneView.scene?.rootNode.addChildNode(meshNode)
    }
    
    func makeTexture() {
        let picData = DataManagement.getData(name: "\(filename)/pic/pic0.jpg")
        let width = (UIImage(data: picData)?.size.width)! / num
        print(width)
        
        picCount = DataManagement.getDataCount(name: "\(filename)/pic")
        yoko = Float(floor(16384.0 / width))
        tate = ceil(Float(picCount)/yoko)
        
        
        var uiimage_array = [UIImage]()
        for i in 0..<picCount {
            let picData = DataManagement.getData(name: "\(filename)/pic/pic\(i).jpg")
            let uiimage = UIImage(data: picData)
            uiimage_array.append(uiimage!)
        }
        
        //16384以下にする必要あり
        imageWidth = UIImage(data: picData)!.size.width
        imageHeight = UIImage(data: picData)!.size.height
        
        texImg = TextureImage(W: (imageWidth! / num) * CGFloat(yoko), H: (imageHeight! / num) * CGFloat(tate), array: uiimage_array, yoko: yoko, num: num).makeTexture()
            
            
        let texImgData = texImg.jpegData(compressionQuality: 0.5)
        DataManagement.saveData(name: "\(filename)/tex.jpg", Data: texImgData!)
        
    }
    
}
