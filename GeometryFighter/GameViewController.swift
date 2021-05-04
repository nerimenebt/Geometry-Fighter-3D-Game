//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Nerimene  on 22/05/2018.
//  Copyright © 2018 Nerimene . All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime:TimeInterval = 0
    var game = GameHelper.sharedInstance
    var splashNodes:[String:SCNNode] = [:]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
        setupSplash()
        setupSounds()
    }
    
    @objc func setupView()
    {
        scnView = (self.view as! SCNView)
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    @objc func spawnShape()
    {
        var geometry:SCNGeometry
        switch ShapeType.random()
        {
        case .Box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .Sphere:
            geometry = SCNSphere(radius: 0.5)
        case .Pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .Torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .Capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .Cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .Cone:
            geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
        case .Tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        }
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY , z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        if color == UIColor.black
        {
            geometryNode.name = "BAD"
            game.playSound(node: scnScene.rootNode, name: "SpawnBad")
        }
        else
        {
            geometryNode.name = "GOOD"
            game.playSound(node: scnScene.rootNode, name: "SpawnGood")
        }
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    @objc func setupCamera()
    {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    @objc func setupScene()
    {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "Background_Diffuse.png"
    }
    
    @objc func cleanScene()
    {
        for node in scnScene.rootNode.childNodes
        {
            if node.presentation.position.y < -2
            {
                node.removeFromParentNode()
            }
        }
    }
    
    @objc func setupHUD()
    {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    @objc func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem
    {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color.withAlphaComponent(0.5)
        trail.emitterShape = geometry
        return trail
    }
    
    @objc func createSplash(name:String, imageFileName:String) -> SCNNode
    {
        let plane = SCNPlane(width: 5, height: 5)
        let splashNode = SCNNode(geometry: plane)
        splashNode.position = SCNVector3(x: 0, y: 5, z: 0)
        splashNode.name = name
        splashNode.geometry?.materials.first?.diffuse.contents = imageFileName
        scnScene.rootNode.addChildNode(splashNode)
        return splashNode
    }
    
    @objc func showSplash(splashName:String)
    {
        for (name,node) in splashNodes
        {
            if name == splashName
            {
                node.isHidden = false
            }
            else
            {
                node.isHidden = true
            }
        }
    }
    
    @objc func setupSplash()
    {
        splashNodes["TapToPlay"] = createSplash(name: "TAPTOPLAY",
                                                imageFileName: "TapToPlay_Diffuse.png")
        splashNodes["GameOver"] = createSplash(name: "GAMEOVER",
                                               imageFileName: "GameOver_Diffuse.png")
        showSplash(splashName: "TapToPlay")
    }
    
    @objc func setupSounds()
    {
        game.loadSound(name: "ExplodeGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeGood.wav")
        game.loadSound(name: "SpawnGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnGood.wav")
        game.loadSound(name: "ExplodeBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeBad.wav")
        game.loadSound(name: "SpawnBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnBad.wav")
        game.loadSound(name: "GameOver",
                       fileNamed: "GeometryFighter.scnassets/Sounds/GameOver.wav")
    }
    
    @objc func handleGoodCollision()
    {
        game.score += 1
        game.playSound(node: scnScene.rootNode, name: "ExplodeGood")
    }
    
    @objc func handleBadCollision()
    {
        game.lives -= 1
        game.playSound(node: scnScene.rootNode, name: "ExplodeBad")
        game.shakeNode(node: cameraNode)
        if game.lives <= 0
        {
            game.saveState()
            showSplash(splashName: "GameOver")
            game.playSound(node: scnScene.rootNode, name: "GameOver")
            game.state = .GameOver
            scnScene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(duration: 5)
            {
                (node:SCNNode!) -> Void in
                self.showSplash(splashName: "TapToPlay")
                self.game.state = .TapToPlay
            })
        }
    }
    
    @objc func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4)
    {
        let explosion =
            SCNParticleSystem(named: "Explode.scnp", inDirectory:
                nil)!
        
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix =
            SCNMatrix4MakeRotation(rotation.w, rotation.x,
                                   rotation.y, rotation.z)
        let translationMatrix =
            SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix =
            SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if game.state == .GameOver
        {
            return
        }
        if game.state == .TapToPlay
        {
            game.reset()
            game.state = .Playing
            showSplash(splashName: "")
            return
        }
        let touch = touches.first
        let location = touch!.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0
        {
            let result: AnyObject! = hitResults[0]
            if result.node.name == "HUD" || result.node.name == "GAMEOVER" || result.node.name == "TAPTOPLAY"
            {
                return
            }
            else if result.node.name == "GOOD"
            {
                handleGoodCollision()
            }
            else if result.node.name == "BAD"
            {
                handleBadCollision()
            }
           // createExplosion(geometry: result.node.geometry!, position: result.node.presentation.position, rotation: result.node.presentation.rotation)
            result.node.removeFromParentNode()
        }
    }
    
    override var shouldAutorotate: Bool
    {
        return true
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        if UIDevice.current.userInterfaceIdiom == .phone
        {
            return .allButUpsideDown
        }
        else
        {
            return .all
        }
    }
}
extension GameViewController: SCNSceneRendererDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        if game.state == .Playing
        {
            if time > spawnTime
            {
                spawnShape()
                spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
            }
            cleanScene()
        }
        game.updateHUD()
    }
}
