//
//  AVURLPlayer.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit
import AVKit

class AVURLPlayer: NSObject {
    private(set) lazy var player: AVPlayer = {
        let result = AVPlayer()
        result.setObserver(self) { time in
            
        }
        
        return result
    }()

    private(set) var currentItem: AVPlayerItem?

    private(set) var currentItemStatus: ItemStatus = .none
    
    private(set) var status: Status = .none
    
    override init() {
        super.init()
    }
    
    deinit {
        player.removeObserver()
    }
}

extension AVURLPlayer {
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
                playerItem.currentTime()
            } else if keyPath == kAVPlayerItemTimeRanges {//缓冲进度更新
                playerItem.loadedTimeRanges
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
    enum Status {
        case none
        case ready
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
    }
    
    enum ItemStatus: Int {
        ///无
        case none = -1
        ///未知
        case unknown
        ///准备完成
        case readyToPlay
        ///失败
        case failed
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
