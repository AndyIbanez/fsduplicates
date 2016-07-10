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
    print("fsduplicates ver. \(VERSION)\n")
    print("usage: fsduplicates [OPTIONS]\n")
    print("Options:\n")
    print(" -i                                  When specified for supported commands, makes interaction interactive.")
    print(" -f DIR_TO_SEARCH DIR_TO_OUTPUT      Find duplicates in DIR_TO_SEARCH recursively. Output to DIR_TO_OUTPUT")
    print(" -fpcalc-path FPCALC_PATH            fpcalc executable path. Default is /usr/local/bin/fpcalc")
    print(" -v                                  Verbose mode.")
    print(" -s [-i] DIR_TO_OUTPUT               Show all the duplicates for the specified library (DIR_TO_OUTPUT)")
}

/// Checks that valid path exists and that it is a directory.
///
/// - parameter path: Path to check.
/// - parameter parameterName: Name of the parameter where this is being checked.
/// - return: A `DirectoryCheckStatus` containing the message and status.
func validDirectory(path: String, parameterName: String) -> DirectoryCheckStatus {
    var isDir: ObjCBool = false
    
    let message: String?
    
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
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

/// Checks if a file already exists in an output file, to avoid scanning it again.
///
/// - parameter file: File to check.
/// - parameter loggedInOutputFile: The output file to check if the file has been logged into.
func file(file: String, loggedInOutputFile outputFile: String) -> Bool {
    let _ = shell(launchPath: "/usr/bin/touch", arguments: [outputFile])
    let shellResult = shell(launchPath: "/bin/cat", arguments: [outputFile])
    if shellResult.contains(outputFile) {
        return true
    }
    return false
}

/// Writes a string at the end of the specified file.
///
/// - parameter string: String to write.
/// - parameter path: Path of the file to write in.
func write(string: String, toFile file: String) {
    guard let dataToWrite = string.data(using: .utf8) else {
        return
    }
    
    let fileHandle = FileHandle(forWritingAtPath: file)
    fileHandle?.seekToEndOfFile()
    fileHandle?.write(dataToWrite)
    fileHandle?.closeFile()
}
