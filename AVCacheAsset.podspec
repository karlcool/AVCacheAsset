
Pod::Spec.new do |s|
  s.name         = "AVCacheAsset"
  s.version      = "1.0.8"
  s.summary      = "AVCacheAsset"
  s.description  = "AVCacheAsset"
  s.homepage     = "https://github.com/karlcool/AVCacheAsset.git"
  s.license      = "Apache License 2.0"
  s.author       = { "yanzhi.liu" => "karlcool.l@qq.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/karlcool/AVCacheAsset.git", :tag => "#{s.version}" }
  s.source_files        = 'AVCacheAsset/Class/*.swift'
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
end