//
//  AVDataTask.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/9.
//

import UIKit
import AVKit

typealias ContentInfo = (type: String, length: Int64)

class AVDataTask: NSObject {

    private(set) lazy var config: URLSessionConfiguration = {
        let result = URLSessionConfiguration.default
        result.networkServiceType = .video
        return result
    }()
    
    private(set) lazy var session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    
    private(set) lazy var request: URLRequest = {
        let end = requestedEnd != nil ? "\(requestedEnd!)" : ""
        var result = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        result.setValue("bytes=\(requestedOffset)-\(end)", forHTTPHeaderField: "Range")
        result.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        return result
    }()
    
    private(set) lazy var task = session.dataTask(with: request)

    let requestedOffset: Int64
    
    let requestedEnd: Int64?

    private var infoCallback: ((ContentInfo) -> Void)?
    
    private var dataCallback: ((Data) -> Void)?
    
    private var finishedCallback: ((Error?) -> Void)?

    let id = UUID().uuidString
    
    let url: URL

    init(url u: URL, offset: Int64? = nil, end: Int64? = nil) {
        url = u
        requestedOffset = offset ?? 0
        requestedEnd = end
        super.init()
    }
    
    deinit {
        cancel()
    }
}

extension AVDataTask {
    func start(didLoadInfo: @escaping (ContentInfo) -> Void, didLoadData: @escaping (Data) -> Void, finished: @escaping (Error?) -> Void) {
        infoCallback = didLoadInfo
        dataCallback = didLoadData
        finishedCallback = finished
        task.resume()
    }
    
    func cancel() {
        task.cancel()
        session.invalidateAndCancel()
    }
}

extension AVDataTask: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate { 
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let _info = response.info() {
            infoCallback?(_info)
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard data.count > 0 else {
            return
        }
        dataCallback?(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if (error as NSError?)?.code == NSURLErrorCancelled {
            finishedCallback?(nil)
        } else {
            finishedCallback?(error)
        }
    }
}

private extension URLResponse {
    func info() -> ContentInfo? {
        guard let header = (self as? HTTPURLResponse)?.allHeaderFields else {
            return nil
        }
        guard let type = header["Content-Type"] as? String else {
            return nil
        }
        guard let range = header["Content-Range"] as? String, let _length = range.split(separator: "/").last else {
            return nil
        }
        guard let length = Int64(_length) else {
            return nil
        }
        return (type, length)
    }
}
