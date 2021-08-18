//
//  AppDelegate.swift
//  AVCacheAsset
//
//  Created by 刘彦直 on 2021/8/18.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        window!.rootViewController = ViewController()
        window!.makeKeyAndVisible()

        return true
    }
}
