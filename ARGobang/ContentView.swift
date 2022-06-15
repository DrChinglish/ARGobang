//
//  ContentView.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/13.
//

import SwiftUI
import ARKit
import UIKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GobangController {
        let storyboard = UIStoryboard(name: "ARStoryboard", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "GoBangController")
        return controller as! GobangController
    }
    
    func updateUIViewController(_ uiViewController: GobangController, context: Context) {
        
    }
    
    typealias UIViewControllerType = GobangController
    
    
}

class GobangController:UIViewController,ARSCNViewDelegate{
    
    @IBOutlet weak var planeSearchLabel: UILabel!
    @IBOutlet weak var planeSearchOverlay: UIView!
    @IBOutlet weak var gameStateLabel: UILabel!
    @IBOutlet weak var startbutton:UIButton!
    @IBAction func didTapStartOver(_ sender: Any) {
        reset()
        startbutton.isHidden = true
    }
    @IBOutlet weak var ARSceneview:ARSCNView!
//    var playerType
    private func updatePlaneOverlay() {
        DispatchQueue.main.async {
            
        self.planeSearchOverlay.isHidden = self.currentPlane != nil
        self.startbutton.isHidden = self.currentPlane == nil
        if self.planeCount == 0 {
            self.planeSearchLabel.text = "Move around to allow the app to find a plane..."
        } else {
            self.planeSearchLabel.text = "Tap on a plane surface to place board..."
        }
            
        }
    }
    var playerType = [
            GamePlayer.x: GamePlayerType.human,
            GamePlayer.o: GamePlayerType.ai
    ]
    
    var planeCount=0{
        didSet{
            updatePlaneOverlay()
        }
    }
    
    var currentPlane:SCNNode?{
        didSet{
            updatePlaneOverlay()
            newTurn()
        }
    }
    
    let board=Board()
    
