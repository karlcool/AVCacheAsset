//
//  AVPlayView.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2022/6/24.
//

import AVKit

open class AVPlayView: UIView {
    open override class var layerClass: AnyClass {
        get { AVPlayerLayer.self }
    }
    
    open override var layer: AVPlayerLayer { super.layer as! AVPlayerLayer }
    
    init(player: AVPlayer? = nil) {
        super.init(frame: .zero)
        layer.player = player
        layer.videoGravity = .resizeAspect
        autoresizingMask = [.flexibleHeight, .flexibleWidth]        
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
