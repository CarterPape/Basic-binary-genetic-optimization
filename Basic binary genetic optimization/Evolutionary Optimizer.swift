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
let SAMPLE_SIZE = 10
let MUTATION_CHANCE_INVERSE: UInt32 = 8
let FITNESS_STAGNATION_THRESHOLD = 400

extension Array {
    func sample(sampleSize: Int) -> [Element] {
        var holder = self
        var toReturn = [Element]()
        for _ in 0..<sampleSize {
            let indexToPop = Int(arc4random_uniform(UInt32(holder.endIndex)))
            toReturn.append(holder.remove(at: Int(indexToPop)))
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
    typealias SingleFitnessFunction = (Value) -> Fitness
    typealias MultiFitnessFunction = ([Value]) -> [Fitness]
    typealias PopulationFitnessFunction = ([Value]) -> [PopulationIndividual]
    
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
    
    internal static func mapSingleFitnessToPopulationFitness(singleFitnessFunction: @escaping SingleFitnessFunction) -> PopulationFitnessFunction {
        let functionToMap = { (value: Value) -> PopulationIndividual in
            return PopulationIndividual(value: value, fitness: singleFitnessFunction(value))
        }
        return { (values: [Value]) -> [PopulationIndividual] in
            return values.map(functionToMap)
        }
    }
    
    internal static func mapMultiFitnessToPopulationFitness(multiFitnessFunction: @escaping MultiFitnessFunction) -> PopulationFitnessFunction {
        return { (values: [Value]) -> [PopulationIndividual] in
            let fitnesses = multiFitnessFunction(values)
            var population = [PopulationIndividual]()
            for i in 0..<values.endIndex {
                population.append(PopulationIndividual(value: values[i], fitness: fitnesses[i]))
            }
            return population
        }
    }
    
    convenience init(individualFitnessFunction: @escaping SingleFitnessFunction) {
        let populationFitnessFunction = type(of: self).mapSingleFitnessToPopulationFitness(singleFitnessFunction: individualFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction)
    }
    
    convenience init(individualFitnessFunction: @escaping SingleFitnessFunction, comparator: @escaping Comparator) {
        let populationFitnessFunction = type(of: self).mapSingleFitnessToPopulationFitness(singleFitnessFunction: individualFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction, comparator: comparator)
    }
    
    convenience init(multiFitnessFunction: @escaping MultiFitnessFunction) {
        let populationFitnessFunction = type(of: self).mapMultiFitnessToPopulationFitness(multiFitnessFunction: multiFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction)
    }
    
    convenience init(multiFitnessFunction: @escaping MultiFitnessFunction, comparator: @escaping Comparator) {
        let populationFitnessFunction = type(of: self).mapMultiFitnessToPopulationFitness(multiFitnessFunction: multiFitnessFunction)
        self.init(populationFitnessFunction: populationFitnessFunction, comparator: comparator)
    }
    
    init(populationFitnessFunction: @escaping PopulationFitnessFunction) {
        self.populationFitnessFunction = populationFitnessFunction
        generatePopulation()
    }
    
    init(populationFitnessFunction: @escaping PopulationFitnessFunction, comparator: @escaping Comparator) {
        self.populationFitnessFunction = populationFitnessFunction
        self.comparator = comparator
        generatePopulation()
    }
    
    func newGeneration() {
        population.sort(by: comparator)
        var newPopulationValues = population[0..<STRONG_SURVIVORS].flatMap({ $0.value })
        for _ in STRONG_SURVIVORS..<POPULATION_SIZE {
            var sample = population.sample(sampleSize: SAMPLE_SIZE).sorted(by: comparator)
            let offspring = Reproducer.reproduce(parent1: sample[0].value, sample[1].value)
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
            currentGeneration += 1
        }
        
        return (generations: currentGeneration, strongestIndividual: currentStrongest)
    }
    
    var strongestIndividual: Individual<Value, Fitness> {
        return population.min(by: comparator)!
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
        let data = NSMutableData(length: MemoryLayout<Value>.size)
        var newValue = Value()
        let error = SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<Value>.size, data!.mutableBytes)
        if error != errSecSuccess {
            print(error)
            exit(1)
        }
        data!.getBytes(&newValue, length: MemoryLayout<Value>.size)
        return newValue
    }
    
    var description: String {
        return "\(value): \(fitness)"
    }
}

class Reproducer<Value: ZeroArgumentInitable> {
    static func reproduce(parent1: Value, _ parent2: Value) -> Value {
        var parent1Accessible = parent1
        var parent2Accessible = parent2
        let parent1Data = NSData(bytes: &parent1Accessible, length: MemoryLayout<Value>.size)
        let parent2Data = NSData(bytes: &parent2Accessible, length: MemoryLayout<Value>.size)
        
        let newData = NSMutableData(capacity: MemoryLayout<Value>.size)
        var newValue = Value()
        
        for n in 0..<MemoryLayout<Value>.size {
            let range = NSRange(n...n)
            var parent1Byte: UInt8 = 0
            var parent2Byte: UInt8 = 0
            let mask = UInt8(arc4random() % (1 << 4))
            parent1Data.getBytes(&parent1Byte, range: range)
            parent2Data.getBytes(&parent2Byte, range: range)
            var newByte: UInt8 = (mask & parent1Byte) | (~mask & parent2Byte)
            
            while arc4random_uniform(MUTATION_CHANCE_INVERSE) == 1 {
                let randomMask = UInt8(1 << (arc4random() % 4))
                newByte = (arc4random() % 2 == 0) ? randomMask | newByte : ~randomMask & newByte
            }
            
            newData!.replaceBytes(in: range, withBytes: &newByte)
        }
        
        newData!.getBytes(&newValue, length: MemoryLayout<Value>.size)
        return newValue
    }
}
