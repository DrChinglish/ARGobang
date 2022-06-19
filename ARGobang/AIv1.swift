//
//  AIv1.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/16.
//

import Foundation
import SwiftUI
import UIKit
private let WIN_BONUS = 100


enum CheckDirection{
                 //     \ | /
    case NS      //      \|/
    case WE      //    ---*---WE
    case NW_SE   //      /|\
    case SW_NE   //     / | \
                 // SW_SE NS SW_SE
}

enum NavigateDirection{
    case N
    case S
    case W
    case E
    case NE
    case NW
    case SE
    case SW
}

enum AIType{
    case defensive
    case offensive
    case balanced
}

struct TestResult{
    let blocked:LineState
    let maxStreak:Int
    let friendly:Bool
    let isBorder:Bool
}

enum LineState{
    case blocked
    case free
}

struct AIv1{
    let gamestate:GameState
    var AItype:AIType
    private func findNextPosition(from currentposition:GamePosition,to direction:NavigateDirection)->GamePosition?{
        var newposition = currentposition
        switch direction {
        case .N:
            guard currentposition.x-1>=0 else {return nil}
            newposition.x -= 1
        case .S:
            guard currentposition.x+1<Dimensions.BOARD_SCALEY else {return nil}
            newposition.x += 1
        case .W:
            guard currentposition.y-1>=0 else {return nil}
            newposition.y -= 1
        case .E:
            guard currentposition.y+1<Dimensions.BOARD_SCALEX else {return nil}
            newposition.y += 1
        case .NW:
            guard currentposition.x-1>=0,currentposition.y-1>=0 else {return nil}
            newposition.x -= 1
            newposition.y -= 1
        case .NE:
            guard currentposition.x-1>=0,currentposition.y+1<Dimensions.BOARD_SCALEX else {return nil}
            newposition.x -= 1
            newposition.y += 1
        case .SW:
            guard currentposition.x+1<Dimensions.BOARD_SCALEY,currentposition.y-1>=0 else {return nil}
            newposition.x += 1
            newposition.y -= 1
        case .SE:
            guard currentposition.x+1<Dimensions.BOARD_SCALEY,currentposition.y+1<Dimensions.BOARD_SCALEX else {return nil}
            newposition.x += 1
            newposition.y += 1
        }
        return newposition
    }
    
    private func testSide(on direction:NavigateDirection,from position:GamePosition)->TestResult{
        let currentchess = gamestate.currentPlayer.rawValue
        var nextPosition = findNextPosition(from: position, to: direction)
        var isBorder = true
        var streak = 0 //how many chess is there in a row
        var friendly = false //wether the chess in one side is friendly
        var startchess:String = ""
        var blocked = LineState.blocked
        while (nextPosition != nil){
            isBorder = false
            let nextchess = gamestate.board[nextPosition!.x][nextPosition!.y]
            if startchess == "" {
                if nextchess != ""{
                    startchess = nextchess
                    streak += 1
                    if(startchess == currentchess){
                        friendly = true
                    }
                    nextPosition = findNextPosition(from: nextPosition!, to: direction)
                    continue
                }else{
                    friendly = true
                    break
                }
            }
            if nextchess == ""{
                blocked = LineState.free
                
                break
            }else if nextchess == startchess{
                streak += 1
                nextPosition = findNextPosition(from: nextPosition!, to: direction)
            }else{
                break
            }
            
        }
        return TestResult(blocked: blocked, maxStreak: streak, friendly: friendly,isBorder: isBorder)
    }
    
