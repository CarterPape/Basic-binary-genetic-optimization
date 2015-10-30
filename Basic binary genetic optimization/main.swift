//
//  main.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 8/10/15.
//  Copyright (c) 2015 Carter Pape. All rights reserved.
//

import Foundation

let STRONG_SURVIVORS = 2
let SAMPLE_SIZE = 5
let MUTATION_CHANCE_INVERSE: UInt32 = 8
let NUM1_GOAL: Float = 600
let NUM2_GOAL: Float = -200
let POPULATION_SIZE = 64
let ITERATIONS = 500
let FITNESS_THRESHOLD = 0.8

extension Array {
    func sample(sampleSize: Int) -> [Element] {
        var holder = self
        var toReturn = [Element]()
        for _ in 0..<sampleSize {
            let indexToPop = Int(arc4random_uniform(UInt32(holder.endIndex)))
            toReturn.append(holder.removeAtIndex(Int(indexToPop)))
        }
        return toReturn
    }
}

protocol ZeroArgumentInitable {
    init()
}

class Individual<ValueType: ZeroArgumentInitable, FitnessType>: CustomStringConvertible {
    let value: ValueType
    let fitness: FitnessType
    let fitnessMeasure: (ValueType) -> FitnessType
    
    init(value: ValueType, fitnessMeasure: (ValueType) -> FitnessType) {
        self.value = value
        self.fitnessMeasure = fitnessMeasure
        self.fitness = fitnessMeasure(value)
    }
    
    init(fitnessMeasure: (ValueType) -> FitnessType) {
        self.fitnessMeasure = fitnessMeasure
        let data = NSMutableData(length: sizeof(ValueType))
        SecRandomCopyBytes(kSecRandomDefault, sizeof(ValueType), UnsafeMutablePointer<UInt8>(data!.mutableBytes))
        
        var newValue = ValueType()
        
        data!.getBytes(&newValue, length: sizeof(ValueType))
        
        self.value = newValue
        
        self.fitness = fitnessMeasure(value)
    }
    
    var description: String {
        return "\(value): \(fitness)"
    }
}

class Reproducer<ValueType: ZeroArgumentInitable, FitnessType> {
    static func reproduce(parent1: Individual<ValueType, FitnessType>,
        parent2: Individual<ValueType, FitnessType>)
        -> Individual<ValueType, FitnessType> {
            var val1 = parent1.value
            var val2 = parent2.value
            let parent1Data = NSData(bytes: &val1, length: sizeof(ValueType))
            let parent2Data = NSData(bytes: &val2, length: sizeof(ValueType))
            let newData = NSMutableData(data: parent1Data)
            var newValue = ValueType()
            
            for n in 0..<sizeof(ValueType) {
                if arc4random_uniform(MUTATION_CHANCE_INVERSE) == 1 {
                    let range = NSRange(n...n)
                    var newByte: UInt8 = UInt8(arc4random() % UInt32(UINT8_MAX + 1))
                    newData.replaceBytesInRange(range, withBytes: &newByte)
                }
                else if arc4random() % 2 == 0 {
                    let range = NSRange(n...n)
                    var newByte: UInt8 = 0
                    parent2Data.getBytes(&newByte, range: range)
                    newData.replaceBytesInRange(range, withBytes: &newByte)
                }
            }
            
            newData.getBytes(&newValue, length: sizeof(ValueType))
            return Individual(value: newValue, fitnessMeasure: parent1.fitnessMeasure)
    }
}
/*
var population = [Individual<TwoFloats, Float>]()

for n in 1...POPULATION_SIZE {
    population.append(Individual<TwoFloats, Float>(fitnessMeasure: FitnessTester.fitness))
}

population = sortedIndividuals(population)

var iterations = 0

while population[0].fitness < 18 || !population[0].fitness.isNormal {
    var newPopulation = Array(population[0..<STRONG_SURVIVORS])
    for n in STRONG_SURVIVORS..<population.endIndex {
        var sample = sortedIndividuals(population.sample(SAMPLE_SIZE))
        let offspring = Reproducer.reproduce(sample[0], parent2: sample[1])
        newPopulation.append(offspring)
    }
    population = sortedIndividuals(newPopulation)
    iterations++
    
    if population[0].description.hasSuffix("nan") {
        var fitness = population[0].fitness
        var data = NSData(bytes: &fitness, length: sizeof(Float))
        println(fitness.isNormal)
        println(data)
    }
    
    println(population[0])
}

println(iterations)
*/

print(PCFitnessCalculator.fitness(PolyCoefficients(a: 4.86568, b: -85.5796, c: -403.044, d: 9828.22, e: -1872.93)))

print(STRONG_SURVIVORS, SAMPLE_SIZE, MUTATION_CHANCE_INVERSE, NUM1_GOAL, NUM2_GOAL, POPULATION_SIZE, ITERATIONS)

for n in 1...20 {
    var population = [Individual<PolyCoefficients, Double>]()

    for n in 1...POPULATION_SIZE {
        population.append(Individual<PolyCoefficients, Double>(fitnessMeasure: PCFitnessCalculator.fitness))
    }

    population = population.sort({ $0.fitness > $1.fitness && $0.fitness.isNormal })

    var iterations = 0

    while iterations < 100 {
        var newPopulation = Array(population[0..<STRONG_SURVIVORS])
        for n in STRONG_SURVIVORS..<population.endIndex {
            var sample = population.sample(SAMPLE_SIZE).sort({ $0.fitness > $1.fitness && $0.fitness.isNormal })
            let offspring = Reproducer.reproduce(sample[0], parent2: sample[1])
            newPopulation.append(offspring)
        }
        population = newPopulation.sort({ $0.fitness > $1.fitness && $0.fitness.isNormal })
        iterations++
    }
    
    print(iterations, population[0])
}