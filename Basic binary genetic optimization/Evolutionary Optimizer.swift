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
    typealias FitnessFunctionType = [ValueType] -> [Individual<ValueType, FitnessType>]
    var population = [Individual<ValueType, FitnessType>]()
    var fitnessFunction: FitnessFunctionType
    var comparator: ComparatorType = { $0.fitness > $1.fitness }
    
    internal func generatePopulation() {
        var populationValues = [ValueType]()
        for _ in 1...POPULATION_SIZE {
            populationValues.append(Individual<ValueType, FitnessType>.randomValue())
        }
        population = self.fitnessFunction(populationValues)
    }
    
    internal init(fitnessFunction: FitnessFunctionType) {
        self.fitnessFunction = fitnessFunction
        generatePopulation()
    }
    
    internal init(fitnessFunction: FitnessFunctionType, comparator: ComparatorType) {
        self.fitnessFunction = fitnessFunction
        self.comparator = comparator
        generatePopulation()
    }
    
    func newGeneration() {
        population.sortInPlace(comparator)
        var newPopulationValues = population[0..<STRONG_SURVIVORS].flatMap({ $0.value })
        for _ in STRONG_SURVIVORS..<POPULATION_SIZE {
            var sample = population.sample(SAMPLE_SIZE).sort(comparator)
            let offspring = Reproducer.reproduce(sample[0].value, sample[1].value)
            newPopulationValues.append(offspring)
        }
        population = fitnessFunction(newPopulationValues)
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

struct Individual<ValueType: ZeroArgumentInitable, FitnessType: Comparable>: CustomStringConvertible {
    let value: ValueType
    let fitness: FitnessType
    
    init(value: ValueType, fitness: FitnessType) {
        self.value = value
        self.fitness = fitness
    }
    
    static func randomValue() -> ValueType {
        let data = NSMutableData(length: sizeof(ValueType))
        var newValue = ValueType()
        SecRandomCopyBytes(kSecRandomDefault, sizeof(ValueType), UnsafeMutablePointer<UInt8>(data!.mutableBytes))
        data!.getBytes(&newValue, length: sizeof(ValueType))
        return newValue
    }
    
    var description: String {
        return "\(value): \(fitness)"
    }
}

class Reproducer<ValueType: ZeroArgumentInitable> {
    static func reproduce(parent1: ValueType, _ parent2: ValueType) -> ValueType {
        var parent1Copy = parent1
        var parent2Copy = parent2
        let parent1Data = NSData(bytes: &parent1Copy, length: sizeof(ValueType))
        let parent2Data = NSData(bytes: &parent2Copy, length: sizeof(ValueType))
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
        return newValue
    }
}