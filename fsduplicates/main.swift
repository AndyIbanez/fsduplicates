//
//  main.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

/// We need to ensure that fpcalc exists. If not we will try to use the default.
let fpcalcPath: String

let arguments = Process.arguments

if let fpcalcIndex = arguments.index(of: "-fpcalc-path") {
    let pathIndex = fpcalcIndex + 1
    if pathIndex >= arguments.count {
        usage()
        exit(1)
    }
} else {
    consoleOutput("-fpcalc-path has not been specified. Will try using the default path (/usr/local/bin/fpcalc)")
    fpcalcPath = "/usr/local/bin/fpcalc"
}

print(shell(launchPath: "/usr/local/bin/fpcalc", arguments: ["-a"]))
