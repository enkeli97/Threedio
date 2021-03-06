//
//  ViewController.swift
//  sceneview
//
//  Created by Sofia Passarelli on 16/02/18.
//  Copyright © 2018 Sofia Passarelli. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var shapeSelector: UIView!
    @IBOutlet weak var colorPicker: UIView!
    @IBOutlet weak var shapeView: UICustomView!
    @IBOutlet weak var colorView: UICustomView!
    @IBOutlet weak var selectorSwitcher: UIButton!
    @IBOutlet weak var throwButton: UIButton!
    @IBOutlet weak var dropButton: UIButton!
    @IBOutlet weak var deleterButton: UIButton!
    @IBOutlet weak var placerButton: UIButton!
    @IBOutlet weak var manipulatorButton: UIButton!
    
    var tapGesture = UITapGestureRecognizer()
    var builder : Builder?
    
    //for handling different anchors and different planes
    var globalAnchor: ARPlaneAnchor?
    
    //plane dimensions (1 = 1 metro)
    let globalWidth: CGFloat = 2.0
    let globalHeight: CGFloat = 2.0
    
    //grid dimensions, initialized in viewDidLoad() function
    var globalScaleX: Float?
    var globalScaleY: Float?
    
    var planeDetected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //sceneView.debugOptions.update(with: ARSCNDebugOptions.showWorldOrigin)
        //sceneView.debugOptions.update(with: ARSCNDebugOptions.showFeaturePoints)
        //sceneView.debugOptions.update(with: .showPhysicsShapes)
        //sceneView.debugOptions.update(with: .renderAsWireframe)
        //sceneView.debugOptions.update(with: .showBoundingBoxes)
        
        //initializing grid dimensions
        self.globalScaleX = (Float(globalWidth)  / 0.1).rounded()
        self.globalScaleY = (Float(globalHeight) / 0.1).rounded()
        
        sceneView.isUserInteractionEnabled = true
        //sceneView.showsStatistics = true
        
        sceneView.scene = SCNScene(named: "mys.scn")!
        //sceneView.scene = SCNScene()
        sceneView.session.delegate = self
        sceneView.delegate = self
        
        generateColors()
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        sceneView.addGestureRecognizer(tapGesture)
        //controller = Builder(targetView: sceneView)
        //controller.mode = .place
        //showSelectors(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        sceneView.session.pause()
    }
    
    func showSelectors(_ show: Bool?) {
        let value = show ?? shapeSelector.isHidden
        shapeView.isHidden = !value
        colorView.isHidden = true
        selectorSwitcher.isHidden = !value
    }
    
    func showManipulators(_ show: Bool?) {
        let value = show ?? throwButton.isHidden
        throwButton.isHidden = !value
        dropButton.isHidden = !value
    }
    
    func showTools(_ show: Bool?) {
        let value = show ?? placerButton.isHidden
        deleterButton.isHidden = !value
        placerButton.isHidden = !value
        manipulatorButton.isHidden = !value
    }
    
    @IBAction func onDeleterTap(_ sender: UIButton) {
        guard let controller = builder else {return}
        showSelectors(false)
        //showManipulators(false)
        controller.mode = .delete
    }
    
    @IBAction func onPlacerTap(_ sender: UIButton) {
        guard let controller = builder else {return}
        showSelectors(true)
        //showManipulators(false)
        controller.mode = .place
    }
    
    @IBAction func onManipulatortap(_ sender: UIButton) {
        guard let controller = builder else {return}
        showSelectors(false)
        //showManipulators(true)
        controller.mode = .manipulate
    }

    @IBAction func onThrowTap(_ sender: Any) {
        guard let controller = builder else {return}
        controller.throwObject()
    }
    
    
    @IBAction func onDropTap(_ sender: Any) {
        guard let controller = builder else {return}
        controller.dropObject()
    }
    
    
    @IBAction func switchSelectors(_ sender: UIButton) {
        shapeView.isHidden = !shapeView.isHidden
        colorView.isHidden = !colorView.isHidden
        if !shapeView.isHidden {
            selectorSwitcher.setImage(#imageLiteral(resourceName: "colorGradient"), for: .normal)
        } else {
            selectorSwitcher.setImage(#imageLiteral(resourceName: "IconConstruction"), for: .normal)
        }
    }
    
    func generateColors() {
        for child in colorPicker.subviews {
            let childButton = child as! UIButton
            GameMaterial.newMaterial(color: childButton.backgroundColor!, withName: childButton.title(for: .normal)!)
        }
    }
    
    var currentColorButton: UIButton? = nil
    @IBAction func selectColor(_ sender: UIButton) {
        guard let controller = builder else {return}
        controller.setMaterial(name: sender.title(for: .normal)!)
    }
    
    var currentShapeButton: UIButton? = nil
    @IBAction func selectShape(_ sender: UIButton) {
        guard let controller = builder else {return}
        if let title = sender.title(for: .normal) {
            controller.setGeometry(name: title)
        }
    }
    
    //MARK: Plane Selection (TAP)
    
    @objc func onTap() {
        if let plane = sceneView.scene.rootNode.childNode(withName: "piano", recursively: true) {
            planeDetected = true
            let playfloor = sceneView.scene.rootNode.childNode(withName: "Playfloor", recursively: true)!
            let origin = sceneView.scene.rootNode.childNode(withName: "Origin", recursively: true)!
            let position = plane.convertPosition(plane.position, to: sceneView.scene.rootNode)
            playfloor.position.y = position.y
            origin.position.y = position.y
            plane.removeFromParentNode()
            sceneView.removeGestureRecognizer(tapGesture)
            builder = Builder(targetView: sceneView)
            builder!.mode = .place
            showSelectors(true)
            showTools(true)
        }
    }
    
    //MARK: RENDERER
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        //unwrapping anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        if self.globalAnchor != nil && !self.planeDetected {
            if planeAnchor != self.globalAnchor {
                sceneView.session.remove(anchor: self.globalAnchor!)
                self.globalAnchor = planeAnchor
            }
        } else {
            self.globalAnchor = planeAnchor
        }
        
        if !self.planeDetected {
            let planeNode = self.createPlaneNode(anchor: self.globalAnchor!)
            node.addChildNode(planeNode)
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        //unwrapping anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        if planeAnchor != self.globalAnchor && !self.planeDetected {
            sceneView.session.remove(anchor: self.globalAnchor!)
            self.globalAnchor = planeAnchor
        }
        
        if !self.planeDetected {
            //Remove existing plane nodes
            node.enumerateChildNodes {
                (childNode, _) in
                childNode.removeFromParentNode()
            }
            
            let planeNode = self.createPlaneNode(anchor: self.globalAnchor!)
            node.addChildNode(planeNode)
        }
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        
        //plane dimensions
        let planeWidth = self.globalWidth
        let planeHeight = self.globalHeight
        
        //extensible plane
        //        let planeWidth = CGFloat(anchor.extent.x)
        //        let planeHeight = CGFloat(anchor.extent.z)
        
        //setting plane with dimensions
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        
        //setting plane material
        let planeMaterial = SCNMaterial()
        let gridImage = UIImage(named: "grid.png")
        planeMaterial.diffuse.contents = gridImage
        let scaleX = self.globalScaleX
        let scaleY = self.globalScaleY
        planeMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(scaleX!, scaleY!, 0)
        planeMaterial.diffuse.wrapS = .repeat
        planeMaterial.diffuse.wrapT = .repeat
        
        plane.firstMaterial = planeMaterial
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.name = "piano"
        
        let x = CGFloat(anchor.center.x)
        let y = CGFloat(anchor.center.y)
        let z = CGFloat(anchor.center.z)
        
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        planeNode.physicsBody = SCNPhysicsBody.static()
        
        return planeNode
    }
}
