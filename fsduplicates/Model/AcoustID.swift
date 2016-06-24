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
    }
    
    // MARK: Properties.
    
    /// Client ID (Registered on AcoustID's website).
    let clientID: String
    
    /// Shared instance of the singleton.
    static let shared = AcoustID()
    
    // MARK: Methods
    
    /// Initializes an AcoustID object. The Client ID should be set in the client_id.plist inside the Meta directory.
    private init() {
        let bundle = Bundle.main()
        
        let fileManager = FileManager.default()
            
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
            print("fpcalc is \(fpcalc)")
        }
        
        let error = AcoustIDError.InvalidFileFingerprint("The file does not contain a valid fingerprint.")
        callback(fingerprint: nil, error: error)
    }
    
    // MARK: Helper methods.
    
    /// fpcalc the fingerprint that will be sent to AcoustID for returning the AcoustID.
    ///
    /// - parameter forFilePath: Location of the file to calculate the fingerprint of.
    private func fcpalc(forFilePath file: String) -> FPCalcResult? {
        let fpcalcResult = shell(launchPath: fpcalcPath, arguments: [file, "-hash"])
        
        let resultArray = fpcalcResult.characters.split{$0 == "\n"}.map(String.init)
        
        if resultArray.count < 4 {
            return nil
        }
        
        let file = resultArray[0]
        
        guard let duration = Int(resultArray[1]) else {
            return nil
        }
        
        let fingerprint = resultArray[2]
        let hash = resultArray[3]
        
        return (file, duration, fingerprint, hash)
    }
}
