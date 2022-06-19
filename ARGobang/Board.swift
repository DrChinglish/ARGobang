//
//  Board.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/13.
//

import Foundation
import SceneKit

//19x19 board

class Board{
    let node:SCNNode
    let node2sqr:[SCNNode:(Int,Int)]
    let sqr2pos:[String:SCNVector3]
    
    init(){
        node=SCNNode()
        let boardbody = SCNBox(width: Dimensions.SQUARE_SIZE*CGFloat(Dimensions.BOARD_SCALEX), height: Dimensions.SQUARE_SIZE, length: Dimensions.SQUARE_SIZE*CGFloat(Dimensions.BOARD_SCALEY), chamferRadius: 0)
        boardbody.firstMaterial!.diffuse.contents = UIColor.orange
        let boardnode = SCNNode(geometry: boardbody)
        boardnode.position = SCNVector3(0,  -Dimensions.SQUARE_SIZE*0.5,0)
        node.addChildNode(boardnode)
        var node2sqr=[SCNNode:(Int,Int)]()
        var sqr2pos=[String:SCNVector3]()
        
        //19x19 board has 18 squares a column/row
        let length=Dimensions.SQUARE_SIZE*CGFloat(Dimensions.BOARD_SCALEX-1)
        
        for i in 0..<Dimensions.BOARD_SCALEX{
            //x coordinate of square(i,...), also point (i,...) on the board
            let colOffset = -length*0.5 + CGFloat(i)*Dimensions.SQUARE_SIZE
            for j in 0..<Dimensions.BOARD_SCALEY{
                let position = SCNVector3(colOffset,0.001,CGFloat(9-j)*Dimensions.SQUARE_SIZE)
                let square = (i,j)
                let geometry = SCNPlane(width: Dimensions.SQUARE_SIZE, height: Dimensions.SQUARE_SIZE)
                geometry.firstMaterial!.diffuse.contents = UIColor.clear
                
                let squarenode = SCNNode(geometry: geometry)
                squarenode.position = position
                squarenode.eulerAngles = SCNVector3(-90.0.degreesToRadians,0,0)
                
                node.addChildNode(squarenode)
                node2sqr[squarenode] = square
                sqr2pos["\(square.0)x\(square.1)"] = position
            
            }
            //grid lines
            
            let geometry = SCNPlane(width:Dimensions.GRID_WIDTH,height: Dimensions.SQUARE_SIZE*CGFloat(Dimensions.BOARD_SCALEY-1))
            geometry.firstMaterial!.diffuse.contents = (UIColor.black)
            
            let hLineNode = SCNNode(geometry: geometry)
            hLineNode.position = SCNVector3(colOffset,0.001,0)
            hLineNode.eulerAngles = SCNVector3(-90.0.degreesToRadians,0,0)
            node.addChildNode(hLineNode)
            
            let vLineNode = SCNNode(geometry: geometry)
            vLineNode.position = SCNVector3(0,0.001,colOffset)
            vLineNode.eulerAngles = SCNVector3(-90.0.degreesToRadians,-90.0.degreesToRadians,0)
            node.addChildNode(vLineNode)
            
        }
        self.node2sqr = node2sqr
        self.sqr2pos = sqr2pos
        
    }
    
    
}
