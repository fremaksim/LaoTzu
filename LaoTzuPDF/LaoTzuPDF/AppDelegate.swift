//
//  AppDelegate.swift
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/4.
//  Copyright © 2018 mozhe. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Log.output().info(url)
        // Log.output().info(options[UIApplication.OpenURLOptionsKey.sourceApplication]) 来源 eg.: com.tencent.xin is 微信
        /* if url.isFileURL { // /private/var/mobile/Containers/Data/Application/B9AD627F-6BAB-48AC-9D4B-4D7D20794027/Documents/Inbox/%E4%B8%9D%E8%B7%AF%E5%AE%89%E8%A3%85%E6%96%87%E6%A1%A3-5.pdf
         Log.output().info("is File URL")
         }
         */
        // Ensure the URL is a file URL
        guard url.isFileURL else { return false }
        
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }
        
        documentBrowserViewController.revealDocument(at: url, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(url) with error: '\(error)'")
                return
            }
            if let documentURL = revealedDocumentURL {
                Log.output().info("revealedDocumentURL: \(documentURL)")
            }
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }
        
        return true
    }
    
}

