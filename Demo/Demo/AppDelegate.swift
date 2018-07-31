//
//  AppDelegate.swift
//  Demo
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import BufferedLogger
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var logger: BFLogger!

    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let writer = MyWriter()
        let config = Config(flushEntryCount: 5,
                            flushInterval: 10,
                            retryRule: MyRetryRule(retryLimit: 3))
        let entryDisk = EntryDisk()
        logger = BFLogger(writer: writer, config: config, entryStorage: entryDisk)
        logger.post("1".data(using: .utf8)!)
        logger.post("2".data(using: .utf8)!)
        logger.post("3".data(using: .utf8)!)
        logger.post("4".data(using: .utf8)!)
        logger.post("5".data(using: .utf8)!)
        logger.post("6".data(using: .utf8)!)
        return true
    }

    func applicationDidEnterBackground(_: UIApplication) {
        logger.suspend()
    }

    func applicationWillEnterForeground(_: UIApplication) {
        logger.resume()
    }
}
