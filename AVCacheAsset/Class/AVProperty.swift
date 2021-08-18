//
//  AVProperty.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/12.
//

import Foundation
 
class AVProperty<T>: NSObject {
    
    let userDefaults = UserDefaults(suiteName: "UserDefaults.suite.AVProperty")
    
    let key: String
    
    var value: T {
        didSet {
            sync()
        }
    }
    
    init(key k: String, default: T) {
        key = k
        value = (userDefaults?.object(forKey: key) as? T) ?? `default`
        super.init()
    }
    
    func sync() {
        userDefaults?.set(value, forKey: key)
    }
    
    static func removeAll(contains: String? = nil) {
        guard let _userDefaults = UserDefaults(suiteName: "UserDefaults.suite.AVProperty") else {
            return
        }
        if let _contains = contains {
            for node in _userDefaults.dictionaryRepresentation() where node.key.contains(_contains) {
                _userDefaults.removeObject(forKey: node.key)
            }
        } else {
            for node in _userDefaults.dictionaryRepresentation() {
                _userDefaults.removeObject(forKey: node.key)
            }
        }
    }
}
