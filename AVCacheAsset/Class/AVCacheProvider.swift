//
//  AVCacheProvider.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/17.
//

import UIKit
import CommonCrypto

class AVCacheProvider: NSObject {
    static let shared = AVCacheProvider()
    
    private lazy var cacheFolder: String = {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/AVCache"
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        }
        return path
    }()
    
    private lazy var locker = NSLock()
    
    private lazy var cacheDic = [URL: AVCache]()
    
    private override init() {
        super.init()
    }
    
    func cache(url: URL) -> AVCache {
        locker.lock()
        defer {
            locker.unlock()
        }
        if cacheDic[url] == nil {
            cacheDic[url] = AVCache(url: url, cachePath: cachePath(url))
        }
        return cacheDic[url]!
    }
    
    func release(url: URL? = nil) {
        locker.lock()
        defer {
            locker.unlock()
        }
        if let _url = url {
            cacheDic.removeValue(forKey: _url)
        } else {
            cacheDic.removeAll()
        }
    }
}

extension AVCacheProvider {
    func cleanCache(_ url: URL? = nil, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            var result = true
            let path: String
            let name: String?
            if let _url = url {
                path = self.cachePath(_url)
                name = self.cacheName(_url)
            } else {
                path = self.cacheFolder
                name = nil
            }
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                result = false
            }
            AVProperty<Int>.removeAll(contains: name)
            DispatchQueue.global().async {
                completion(result)
            }
        }
    }
    
    func cacheSize(completion: @escaping (UInt64) -> Void) {
        DispatchQueue.global().async {
            var result: UInt64 = 0
            let files = (try? FileManager.default.contentsOfDirectory(atPath: self.cacheFolder)) ?? []
            for f in files {
                if let size = (try? FileManager.default.attributesOfItem(atPath: self.cacheFolder + "/" + f))?[.size] as? UInt64 {
                    result += size
                }
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func cachePath(_ url: URL) -> String {
        return cachePath(cacheName(url))
    }
    
    func cachePath(_ cacheName: String) -> String {
        var path = cacheFolder
        path += "/\(cacheName)"
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        }
        return path
    }
    
    func cacheName(_ url: URL) -> String {
        return "cache" + url.absoluteString.md5 + "cache"
    }
}

private extension String {
    var md5: String {
        guard let str = self.cString(using: .utf8) else {
            return ""
        }
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let pointer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str, strLen, pointer)
        
        var result = String()
        for i in 0 ..< digestLen {
            result.append(.init(format: "%02x", pointer[i]))
        }
        pointer.deallocate()
        return result
    }
}
