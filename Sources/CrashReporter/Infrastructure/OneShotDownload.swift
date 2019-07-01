//  Part of <https://github.com/brentsimmons/RSWeb/>
//
//  Created by Brent Simmons on 8/27/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//  Copyright © 2019 Christian Tietze. All rights reserved.
//  Distributed under the MIT License.

import Foundation

public typealias OneShotDownloadCallback = (Data?, URLResponse?, Error?) -> Swift.Void

private final class OneShotDownloadManager {

    private let urlSession: URLSession
    fileprivate static let shared = OneShotDownloadManager()

    public init() {

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        sessionConfiguration.httpMaximumConnectionsPerHost = 2
        sessionConfiguration.httpCookieStorage = nil
        sessionConfiguration.urlCache = nil
        sessionConfiguration.timeoutIntervalForRequest = 30

        if let appName = Bundle.main.infos[.bundleName],
           let version = Bundle.main.infos[.version] {
            sessionConfiguration.httpAdditionalHeaders = ["User-Agent" : "\(appName)-\(version)"]
        }

        urlSession = URLSession(configuration: sessionConfiguration)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    public func download(_ url: URL, _ callback: @escaping OneShotDownloadCallback) {
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async() {
                callback(data, response, error)
            }
        }
        task.resume()
    }

    public func download(_ urlRequest: URLRequest, _ callback: @escaping OneShotDownloadCallback) {
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async() {
                callback(data, response, error)
            }
        }
        task.resume()
    }
}

// Call one of these. It’s easier than referring to OneShotDownloadManager.
// callback is called on the main queue.

public func download(_ url: URL, _ callback: @escaping OneShotDownloadCallback) {
    precondition(Thread.isMainThread)
    OneShotDownloadManager.shared.download(url, callback)
}

public func download(_ urlRequest: URLRequest, _ callback: @escaping OneShotDownloadCallback) {
    precondition(Thread.isMainThread)
    OneShotDownloadManager.shared.download(urlRequest, callback)
}
