//
//  AVURLPlayer.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit
import AVKit

protocol AVURLPlayerDelegate: NSObjectProtocol {
    func player(_ player: AVURLPlayer, didUpdate itemStatus: AVURLPlayer.ItemStatus)
    
    func player(_ player: AVURLPlayer, didUpdate playerStatus: AVURLPlayer.Status)
    
    func player(_ player: AVURLPlayer, didUpdate playTime: Double, duration: Double)
    
    func player(_ player: AVURLPlayer, didUpdate bufferRanges: [NSValue])
}

class AVURLPlayer: NSObject {
    private(set) lazy var player: AVPlayer = {
        let result = AVPlayer()
        result.setObserver(self) { [weak self] time in
            if let _self = self {
                _self.delegate?.player(_self, didUpdate: _self.currentTime, duration: _self.duration)
            }
        }
        return result
    }()

    private(set) lazy var previewLayer: AVPlayerLayer = {
        let result = AVPlayerLayer(player: player)
        result.videoGravity = .resizeAspect
        return result
    }()
    
    private lazy var seeker = AVPlayerSeeker(player: player)
    
    private(set) var currentURL: URL?
    
    private(set) var currentAsset: AVAsset?
    
    private(set) var currentItem: AVPlayerItem?

    private(set) var currentItemStatus: ItemStatus = .none {
        didSet {
            if oldValue != currentItemStatus {
                delegate?.player(self, didUpdate: currentItemStatus)
                if currentItemStatus == .readyToPlay {
                    delegate?.player(self, didUpdate: currentTime, duration: duration)
                }
            }
        }
    }
    
    private(set) var status: Status = .none {
        didSet {
            if oldValue != status {
                delegate?.player(self, didUpdate: status)
            }
        }
    }
    
    private(set) var needResume = false
    ///播放次数，-1为无限循环
    var repeatCount = 0
    ///当前循环次数
    private(set) var currentRepeatCount = 0
    
    weak var delegate: AVURLPlayerDelegate?
    
    var isPlaying: Bool { status == .playing }
    
    var isPaused: Bool { status == .paused || status == .waitingToPlayAtSpecifiedRate }
    
    ///item当前播放时间，秒级
    var currentTime: Double {
        let sec = currentItem?.currentTime().seconds ?? 0.0
        return sec.isNaN ? 0 : sec
    }
    
    ///item总时长，只有在currentItemStatus在readyToPlay之后才有效
    var duration: Double {
        let sec = currentItem?.duration.seconds ?? 0.0
        return sec.isNaN ? 0 : sec
    }
    
    override init() {
        super.init()
        setupNotification()
    }
    
    init(url: URL) {
        super.init()
        setupNotification()
        prepare(url: url)
    }
    
    deinit {
        delegate = nil
        player.pause()
        player.removeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func willResignActive() {
        needResume = !isPaused
        pause()
    }
    
    @objc private func didBecomeActive() {
        guard needResume else {
            return
        }
        play()
    }
    
    @objc private func didPlayToEndTime(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem, let _currentItem = currentItem else {
            return
        }
        guard item == _currentItem else {
            return
        }
        if repeatCount < 0 || repeatCount > currentRepeatCount {//循环播放
            currentRepeatCount += 1
            seek(toTime: .zero)
            player.play()
        }
    }
}

extension AVURLPlayer {
    func prepare(url: URL) {
        pause()
        currentItem?.removeObserver()
        currentURL = url
        if url.isFileURL {//本地视频
            currentAsset = AVAsset(url: url)
        } else {//在线视频
            currentAsset = AVCacheAsset(url: url)
        }
        currentItem = AVPlayerItem(asset: currentAsset!)
        currentItem!.setObserver(self)
        player.replaceCurrentItem(with: currentItem!)
        currentItemStatus = .none
        currentRepeatCount = 0
    }
    
    func play() {
        guard currentItem != nil else {
            return
        }
        player.play()
        if currentURL?.isFileURL ?? false {
            currentItemStatus = .bufferFull
        } else {
            currentItemStatus = .buffering
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func seek(toTime: CMTime) {
        player.pause()
        seeker.seek(to: toTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.player.play()
        }
    }
    
    func seek(toSeconds: Double) {
        seek(toTime: .init(seconds: toSeconds, preferredTimescale: 600))
    }
}

extension AVURLPlayer {
     override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let playerItem = object as? AVPlayerItem, currentItem == playerItem {
            if keyPath == kAVPlayerItemStatus {
                currentItemStatus = ItemStatus(playerItem.status)
            } else if keyPath == kAVPlayerItemBufferEmpty {//缓冲耗尽
                if playerItem.isPlaybackBufferEmpty {
                    currentItemStatus = .buffering
                }
            } else if keyPath == kAVPlayerItemKeepUp {//缓冲足够
                if playerItem.isPlaybackLikelyToKeepUp {
                    currentItemStatus = .bufferReady
                }
            } else if keyPath == kAVPlayerItemBufferFull {//缓冲完成
                if playerItem.isPlaybackBufferFull {
                    currentItemStatus = .bufferFull
                }
            } else if keyPath == kAVPlayerItemDuration {//播放进度改变

            } else if keyPath == kAVPlayerItemTimeRanges {//缓冲进度更新
                delegate?.player(self, didUpdate: playerItem.loadedTimeRanges)
            }
        } else if let player = object as? AVPlayer, self.player == player {
            if keyPath == kAVPlayerRate {//播放器速率改变，0可简单理解为暂停，1可简单理解为播放，0.5就是0.5倍数

            } else if keyPath == kAVPlayerTimeControl {
                status = Status(player.timeControlStatus)
            } else if keyPath == kAVPlayerError {
                status = .failed(player.error)
            }
        }
    }
}

extension AVURLPlayer {
    enum Status: Equatable {
        case none
        case paused
        case waitingToPlayAtSpecifiedRate
        case playing
        case failed(Error?)
        
        init(_ status: AVPlayer.TimeControlStatus) {
            switch status {
            case .paused:
                self = .paused
            case .playing:
                self = .playing
            case .waitingToPlayAtSpecifiedRate:
                self = .waitingToPlayAtSpecifiedRate
            default:
                self = .none
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.paused, .paused):
                return true
            case (.waitingToPlayAtSpecifiedRate, .waitingToPlayAtSpecifiedRate):
                return true
            case (.playing, .playing):
                return true
            case (.failed(_), .failed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    enum ItemStatus: Int {
        ///无
        case none = -1
        ///未知
        case unknown
        ///失败
        case failed
        ///准备完成
        case readyToPlay
        ///缓冲中
        case buffering
        ///缓冲可播放
        case bufferReady
        ///缓冲完成
        case bufferFull
        ///播放完成
        case playToEndTime
        
        init(_ status: AVPlayerItem.Status) {
            switch status {
            case .failed:
                self = .failed
            case .readyToPlay:
                self = .readyToPlay
            case .unknown:
                self = .unknown
            default:
                self = .none
            }
        }
    }
}
