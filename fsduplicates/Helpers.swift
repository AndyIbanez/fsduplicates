//
//  Helpers.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

// MARK: Useful types.

// A touple to return all the required information from a valid directory check.
typealias DirectoryCheckStatus = (isDirectory: Bool, message: String?)

// MARK: Useful functions.

/// Executes a shell command.
///
/// This function was graciously copied, pasted, and adapted from [StackOverflow](http://stackoverflow.com/a/26972043/648767)
/// - parameter launchPath: the path of the script to execute. It can simply be the tool name if it is in the user's PATH.
/// - parameter arguments: Additional arguments to pass in to the shell.
func shell(launchPath: String, arguments: [String]) -> String
{
    let task = Task()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = String(data: data, encoding: .utf8)!
    
    return output
}

/// Prints to the console.
///
/// - parameter message: The message to print.
func consoleOutput(_ message: String) {
    if arguments.contains("-v") {
        print(message)
    }
}

/// Outputs the usage information.
func usage() {
    print("usage: fsduplicates [OPTIONS]\n")
    print("Options:\n")
    print(" -f DIR_TO_SEARCH DIR_TO_OUTPUT      Find duplicates in DIR_TO_SEARCH recursively. Output to DIR_TO_OUTPUT")
    print(" -fpcalc-path FPCALC_PATH            fpcalc executable path. Default is /usr/local/bin/fpcalc")
    print(" -v                                  Verbose mode.")
}

// Checks that valid path exists and that it is a directory.
func validDirectory(path: String, parameterName: String) -> DirectoryCheckStatus {
    var isDir: ObjCBool = false
    
    let message: String?
    
    if FileManager.default().fileExists(atPath: path, isDirectory: &isDir) {
        if !isDir {
            message = "\(parameterName): not a directory."
        } else {
            message = nil
        }
    } else {
        message = "Invalid argument for \(parameterName)"
    }
    
    return(Bool(isDir), message)
}
