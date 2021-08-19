//
//  ViewController.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    lazy var url = URL(string: "https://stream7.iqilu.com/10339/article/202002/18/2fca1c77730e54c7b500573c2437003f.mp4")!

    lazy var preloader = AVPreloader.shared

    lazy var player: AVURLPlayer = {
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
    
    lazy var indicator: UIActivityIndicatorView = {
        let temp = UIActivityIndicatorView(style: .whiteLarge)
        temp.isUserInteractionEnabled = false
        return temp
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configSubviews()
        DLog("缓存路径:\(AVCacheProvider.shared.cachePath(url))")
//        preloader.preload(url: url, length: 1000 * 1000 * 5)

        play()
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
        view.layer.addSublayer(player.layer)
        view.addSubview(controlView)
        view.addSubview(indicator)
        controlView.addSubview(playBtn)
        controlView.addSubview(slider)
    }
    
    func measureSubviews() {
        let h: CGFloat = 60
        controlView.frame = .init(x: 0, y: view.bounds.height - h - 50, width: view.bounds.width, height: h)
        playBtn.frame = .init(x: 0, y: 0, width: h, height: h)
        slider.frame = .init(x: playBtn.bounds.width, y: 0, width: controlView.bounds.width - playBtn.bounds.width, height: h)
        indicator.frame = view.bounds
        player.layer.frame = view.bounds
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
        if playerStatus == .waitingToPlayAtSpecifiedRate || playerStatus == .seeking {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
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
