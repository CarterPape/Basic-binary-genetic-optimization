//
//  Centralization.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 11/2/15.
//  Copyright © 2015 Carter Pape. All rights reserved.
//

import Foundation

struct PointInR3: ZeroArgumentInitable, CustomStringConvertible {
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
    
    var isNormal: Bool {
        return x.isNormal && y.isNormal && z.isNormal
    }
    
    var description: String {
        return "(\(x), \(y), \(z))"
    }
}

func / (left: PointInR3, right: Float) -> PointInR3 {
    return PointInR3(x: left.x / right, y: left.y / right, z: left.z / right)
}

func + (left: PointInR3, right: PointInR3) -> PointInR3 {
    return PointInR3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func += (inout left: PointInR3, right: PointInR3) {
    left = left + right
}

func log(point: PointInR3) -> PointInR3 {
    let x = point.x.isNormal ? max(0, log(abs(point.x))) : 0
    let y = point.y.isNormal ? max(0, log(abs(point.y))) : 0
    let z = point.z.isNormal ? max(0, log(abs(point.z))) : 0
    return PointInR3(x: x, y: y, z: z)
}

func sqrt(point: PointInR3) -> PointInR3 {
    let x = point.x.isNormal ? max(0, sqrt(abs(point.x))) : 0
    let y = point.y.isNormal ? max(0, sqrt(abs(point.y))) : 0
    let z = point.z.isNormal ? max(0, sqrt(abs(point.z))) : 0
    return PointInR3(x: x, y: y, z: z)
}

func square(x: Float) -> Double {
    return Double(x) * Double(x)
}

func squareDiff(x: Float, _ y: Float) -> Double {
    return square(x - y)
}

func squareOfDistanceBetween(p1: PointInR3, _ p2: PointInR3) -> Double {
    return squareDiff(p1.x, p2.x) + squareDiff(p1.y, p2.y) + squareDiff(p1.z, p2.z)
}

class PointInR3FitnessTester {
    static func goalPoint(points: [PointInR3]) -> PointInR3 {
        var avgPoint = PointInR3(x: 0, y: 0, z: 0)
        for point in points {
            if (point.isNormal) {
                avgPoint += point / Float(points.count)
            }
        }
        return sqrt(avgPoint)
    }
    
    static func fitness(points: [PointInR3]) -> [Double] {
        var fitnesses = [Double]()
        let avgPoint = self.goalPoint(points)
        for point in points {
            fitnesses.append(-squareOfDistanceBetween(point, avgPoint))
        }
        return fitnesses
    }
}