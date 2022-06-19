//
//  Chess.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/15.
//

import Foundation
import SceneKit

class Chess{
    class func chess(for player:GamePlayer)->SCNNode{
        switch player {
        case .x:
            return blackchess()
        case .o:
            return whitechess()
        }
    }
    class func whitechess()->SCNNode{
        let geometry = SCNCylinder(radius: Dimensions.CHESS_RADIUS, height: Dimensions.CHESS_HEIGHT)
        geometry.firstMaterial?.diffuse.contents = UIColor.white
        let chessmodel = SCNNode(geometry: geometry)
        
        return chessmodel
    }
    
    class func blackchess()->SCNNode{
        let geometry = SCNCylinder(radius: Dimensions.CHESS_RADIUS, height: Dimensions.CHESS_HEIGHT)
        geometry.firstMaterial?.diffuse.contents = UIColor.black
        let chessmodel = SCNNode(geometry: geometry)
        return chessmodel
    }
}
