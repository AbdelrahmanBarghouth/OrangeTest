//
//  ViewController.swift
//  Test
//
//  Created by Khaled Elfakharany on 13/11/2018.
//  Copyright © 2018 Khaled Elfakharany. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var scanFrame: UIImageView!
    
    @IBOutlet weak var menuIcon: UIButton!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var previousBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    
    var targetAnchor : ARAnchor!
    var targetPlane: SCNPlane!
    var targetPendlum : SCNNode!
    var day = 1
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/GameScene.scn")!
        
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARImageTrackingConfiguration()
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Photos", bundle: Bundle.main) else {
            print("Images not found")
            return
        }
        
        configuration.trackingImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        

        sceneView.session.run(configuration)
        
        hideActionGraphics()
        dayLabel.layer.cornerRadius = dayLabel.frame.height/2
        dayLabel.layer.masksToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            targetAnchor = imageAnchor
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.0)
            targetPlane = plane
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            
            let clockScene = SCNScene(named: "art.scnassets/clock1.scn")!
            let clockNode = clockScene.rootNode.childNodes.first!
            clockNode.position = SCNVector3Make(0, -0.026, 0)
            clockNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
            clockNode.position.z = 0.01
            
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            
            let minuteNode = clockScene.rootNode.childNode(withName: "min", recursively: true)
            minuteNode?.eulerAngles.z = Float(((360.0 - (6 * Double(minutes))) * Double.pi ) / 180)
            
            
            let hourNode = clockScene.rootNode.childNode(withName: "min", recursively: true)
            hourNode?.eulerAngles.z = Float(((360.0 - (6 * Double(hour * 5))) * Double.pi ) / 180)
            
            let pendulumNode = clockScene.rootNode.childNode(withName: "pendulum", recursively: true)
            targetPendlum = pendulumNode
            
            
            
            
            
            planeNode.addChildNode(clockNode)
            
            node.addChildNode(planeNode)
        }
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor, imageAnchor == targetAnchor{
            if imageAnchor.isTracked{
                ShowActionGraphics()
                updateDay(day: day)
            }else{
                hideActionGraphics()
            }
        }
        
    }
    
    
    // Helper Methods
    
    func randomCGFloat() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
    }
    
    func rotatePendlum() {
        let rotateAction = SCNAction.rotateTo(x: 1.1, y: 0, z: CGFloat(Float((30 * Double.pi ) / 180)), duration: 1)
        let rotateAction2 = SCNAction.rotateTo(x: 1.1, y: 0, z: CGFloat(Float((-30 * Double.pi ) / 180)), duration: 2)
        let rotateAction3 = SCNAction.rotateTo(x: 1.1, y: 0, z: CGFloat(Float((0 * Double.pi ) / 180)), duration: 1)
        let sequence = SCNAction.sequence([rotateAction, rotateAction2, rotateAction3])
        targetPendlum.runAction(sequence)
        playSound()
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "soundEffect", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func hideActionGraphics() {
        scanFrame.isHidden = false
        menuIcon.isHidden = true
        previousBtn.isHidden = true
        nextBtn.isHidden = true
        dayLabel.isHidden = true
    }
    
    func ShowActionGraphics() {
        updateDay(day: day)
        scanFrame.isHidden = true
        menuIcon.isHidden = false
        previousBtn.isHidden = false
        nextBtn.isHidden = false
        dayLabel.isHidden = false
    }
    
    func updateDay(day: Int) {
        if day == 1 {
            previousBtn.isHidden = true
        }else if day == 12 {
            nextBtn.isHidden = true
        }
        dayLabel.text = "Play Day " + String(day)
    }

    @IBAction func prevPressed(_ sender: Any) {
        rotatePendlum()
        day = day-1
        updateDay(day: day)
    }
    @IBAction func nextPressed(_ sender: Any) {
        rotatePendlum()
        day = day+1
        updateDay(day: day)
    }
    @IBAction func menuPressed(_ sender: Any) {
        
        targetPlane.firstMaterial?.diffuse.contents = UIColor(red: randomCGFloat(), green: randomCGFloat(), blue: randomCGFloat(), alpha: randomCGFloat())
    }
}
