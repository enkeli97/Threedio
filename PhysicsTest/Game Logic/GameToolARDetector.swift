//
//  GameToolIdentifier.swift
//  PhysicsTest
//
//  Created by Raffaele Tontaro on 07/03/18.
//  Copyright © 2018 Raffaele Tontaro. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

/**
 Handles everything that has to do with the initial phase of the game: plane detection
 */

class GameToolARDetector: NSObject, GameTool {
    
    var sceneView: ARSCNView!
    var listeners = GameToolListenerList()
    var playfloor: SCNNode?
    var origin: SCNNode?
    var plane: SCNNode!
    
    //plane dimensions (1 = 1 metro)
    private let globalWidth: CGFloat = 2.0
    private let globalHeight: CGFloat = 2.0
    private let cellSize: CGFloat = 0.1
    private var planeDetected = false
    
    required init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        
        plane = SCNNode()
        let planeGeometry = SCNPlane(width: globalWidth, height: globalHeight)
        planeGeometry.materials = [createGridMaterial(plane: planeGeometry)]
        plane.geometry = planeGeometry
        sceneView.scene.rootNode.addChildNode(plane)
        plane.eulerAngles.x = -.pi / 2
    }
    
    func onUpdate(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let point = CGPoint(x: sceneView.frame.width / 2, y: sceneView.frame.height / 2)
        if let hit =  sceneView.hitTest(point, types: .existingPlaneUsingExtent).first {
            let camera = sceneView.pointOfView!
            let position = camera.convertPosition(SCNVector3(0,0, -hit.distance), to: sceneView.scene.rootNode)
            playfloor?.position = position
            origin?.position = position
            plane.position = position + SCNVector3(0, 0.01, 0)
            plane.isHidden = false
            self.origin?.isHidden = false
            playfloor?.eulerAngles.y = plane.eulerAngles.y
            origin?.eulerAngles.y = plane.eulerAngles.y
            planeDetected = true
        }
    }
    
    func onEnter() -> Any? {
        playfloor = sceneView.scene.rootNode.childNode(withName: "Playfloor", recursively: true)!
        origin = sceneView.scene.rootNode.childNode(withName: "Origin", recursively: true)!
        self.origin?.isHidden = true
        plane.isHidden = true
        
        return nil
    }
    
    func onTap(_ sender: UITapGestureRecognizer) -> Any? {
        if planeDetected {
            plane.removeFromParentNode()
            plane = nil
            return true
        } else {
            return false
        }
    }
    
    var currentPoint: CGPoint?
    var currentRotation: Float = 0
    let fullRotationDistance: CGFloat = 2000
    
    func onPan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            currentPoint = sender.translation(in: sceneView)
            currentRotation = plane.eulerAngles.y
        } else if sender.state == .changed {
            let newPoint = sender.translation(in: sceneView)
            let horizontalChange = newPoint.x - currentPoint!.x
            let rotation = 2 * Float.pi * Float(horizontalChange / fullRotationDistance)
            plane.eulerAngles.y = currentRotation + rotation
        }
    }
}

//MARK: - PRIVATE EXTENSION
private extension GameToolARDetector {
    func createGridMaterial(plane: SCNPlane) -> SCNMaterial {
        let wRepeat = Float(plane.width / cellSize)
        let hRepeat = Float(plane.height / cellSize)
        
        let image = UIImage(named: "grid.png")
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(wRepeat, hRepeat, 0)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        return material
    }
}