    var gamestate:GameState!{
        didSet{
            //state label
            if let winner = gamestate.currentWinner{
                let alert = UIAlertController(title: "Game Over", message: "\(winner.rawValue) wins!!!!", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                                    self.reset()
                                }))
                                present(alert, animated: true, completion: nil)
            }
        }
    }
    var figures:[String:SCNNode] = [:]
    var lightNode:SCNNode?
    var floorNode:SCNNode?
    var draggingFrom:GamePosition? = nil
    var draggingFromPosition:SCNVector3? = nil
        
        // from demo APP
        // Use average of recent virtual object distances to avoid rapid changes in object scale.
        var recentVirtualObjectDistances = [CGFloat]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            startbutton.isHidden = true
            gameStateLabel.isHidden = true
            gamestate = GameState()  // create new game
            
            ARSceneview.delegate = self
            //sceneView.showsStatistics = true
            //sceneView.antialiasingMode = .multisampling4X
            //sceneView.preferredFramesPerSecond = 60
            //sceneView.contentScaleFactor = 1.3
            ARSceneview.antialiasingMode = .multisampling4X
            
            ARSceneview.automaticallyUpdatesLighting = false
            
            let tap = UITapGestureRecognizer()
            tap.addTarget(self, action: #selector(didTap))
            ARSceneview.addGestureRecognizer(tap)
            
            let pan = UIPanGestureRecognizer()
            pan.addTarget(self, action: #selector(didPan))
            ARSceneview.addGestureRecognizer(pan)
        }
        
        // from APples app
        func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
            if ARSceneview.scene.lightingEnvironment.contents == nil {
                if let environmentMap = UIImage(named: "Asset/environment_blur.exr") {
                    ARSceneview.scene.lightingEnvironment.contents = environmentMap
                }
            }
            ARSceneview.scene.lightingEnvironment.intensity = intensity
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.isLightEstimationEnabled = true
            
            ARSceneview.session.run(configuration)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            ARSceneview.session.pause()
        }
        
        private func reset() {
            let alert = UIAlertController(title: "Game type", message: "Choose players", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "x:HUMAN vs o:AI", style: .default, handler: { action in
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.human,
                    GamePlayer.o: GamePlayerType.ai
                    ])
            }))
            alert.addAction(UIAlertAction(title: "x:HUMAN vs o:HUMAN", style: .default, handler: { action in
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.human,
                    GamePlayer.o: GamePlayerType.human
                    ])
            }))
            alert.addAction(UIAlertAction(title: "x:AI vs o:AI", style: .default, handler: { action in
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.ai,
                    GamePlayer.o: GamePlayerType.ai
                    ])
            }))
            present(alert, animated: true, completion: nil)
            
            
            
        }
        
        private func beginNewGame(_ players:[GamePlayer:GamePlayerType]) {
            playerType = players
            gamestate = GameState()
            
            removeAllFigures()
            
            figures.removeAll()
        }
        
        private func newTurn() {
            //to implement ai here
        }
        
        private func removeAllFigures() {
            for (_, figure) in figures {
                figure.removeFromParentNode()
            }
        }
        
        private func restoreGame(at position:SCNVector3) {
            board.node.position = position
            ARSceneview.scene.rootNode.addChildNode(board.node)
            
            let light = SCNLight()
            light.type = .directional
            light.castsShadow = true
            light.shadowRadius = 200
            light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            light.shadowMode = .deferred
            let constraint = SCNLookAtConstraint(target: board.node)
            lightNode = SCNNode()
            lightNode!.light = light
            lightNode!.position = SCNVector3(position.x + 10, position.y + 10, position.z)
            // lightNode!.eulerAngles = SCNVector3(45.0.degreesToRadians, 0, 0)
            lightNode!.constraints = [constraint]
            ARSceneview.scene.rootNode.addChildNode(lightNode!)
     
            
            for (key, figure) in figures {
                // yeah yeah, I know I should turn GamePosition into a struct and provide it with
                // Equtable and Hashable then this stupid stringy stuff would be gone. Will do this eventually
                let xyComponents = key.components(separatedBy: "x")
                guard xyComponents.count == 2,
                      let x = Int(xyComponents[0]),
                      let y = Int(xyComponents[1]) else { fatalError() }
                put(piece: figure,
                    at: (x: x,
                         y: y))
            }
        }
        
        private func groundPositionFrom(location:CGPoint) -> SCNVector3? {
            let query = ARSceneview.raycastQuery(from: location, allowing: .existingPlaneInfinite, alignment: .any)
            let results : [ARRaycastResult] = ARSceneview.session.raycast(query!)
            guard results.count > 0 else { return nil }
            
            return SCNVector3.positionFromTransform(results[0].worldTransform)
        }
        
        private func anyPlaneFrom(location:CGPoint) -> (SCNNode, SCNVector3)? {
            let query = ARSceneview.raycastQuery(from: location, allowing: .existingPlaneInfinite, alignment: .any)
            let results = ARSceneview.session.raycast(query!)
            guard results.count > 0,
                  let anchor = results[0].anchor,
                  let node = ARSceneview.node(for: anchor) else { return nil }
            
            return (node, SCNVector3.positionFromTransform(results[0].worldTransform))
        }
        
        private func squareFrom(location:CGPoint) -> ((Int, Int), SCNNode)? {
            guard let _ = currentPlane else { return nil }
            
            let hitResults = ARSceneview.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: false,SCNHitTestOption.rootNode:board.node])
            
            for result in hitResults {
                if let square = board.node2sqr[result.node] {
                    return (square, result.node)
                }
            }
            return nil
        }
        
        private func revertDrag() {
            if let draggingFrom = draggingFrom {
                
                let restorePosition = ARSceneview.scene.rootNode.convertPosition(draggingFromPosition!, from: board.node)
                let action = SCNAction.move(to: restorePosition, duration: 0.3)
                figures["\(draggingFrom.x)x\(draggingFrom.y)"]?.runAction(action)
                
                self.draggingFrom = nil
                self.draggingFromPosition = nil
            }
        }
        
        // MARK: - Gestures
        
        @objc func didPan(_ sender:UIPanGestureRecognizer) {
            guard case .move = gamestate.mode,
                  playerType[gamestate.currentPlayer]! == .human else { return }
            
            let location = sender.location(in: ARSceneview)
            
            switch sender.state {
            case .began:
                print("begin \(location)")
                guard let square = squareFrom(location: location) else { return }
                draggingFrom = (x: square.0.0, y: square.0.1)
                draggingFromPosition = square.1.position
                
            case .cancelled:
                print("cancelled \(location)")
                revertDrag()
                
            case .changed:
                print("changed \(location)")
                guard let draggingFrom = draggingFrom,
                      let groundPosition = groundPositionFrom(location: location) else { return }
                
                let action = SCNAction.move(to: SCNVector3(groundPosition.x, groundPosition.y + Float(Dimensions.DRAG_LIFTOFF), groundPosition.z),duration: 0.1)
                figures["\(draggingFrom.x)x\(draggingFrom.y)"]?.runAction(action)
                
            case .ended:
                print("ended \(location)")
                
                guard let draggingFrom = draggingFrom,
                    let square = squareFrom(location: location),
                    square.0.0 != draggingFrom.x || square.0.1 != draggingFrom.y,
                    let newGameState = gamestate.perform(action: .move(from: draggingFrom,to: (x: square.0.0, y: square.0.1))) else {
                        revertDrag()
                        return
                }
                
                
                
                // move in visual model
                let toSquareId = "\(square.0.0)x\(square.0.1)"
                figures[toSquareId] = figures["\(draggingFrom.x)x\(draggingFrom.y)"]
                figures["\(draggingFrom.x)x\(draggingFrom.y)"] = nil
                self.draggingFrom = nil
                
                // copy pasted insert thingie
                let newPosition = ARSceneview.scene.rootNode.convertPosition(square.1.position,
                                                                           from: square.1.parent)
                let action = SCNAction.move(to: newPosition,
                                            duration: 0.1)
                figures[toSquareId]?.runAction(action) {
                    DispatchQueue.main.async {
                        self.gamestate = newGameState
                    }
                }
                
            case .failed:
                print("failed \(location)")
                revertDrag()
                
            default: break
            }
        }
        
        @objc func didTap(_ sender:UITapGestureRecognizer) {
            let location = sender.location(in: ARSceneview)
            
            // tap to place board..
            guard let _ = currentPlane else {
                guard let newPlaneData = anyPlaneFrom(location: location) else { return }
                
                let floor = SCNFloor()
                floor.reflectivity = 0
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.white
                
                // https://stackoverflow.com/questions/30975695/scenekit-is-it-possible-to-cast-an-shadow-on-an-transparent-object/44799498#44799498
                material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
                floor.materials = [material]
                
                floorNode = SCNNode(geometry: floor)
                floorNode!.position = newPlaneData.1
                ARSceneview.scene.rootNode.addChildNode(floorNode!)
                
                self.currentPlane = newPlaneData.0
                restoreGame(at: newPlaneData.1)
                
                return
            }
            
            // otherwise tap to place board piece.. (if we're in "put" mode)
            guard case .put = gamestate.mode,
                  playerType[gamestate.currentPlayer]! == .human else { return }
            
            if let squareData = squareFrom(location: location),
               let newGameState = gamestate.perform(action: .put(at: (x: squareData.0.0,y: squareData.0.1))) {
                
                put(piece: Chess.chess(for: gamestate.currentPlayer),
                    at: squareData.0) {
                        DispatchQueue.main.async {
                            self.gamestate = newGameState
                        }
                }
                
                
            }
        }
        
        /// animates AI moving a piece
        private func move(from:GamePosition,
                          to:GamePosition,
                          completionHandler: (() -> Void)? = nil) {
            
            let fromSquareId = "\(from.x)x\(from.y)"
            let toSquareId = "\(to.x)x\(to.y)"
            guard let piece = figures[fromSquareId],
                  let rawDestinationPosition = board.sqr2pos[toSquareId]  else { fatalError() }
            
            // this stuff will change once we stop putting nodes directly in world space..
            let destinationPosition = ARSceneview.scene.rootNode.convertPosition(rawDestinationPosition,
                                                                               from: board.node)
            
            // update visual game state
            figures[toSquareId] = piece
            figures[fromSquareId] = nil
            
            // create drag and drop animation
            let pickUpAction = SCNAction.move(to: SCNVector3(piece.position.x, piece.position.y + Float(Dimensions.DRAG_LIFTOFF), piece.position.z),
                                              duration: 0.25)
            let moveAction = SCNAction.move(to: SCNVector3(destinationPosition.x, destinationPosition.y + Float(Dimensions.DRAG_LIFTOFF), destinationPosition.z),
                                            duration: 0.5)
            let dropDownAction = SCNAction.move(to: destinationPosition,
                                                duration: 0.25)
            
            // run drag and drop animation
            piece.runAction(pickUpAction) {
                piece.runAction(moveAction) {
                    piece.runAction(dropDownAction,
                                    completionHandler: completionHandler)
                }
            }
        }
        
        /// renders user and AI insert of piece
        private func put(piece:SCNNode,
                         at position:GamePosition,
                         completionHandler: (() -> Void)? = nil) {
            let squareId = "\(position.x)x\(position.y)"
            guard let squarePosition = board.sqr2pos[squareId] else { fatalError() }
            
            piece.opacity = 0  // initially invisible
            // // https://stackoverflow.com/questions/30392579/convert-local-coordinates-to-scene-coordinates-in-scenekit
            piece.position = ARSceneview.scene.rootNode.convertPosition(squarePosition,from: board.node)
            ARSceneview.scene.rootNode.addChildNode(piece)
            figures[squareId] = piece
            
            let action = SCNAction.fadeIn(duration: 0.5)
            piece.runAction(action,
                            completionHandler: completionHandler)
        }
        
        
        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            
            // from apples app
            DispatchQueue.main.async {
                // If light estimation is enabled, update the intensity of the model's lights and the environment map
                if let lightEstimate = self.ARSceneview.session.currentFrame?.lightEstimate {
                    
                    // Apple divived the ambientIntensity by 40, I find that, atleast with the materials used
                    // here that it's a big too bright, so I increased to to 50..
                    self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 50)
                } else {
                    self.enableEnvironmentMapWithIntensity(25)
                }
            }
        }
        
        // did at plane(?)
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            planeCount += 1
        }
        
        // did update plane?
        func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {

        }
        
        // did remove plane?
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if node == currentPlane {
                removeAllFigures()
                lightNode?.removeFromParentNode()
                lightNode = nil
                floorNode?.removeFromParentNode()
                floorNode = nil
                board.node.removeFromParentNode()
                currentPlane = nil
            }
            
            if planeCount > 0 {
                planeCount -= 1
            }
        }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
