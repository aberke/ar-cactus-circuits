//
//  ViewController.swift
//  cacti-mirror
//
//  Created by Alexandra Berke on 11/11/18.
//  Copyright © 2018 aberke. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// Toggle debug variable to true to show detected plane.
var debug = false


class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    let fadeDuration: TimeInterval = 0.3
    let rotateDuration: TimeInterval = 3
    
    var cactusFound: Bool = false
    
    lazy var fadeAndSpinAction: SCNAction = {
        return .sequence([
            .fadeIn(duration: fadeDuration),
            .wait(duration: 3),
            .rotateBy(x: 0, y: 0, z: CGFloat.pi * 360 / 180, duration: rotateDuration),
            .wait(duration: 3),
            .fadeOut(duration: fadeDuration),
        ])
    }()
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 3),
            .removeFromParentNode()
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    @IBAction func resetButtonDidTouch(_ sender: UIBarButtonItem) {
        resetTrackingConfiguration()
    }
    
    func resetTrackingConfiguration() {
        // This is the function that sets of the AR configuration.
        // ARWorldTrackingConfiguration class provides motion tracking and enables
        // features to help you place virtual content in relation to real-world surfaces.
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        sceneView.session.run(configuration, options: options)
        self.cactusFound = false
        label.text = "searching for circuits"
    }
}

extension ViewController: ARSCNViewDelegate {
    // By default, the ARSCNView class adds an SCNNode object to the SceneKit scene for each anchor.
    // Your view’s delegate can implement the renderer(_:didAdd:for:) method to add content
    // to the scene.
    // When you add content as a child of the node corresponding to the anchor,
    // the ARSCNView class automatically moves that content as ARKit refines its
    // estimate of the plane’s position.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Get the anchor
        if (self.cactusFound) {
            return
        }
        self.cactusFound = true
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        // ----- Debugging plane ---------------
        if (debug) {
            let debugPlaneNode = getDebugPlaneNode(withReferenceImage: referenceImage)
            node.addChildNode(debugPlaneNode)
        }
        // ----- Debugging plane ---------------
        let scene = SCNScene(named: "art.scnassets/cactus.scn")!
        let cactusNode = scene.rootNode.childNode(withName: "cactus", recursively: true)!
        let scaleFactor = 0.012
        cactusNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        cactusNode.opacity = 1
        cactusNode.runAction(self.fadeAndSpinAction)
        // Add the cactus node to the scene
        node.addChildNode(cactusNode)
        DispatchQueue.main.async {
            self.label.text = "cacti detected"
        }
    }

    func getDebugPlaneNode(withReferenceImage image: ARReferenceImage) -> SCNNode {
        // Create a plane to visualize the initial position of the detected image.
        let plane = SCNPlane(width: image.physicalSize.width,
                             height: image.physicalSize.height)
        let node = SCNNode(geometry: plane)
        node.opacity = 0.25
        //`SCNPlane` is vertically oriented in its local coordinate space, but
        //`ARImageAnchor` assumes the image is horizontal in its local space, so
        //rotate the plane to match.
        node.eulerAngles.x = -.pi / 2
        node.runAction(self.imageHighlightAction)
        return node
    }
}
