//
//  AVCacheAsset.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/17.
//

import Foundation
import AVKit

class AVCacheAsset: AVURLAsset {
    private(set) lazy var tasker = AVDataTasker(url: originUrl)

    let originUrl: URL

    override init(url URL: URL, options: [String : Any]? = nil) {
        originUrl = URL
        super.init(url: URL.fakeUrl, options: options)
        resourceLoader.setDelegate(self, queue: .init(label: "AVResourceLoader.workQueue"))
    }
}

extension AVCacheAsset: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        tasker.startTask(request: loadingRequest)
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        tasker.cancel(request: loadingRequest)
    }
}

private extension URL {
    var fakeUrl: URL {
        guard var c = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        c.scheme = "fake" + (c.scheme ?? "")
        return c.url ?? self
    }
    
    var trueUrl: URL {
        guard var c = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        c.scheme = c.scheme?.replacingOccurrences(of: "fake", with: "")
        return c.url ?? self
    }
}
