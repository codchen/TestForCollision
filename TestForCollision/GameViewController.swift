

//
//  GameViewController.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity
import CoreMotion

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

struct message{
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var count: Int
    var time: NSTimeInterval
}

class GameViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    let serviceType = "TestCollision"
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    var myScene: GameScene!
    var lastCount: Dictionary<String, Int> = Dictionary<String, Int>()
    
    var lastFinish: NSDate!
    var currentTime: NSDate!
    
    var initialized = false
    
    let motionManager: CMMotionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // create the browser viewcontroller with a unique service name
        self.browser = MCBrowserViewController(serviceType:serviceType,
            session:self.session)
        
        self.browser.delegate = self;
        
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
            discoveryInfo:nil, session:self.session)
        
        // tell the assistant to start advertising our fabulous chat
        self.assistant.start()
    }
    
    override func viewDidAppear(animated: Bool) {
        if (myScene == nil){
            self.presentViewController(browser, animated: animated, completion: nil)
        }
    }
    
    func browserViewControllerDidFinish(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is dismissed (ie the Done
            // button was tapped)
            
            dismissViewControllerAnimated(true, completion: nil)
            if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                self.myScene = scene
                // Configure the view.
                let skView = self.view as SKView
                skView.showsFPS = true
                skView.showsNodeCount = true
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .AspectFill
                
                scene.session = self.session
                
                self.motionManager.accelerometerUpdateInterval = 0.1
                self.motionManager.startAccelerometerUpdates()
                
                scene.motionManager = self.motionManager
                
                skView.presentScene(scene)
            }
    }
    
    func browserViewControllerWasCancelled(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is cancelled
            
            dismissViewControllerAnimated(true, completion: nil)
            if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                self.myScene = scene
                // Configure the view.
                let skView = self.view as SKView
                skView.showsFPS = true
                skView.showsNodeCount = true
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .AspectFill
                
                scene.session = self.session
                
                skView.presentScene(scene)
            }
            
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!,
        fromPeer peerID: MCPeerID!)  {
//            if (self.initialized){
//                print("Session interval: \(NSDate().timeIntervalSinceDate(self.lastFinish))\n")
//            }
            dispatch_async(dispatch_get_main_queue()){
                self.currentTime = NSDate()
                if (self.myScene != nil){
                    var thisMessage = UnsafePointer<message>(data.bytes).memory
                    //println("x: \(thisMessage.x), y: \(thisMessage.y)\n")
//                    print("Latency: \(self.currentTime.timeIntervalSince1970 - thisMessage.time)\n")
                    if (contains(self.myScene.peerList, peerID.displayName) == false){
                        var newNode = SKSpriteNode(imageNamed: "50x50_ball") as SKSpriteNode
                        newNode.position = CGPoint(x: thisMessage.x, y: thisMessage.y)
                        newNode.name = peerID.displayName
                        newNode.physicsBody = SKPhysicsBody(circleOfRadius: newNode.size.width / 2)
                        newNode.physicsBody?.velocity = CGVector(dx: thisMessage.dx, dy: thisMessage.dy)
                        newNode.physicsBody?.linearDamping = 0
                        newNode.physicsBody?.restitution = 1
                        self.myScene.addChild(newNode)
                        
                        self.myScene.peerList.append(peerID.displayName)
                        self.myScene.peerNodesInfo[peerID.displayName] = nodeInfo(x: thisMessage.x, y: thisMessage.y, dx: thisMessage.dx, dy: thisMessage.dy)
                        self.myScene.peerNodesUpdated[peerID.displayName] = true
                        
                        self.lastCount[peerID.displayName] = thisMessage.count
                    }
                    else if (thisMessage.count > self.lastCount[peerID.displayName]){
                        self.lastCount[peerID.displayName] = thisMessage.count
                        self.myScene.peerNodesInfo[peerID.displayName] = nodeInfo(x: thisMessage.x, y: thisMessage.y, dx: thisMessage.dx, dy: thisMessage.dy)
                        self.myScene.peerNodesUpdated[peerID.displayName] = true
                    }
                }
            }
            
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(session: MCSession!,
        didStartReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!)  {
            
            // Called when a peer starts sending a file to us
    }
    
    func session(session: MCSession!,
        didFinishReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!,
        atURL localURL: NSURL!, withError error: NSError!)  {
            // Called when a file has finished transferring from another peer
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!,
        withName streamName: String!, fromPeer peerID: MCPeerID!)  {
            // Called when a peer establishes a stream with us
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!,
        didChangeState state: MCSessionState)  {
            // Called when a connected peer changes state (for example, goes offline)
            
    }
}
