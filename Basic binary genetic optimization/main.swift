//
//  main.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 8/10/15.
//  Copyright (c) 2015 Carter Pape. All rights reserved.
//

import Foundation

print(STRONG_SURVIVORS, SAMPLE_SIZE, MUTATION_CHANCE_INVERSE, NUM1_GOAL, NUM2_GOAL, POPULATION_SIZE)

for n in 1...20 {
    var optimizer = EvolutionaryOptimizer<PointInR3, Double>(
        multiFitnessFunction: PointInR3FitnessTester.fitness,
        comparator: { $0.fitness > $1.fitness && $0.fitness.isNormal })
    print(optimizer.evolve())
}