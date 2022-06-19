//
//  ContentView.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/13.
//

import SwiftUI
import ARKit
import UIKit
import CoreData
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
    @IBAction func didValuechanged(_ sender: Any){
        updateAIType()
    }
    @IBOutlet weak var labelAI1:UILabel!
    @IBOutlet weak var labelAI2:UILabel!
    @IBOutlet weak var planeSearchOverlay: UIView!
    @IBOutlet weak var gameStateLabel: UILabel!
    @IBOutlet weak var startbutton:UIButton!
    @IBOutlet weak var AISegmentControl:UISegmentedControl!
    @IBOutlet weak var AISegmentControl2:UISegmentedControl!
    @IBOutlet weak var restartButton:UIButton!
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
                if playerType[GamePlayer.x] == .human && playerType[GamePlayer.o] == .ai{
                    DispatchQueue.main.async {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let context = delegate.persistentContainer.viewContext
                        
                        let gameEntity = NSEntityDescription.entity(forEntityName: "GameHistory", in: context)
                        let game = GameHistory(entity: gameEntity!, insertInto: context)
                        game.winHuman = self.playerType[winner] == .human ? true : false
                        game.time = Date.init(timeIntervalSince1970: Date.timeIntervalBetween1970AndReferenceDate+Date.timeIntervalSinceReferenceDate)
                        
                        do {
                            try context.save()
                            let gamesRequest: NSFetchRequest<GameHistory> = GameHistory.fetchRequest()
                            let games = try context.fetch(gamesRequest)
                            self.gameHistory = games
                            self.gameHistoryMeta = GameHistoryMeta(games: games)
                        }catch{
                            let error = error as NSError
                            fatalError("Unresolved error \(error), \(error.userInfo)")
                        }
                        
                        
                    }
                }
                DispatchQueue.main.async {
                    let winnerstring = winner == .x ? "黑棋" : "白棋"
                    print("winner!")
                    let alert = UIAlertController(title: "游戏结束r", message: "\(winnerstring) 获胜!!!!", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                                        self.reset()
                                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }else{
                if currentPlane != nil{
                    newTurn()
                }
            }
        }
    }
    var figures:[String:SCNNode] = [:]
    var lightNode:SCNNode?
    var floorNode:SCNNode?
    var draggingFrom:GamePosition? = nil
    var draggingFromPosition:SCNVector3? = nil
    var gameHistoryMeta:GameHistoryMeta? = nil
    var gameHistory:[GameHistory]? = nil
    
    var AItype1 = AIType.balanced
    var AItype2:AIType = AIType.balanced
    
    private func updateAIType(){
        
        switch AISegmentControl!.selectedSegmentIndex{
        case 0: AItype1 = AIType.balanced
        case 1: AItype1 =  AIType.offensive
        case 2: AItype1 =  AIType.defensive
        default:
            AItype1 =  AIType.balanced
        }
        switch AISegmentControl2!.selectedSegmentIndex{
        case 0: AItype2 = AIType.balanced
        case 1: AItype2 =  AIType.offensive
        case 2: AItype2 =  AIType.defensive
        default:
            AItype2 =  AIType.balanced
        }
        
    }
   
        // from demo APP
        // Use average of recent virtual object distances to avoid rapid changes in object scale.
        var recentVirtualObjectDistances = [CGFloat]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            
            
            do{
                let gamesRequest: NSFetchRequest<GameHistory> = GameHistory.fetchRequest()
                let games = try context.fetch(gamesRequest)
                gameHistory = games
                gameHistoryMeta = GameHistoryMeta(games: games)
            }catch{
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            
            startbutton.isHidden = true
            gameStateLabel.isHidden = true
            gamestate = GameState()  // create new game
            
            ARSceneview.delegate = self
            
            ARSceneview.antialiasingMode = .multisampling4X
            
            ARSceneview.automaticallyUpdatesLighting = false
            
            let tap = UITapGestureRecognizer()
            tap.addTarget(self, action: #selector(didTap))
            ARSceneview.addGestureRecognizer(tap)
            
            
        }
        
        // from Apples app
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
            AISegmentControl.isHidden = true
            AISegmentControl2.isHidden = true
            labelAI1.isHidden = true
            labelAI1.isHidden = true
            restartButton.isHidden = true
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
            restartButton.isHidden = true
            AISegmentControl.isHidden = true
            labelAI1.isHidden = true
            labelAI2.isHidden = true
            AISegmentControl2.isHidden = true
            let pastGameInfo = "过去进行的\(gameHistoryMeta!.totalGames)场人机对战游戏中，人类共胜利\(gameHistoryMeta!.humanWins)次，AI共胜利\(gameHistoryMeta!.totalGames - gameHistoryMeta!.humanWins)次"
            let alert = UIAlertController(title: "游戏模式", message: "请选择游戏模式\n \(pastGameInfo)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "黑棋：人类 vs 白棋：AI", style: .default, handler: { action in
                self.AISegmentControl.isHidden = false
                self.labelAI1.isHidden = false
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.human,
                    GamePlayer.o: GamePlayerType.ai
                    ])
            }))
            alert.addAction(UIAlertAction(title: "黑棋：人类 vs 白棋：人类", style: .default, handler: { action in
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.human,
                    GamePlayer.o: GamePlayerType.human
                    ])
            }))
            alert.addAction(UIAlertAction(title: "黑棋：AI vs 白棋：AI", style: .default, handler: { action in
                self.AISegmentControl.isHidden = false
                self.AISegmentControl2.isHidden = false
                self.labelAI1.isHidden = false
                self.labelAI2.isHidden = false
                self.beginNewGame([
                    GamePlayer.x: GamePlayerType.ai,
                    GamePlayer.o: GamePlayerType.ai
                    ])
            }))
            present(alert, animated: true, completion: nil)
            
            
            
        }
        
        private func beginNewGame(_ players:[GamePlayer:GamePlayerType]) {
            restartButton.isHidden = false
            playerType = players
            gamestate = GameState()
            
            removeAllFigures()
            
            figures.removeAll()
        }
        
        private func newTurn() {
            //to implement ai here
            print("turn for \(playerType[gamestate.currentPlayer]?.rawValue)")
            guard playerType[gamestate.currentPlayer]! == .ai else{return}
            let type = gamestate.currentPlayer == .o ? AItype1 : AItype2
            print("AI thinking")
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                
                let position = AIv1(gamestate: self.gamestate, AItype: type).bestPosition
                print("position is (\(position.x),\(position.y))")
                DispatchQueue.main.async {
                    guard let newState = self.gamestate.perform(at: position) else {fatalError()}
                    let updateGameState = {
                        DispatchQueue.main.async {
                            self.gamestate = newState
                        }
                    }
                    self.put(piece: Chess.chess(for: self.gamestate.currentPlayer), at: position, completionHandler: updateGameState)
                }
                
            }
            
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
        
        
        
        @objc func didTap(_ sender:UITapGestureRecognizer) {
            let location = sender.location(in: ARSceneview)
            
            // tap to place board..
            guard let _ = currentPlane else {
                guard let newPlaneData = anyPlaneFrom(location: location) else { return }
                
                let floor = SCNFloor()
                floor.reflectivity = 0
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.white
                
                material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
                floor.materials = [material]
                
                floorNode = SCNNode(geometry: floor)
                floorNode!.position = newPlaneData.1
                ARSceneview.scene.rootNode.addChildNode(floorNode!)
                
                self.currentPlane = newPlaneData.0
                restoreGame(at: newPlaneData.1)
                
                return
            }
            
            
            guard case .put = gamestate.mode,
                  playerType[gamestate.currentPlayer]! == .human else { return }
            
            if let squareData = squareFrom(location: location),
               let newGameState = gamestate.perform(at:GamePosition(squareData.0)) {
                
                put(piece: Chess.chess(for: gamestate.currentPlayer),
                    at: squareData.0) {
                        
                            self.gamestate = newGameState
                        
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
