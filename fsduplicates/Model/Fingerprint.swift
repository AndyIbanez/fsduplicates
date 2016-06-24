//
//  Fingerprint.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/22/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

/// Represents a status of the fingerprint.
enum Status: Int8 {
    /// The status of the fingerprint is undefined.
    case unknown = 0
    
    /// Fingerprint identification went OK.
    case ok = 1
}

/// Represents a Fingerprint returned by AcoustID.
struct Fingerprint {
    /// The acoustid of the file returned by AcoustID.
    let acoustID: String
    
    /// Initializes a Fingerprint with raw data (returned from a web server).
    ///
    /// - parameter data: The raw data to build the fingerprint object with.
    init(data: Data) {
        acoustID = ""
    }
}
