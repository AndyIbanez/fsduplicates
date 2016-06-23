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
    
    /// Client ID (Registered on AcoustID's website).
    let clientID: String
    
    /// Shared instance of the singleton.
    static let instance = AcoustID()
    
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
    
    ///
}
