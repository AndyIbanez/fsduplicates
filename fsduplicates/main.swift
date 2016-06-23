//
//  main.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

private let fpcalcPath: String

let arguments = Process.arguments

// Trigger help.

if arguments.contains("-h") {
    usage()
    exit(0)
}

// We are gonna check that fpalc does exist, or that it was passed as a valid path. If fpalc is not found, exit early.

if let fpcalcIndex = arguments.index(of: "-fpcalc-path") {
    // Ensuring that a path to fpcalc was passed.
    let pathIndex = fpcalcIndex + 1
    if pathIndex >= arguments.count {
        print("Invalid fpcalc path")
        usage()
        exit(1)
    }
    
    // Ensuring that fpcalc can be called at that specific path.
    fpcalcPath = arguments[pathIndex]
    
    let fpcalcExecutableExists = FileManager.default().isExecutableFile(atPath: fpcalcPath)
    if !fpcalcExecutableExists {
        print("\(fpcalcPath) does not exist. Exiting...")
        exit(1)
    }
} else {
    consoleOutput("-fpcalc-path has not been specified. Will try using the default path (/usr/local/bin/fpcalc)")
    fpcalcPath = "/usr/local/bin/fpcalc"
}

//print(shell(launchPath: "/usr/local/bin/fpcalc", arguments: ["-a"]))
