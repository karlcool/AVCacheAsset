//
//  ViewController.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit
import AVKit

class ViewController: UIViewController, AVAssetDownloadDelegate {
    //http://cctvalih5ca.v.myalicdn.com/live/cctv1_2/index.m3u8
    //http://upload2.koucaimiao.com/filesystem/60d9459257b6c86f769a445e
    //http://upload1.koucaimiao.com/filesystem/60b483f68fdf293199bb21a5
    //https://seed128.bitchute.com/vBEqxcyTQvca/ucXUjHNSZo9G.mp4
    lazy var url = URL(string: "http://upload1.koucaimiao.com/filesystem/60b483f68fdf293199bb21a5")!
    
    lazy var asset = AVCacheAsset(url: url)
    
    lazy var playItem = AVPlayerItem(asset: asset)
    
    lazy var playLayer = AVPlayerLayer(player: player)
    
    lazy var player = AVPlayer(playerItem: playItem)

    lazy var preloader = AVPreloader.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        preloader.preload(url: url, length: 1000 * 1000 * 5)
//        play()
        
        AVURLPlayer()
    }

    func play() {
        view.layer.addSublayer(playLayer)
        playLayer.frame = view.bounds
        player.play()
    }
}

func DLog<T>(_ message: @autoclosure () -> T, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
    #if DEBUG
    // 要把路径最后的字符串截取出来
    let fName = ((fileName as NSString).pathComponents.last!.replacingOccurrences(of: "swift", with: ""))
    NSLog("%@", "\(fName)\(methodName)[\(lineNumber)]: \(message())")
    #endif
}
