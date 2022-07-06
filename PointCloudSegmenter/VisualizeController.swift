//
//  VisualizeController.swift
//  SceneDepthPointCloud
//
//  Created by User01 on 21/03/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SceneKit
import ARKit

struct PointCloudVertex {
    var x: Float, y: Float, z: Float
    var r: Float, g: Float, b: Float
}

class VisualizeController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var chosenCloud: URL!
    
    var tappedNode: SCNNode!
    var prevColor: Any!
    var firstCoordinate: SCNVector3!
    var secondCoordinate: SCNVector3!
    var distanceLine: SCNNode!
    
    var backButton = UIButton(type: .system)
    var modeButton = UIButton(type: .system)
    var infoText = UILabel()
    
    var volumeMode = true
    var volumeText = "Click to get volume"
    var distanceText = "Click two points"
    
    var volumeArray = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        backButton.setBackgroundImage(.init(systemName: "arrowshape.turn.up.left.fill"), for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(toMainMenu), for: .touchUpInside)
        backButton.tintColor = .white
        view.addSubview(backButton)
        
        modeButton.setBackgroundImage(.init(systemName: "rectangle.fill"), for: .normal)
        modeButton.translatesAutoresizingMaskIntoConstraints = false
        modeButton.addTarget(self, action: #selector(changeMode), for: .touchUpInside)
        modeButton.tintColor = .white
        view.addSubview(modeButton)
        
        infoText.text = "Click to get volume"
        infoText.translatesAutoresizingMaskIntoConstraints = false
        infoText.textColor = .white
        view.addSubview(infoText)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = true
        sceneView.gestureRecognizers?.remove(at: 2)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
        
        var xDir: Float = Float.infinity
        var yDir: Float = Float.infinity
        var zDir: Float = Float.infinity

        let scene = SCNScene()
        
        let pointCloud = FileReader.readFile(url: chosenCloud, raw: false)
        var prevId = -1
        
        for point in pointCloud {

            let x = point[0]
            let y = point[1]
            let z = point[2]
            let cls = Int(point[3])
            let vol = point[4]
            let id = Int(point[5])
            
            let node = getCircleNode(location: SCNVector3(x,y,z), classification: cls)
            if (xDir == Float.infinity) {
                xDir = 0 - node.position.x
                yDir = 0 - node.position.y
                zDir = -7 - node.position.z
            }
            
            if prevId != id {
                volumeArray.append(vol)
                prevId = id
            }
            
            node.position.x += xDir
            node.position.y += yDir
            node.position.z += zDir
            
            node.name = String(id)
            scene.rootNode.addChildNode(node)
            
        }
        
        sceneView.scene = scene
        sceneView.scene.background.contents = UIColor.black

        NSLayoutConstraint.activate([
            backButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            
            modeButton.widthAnchor.constraint(equalToConstant: 50),
            modeButton.heightAnchor.constraint(equalToConstant: 50),
            modeButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50),
            modeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            infoText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoText.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 150)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Enable both the `sceneDepth` and `smoothedSceneDepth` frame semantics.
        let config = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func toMainMenu() -> Void {
        sceneView.session.pause()
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "mainController") as! MainController
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    @objc func changeMode() -> Void {
        volumeMode = !volumeMode
        
        if volumeMode {
            modeButton.setBackgroundImage(.init(systemName: "rectangle.fill"), for: .normal)
            infoText.text = volumeText
            firstCoordinate = nil
            secondCoordinate = nil
            
            if distanceLine != nil {
                distanceLine.removeFromParentNode()
            }
            distanceLine = nil
        }
        else {
            modeButton.setBackgroundImage(.init(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
            infoText.text = distanceText
            if tappedNode != nil {
                sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
                    let material = $0.geometry!.firstMaterial!
                    material.diffuse.contents = prevColor
                })
            }
            tappedNode = nil
        }
    }
    
    @objc func handleTap(rec: UITapGestureRecognizer){
       if rec.state == .ended {
           let location: CGPoint = rec.location(in: sceneView)
           let hits = self.sceneView.hitTest(location, options: nil)
           
           if !hits.isEmpty{
               if volumeMode {
                   handleTapVolume(hits: hits)
               }
               else {
                   handleTapDistance(hits: hits)
               }
           }
       }
    }
    
    func handleTapVolume(hits: [SCNHitTestResult]) {
        if tappedNode != nil {
            sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
                let material = $0.geometry!.firstMaterial!
                material.diffuse.contents = prevColor
            })
        }
        
        tappedNode = hits.first?.node
        sceneView.scene.rootNode.childNodes.filter({ $0.name == tappedNode.name }).forEach({
            let material = $0.geometry!.firstMaterial!
            prevColor = material.diffuse.contents
            material.diffuse.contents = UIColor.white
        })
        
        let id = Int(tappedNode.name!)!
        let vol = volumeArray[id]
        let volRounded = Double(round(1000 * vol) / 1000)
        
        if vol == -1 {
            infoText.text = "Volume undefined"
        }
        else if vol < 0.001{
            infoText.text = "Volume < 0.001 m^3"
        }
        else {
            infoText.text = "Volume: \(volRounded) m^3"
        }
    }
    
    func handleTapDistance(hits: [SCNHitTestResult]) {
        if firstCoordinate == nil {
            firstCoordinate = hits.first?.worldCoordinates
            infoText.text = "Tap a second location"
            if distanceLine != nil {
                distanceLine.removeFromParentNode()
            }
        }
        else if secondCoordinate == nil {
            secondCoordinate = hits.first?.worldCoordinates
            
            let scene = sceneView.scene
            distanceLine = lineBetweenNodes(positionA: firstCoordinate, positionB: secondCoordinate, inScene: scene)
            let dist = getDistance(node1Pos: firstCoordinate, node2Pos: secondCoordinate)
            
            scene.rootNode.addChildNode(distanceLine)
            infoText.text = "Distance: \(dist) m\nTap a new location"
            
            firstCoordinate = nil
            secondCoordinate = nil
        }
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

func getCircleNode(location: SCNVector3, classification: Int) -> SCNNode {
    let palette = [
        UIColor.red,
        UIColor.green,
        UIColor.blue,
        UIColor.orange,
        UIColor.brown,
        UIColor.cyan,
        UIColor.magenta,
        UIColor.purple,
        UIColor.yellow,
        UIColor.systemPink,
        UIColor.systemIndigo,
        UIColor.lightGray,
        UIColor.darkGray,
    ]
    
    let sphere = SCNSphere(radius: 0.01)
    sphere.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
    sphere.firstMaterial?.diffuse.contents = palette[classification]
    
    let node = SCNNode(geometry: sphere)
    node.position.x = location.x
    node.position.y = location.y
    node.position.z = location.z
    
    return node
}

func getDistance(node1Pos: SCNVector3, node2Pos: SCNVector3) -> Float {
    let distance = SCNVector3 (
        node2Pos.x - node1Pos.x,
        node2Pos.y - node1Pos.y,
        node2Pos.z - node1Pos.z
    )
    let length: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
    
    return length
}

func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
    let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
    let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

    let lineGeometry = SCNCylinder()
    lineGeometry.radius = 0.005
    lineGeometry.height = CGFloat(distance)
    lineGeometry.radialSegmentCount = 5
    lineGeometry.firstMaterial!.diffuse.contents = UIColor.white

    let lineNode = SCNNode(geometry: lineGeometry)
    lineNode.position = midPosition
    lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
    return lineNode
}
