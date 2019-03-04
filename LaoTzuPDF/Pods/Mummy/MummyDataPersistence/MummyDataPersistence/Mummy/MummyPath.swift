//
//  MummuPath.swift
//  MohistDataPersistenceModule
//
//  Created by mozhe on 2018/10/26.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation

public class MummyPath {
    
    /// MyApp.app - "应用程序包": 这里面存放的是应用程序的源文件，包括资源文件和可执行文件
    static var bundlePath: String {
        return Bundle.main.bundlePath
    }
    
    /// Documents: 最常用的目录，iTunes同步该应用时会同步此文件夹中的内容，适合存储重要数据。
    static var documentsPath: String {
        
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
    }
    static var documentURLPath: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return path
    }
    
    ///Library/Caches: iTunes不会同步此文件夹，适合存储体积大，不需要备份的非重要数据。
    static var cachesPath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    static var cachesURLPath: URL {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return path
    }
    
    
    // MARK: --  不应该直接访问该路径 使用UserDefaults 类处理
    /// Library/Preferences: iTunes同步该应用时会同步此文件夹中的内容，通常保存应用的设置信息。
    static var perferencesPath: String {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        return (path as NSString).appendingPathComponent("Preferences")
    }
    
    static var perferencesURLPath: URL {
        let path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return path.appendingPathComponent("Preferences")
    }
    
    ///tmp: iTunes不会同步此文件夹，系统可能在应用没运行时就删除该目录下的文件，所以此目录适合保存应用中的一些临时文件，用完就删除
    static var tmpPath: String {
        return NSTemporaryDirectory()
    }
    
    
}
