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

//    lazy var url = URL(fileURLWithPath: "/Users/karlcool/Downloads/test.mov")
    
    lazy var preloader = AVPreloader.shared

    lazy var player: AVURLPlayer! = {
        let result = AVURLPlayer(url: url)
        result.delegate = self
        result.repeatCount = -1
        return result
    }()
    
    lazy var controlView: UIView = {
        let temp = UIView()
        temp.backgroundColor = .white
        return temp
    }()

    lazy var playBtn: UIButton = {
        let temp = UIButton()
        temp.setTitleColor(.black, for: .normal)
        temp.setTitle("播放", for: .normal)
        temp.addTarget(self, action: #selector(play), for: .touchUpInside)
        return temp
    }()
    
    lazy var slider: UISlider = {
        let temp = UISlider()
        temp.minimumValue = 0
        temp.addTarget(self, action: #selector(progress(_:)), for: .valueChanged)
        return temp
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.addSublayer(player.previewLayer)
        configSubviews()
        player.previewLayer.frame = view.bounds
        DLog("缓存路径:\(AVCacheProvider.shared.cachePath(url))")
//        preloader.preload(url: url, length: 1000 * 1000 * 5)

        play()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(50)) {
            self.remove()
        }
    }
    
    func remove() {
        player.previewLayer.removeFromSuperlayer()
        player = nil
    }

    @objc func play() {
        if player.status == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    @objc func progress(_ sender: UISlider) {
        
        player.seek(toSeconds: Double(sender.value))
    }
}

//MARK: - ConfigSubViews
extension ViewController {
    func configSubviews() {
        setupSubviews()
        measureSubviews()
    }
    
    func setupSubviews() {
        view.addSubview(controlView)
        controlView.addSubview(playBtn)
        controlView.addSubview(slider)
    }
    
    func measureSubviews() {
        let h: CGFloat = 60
        controlView.frame = .init(x: 0, y: view.bounds.height - h - 50, width: view.bounds.width, height: h)
        playBtn.frame = .init(x: 0, y: 0, width: h, height: h)
        slider.frame = .init(x: playBtn.bounds.width, y: 0, width: controlView.bounds.width - playBtn.bounds.width, height: h)
    }
}


extension ViewController: AVURLPlayerDelegate {
    func player(_ player: AVURLPlayer, didUpdate itemStatus: AVURLPlayer.ItemStatus) {
        DLog("视频状态\(itemStatus)")
        if itemStatus == .readyToPlay {
            slider.maximumValue = Float(player.duration)
        }
    }
    
    func player(_ player: AVURLPlayer, didUpdate playerStatus: AVURLPlayer.Status) {
        DLog("播放状态\(playerStatus)")
        playBtn.setTitle(playerStatus == .paused ? "播放" : "暂停", for: .normal)
    }
    
    func player(_ player: AVURLPlayer, didUpdate playTime: Double, duration: Double) {
        slider.setValue(Float(playTime), animated: true)
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
