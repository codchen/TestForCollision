//
//  GameScene.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity
import CoreMotion

struct nodeInfo {
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    
    var node1: SKSpriteNode!

    var session: MCSession!
    var motionManager: CMMotionManager!
    
    var c = 0
    
    //node info
    var peerList: [String] = []
    var peerNodesInfo: Dictionary<String, nodeInfo> = Dictionary<String, nodeInfo>()
    var peerNodesUpdated: Dictionary<String, Bool> = Dictionary<String, Bool>()
    
    var currentComputingNode: SKSpriteNode!
    var currentNodeInfo: nodeInfo!
    
    var offset: CGFloat!
    
    //physics constants
    let maxSpeed = 600
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        node1 = SKSpriteNode(imageNamed: "50x50_ball")

        node1.physicsBody = SKPhysicsBody(circleOfRadius: node1.size.width / 2)
        node1.physicsBody?.linearDamping = 0
        node1.physicsBody?.restitution = 1
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: -node1.size.width, y: playableMargin - node1.size.height, width: size.width + node1.size.width * 2, height: size.height - playableMargin * 2 + node1.size.height * 2)
        
        node1.position = randomPos()
        addChild(node1)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        offset = point1.distanceTo(point2)
        if offset >= node1.size.width / 2{
            return false
        }
        return true
    }
    
    func update_peer_dead_reckoning(nodeName: String){
//        if closeEnough(node2.position, point2: CGPoint(x: x + abs(t_delay) * dx, y: y + abs(t_delay) * dy)){
//            node2.physicsBody!.velocity.dx = (x + (abs(t_delay) + 1) * dx - node2.position.x)
//            node2.physicsBody!.velocity.dy = (y + (abs(t_delay) + 1) * dy - node2.position.y)
//        }
//        else{
//            node2.physicsBody!.velocity.dx = dx
//            node2.physicsBody!.velocity.dy = dy
//        }
        currentComputingNode = childNodeWithName(nodeName) as SKSpriteNode
        currentNodeInfo = peerNodesInfo[nodeName]
        if closeEnough(currentComputingNode.position, point2: CGPoint(x: currentNodeInfo.x, y: currentNodeInfo.y)){
            currentComputingNode.physicsBody!.velocity.dx = currentNodeInfo.dx
            currentComputingNode.physicsBody!.velocity.dy = currentNodeInfo.dy
        }
        else{
            //TODO if not close enough, consider directly adjust the position. If so, this adjustment wont occur frequently
            currentComputingNode.physicsBody!.velocity.dx = currentNodeInfo.dx + (currentNodeInfo.x - currentComputingNode.position.x) / 0.2
            currentComputingNode.physicsBody!.velocity.dy = currentNodeInfo.dy + (currentNodeInfo.y - currentComputingNode.position.y) / 0.2
        }
        peerNodesUpdated[nodeName] = false
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        //move_from_accelerometer()
    }
    
    override func didEvaluateActions() {
        for name in peerList{
            if (peerNodesUpdated[name] == true){
                update_peer_dead_reckoning(name)
            }
        }
    }
    
    override func didSimulatePhysics() {
        
        if session.connectedPeers.count >= 1{
            //if (lastSpeed != node1.physicsBody?.velocity){
            var error: NSError?
            var m = message(x: node1.position.x, y: node1.position.y, dx: node1.physicsBody!.velocity.dx, dy: node1.physicsBody!.velocity.dy, count: c, time: NSDate().timeIntervalSince1970)
            c++
            let data = NSData(bytes: &m, length: sizeof(message))
            session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable, error: &error)
            if (error != nil){println("error")}
            //lastSpeed = node1.physicsBody?.velocity
            //}
        }
    }
    
    func move_from_accelerometer(){
        if let data = motionManager.accelerometerData{
            node1.physicsBody!.velocity.dx = CGFloat(data.acceleration.y) * CGFloat(maxSpeed)
            node1.physicsBody!.velocity.dy = CGFloat(-1 * data.acceleration.x) * CGFloat(maxSpeed)
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        //node1.physicsBody?.applyForce(CGVector(dx: -50, dy: 0))
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        node1.physicsBody?.velocity = CGVector(dx: loc.x - node1.position.x, dy: loc.y - node1.position.y)
    }
}
