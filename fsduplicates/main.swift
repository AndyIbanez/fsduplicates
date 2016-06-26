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
let VERSION = "0.0.2"

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
    let noFingerprintsFile = outputDir + "/no_fps_library"
    
    let _ = shell(launchPath: "/usr/bin/touch", arguments: [outputSourceFile, filesAndHashesFile, noFingerprintsFile])
    
    let loggedFiles = shell(launchPath: "/bin/cat", arguments: [outputSourceFile]).characters.split{$0 == "\n"}.map(String.init)
    
    consoleOutput("Reading files in directory...")
    
    var isDir: ObjCBool = false
    let sourceFiles = shell(launchPath: "/usr/bin/find", arguments: [sourceDir, "-name", "*"]).characters.split{$0 == "\n"}.map(String.init).filter{ FileManager.default().fileExists(atPath: $0, isDirectory: &isDir) && !isDir }
    consoleOutput("Validating songs against AcoustID and building the index. This can take a while...")
    
    /// AcoustID's API requirements only allow us to make three calls every second. We will manually get three elements per iteration, and the stride will help us avoid repetition.
    for var i in stride(from: 0, to: sourceFiles.count, by: 3) {
        sleep(3)
        for var j in i ... i + 2 {
            if j >= sourceFiles.count {
                break
            }
            if loggedFiles.index(of: sourceFiles[j]) != nil {
                consoleOutput("\(sourceFiles[j]) is already logged")
            } else {
                AcoustID.shared.calculateFingerprint(atPath: sourceFiles[j], callback: { (fingerprint, error) in
                    if let error = error {
                        switch error {
                            case .InvalidFileFingerprint(let message): consoleOutput("Error on file \(sourceFiles[j]): \(message)")
                            case .ServerError(let message): consoleOutput("Server error for file \(sourceFiles[j]): \(message)")
                            
                            case .NoFingerprintFound(let message):
                                let msg = "No AcoustID found for file: \(sourceFiles[j])"
                                consoleOutput(msg)
                                write(string: (sourceFiles[j] + "\n"), toFile: noFingerprintsFile)
                        }
                    } else {
                        if let fp = fingerprint {
                            consoleOutput("Obtained fingerprint for \(sourceFiles[j]): \(fp.acoustID)")
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
    consoleOutput("The index has been created")
    exit(0)
}

// MARK: -s flag (if present).

if let showFlagIndex = arguments.index(of: "-s") {
    
    /// A touple for keeping track of AcoustID's and their repetitions.
    typealias FingerprintRepetitions = (repeated: Int, acoustID: String)
    
    // Ensuring the command is valid.
    if showFlagIndex < arguments.count - 2 {
        print("Missing parameter DIR_TO_OUTPUT")
        usage()
        exit(1)
    }
    
    var interactive = arguments.index(of: "-i") == nil ? false : true
    
    let outputDir = arguments[showFlagIndex + 1]
    let (validOutput, outputMessage) = validDirectory(path: outputDir, parameterName: "DIR_TO_OUTPUT")
    
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
    let noFingerprintsFile = outputDir + "/no_fps_library"
    
    if !FileManager.default().fileExists(atPath: filesAndHashesFile) {
        print("No duplicates found. Did you run the -f flag specifying \(outputDir) as the DIR_TO_OUTPUT?")
        exit(1)
    }
    
    consoleOutput("Gathering duplicates...")
    
    // Executing logic.
    
    // cat fps_library | cut -d":" -f1 | sort | uniq -c | sort
    let catTask = Task()
    let cutTask = Task()
    let sortTask = Task()
    let uniqTask = Task()
    let sortResultTask = Task()
    
    catTask.launchPath = "/bin/cat"
    catTask.arguments = [filesAndHashesFile]
    
    cutTask.launchPath = "/usr/bin/cut"
    cutTask.arguments = ["-d", ":", "-f1"]
    
    sortTask.launchPath = "/usr/bin/sort"
    
    uniqTask.launchPath = "/usr/bin/uniq"
    uniqTask.arguments = ["-c"]
    
    sortResultTask.launchPath = "/usr/bin/sort"
    sortResultTask.arguments = ["-nr"]
    
    let pipeBetweenCatAndCut = Pipe()
    catTask.standardOutput = pipeBetweenCatAndCut
    cutTask.standardInput = pipeBetweenCatAndCut
    
    let pipeBetweenCutAndSort = Pipe()
    cutTask.standardOutput = pipeBetweenCutAndSort
    sortTask.standardInput = pipeBetweenCutAndSort
    
    let pipeBetweenSortAndUniq = Pipe()
    sortTask.standardOutput = pipeBetweenSortAndUniq
    uniqTask.standardInput = pipeBetweenSortAndUniq
    
    let pipeBetweenUniqAndFinalSort = Pipe()
    uniqTask.standardOutput = pipeBetweenUniqAndFinalSort
    sortResultTask.standardInput = pipeBetweenUniqAndFinalSort
    
    let finalPipe = Pipe()
    sortResultTask.standardOutput = finalPipe
    
    let resultToRead = finalPipe.fileHandleForReading
    
    catTask.launch()
    cutTask.launch()
    sortTask.launch()
    uniqTask.launch()
    sortResultTask.launch()
    
    let resultData = resultToRead.readDataToEndOfFile()
    let result = String(data: resultData, encoding: .utf8)

    // The ultimate goal of this is to take all the raw output of the pipe and convert it into an array of FingerprintRepetitions.
    let resultFps = result?.characters.split {$0 == "\n"}.map(String.init)
    if let res = resultFps {
        //  string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let cleaned: [FingerprintRepetitions] = res.map { rawPair in
            let noWs = rawPair.trimmingCharacters(in: NSCharacterSet.whitespaces())
            let pair = noWs.characters.split{ $0 == " " }.map(String.init)
            if let nInt = Int(pair[0]) {
                let p: FingerprintRepetitions = (nInt, pair[1])
                return p
            }
            return (0, "") // Not very likely to happen at all.
        }
        
        // We only care about the ones that are repeated. So those who appear only once are discarded.
        let filtered = cleaned.filter{ $0.repeated > 1 }
        
        // Read all the files from the library to do the the comparison.
        var loggedFiles = shell(launchPath: "/bin/cat", arguments: [filesAndHashesFile]).characters.split{$0 == "\n"}.map(String.init)
        
        /// Represents a single action.
        enum SReadlineAction: String {
            /// Move
            case m
            
            /// Symbolic link all
            case s
            
            /// Delete a file
            case d
            
            /// Skip to next duplicate sets.
            case i
            
            /// User option is invalid.
            case invalid
            
            /// Creates an action with a raw value.
            init(rawOption: String) {
                switch rawOption {
                case "m": self = m
                case "s": self = s
                case "d": self = d
                case "i": self = i
                default: self = invalid
                }
            }
        }
        
        /// Represents a valid interactive action.
        typealias SReadlineOption = (action: SReadlineAction, fileSelection: Int?, errorMessage: String?)
        
        func parseOption(userInput: String) -> SReadlineOption {
            let splat = userInput.characters.split{$0 == " "}.map(String.init)
            
            var opt: SReadlineAction = .invalid
            var file: Int? = nil
            
            if splat.count > 0 {
                opt = SReadlineAction(rawOption: splat[0])
                if splat.count > 1 {
                    file = Int(splat[1])
                }
                
                if opt == .m || opt == .d {
                    if let f = file {
                        return (opt, f, nil)
                    } else {
                        return(.invalid, nil, "Format: OPT FILE#")
                    }
                }
                
                return(opt, nil, nil)
            } else {
                return (.invalid, 0, "Please insert an option")
            }
        }
        
        func songName(_ fullPath: String) -> String {
            let components = fullPath.characters.split{$0 == "/"}.map(String.init)
            return components[components.count - 1]
        }
        
        func songPath(_ keyPair: String) -> String {
            // keyPair = acoustid:file_path
            let components = keyPair.characters.split{$0 == ":"}.map(String.init)
            return components[components.count - 1]
        }
        
        for item in filtered {
            let acoustid = item.acoustID
            print("\n-----------------------------------")
            print("Showing duplicates for \(acoustid):")
            var counter = 0
            let existing = loggedFiles.filter { line in
                if line.contains(acoustid) {
                    let lineFileOnly = line.characters.split{$0 == ":"}.map(String.init)
                    counter += 1
                    print("\(counter). \(lineFileOnly[1])")
                    return true
                }
                return false
            }
            print("-----------------------------------")
            
            if interactive {
                var option: SReadlineOption = (.invalid, nil, nil)
                repeat {
                    print("What do you want to do?:")
                    print("(m)ove file to Library               (d)elete a file")
                    print("(s)ymbolic link all to Library       (i)gnore")
                    print("\nOPTION: ")
                    if let opt = readLine(strippingNewline: true) {
                        option = parseOption(userInput: opt)
                        if option.action == .invalid {
                            print("\n"+option.errorMessage!+"\n") // Everytime `action` is invalid, it will have an errorMessage. Safe to force-unwrap.
                            continue
                        }
                        
                        let acoustidDirPath = outputDir + "/\(acoustid)"
                        
                        if option.action == .s {
                            do {
                                consoleOutput("Attempting to create directory for symbolic links...")
                                try FileManager.default().createDirectory(atPath: acoustidDirPath, withIntermediateDirectories: false, attributes: nil)
                                consoleOutput("Directory created for symbolic links: \(acoustidDirPath)")
                                for file in existing {
                                    let nameSong = songName(file)
                                    let songLink = acoustidDirPath + "/\(nameSong)"
                                    try FileManager.default().createSymbolicLink(atPath: songLink, withDestinationPath: songPath(file))
                                    consoleOutput("Created symbolic link for \(songLink) \(file)")
                                }
                            } catch {
                                consoleOutput("Error creating symbolic links: \(error)")
                            }
                        }
                        
                        if option.action == .m {
                            do {
                                if let file = option.fileSelection where (file - 1) < existing.count {
                                    let songP = songPath(existing[file - 1])
                                    consoleOutput("Attempting to move file to directory...")
                                    //try FileManager.default().moveItem(atPath: songP, toPath: acoustidDirPath)
                                    loggedFiles = loggedFiles.filter { return !$0.contains(songP) }
                                    try FileManager.default().removeItem(atPath: filesAndHashesFile)
                                    FileManager.default().createFile(atPath: filesAndHashesFile, contents: nil, attributes: nil)
                                    for line in loggedFiles {
                                        write(string: "\(line)\n", toFile: filesAndHashesFile)
                                    }
                                } else {
                                    print("Invalid song number.")
                                    continue
                                }
                            } catch {
                                consoleOutput("Error moving file: \(error)")
                            }
                        }
                        
                        if option.action == .i {
                            break
                        }
                    } else {
                        continue
                    }
                } while option.action == .invalid
            }
        }
        
        //print("filtered \(filtered)")
    } else {
        consoleOutput("Error reading proceded results.")
        exit(1)
    }
}
