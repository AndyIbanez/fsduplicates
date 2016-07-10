//
//  AcoustID.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

/// This singleton represents the [AcoustID](https://acoustid.org) service. It fetches fingerprint data from this service.
class AcoustID {
    
    // MARK: Definitions
    
    /// Closure to call when a fingerprint is returned from AcoustID.
    typealias AcoustIDFingerprintClosure = (fingerprint: Fingerprint?, error: AcoustIDError?) -> Void
    
    /// Info returned from fpcalc.
    typealias FPCalcResult = (file: String, duration: Int, fingerprint: String, hash: String)
    
    /// An AcoustID error.
    enum AcoustIDError: ErrorProtocol {
        /// The provided file is either invalid or could not generate a valid fingerprint.
        case InvalidFileFingerprint(String)
        
        /// Server error.
        case ServerError(String)
        
        /// A fingerprint was not found for this file.
        case NoFingerprintFound(String)
    }
    
    // MARK: Properties.
    
    /// Client ID (Registered on AcoustID's website).
    let clientID: String
    
    /// Shared instance of the singleton.
    static let shared = AcoustID()
    
    // MARK: Methods
    
    /// Initializes an AcoustID object. The Client ID should be set in the client_id.plist inside the Meta directory.
    private init() {
        let bundle = Bundle.main
        
        let fileManager = FileManager.default
            
        var isDir: ObjCBool = false
        if let clientIDPlistPath = bundle.pathForResource("client_id", ofType: "plist") where fileManager.fileExists(atPath: clientIDPlistPath, isDirectory: &isDir) {
            if let clientFile = NSDictionary(contentsOfFile: clientIDPlistPath), let clientID = clientFile["client_id"] as? String {
                self.clientID = clientID
            } else {
                fatalError("Error client_id value from client_id.plist file.")
            }
        } else {
            fatalError("No client_id.plist file found")
        }
    }
    
    /// Calculates the fingerprint for the song given at the specified path.
    ///
    /// - parameter path: The path of the song to calculate the fingerprint of.
    /// - parameter callback: Closure to call after the operation is done.
    func calculateFingerprint(atPath path: String, callback: AcoustIDFingerprintClosure) {
        if let fpcalc = self.fcpalc(forFilePath: path) {
            let baseUrl = "http://api.acoustid.org/v2/lookup"
            let durQuery = "duration=\(fpcalc.duration)"
            let fpQuery = "fingerprint=\(fpcalc.fingerprint)"
            let cliQuery = "client=\(clientID)"
            // The URL will always be valid, so no problem with the forced unwrap.
            Internet.shared.post(to: URL(string: baseUrl)!, with: [durQuery, fpQuery, cliQuery]) { data, statusCode, error in
                if let er = error {
                    callback(fingerprint: nil, error: .ServerError("\(er)"))
                } else {
                    if let dat = data {
                        var error: AcoustIDError? = nil
                        let fp = Fingerprint(data: dat)
                        if fp == nil {
                            error = .NoFingerprintFound("No Fingerprint found.")
                        }
                        callback(fingerprint: fp, error: error)
                    } else {
                        callback(fingerprint: nil, error: .ServerError("data is nil."))
                    }
                }
            }
        } else {
            let error = AcoustIDError.InvalidFileFingerprint("The file does not contain a valid fingerprint")
            callback(fingerprint: nil, error: error)
        }
    }
    
    // MARK: Helper methods.
    
    /// fpcalc the fingerprint that will be sent to AcoustID for returning the AcoustID.
    ///
    /// - parameter forFilePath: Location of the file to calculate the fingerprint of.
    private func fcpalc(forFilePath file: String) -> FPCalcResult? {
        
        /// Split a KEY=value pair and return the value.
        ///
        /// - parameter keyValue: The keyValue pair to split.
        func splitKeyValuePair(_ kvp: String) -> String {
            let splat = kvp.characters.split{ $0 == "="}.map(String.init)
            return splat[1] // Unless fpcalc changes, this is guaranteed to always work.
        }
        
        let fpcalcResult = shell(launchPath: fpcalcPath, arguments: [file, "-hash"])
        
        let resultArray = fpcalcResult.characters.split{$0 == "\n"}.map(String.init)
        
        if resultArray.count < 4 {
            return nil
        }
        
        let file = splitKeyValuePair(resultArray[0])
        
        guard let duration = Int(splitKeyValuePair(resultArray[1])) else {
            return nil
        }
        
        let fingerprint = splitKeyValuePair(resultArray[2])
        let hash = splitKeyValuePair(resultArray[3])
        
        return (file, duration, fingerprint, hash)
    }
}
