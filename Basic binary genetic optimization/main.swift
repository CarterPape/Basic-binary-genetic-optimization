//
//  main.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 8/10/15.
//  Copyright (c) 2015 Carter Pape. All rights reserved.
//

import Foundation

print(PCFitnessCalculator.fitness(PolyCoefficients(a: 4.86568, b: -85.5796, c: -403.044, d: 9828.22, e: -1872.93)))

print(STRONG_SURVIVORS, SAMPLE_SIZE, MUTATION_CHANCE_INVERSE, NUM1_GOAL, NUM2_GOAL, POPULATION_SIZE)

for n in 1...20 {
    var optimizer = EvolutionaryOptimizer<PolyCoefficients, Double>(fitnessFunction: PCFitnessCalculator.fitness,
        comparator: { $0.fitness > $1.fitness && $0.fitness.isNormal })
    
    print(optimizer.evolve())
}