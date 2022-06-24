//
//  AVCacheProvider.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/17.
//

import UIKit
import CommonCrypto

public class AVCacheProvider: NSObject {
    public static let shared = AVCacheProvider()
    
    private lazy var cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/AVCache"
    
    private lazy var locker = NSLock()
    
    private lazy var cacheDic = NSMapTable<NSURL, AVCache>(keyOptions: .strongMemory, valueOptions: .weakMemory)
    
    private override init() {
        super.init()
    }
    
    public func cache(url: URL) -> AVCache {
        locker.lock()
        defer {
            locker.unlock()
        }
        if let result = cacheDic.object(forKey: url as NSURL) {
            cachePath(url)//检查并创建文件
            return result
        } else {
            let result = AVCache(url: url, cachePath: cachePath(url))
            cacheDic.setObject(result, forKey: url as NSURL)
            return result
        }
    }
}

public extension AVCacheProvider {
    func cleanCache(_ url: URL? = nil, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            AVPreloader.shared.cancel(url: url)
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
    
    func cacheSize() -> UInt {
        let keys: Set<URLResourceKey> = [.fileSizeKey]
        let urls = (try? FileManager.default.contentsOfDirectory(atPath: cacheFolder).map({ URL(fileURLWithPath: $0) })) ?? []
        let totalSize = urls.reduce(0) { size, fileURL in
            let fileSize = (try? fileURL.resourceValues(forKeys: keys))?.fileSize ?? 0
            return size + fileSize
        }
        return UInt(totalSize)
    }

    @discardableResult func cachePath(_ url: URL) -> String {
        return cachePath(cacheName(url))
    }
    
    func cachePath(_ cacheName: String) -> String {
        var path = cacheFolder
        path += "/\(cacheName)"
        if !FileManager.default.fileExists(atPath: cacheFolder) {
            try? FileManager.default.createDirectory(atPath: cacheFolder, withIntermediateDirectories: false, attributes: nil)
        }
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
