//
//  Internet.swift
//  fsduplicates
//
//  Created by Andy Ibanez on 6/24/16.
//  Copyright © 2016 Andy Ibanez. All rights reserved.
//

import Foundation

/// Block with HTTP GET results.
typealias HTTPResult = (data: Data?, statusCode: Int?, error: ErrorProtocol?) -> Void

/// Small helper class to deal with HTTP.
class Internet {
    /// Main Session object belonging to this class.
    private let session = URLSession(configuration: .default)
    
    /// Shared instance.
    static let shared = Internet()
    
    /// Private initializer
    private init() {}
    
    /// HTTP GET to the specified URL.
    ///
    /// - parameter url: URL to get.
    /// - parameter callback: The method that should get called when the operation is finished.
    func get(_ url: URL, _ callback: HTTPResult) {
        // let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
        let task = session.dataTask(with: url) { (data, response, error) in
            var statusCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            callback(data: data, statusCode: statusCode, error: error)
        }
        
        task.resume()
    }
    
    /// HTTP POST to the specified URL
    ///
    /// - parameter url: URL to post to.
    /// - parameter values: Key-Value pairs to send along the request.
    /// - parameter callback: Closure to call when the request is done.
    func post (to url: URL, with parameters: [String], _ callback: HTTPResult) {
        var request = URLRequest(url: url)
        let params = parameters.reduce("") { "\($0)\($1)&" }
        request.httpBody = params.data(using: .utf8)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) { data, response, error in
            var statusCode: Int? = nil
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            callback(data: data, statusCode: statusCode, error: error)
        }
        task.resume()
    }
}
