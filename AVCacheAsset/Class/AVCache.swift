//
//  AVCache.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/9.
//

import UIKit

open class AVCache {
    private lazy var fileLength: Int64 = {
        guard let readHandle = FileHandle(forReadingAtPath: cachePath) else {
            return 0
        }
        return Int64(readHandle.seekToEndOfFile())
    }()
    
    private lazy var contentType = AVProperty(key: "AVProperty.\(cacheName).type", default: "")
    
    private lazy var contentLength = AVProperty(key: "AVProperty.\(cacheName).length", default: Int64(0))

    private lazy var uncacheRange = AVFileRange(id: cacheName)
    
    private lazy var writeHandle = FileHandle(forWritingAtPath: cachePath)
    
    private lazy var readHandle = FileHandle(forReadingAtPath: cachePath)
  
    private lazy var writeQueue = DispatchQueue(label: "AVCache.writeQueue.\(cacheName)")
    
    private lazy var locker = NSLock()
    
    let url: URL
    
    let cachePath: String
    
    let cacheName: String
    
    init(url: URL, cachePath: String) {
        self.url = url
        self.cachePath = cachePath
        cacheName = (cachePath as NSString).lastPathComponent
    }
    
    deinit {
        readHandle?.closeFile()
        writeHandle?.closeFile()
    }
    
    func contentInfo() -> ContentInfo? {
        let length = contentLength.value
        guard length != 0 else {
            return nil
        }
        return (contentType.value, length)
    }
    
    func cache(info: ContentInfo) {
        contentType.value = info.type
        contentLength.value = info.length
    }
    
    func data(offset: Int64, length: Int64) -> Data {
        locker.lock()
        defer {
            locker.unlock()
        }
        guard offset < fileLength, let range = FileRange(start: offset, end: offset + length) else {
            return Data()
        }
        uncacheRange.exclude(range)
        guard !range.isInvalid, offset == range.start else {
            return Data()
        }

        let _offset = range.start
        let _length = range.end - range.start
        
        readHandle?.seek(toFileOffset: UInt64(_offset))
        let result = readHandle?.readData(ofLength: Int(_length)) ?? Data()
        return result
    }

    func cache(data: Data, offset: Int64) {
        writeQueue.async {
            self._cache(data: data, offset: offset)
        }
    }

    private func _cache(data: Data, offset: Int64) {
        locker.lock()
        defer {
            locker.unlock()
        }
        let length = Int64(data.count)
        guard offset >= 0, length > 0 else {
            return
        }

        writeHandle?.seek(toFileOffset: UInt64(offset))
        writeHandle?.write(data)

        if let uncache = FileRange(start: fileLength, end: offset) {
            uncacheRange.add(uncache)
        }
        if let newRange = FileRange(start: offset, end: offset + length) {
            uncacheRange.deduct(newRange)
        }
        fileLength = max(offset + length, fileLength)
    }
}
