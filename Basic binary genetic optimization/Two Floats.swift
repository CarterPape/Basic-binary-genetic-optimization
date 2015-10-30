//
//  Two Floats.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 10/29/15.
//  Copyright © 2015 Carter Pape. All rights reserved.
//

import Foundation

let NUM1_GOAL: Float = 600
let NUM2_GOAL: Float = -200

struct TwoFloats: ZeroArgumentInitable, CustomStringConvertible {
    var num1: Float = 0
    var num2: Float = 0
    
    var description: String {
        return "\(num1) \(num2)"
    }
}

class TwoFloatFitnessTester {
    static func fitness(pair: TwoFloats) -> Float {
        return 10 * pow(2, -(abs(NUM1_GOAL-pair.num1))) + 10 * pow(2, -(abs(NUM2_GOAL-pair.num2)))
    }
}