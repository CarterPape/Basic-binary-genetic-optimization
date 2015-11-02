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

class EvolutionaryOptimizer<Value: ZeroArgumentInitable, Fitness: Comparable> {
    typealias PopulationIndividual = Individual<Value, Fitness>
    typealias Comparator = (PopulationIndividual, PopulationIndividual) -> Bool
    typealias SingleFitnessFunction = Value -> Fitness
    typealias PopulationFitnessFunction = [Value] -> [PopulationIndividual]
    var population = [PopulationIndividual]()
    var populationFitnessFunction: PopulationFitnessFunction
    var comparator: Comparator = { $0.fitness > $1.fitness }
    
    internal func generatePopulation() {
        var populationValues = [Value]()
        for _ in 1...POPULATION_SIZE {
            populationValues.append(PopulationIndividual.randomValue())
        }
        population = self.populationFitnessFunction(populationValues)
    }
    
    internal static func mappedFitnessFunction(individualFitnessFunction: SingleFitnessFunction) -> PopulationFitnessFunction {
        let functionToMap = { (value: Value) -> PopulationIndividual in
            return PopulationIndividual(value: value, fitness: individualFitnessFunction(value))
        }
        return { (values: [Value]) -> [PopulationIndividual] in
            return values.map(functionToMap)
        }
    }
    
    convenience init(individualFitnessFunction: SingleFitnessFunction) {
        let populationFitnessFunction = self.dynamicType.mappedFitnessFunction(individualFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction)
    }
    
    convenience init(individualFitnessFunction: SingleFitnessFunction, comparator: Comparator) {
        let populationFitnessFunction = self.dynamicType.mappedFitnessFunction(individualFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction, comparator: comparator)
    }
    
    init(populationFitnessFunction: PopulationFitnessFunction) {
        self.populationFitnessFunction = populationFitnessFunction
        generatePopulation()
    }
    
    init(populationFitnessFunction: PopulationFitnessFunction, comparator: Comparator) {
        self.populationFitnessFunction = populationFitnessFunction
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
        population = populationFitnessFunction(newPopulationValues)
    }
    
    func evolve() -> (generations: Int, strongestIndividual: Individual<Value, Fitness>) {
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
    
    var strongestIndividual: Individual<Value, Fitness> {
        return population.minElement(comparator)!
    }
}

struct Individual<Value: ZeroArgumentInitable, Fitness: Comparable>: CustomStringConvertible {
    let value: Value
    let fitness: Fitness
    
    init(value: Value, fitness: Fitness) {
        self.value = value
        self.fitness = fitness
    }
    
    static func randomValue() -> Value {
        let data = NSMutableData(length: sizeof(Value))
        var newValue = Value()
        SecRandomCopyBytes(kSecRandomDefault, sizeof(Value), UnsafeMutablePointer<UInt8>(data!.mutableBytes))
        data!.getBytes(&newValue, length: sizeof(Value))
        return newValue
    }
    
    var description: String {
        return "\(value): \(fitness)"
    }
}

class Reproducer<Value: ZeroArgumentInitable> {
    static func reproduce(parent1: Value, _ parent2: Value) -> Value {
        var parent1Copy = parent1
        var parent2Copy = parent2
        let parent1Data = NSData(bytes: &parent1Copy, length: sizeof(Value))
        let parent2Data = NSData(bytes: &parent2Copy, length: sizeof(Value))
        let newData = NSMutableData(data: parent1Data)
        var newValue = Value()
        
        for n in 0..<sizeof(Value) {
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
        
        newData.getBytes(&newValue, length: sizeof(Value))
        return newValue
    }
}