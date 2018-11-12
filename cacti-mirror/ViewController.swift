//
//  ViewController.swift
//  cacti-mirror
//
//  Created by Alexandra Berke on 11/11/18.
//  Copyright © 2018 aberke. All rights reserved.
//
// Refer to:
// https://developer.apple.com/documentation/arkit/building_your_first_ar_experience

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    let fadeDuration: TimeInterval = 0.3
    let rotateDuration: TimeInterval = 3
    let waitDuration: TimeInterval = 5
    
    lazy var fadeAndSpinAction: SCNAction = {
        return .sequence([
            .fadeIn(duration: fadeDuration),
            .rotateBy(x: 0, y: 0, z: CGFloat.pi * 360 / 180, duration: rotateDuration),
            .wait(duration: waitDuration),
            .fadeOut(duration: fadeDuration)
            ])
    }()
    
    lazy var fadeAction: SCNAction = {
        return .sequence([
            .fadeOpacity(by: 0.8, duration: fadeDuration),
            .wait(duration: waitDuration),
            .fadeOut(duration: fadeDuration)
            ])
    }()
    
    // Load the objects that will be used as overlay nodes.
    lazy var treeNode: SCNNode = {
        guard let scene = SCNScene(named: "tree.scn"),
            let node = scene.rootNode.childNode(withName: "tree", recursively: false) else { return SCNNode() }
        let scaleFactor = 0.005
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        // Rotate the object to match the orientation of the node it is overlayed on to.
        node.eulerAngles.x = -.pi / 2
        return node
    }()
    
    lazy var cactusNode: SCNNode = {
        guard let scene = SCNScene(named: "art.scnassets/cactus.scn"),
            let node = scene.rootNode.childNode(withName: "cactus", recursively: false) else { return SCNNode() }
        let scaleFactor = 0.002
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        return node
    }()
    
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
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        let imageName = referenceImage.name ?? "no name"
        
        let overlayNode = self.getNode(withImageName: imageName)
        overlayNode.opacity = 1 //0
        overlayNode.position.y = 0.2
        overlayNode.runAction(self.fadeAndSpinAction)
        
        node.addChildNode(overlayNode)
        
        DispatchQueue.main.async {
            self.label.text = "cacti detected (\"\(imageName)\")"
        }
    }
    
    func getPlaneNode(withReferenceImage image: ARReferenceImage) -> SCNNode {
        let plane = SCNPlane(width: image.physicalSize.width,
                             height: image.physicalSize.height)
        let node = SCNNode(geometry: plane)
        return node
    }
    
    func getNode(withImageName name: String) -> SCNNode {
        var node = SCNNode()
        switch name {
        case "lego-cactus-board-for-ar":
            node = cactusNode
        case "lego-cactus-board-top":
            node = treeNode
        default:
            break
        }
        return node
    }
    
}
