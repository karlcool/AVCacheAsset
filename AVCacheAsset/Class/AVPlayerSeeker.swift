//
//  AVPlayerSeeker.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/19.
//

import AVKit

class AVPlayerSeeker {
    
    private var isSeeking = false
    
    private var targetTime = CMTime.zero
    
    weak var player: AVPlayer?
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    deinit {
        DLog("!!")
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        targetTime = time
        guard !isSeeking else {
            return
        }
        isSeeking = true
        _seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }
    
    private func _seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        player?.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: { [weak self] success in
            guard let _self = self else {
                completionHandler(success)
                return
            }
            if _self.targetTime == time {
                _self.isSeeking = false
                completionHandler(success)
            } else {
                _self._seek(to: _self.targetTime, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
            }
        })
    }
}
