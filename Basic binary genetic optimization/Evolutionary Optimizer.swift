//
//  Evolutionary Optimizer.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 10/30/15.
//  Copyright © 2015 Carter Pape. All rights reserved.
//

import Foundation

let POPULATION_SIZE = 64
let STRONG_SURVIVORS = 2
let SAMPLE_SIZE = 5
let MUTATION_CHANCE_INVERSE: UInt32 = 8
let FITNESS_STAGNATION_THRESHOLD = 100

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

class EvolutionaryOptimizer<ValueType: ZeroArgumentInitable, FitnessType: Comparable> {
    typealias ComparatorType = (Individual<ValueType, FitnessType>, Individual<ValueType, FitnessType>) -> Bool
    var population = [Individual<ValueType, FitnessType>]()
    var fitnessFunction: (ValueType) -> FitnessType
    var comparator: ComparatorType = { $0.fitness > $1.fitness }
    
    private func generatePopulation() {
        for _ in 1...POPULATION_SIZE {
            population.append(Individual<ValueType, FitnessType>(fitnessMeasure: fitnessFunction))
        }
    }
    
    init(fitnessFunction: (ValueType) -> FitnessType) {
        self.fitnessFunction = fitnessFunction
        generatePopulation()
    }
    
    init(fitnessFunction: (ValueType) -> FitnessType, comparator: ComparatorType) {
        self.fitnessFunction = fitnessFunction
        generatePopulation()
        self.comparator = comparator
    }
    
    func newGeneration() {
        population.sortInPlace(comparator)
        var newPopulation = Array(population[0..<STRONG_SURVIVORS])
        // print(newPopulation[0])
        for _ in STRONG_SURVIVORS..<POPULATION_SIZE {
            var sample = population.sample(SAMPLE_SIZE).sort(comparator)
            let offspring = Reproducer.reproduce(sample[0], sample[1])
            newPopulation.append(offspring)
        }
        population = newPopulation
    }
    
    func evolve() -> (generations: Int, strongestIndividual: Individual<ValueType, FitnessType>) {
        var currentGeneration = 1
        var currentStrongest = strongestIndividual
        var recordSettingGeneration = currentGeneration
        
        while currentGeneration - recordSettingGeneration < FITNESS_STAGNATION_THRESHOLD {
            newGeneration()
            let newStrongest = strongestIndividual
            if comparator(newStrongest, currentStrongest) {
                currentStrongest = newStrongest
                recordSettingGeneration = currentGeneration
            }
            currentGeneration++
        }
        
        return (generations: currentGeneration, strongestIndividual: currentStrongest)
    }
    
    var strongestIndividual: Individual<ValueType, FitnessType> {
        return population.minElement(comparator)!
    }
}

class Individual<ValueType: ZeroArgumentInitable, FitnessType: Comparable>: CustomStringConvertible {
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

class Reproducer<ValueType: ZeroArgumentInitable, FitnessType: Comparable> {
    static func reproduce(parent1: Individual<ValueType, FitnessType>,
        _ parent2: Individual<ValueType, FitnessType>)
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