//
//  main.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

// MARK: Tool info

/// Command line tool version
let VERSION = "1.0.0"

/// Path of the fpcalc tool.
let fpcalcPath: String

/// Command line arguments.
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
    // Acoustic id and file path touple.
    typealias AcousticPair = (acoustID: String, filePath: String)
    
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
    
    let outputSourceFile = outputDir + "/library"
    let filesAndHashesFile = outputDir + "/fps_library"
    
    let _ = shell(launchPath: "/usr/bin/touch", arguments: [outputSourceFile])
    let _ = shell(launchPath: "/usr/bin/touch", arguments: [filesAndHashesFile])
    
    let loggedFiles = shell(launchPath: "/bin/cat", arguments: [outputSourceFile]).characters.split{$0 == "\n"}.map(String.init)
    
    consoleOutput("Reading files in directory...")
    
    var isDir: ObjCBool = false
    let sourceFiles = shell(launchPath: "/usr/bin/find", arguments: [sourceDir, "-name", "*"]).characters.split{$0 == "\n"}.map(String.init).filter{ FileManager.default().fileExists(atPath: $0, isDirectory: &isDir) && !isDir }
    
    /// AcoustID's API requirements only allow us to make three calls every second. We will manually get three elements per iteration, and the stride will help us avoid repetition.
    for var i in stride(from: 0, to: sourceFiles.count, by: 3) {
        sleep(3)
        for var j in i ... i + 2 {
            if loggedFiles.index(of: sourceFiles[j]) != nil {
                consoleOutput("\(sourceFiles[j]) is already logged")
            } else {
                AcoustID.shared.calculateFingerprint(atPath: sourceFiles[j], callback: { (fingerprint, error) in
                    if let error = error {
                        switch error {
                            case .InvalidFileFingerprint(let message): consoleOutput("Error on file \(sourceFiles[j]): \(message)")
                            case .ServerError(let message): consoleOutput("Server error for file \(sourceFiles[j]): \(message)")
                        }
                    } else {
                        if let fp = fingerprint {
                            write(string: (sourceFiles[j] + "\n"), toFile: outputSourceFile)
                            write(string: "\(fp.acoustID):\(sourceFiles[j])\n", toFile: filesAndHashesFile)
                        } else {
                            consoleOutput("AcoustID returned successfully, but fingerprint is empty for file: \(sourceFiles[j])")
                        }
                    }
                })
            }
        }
    }
    //print("source files are \(sourceFiles)")
}
