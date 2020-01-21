//
//  ErrorHandling.swift
//  Power Crude
//
//  Created by William Everett on 1/20/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation

func powerCrudeHandleError(description : String?) {
    if description != nil {
        print(description!)
    }
    
    exit(-1)
}
