//
//  ViewController.swift
//  AR-Hoops
//
//  Created by Martin Saporiti on 30/06/2018.
//  Copyright © 2018 Martin Saporiti. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var power : Float = 1.0
    
    let timer = Each(0.05).seconds
    
    var basketAdded = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                       ARSCNDebugOptions.showWorldOrigin]
        
        sceneView.autoenablesDefaultLighting = true
        configuration.planeDetection = .horizontal
        self.sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        tapGestureRecognizer.cancelsTouchesInView = false
        sceneView.session.run(configuration)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            self.planeDetectedLabel.isHidden = true
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer){
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
            
        }
    }
    
    func addBasket(hitTestResult: ARHitTestResult ){
        if (!basketAdded){
            let basketScene = SCNScene(named: "basket.scnassets/basketball.scn")
            let basketNode = basketScene?.rootNode.childNode(withName: "basket", recursively: false)
            
            let positionOfPlane = hitTestResult.anchor?.transform.columns.3
            let xPosition = positionOfPlane?.x
            let yPosition = positionOfPlane?.y
            let zPosition = positionOfPlane?.z
            
            basketNode?.position = SCNVector3(xPosition!, yPosition!, zPosition!)
            
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound : true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            
            sceneView.scene.rootNode.addChildNode(basketNode!)
            
            let backboard = basketNode?.childNode(withName: "backboard", recursively: false)
            backboard?.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "tablero")
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                self.basketAdded = true
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.basketAdded ){
            timer.perform(closure: { () -> NextStep in
                self.power += 1
                return .continue
            })
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded {
            timer.stop()
            shotBall()
        }
        power = 1
    }

    func shotBall(){
        guard let pointOfView = sceneView.pointOfView else {return}
        
        removeEveryOtherBall()
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "ball")
        ball.position = position
        ball.name = "ball"
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        body.restitution = 0.2
        ball.physicsBody = body
        ball.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    
    func removeEveryOtherBall(){
        self.sceneView.scene.rootNode.enumerateHierarchy{(node, _) in
            if (node.name == "ball"){
                node.removeFromParentNode()
            }
        }
    }
    
    deinit {
        timer.stop()
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