    private func findAdjacent(direction: CheckDirection,for position:GamePosition)->(scoreatk:Int,scoredef:Int){
        var scoreatk = 0
        var scoredef = 0
        let directionA:NavigateDirection
        let directionB:NavigateDirection
        switch direction {
        case .NS:
            directionA = .N
            directionB = .S
        case .WE:
            directionA = .W
            directionB = .E
        case .NW_SE:
            directionA = .NW
            directionB = .SE
        case .SW_NE:
            directionA = .SW
            directionB = .NE
        }
        let resultA = testSide(on: directionA, from: position)
        if !resultA.isBorder {
            scoredef+=1
            scoreatk+=1
        }
        let resultB = testSide(on: directionB, from: position)
        scoreatk+=1
        scoredef+=1
        var rawscore = 0
        if resultA.friendly == resultB.friendly{//same chess on both side
            var blockcount = 0
            if resultA.blocked == .blocked{blockcount += 1}
            if resultB.blocked == .blocked{blockcount += 1}
            let totalstreak = resultB.maxStreak+resultA.maxStreak+1
            
            if totalstreak >= 5{
                rawscore = WIN_BONUS*2
            }else{
                //to de discussed...
                rawscore = totalstreak*(2-blockcount)
            }
            if(resultA.friendly){//atk score
                scoreatk = rawscore
            }else{//def score
                scoredef = rawscore
            }
        }else{//different chess
            let friendlyside:TestResult
            let hostileside:TestResult
            if resultA.friendly {
                friendlyside = resultA
                hostileside = resultB
            }else{
                friendlyside = resultB
                hostileside = resultA
            }
            //will not appear that you will win
            scoreatk = (friendlyside.maxStreak+1)*(2 - (friendlyside.blocked == .blocked ? 1 : 0))
            if hostileside.maxStreak+1>=5 {//could have win
                scoredef = WIN_BONUS*2
            }else if hostileside.maxStreak+1 == 4 && hostileside.blocked == .free{
                scoredef = WIN_BONUS //a free four streak means win
            }
            else{
                scoredef = (hostileside.maxStreak+1)*(3 - (hostileside.blocked == .blocked ? 2 : 0))
            }
        }
        return (scoreatk:scoreatk,scoredef:scoredef)
    }
    
    private func checkPosition(at position:GamePosition)->(scoreatk:Int,scoredef:Int){
        var scoreatk = 0
        var scoredef = 0
        let resNS = findAdjacent(direction: .NS, for: position)
        let resWE = findAdjacent(direction: .WE, for: position)
        let resNW_SE = findAdjacent(direction: .NW_SE, for: position)
        let resSW_NE = findAdjacent(direction: .SW_NE, for: position)
        scoredef += resNS.scoredef+resWE.scoredef+resNW_SE.scoredef+resSW_NE.scoredef
        scoreatk += resNS.scoreatk+resWE.scoreatk+resNW_SE.scoreatk+resSW_NE.scoreatk
        return (scoreatk:scoreatk,scoredef:scoredef)
    }
    
    private func possiblePosition()->[GamePosition]{
        var availablePositions = [GamePosition]()
        for x in 0..<gamestate.board.count{
            for y in 0..<gamestate.board[x].count{
                if gamestate.board[x][y]==""{
                    availablePositions.append(GamePosition(x:x,y:y))
                }
                    
            }
        }
        return availablePositions
    }
    
    //a non iteration version
    private func analysePositions(originPlayer:GamePlayer)->[(scoredef:Int,scoreatk:Int,position:GamePosition)]{
        var analysedPositions = [(scoredef:Int,scoreatk:Int,position:GamePosition)]()
        var count = 0
        print("Finding possible positions")
        let possibleposition = possiblePosition()
        for position in possibleposition{
            print("analyzing position \(count) of \(possibleposition.count)")
            count += 1
            var scoredef = 0
            var scoreatk = 0
            guard let postGameState = gamestate.perform(at: position) else {fatalError()}
            if let winner = postGameState.currentWinner{
                let scoreWin = WIN_BONUS
                if winner == originPlayer{
                    scoreatk += scoreWin
                    scoredef += scoreWin
                }
            }else{//case there is no winner
                let localscore = checkPosition(at: position)
                scoredef = localscore.scoredef
                scoreatk = localscore.scoreatk
            }
            analysedPositions.append((scoredef:scoredef,scoreatk:scoreatk,position:position))
        }
        return analysedPositions
    }
    
    private func calScore(scoreatk:Int,scoredef:Int)->Double{
        var atkweight = 0.0
        var defweight = 0.0
        switch AItype {
        case .defensive:
            atkweight = 0.3
            defweight = 0.7
        case .offensive:
            atkweight = 0.7
            defweight = 0.3
        case .balanced:
            atkweight = 0.5
            defweight = 0.5
        }
        return atkweight*Double(scoreatk)+defweight*Double(scoredef)
    }
    
    var bestPosition:GamePosition{
        var highScore = [(weightedscore:Double,position:GamePosition)]()
        for res in analysePositions(originPlayer: gamestate.currentPlayer){
            let score = calScore(scoreatk: res.scoreatk, scoredef: res.scoredef)
            if highScore.isEmpty {
                highScore.append((score,res.position))
            }else if highScore[0].weightedscore < score{
                highScore.removeAll()
                highScore.append((score,res.position))
            }else if highScore[0].weightedscore == score{
                highScore.append((score,res.position))
            }
        }
        let selected = Int.random(in: 0..<highScore.count)
        return highScore[selected].position
    }
    
}
