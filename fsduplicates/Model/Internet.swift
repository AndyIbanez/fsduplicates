//
//  Internet.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/24/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

/// Block with HTTP GET results.
typealias GetResult = (data: Data?, statusCode: Int?, error: ErrorProtocol?) -> Void

/// Small helper class to deal with HTTP.
class Internet {
    /// Main Session object belonging to this class.
    private let session = URLSession(configuration: .default())
    
    /// Shared instance.
    let shared = Internet()
    
    /// HTTP GET to the specified URL.
    ///
    /// - parameter url: URL of the URL to GET.
    /// - parameter callback: The method that should get called when the operation is finished.
    func get(_ url: URL, _ callback: GetResult) {
        // let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
        session.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                var statusCode: Int? = nil
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                callback(data: data, statusCode: statusCode, error: error)
            }
        }
    }
}
