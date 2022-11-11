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

class MappingViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
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
    var imageData: Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.session.delegate = self
        sceneView.scene = scene
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
        if let View = sceneView {
            self.depth_pointCloudRenderer = MappingSupport.depth_Renderer(session: View.session, metalDevice: View.device!, sceneView: View)
            self.depth_pointCloudRenderer.drawRectResized(size: View.bounds.size)
        }
        
        //保存ディレクトリの初期化
        DataManagement.removeDirectory(name: "保存前")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configuration.environmentTexturing = .none
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func scanStartButtonTapped(_ sender: UIButton) {
        print("startTapped")
        
        if isScanning {
            UIView.animate(withDuration: 0.2) {
                self.scanStartButton.layer.cornerRadius = 25
                self.scanStopButton.layer.cornerRadius = 27.5
                
                self.parameta_flag = false
                    
                self.save_allData()
                
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
                DataManagement.makeDirectory(name: "保存前/pic")
                DataManagement.makeDirectory(name: "保存前/json")
                DataManagement.makeDirectory(name: "保存前/depth")
                DataManagement.makeDirectory(name: "保存前/mesh")
                
                //マッピング開始時の画像を取得
                let startImg = self.sceneView.snapshot()
                self.imageData = startImg.jpegData(compressionQuality: 0.5)
                
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
                    DataManagement.saveData(name: "保存前/pic/pic\(parametaCount).jpg", Data: imgData)
                    DataManagement.saveData(name: "保存前/json/json\(parametaCount).data", Data: jsonData)
                    DataManagement.saveData(name: "保存前/depth/depth\(parametaCount).data", Data: depthData)
                    DispatchQueue.main.async {
                        self.parametaCount += 1
                        //self.takeParametaCountLabel.text = "取得パラメータ数：\(self.parametaCount)"
                        print("取得パラメータ数：\(self.parametaCount)")
                    }
                }
            }
        }
    }
    
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
    
    func save_allData() {
        
        self.save_meshData()
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = format.string(from: date)
        print("現在時刻：\(filename)")
        
        DataManagement.rename(oldName: "保存前", newName: filename)
        
        self.save_worldmapData(filename: filename)
    }
    
    //mesh保存
    func save_meshData() {
        guard let anchors = sceneView.session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor}
        
        for (i, anchor) in meshAnchors.enumerated() {
            
            guard let meshData = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else{ return }
            
            //メッシュデータを保存
            DataManagement.saveData(name: "保存前/mesh/mesh\(i).data", Data: meshData)
        }
    }
    
    //worldmap保存
    func save_worldmapData(filename: String) {
        sceneView.session.getCurrentWorldMap { [self] worldMap, error in
            if let map = worldMap {
                if let worldData = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) {
                    
                    //データをドキュメント内に保存
                    DataManagement.saveData(name: "\(filename)/worldMap.data", Data: worldData)
                    DataManagement.saveData(name: "\(filename)/worldImage.jpg", Data: imageData!)
                }
            }
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if parameta_flag == true {
            self.depth_pointCloudRenderer.draw_depth() //深度情報
            self.depth_pointCloudRenderer.draw_mapping() //マッピング支援
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            var sceneNode : SCNNode?
            if let meshAnchor = anchor as? ARMeshAnchor {
                let meshGeometry = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                sceneNode = SCNNode(geometry: meshGeometry)
            }
            if let node = sceneNode {
                node.simdTransform = anchor.transform
                knownAnchors[anchor.identifier] = node
                //sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var meshAnchors = [ARMeshAnchor]()
        for anchor in anchors {
            if let node = knownAnchors[anchor.identifier] {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    meshAnchors.append(meshAnchor) //updateされたメッシュ情報
                    node.geometry = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                }
                node.simdTransform = anchor.transform
            }
        }
        depth_pointCloudRenderer.meshAnchors = meshAnchors
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
    
}
