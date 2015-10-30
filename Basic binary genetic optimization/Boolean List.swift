//
//  Boolean List.swift
//  Basic binary genetic optimization
//
//  Created by Carter Pape on 8/11/15.
//  Copyright (c) 2015 Carter Pape. All rights reserved.
//

import Foundation

let BOOL_LIST_SIZE = 5

struct BoolList {
    private var _boolList: UInt8
    var boolList: [Bool] {
        get {
            var list: [Bool] = []
            for n in 0..<BOOL_LIST_SIZE {
                list.append(_boolList & (1 << UInt8(n)) > 0)
            }
            return list
        }
        set(newList) {
            _boolList = 0
            var n: UInt8 = 0
            for bitAsBool in newList {
                let bitaAsUInt8: UInt8 = bitAsBool ? 1 : 0
                _boolList |= bitaAsUInt8 << n
                n += 1
            }
        }
    }
    
    init(_ boolList: [Bool]) {
        self._boolList = 0
        self.boolList = boolList
    }
}