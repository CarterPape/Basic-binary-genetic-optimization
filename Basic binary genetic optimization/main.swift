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

extension Array {
    func sample(sampleSize: Int) -> [T] {
        var holder = self
        var toReturn = [T]()
        for n in 0..<sampleSize {
            var indexToPop = Int(arc4random_uniform(UInt32(holder.endIndex)))
            toReturn.append(holder.removeAtIndex(Int(indexToPop)))
        }
        return toReturn
    }
}

func sortedIndividuals(population: [Individual<TwoFloats, Float>]) -> [Individual<TwoFloats, Float>] {
    return sorted(population, { $0.fitness > $1.fitness && $0.fitness.isNormal })
}

protocol ZeroArgumentInitable {
    init()
}

struct TwoFloats: ZeroArgumentInitable, Printable {
    var num1: Float = 0
    var num2: Float = 0
    
    var description: String {
        return "\(num1) \(num2)"
    }
}

class Individual<ValueType: ZeroArgumentInitable, FitnessType>: Printable {
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
        
        self.value = ValueType()
        
        data!.getBytes(&value, length: sizeof(ValueType))
        
        self.fitness = fitnessMeasure(value)
    }
    
    var description: String {
        return "\(value): \(fitness)"
    }
}

class FitnessTester {
    static func fitness(pair: TwoFloats) -> Float {
        return 10 * pow(2, -(abs(NUM1_GOAL-pair.num1))) + 10 * pow(2, -(abs(NUM2_GOAL-pair.num2)))
    }
}

class Reproducer<ValueType: ZeroArgumentInitable, FitnessType> {
    static func reproduce(var parent1: Individual<ValueType, FitnessType>,
        var parent2: Individual<ValueType, FitnessType>)
        -> Individual<ValueType, FitnessType> {
            var val1 = parent1.value
            var val2 = parent2.value
            var parent1Data = NSData(bytes: &val1, length: sizeof(ValueType))
            var parent2Data = NSData(bytes: &val2, length: sizeof(ValueType))
            var newData = NSMutableData(data: parent1Data)
            var newValue = ValueType()
            
            for n in 0..<sizeof(ValueType) {
                if arc4random_uniform(MUTATION_CHANCE_INVERSE) == 1 {
                    var range = NSRange(n...n)
                    var newByte: UInt8 = UInt8(arc4random() % UInt32(UINT8_MAX + 1))
                    newData.replaceBytesInRange(range, withBytes: &newByte)
                }
                else if arc4random() % 2 == 0 {
                    var range = NSRange(n...n)
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


println(STRONG_SURVIVORS, SAMPLE_SIZE, MUTATION_CHANCE_INVERSE, NUM1_GOAL, NUM2_GOAL, POPULATION_SIZE, ITERATIONS)

for n in 1...20 {
    var population = [Individual<TwoFloats, Float>]()

    for n in 1...POPULATION_SIZE {
        population.append(Individual<TwoFloats, Float>(fitnessMeasure: FitnessTester.fitness))
    }

    population = sortedIndividuals(population)

    var iterations = 0

    while population[0].fitness < 19 || !population[0].fitness.isNormal {
        var newPopulation = Array(population[0..<STRONG_SURVIVORS])
        for n in STRONG_SURVIVORS..<population.endIndex {
            var sample = sortedIndividuals(population.sample(SAMPLE_SIZE))
            let offspring = Reproducer.reproduce(sample[0], parent2: sample[1])
            newPopulation.append(offspring)
        }
        population = sortedIndividuals(newPopulation)
        iterations++
    }
    
    println(iterations)
}