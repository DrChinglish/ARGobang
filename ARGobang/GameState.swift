//
//  GameState.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/13.
//

import Foundation

typealias GamePosition = (x:Int, y:Int)
struct GameHistoryMeta{
    let totalGames:Int
    let humanWins:Int
    init(games:[GameHistory]){
        var total = 0
        var human = 0
        for game in games {
            if game.winHuman{
                human+=1
            }
            total+=1
        }
        totalGames = total
        humanWins = human
    }
}


enum GamePlayerType:String {
    case human = "human"
    case ai = "ai"
}

enum GameMode:String {
    case put = "put"
    case move = "move"
}

enum GamePlayer:String {
    case x = "x"
    case o = "o"
}

/// we have made the game actions generic in order to make it easier to implement the AI
enum GameAction {
    case put(at:GamePosition)
    case move(from:GamePosition, to:GamePosition)
}


struct GameState {
    let currentPlayer:GamePlayer
    let mode:GameMode
    let board:[[String]]
    
    
    init() {
        self.init(currentPlayer: arc4random_uniform(2) == 0 ? .x : .o,  // random start player
                  mode: .put,   // start mode is to put/drop pieces
                  board: [[String]](repeating: [String](repeating: "", count: 19), count: 19))    // board is empty
    }
    
    /// this private init allows the perform func to return a new GameState
    private init(currentPlayer:GamePlayer,
                 mode:GameMode,
                 board:[[String]]) {
        self.currentPlayer = currentPlayer
        self.mode = mode
        self.board = board
    }
    
    //perform a put action on a position
    func perform(at position:GamePosition)->GameState?{
        guard board[position.x][position.y] == "" else {return nil}
        var newboard = board
        newboard[position.x][position.y] = currentPlayer.rawValue
        return GameState(currentPlayer: currentPlayer == .x ?.o : .x, mode: .put, board: newboard)
    }
    
    
    
    
    
    // is there a winner?
    var currentWinner:GamePlayer? {
        
        get {
            var checkstatus = [[Int]](repeating: [Int](repeating: 0, count: 19), count: 19)
            func checkH(at position:(Int,Int))->Bool{
                let chesstype = board[position.0][position.1]
                if chesstype == ""{
                    return false
                }
                for i in position.1..<(position.1+5){
                    guard i<19 else{return false}
                    if(board[position.0][i]==chesstype){
                        checkstatus[position.0][i] |= 0x4
                        continue
                    }else{
                        return false
                    }
                }
                return true
            }
            func checkV(at position:(Int,Int))->Bool{
                let chesstype = board[position.0][position.1]
                if chesstype == ""{
                    return false
                }
                for i in position.0..<(position.0+5){
                    guard i<19 else{return false}
                    if(board[i][position.1]==chesstype){
                        checkstatus[i][position.1] |= 0x2
                        continue
                    }else{
                        return false
                    }
                }
                return true
            }
            
            func checkA(at position:(Int,Int))->Bool{
                let chesstype = board[position.0][position.1]
                if chesstype == ""{
                    return false
                }
                var found = true
                for i in 0..<5{
                    guard (i+position.0)<19,(i+position.1)<19 else{
                        found = false
                        break
                    }
                    if(board[i+position.0][i+position.1]==chesstype){
                        checkstatus[i+position.0][i+position.1] |= 0x1
                        continue
                    }else{
                        found = false
                        break
                    }
                }
                if found {
                    return true
                }
                for i in 0..<5{
                    guard(i+position.0)<19,(position.1-i)>=0
                    else{return false}
                    if(board[i+position.0][position.1-i]==chesstype){
                        checkstatus[i+position.0][position.1-i] |= 0x8
                        continue
                    }else{
                        return false
                    }
                }
                return true
            }
            //for each chess on board, check the following:
            //1.left to right
            //2.top to bottom
            //3.top left to bottom right
            //4.top right to bottom left
            //use a 19x19 array of int to tag if they were checked
            //say a chess has several state represented in 0/1 bit
            //e.g. 0001B means this chess is checked accross
            //     AHVA   Horizontal Vertical Accross
            //
            for i in 0..<19{
                for j in 0..<19{
                    if checkstatus[i][j] & 0x4 == 0{//do H check
                        if checkH(at: (i,j)){
                            return GamePlayer(rawValue: board[i][j])
                        }
                    }
                    if checkstatus[i][j] & 0x2 == 0{//do V check
                        if checkV(at: (i,j)){
                            return GamePlayer(rawValue: board[i][j])
                        }
                    }
                    if checkstatus[i][j] & 0x9 != 0x9{//do A check
                        if checkA(at: (i,j)){
                            return GamePlayer(rawValue: board[i][j])
                        }
                    }
                }
            }
            return nil
        }
    }
}


