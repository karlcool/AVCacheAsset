//
//  AVPreloader.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/17.
//

import Foundation

///预加载器
open class AVPreloader: NSObject {
    static let shared = AVPreloader()
    
    private let locker = NSLock()
    
    private lazy var tasks = Set<Task>()
    
    private override init() {
        super.init()
    }
    
    private func add(task: Task) {
        locker.lock()
        tasks.insert(task)
        locker.unlock()
    }
    
    private func remove(task: Task) {
        locker.lock()
        tasks.remove(task)
        locker.unlock()
    }
}

public extension AVPreloader {
    func preload(urls: [(URL, Int64)]) {
        for node in urls {
            preload(url: node.0, length: node.1)
        }
    }
    
    func preload(urls: [URL], length: Int64 = 1024 * 1024 * 3) {
        for url in urls {
            preload(url: url, length: length)
        }
    }
    
    func preload(url: URL, length: Int64, completion: ((Error?) -> Void)? = nil) {
        let task = Task(url: url)
        add(task: task)
        task.preload(length: length) { [weak self, weak task] error in
            if let _task = task {
                self?.remove(task: _task)
            }
            completion?(error)
        }
    }
}

private extension AVPreloader {
    class Task: NSObject {
        private(set) var task: AVDataTask?
        
        private var currentOffset: Int64 = 0
        
        let cache: AVCache

        init(url: URL) {
            cache = AVCacheProvider.shared.cache(url: url)
            super.init()
        }
        
        func preload(length: Int64, completion: ((Error?) -> Void)? = nil) {
            let temp = cache.data(offset: 0, length: length)
            guard temp.count < length else {//已经有缓存数据了
                DispatchQueue.main.async {
                    completion?(nil)
                }
                return
            }
            let offset = Int64(temp.count)
            task = AVDataTask(url: cache.url, offset: offset, end: length)
            currentOffset = offset
            task!.start { [weak self] info in
                if let _self = self {
                    _self.cache.cache(info: info)
                }
            } didLoadData: { [weak self] data in
                if let _self = self {
                    _self.cache.cache(data: data, offset: _self.currentOffset)
                    _self.currentOffset += Int64(data.count)
                }
            } finished: { [weak self] error in
                if let _self = self {
                    _self.task = nil
                }
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
}
