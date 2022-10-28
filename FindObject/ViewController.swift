//
//  ViewController.swift
//  FindObject
//
//  Created by 金子友南 on 2022/10/11.
//

import UIKit
import SceneKit
import ARKit
import RealityKit


import MappingSupport

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let scene = SCNScene()
    var configuration = ARWorldTrackingConfiguration()
    var depth_pointCloudRenderer: MappingSupport.depth_Renderer!
    
    private let session = ARSession()
    
    @IBOutlet weak var scanStartButton: UIButton!
    @IBOutlet weak var scanStopButton: UIButton!
    
    var isScanning = false
    
    var knownAnchors = Dictionary<UUID, SCNNode>()
    var timer: Timer!
    var parametaCount = 0
    var parameta_flag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.session.delegate = self
        sceneView.scene = scene
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)

        if let View = view as? ARSCNView {
            print("call")
//        self.depth_pointCloudRenderer = MappingSupport.depth_Renderer(session: self.sceneView.session, metalDevice: self.sceneView.device!, sceneView:self.sceneView)
//            self.depth_pointCloudRenderer.drawRectResized(size: self.sceneView.bounds.size)
        }
        print(sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        // let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .none

        // Run the view's session
        sceneView.session.run(configuration)
        
//        self.depth_pointCloudRenderer = MappingSupport.depth_Renderer(session: self.sceneView.session, metalDevice: self.sceneView.device!, sceneView:self.sceneView)
//        self.depth_pointCloudRenderer.drawRectResized(size: self.sceneView.bounds.size)
    }
    
    override func viewWillLayoutSubviews() {
        self.depth_pointCloudRenderer = MappingSupport.depth_Renderer(session: self.sceneView!.session, metalDevice: self.sceneView!.device!, sceneView:self.sceneView!)
        self.depth_pointCloudRenderer.drawRectResized(size: self.sceneView!.bounds.size)
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        self.depth_pointCloudRenderer = MappingSupport.depth_Renderer(session: self.sceneView.session, metalDevice: self.sceneView.device!, sceneView:self.sceneView)
//        self.depth_pointCloudRenderer.drawRectResized(size: self.sceneView.bounds.size)
//        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDaisa")
       
        // Pause the view's session
        sceneView.session.pause()
    }

    @IBAction func scanStartButtonTapped(_ sender: UIButton) {
        print("startTapped")
        
        if isScanning {
            UIView.animate(withDuration: 0.2) {
                self.scanStartButton.layer.cornerRadius = 25
                self.scanStopButton.layer.cornerRadius = 27.5
                
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.scanStartButton.layer.cornerRadius = 3.0
                self.scanStopButton.layer.cornerRadius = 3.0
                
                // メッシュの取得
                if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                    self.configuration.sceneReconstruction = .meshWithClassification
                }
                self.configuration.frameSemantics = .sceneDepth
                // メッシュの表示
                self.sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
                
                // データ保存用のディレクトリ作成
                DataManagement.makeDirectory(name: "pic")
                DataManagement.makeDirectory(name: "json")
                DataManagement.makeDirectory(name: "depth")
                DataManagement.makeDirectory(name: "mesh")
                
                self.parameta_flag = true
                self.lastCameraTransform = self.sceneView.session.currentFrame?.camera.transform
                
                

            }
        }
        isScanning.toggle()
    }
    
    @objc func update() {
        if parameta_flag, shouldAccumulate(frame: sceneView.session.currentFrame!) {
            //depth,img,jsonデータを取得（データがない時はfalseを返す）
            let (depthData, depthBool) = depth_pointCloudRenderer.get_depthData()
            let (imgData, imgBool) = depth_pointCloudRenderer.get_imgData()
            let (jsonData, jsonBool) = depth_pointCloudRenderer.get_jsonData()
            if depthBool, imgBool, jsonBool {
                DispatchQueue.global().async { [self] in
                    DataManagement.saveData(name: "pic\(parametaCount).jpg", Data: imgData)
                    DataManagement.saveData(name: "json\(parametaCount).data", Data: jsonData)
                    //DataManagement.saveData(name: "depth\(parametaCount).data", Data: depthData)
                    DispatchQueue.main.async {
                        self.parametaCount += 1
                        //self.takeParametaCountLabel.text = "取得パラメータ数：\(self.parametaCount)"
                        print("取得パラメータ数：\(self.parametaCount)")
                    }
                }
            }
        }
    }
    
    @IBAction func testTap(_ sender: UIButton) {
        print("testtap")
        
    }
    
    
//    let degreesToRadian = Float.pi / 180
    private let cameraRotationThreshold = cos(2 * Float.pi / 180)
    private let cameraTranslationThreshold: Float = pow(0.02, 2)
    var lastCameraTransform: simd_float4x4!
    
    //デバイスの移動が小さければfalse
    private func shouldAccumulate(frame: ARFrame) -> Bool {
        //return true
        let cameraTransform = frame.camera.transform
        let shouldAccum = dot(cameraTransform.columns.2, lastCameraTransform.columns.2) <= cameraRotationThreshold
        || distance_squared(cameraTransform.columns.3, lastCameraTransform.columns.3) >= cameraTranslationThreshold
        return shouldAccum
    }
    
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
            for anchor in anchors {
                var sceneNode : SCNNode?
                if let meshAnchor = anchor as? ARMeshAnchor {
                    print(meshAnchor)
                    let meshGeometry = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                    sceneNode = SCNNode(geometry: meshGeometry)
                }
                if let node = sceneNode {
                    node.simdTransform = anchor.transform
                    knownAnchors[anchor.identifier] = node
                    //node.name = “mesh”
                    //meshAnchors_array.append(node.name!)
                    //anchor_picNum[anchor.identifier] = [parametaCount]
                    //if mapping_mesh_flag == true {
                        //print(“メッシュ追加“)
                        //sceneView.scene.rootNode.addChildNode(node)
                    //}
                    //modelView.scene?.rootNode.addChildNode(node)
                    sceneView.scene.rootNode.addChildNode(node)
                }
            }
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        if mesh_flag {
//            var meshAnchors = [ARMeshAnchor]()
            for anchor in anchors {
                if let node = knownAnchors[anchor.identifier] {
                    if let meshAnchor = anchor as? ARMeshAnchor {
//                        meshAnchors.append(meshAnchor) //updateされたメッシュ情報
//                        if anchor_picNum[meshAnchor.identifier]?.firstIndex(of: parametaCount) == nil {
//                            anchor_picNum[meshAnchor.identifier]!.append(parametaCount)
//                        }
                        node.geometry = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                    }
                    node.simdTransform = anchor.transform
                }
            }
            //depth_pointCloudRenderer.meshAnchors = meshAnchors
//        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let node = knownAnchors[anchor.identifier] {
                node.removeFromParentNode()
                // knownAnchors からも削除
                knownAnchors.removeValue(forKey: anchor.identifier)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if parameta_flag == true {
            self.depth_pointCloudRenderer.draw_depth() //深度情報
//            if mappingSupportFlag == false {
//                self.depth_pointCloudRenderer.draw_mapping() //マッピング支援
//                if remap_flag {
//                    depth_pointCloudRenderer.meshAnchors = remapAnchors
//                }
//            }
        }
    }
    
}
