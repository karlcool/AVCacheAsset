//
//  ViewController.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    //http://cctvalih5ca.v.myalicdn.com/live/cctv1_2/index.m3u8
    //http://upload2.koucaimiao.com/filesystem/60d9459257b6c86f769a445e
    //http://upload1.koucaimiao.com/filesystem/60b483f68fdf293199bb21a5
    //https://seed128.bitchute.com/vBEqxcyTQvca/ucXUjHNSZo9G.mp4
    lazy var url = URL(string: "http://upload1.koucaimiao.com/filesystem/60b483f68fdf293199bb21a5")!

    lazy var player: AVURLPlayer = {
        let result = AVURLPlayer(url: url)
        result.delegate = self
        return result
    }()

    lazy var preloader = AVPreloader.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        DLog("缓存路径:\(AVCacheProvider.shared.cachePath(url))")
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
        play()
    }

    func play() {
        view.layer.addSublayer(player.previewLayer)
        player.previewLayer.frame = view.bounds
        player.play()
    }
}

extension ViewController: AVURLPlayerDelegate {
    func player(_ player: AVURLPlayer, didUpdate itemStatus: AVURLPlayer.ItemStatus) {
        DLog("视频状态\(itemStatus)")
    }
    
    func player(_ player: AVURLPlayer, didUpdate playerStatus: AVURLPlayer.Status) {
        DLog("播放状态\(playerStatus)")
    }
    
    func player(_ player: AVURLPlayer, didUpdate playTime: Double, duration: Double) {
        
    }
    
    func player(_ player: AVURLPlayer, didUpdate bufferRanges: [NSValue]) {
        
    }
}

func DLog<T>(_ message: @autoclosure () -> T, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
    #if DEBUG
    // 要把路径最后的字符串截取出来
    let fName = ((fileName as NSString).pathComponents.last!.replacingOccurrences(of: "swift", with: ""))
    NSLog("%@", "\(fName)\(methodName)[\(lineNumber)]: \(message())")
    #endif
}
