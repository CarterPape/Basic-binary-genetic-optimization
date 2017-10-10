//
//  Quadratic Fit.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 10/29/15.
//  Copyright © 2015 Carter Pape. All rights reserved.
//

import Foundation

let COORDINATES = [(-20.4584, 1.1311E6), (-19.6532, 1.07875E6), (-17.7455,  743744), (-16.4295, 517170), (-16.5938, 461405), (-14.6301,  242092), (-13.9227, 242717), (-13.6944, 113868), (-13.7244,  89843), (-11.3161,  35431.4), (-10.2388, -968.642), (-8.02417, -21252.7), (-7.97579, -39748), (-6.66022, -39964.7), (-7.11797, -45923.1), (-4.60814, -47572.9), (-4.20268, -37078.1), (-3.71671, -28790.2), (-2.3382, -17617.2), (-0.454705, -7243.94), (0.759755, 110.938), (0.926743,  7953.21), (3.14602, 14934), (3.00355, 21648.5), (4.81191,  26638.7), (3.87463, 30312.5), (4.93636, 27739.1), (6.93525,  24404.7), (6.91011, 23925.3), (8.99133, 24156.9), (10.3672,  25166.3)];

// print(PCFitnessCalculator.fitness(PolyCoefficients(a: 4.86568, b: -85.5796, c: -403.044, d: 9828.22, e: -1872.93)))

struct PolyCoefficients: ZeroArgumentInitable, CustomStringConvertible {
    var a: Float = 0
    var b: Float = 0
    var c: Float = 0
    var d: Float = 0
    var e: Float = 0
    
    var description: String {
        return "(\(a)) x^4 + (\(b)) x^3 + (\(c)) x^2 + (\(d)) x + (\(e))"
    }
}

class PCFitnessCalculator {
    static func populationFitness(values: [PolyCoefficients]) -> [Individual<PolyCoefficients, Double>] {
        return values.map({ return Individual<PolyCoefficients, Double>(value: $0, fitness: fitness($0)) })
    }
    
    static func fitness(_ coefficients: PolyCoefficients) -> Double {
        let polynomialFunction = {
            (x: Double) -> Double in
            let x4 = Double(coefficients.a) * x * x * x * x
            let x3 = Double(coefficients.b) * x * x * x
            let x2 = Double(coefficients.c) * x * x
            let x1 = Double(coefficients.d) * x
            return x4 + x3 + x2 + x1 + Double(coefficients.e)
        }
        return rSquared(polynomialFunc: polynomialFunction, observed: COORDINATES)
    }
    
    private static func rSquared(polynomialFunc: (Double) -> Double, observed: [(Double, Double)]) -> Double {
        var yTotal = 0.0
        var resSumOfSquares = 0.0
        var totSumOfSquares = 0.0
        var yMean: Double
        for coordinate in observed {
            let residual = coordinate.1 - polynomialFunc(coordinate.0)
            resSumOfSquares += residual * residual
            yTotal += coordinate.1
        }
        yMean = yTotal / Double(observed.count)
        for coordinate in observed {
            let residual = coordinate.1 - yMean
            totSumOfSquares += residual * residual
        }
        return 1 - (resSumOfSquares / totSumOfSquares)
    }
}
