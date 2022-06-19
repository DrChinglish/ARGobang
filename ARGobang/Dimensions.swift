//
//  Dimensions.swift
//  ARGobang
//
//  Created by JU88 on 2022/6/13.
//

import Foundation
import UIKit

class Dimensions{
    private static let base = 72.0
    static let SQUARE_SIZE:CGFloat=4.0/base
    static let GRID_WIDTH:CGFloat=0.2/base
    static let DRAG_LIFTOFF:CGFloat = 1.5/base
    static let CHESS_HEIGHT:CGFloat = 0.2/base
    static let CHESS_RADIUS:CGFloat = SQUARE_SIZE*0.4
    static let BOARD_SCALEX:Int = 19
    static let BOARD_SCALEY:Int = 19
}
