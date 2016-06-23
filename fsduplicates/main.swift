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

// MARK: fpcalc validity checks

if let fpcalcIndex = arguments.index(of: "-fpcalc-path") {
    // Ensuring that a path to fpcalc was passed.
    let pathIndex = fpcalcIndex + 1
    if pathIndex >= arguments.count {
        print("Invalid fpcalc path")
        usage()
        exit(1)
    }
    
    fpcalcPath = arguments[pathIndex]
} else {
    consoleOutput("-fpcalc-path has not been specified. Will try using the default path (/usr/local/bin/fpcalc)")
    fpcalcPath = "/usr/local/bin/fpcalc"
}

// Ensuring that fpcalc does exist at the specified path and can be called.
let fpcalcExecutableExists = FileManager.default().isExecutableFile(atPath: fpcalcPath)
if !fpcalcExecutableExists {
    print("\(fpcalcPath) does not exist. Exiting...")
    exit(1)
}

// MARK: -f flag logic (if present).

if let fFlagIndex = arguments.index(of: "-f") {
    // This flag requires to extra arguments.
    let minimumExpectedSize = fFlagIndex + 2
    
    if minimumExpectedSize >= arguments.count {
        print("Missing arguments for -f")
        usage()
        exit(1)
    }
    
    // Checking that the directories are valid.
    
    let sourceDir = arguments[fFlagIndex + 1]
    let outputDir = arguments[fFlagIndex + 2]
    
    let (validSource, sourceMessage) = validDirectory(path: sourceDir, parameterName: "DIR_TO_SEARCH")
    let (validOutput, outputMessage) = validDirectory(path: outputDir, parameterName: "DIR_TO_OUTPUT")
    
    if !validSource {
        if let msg = sourceMessage {
            print("\(msg)")
        } else {
            print("Unknown error")
        }
        exit(1)
    }
    
    if !validOutput {
        if let msg = outputMessage {
            print("\(msg)")
        } else {
            print("Unknown error")
        }
        exit(1)
    }
    
    let sourceFiles = shell(launchPath: "/usr/bin/find", arguments: [sourceDir, "-name", "*"])
    print("source files are \(sourceFiles)")
}
