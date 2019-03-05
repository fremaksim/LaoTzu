//
//  MummyCaches.swift
//  MohistDataPersistenceModule
//
//  Created by mozhe on 2018/10/26.
//  Copyright © 2018 mozhe. All rights reserved.
//

import Foundation
import CommonCrypto

open class MummyCaches{
    
    /// 单例
    public static let shared = MummyCaches()
    
    private let standUserDefaults = UserDefaults.standard
    
    private let MummyJSONDataCacheKeyPath = "MummyJSONDataCacheKeyPath"
    
}

// MARK: -- Struct, Class KeyArchived an KeyUnarchived
extension MummyCaches: MummyCachesKeyArchiverUnArchiverable {
    
    /// Archive Struct, Class instance to file which stored in Sandbox for disk caches.
    ///
    /// - Parameters:
    ///   - path: file stored path
    ///   - fileName: file's name to be stored
    ///   - object: struct, class instance
    /// - Returns: flag the stored operation is success or failed
    open func keyedArchiver<T: Codable>(path: URL, fileName: String, object: T) -> Bool{
        let fullPath = path.appendingPathComponent(fileName)
        let mutableData = NSMutableData()
        let archive = NSKeyedArchiver(forWritingWith: mutableData)
        do{
            try archive.encodeEncodable(object, forKey: NSKeyedArchiveRootObjectKey)
            archive.finishEncoding()
            return  mutableData.write(to: fullPath, atomically: true)
        }catch {
            return false
        }
    }
    
    /// Unarchive a struct, class instance from disk caches with the path and file's name for specify type
    ///
    /// - Parameters:
    ///   - path: file's path
    ///   - fileName: file's name
    ///   - object: specify type, the type of struct , class instance stored
    /// - Returns: struct, class instance
    open func keyedUnArchiver<T: Codable>(path: URL, fileName: String, object: T.Type) -> T? {
        let fullPath = path.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: fullPath.path){
            return nil
        }
        do {
            let data = try Data(contentsOf: fullPath)
            let unArchiver = NSKeyedUnarchiver(forReadingWith: data)
            do {
                let object = try unArchiver.decodeTopLevelDecodable(object, forKey: NSKeyedArchiveRootObjectKey)
                return object
            }catch {
                print(error.localizedDescription)
                return nil
            }
        } catch  {
            return nil
        }
    }
}

//MARK: - DataCodable Protocol
extension MummyCaches: MummyCachesDataCodable {
    
    /// Returns URL constructed from specified directory
    fileprivate func getURL(for directory: Directory) -> URL {
        var searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directory {
        case .documents:
            searchPathDirectory = .documentDirectory
        case .caches:
            searchPathDirectory = .cachesDirectory
        }
        
        if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not create URL for specified directory!")
        }
    }
    
    
    /// Store an encodable struct to the specified directory on disk
    ///
    /// - Parameters:
    ///   - object: the encodable struct to store
    ///   - directory: where to store the struct
    ///   - fileName: what to name the file where the struct data will be stored
    public func store<T: Encodable>(_ object: T, to directory: Directory, as fileName: String) {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Retrieve and convert a struct from a file on disk
    ///
    /// - Parameters:
    ///   - fileName: name of the file where struct data is stored
    ///   - directory: directory where struct data is stored
    ///   - type: struct type (i.e. Message.self)
    /// - Returns: decoded struct model(s) of data
    public func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type) -> T {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            fatalError("File at path \(url.path) does not exist!")
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("No data at \(url.path)!")
        }
    }
    
    /// Remove all files at specified directory
    public func clear(_ directory: Directory) {
        let url = getURL(for: directory)
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Remove specified file from specified directory
    public func remove(_ fileName: String, from directory: Directory) {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    public func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
}


// MARK: -- JSON Data Protocol

// 用于缓存上一次请求数据，保证网路请求失败是还有数据显示在那
extension MummyCaches: MummyCachesJSONDatable {
    
    // MARK: -- Open Methods
    
    open  func JSONToData(_ JSONResponse: AnyObject) -> Data? {
        do {
            return  try JSONSerialization.data(withJSONObject: JSONResponse,
                                               options: .prettyPrinted)
        }catch {
            return nil
        }
    }
    
    open  func dataToJSON(_ data: Data) -> AnyObject? {
        do{
            let json = try JSONSerialization.jsonObject(with: data,
                                                        options: .mutableContainers)
            return json as AnyObject
        }catch{
            return nil
        }
    }
    
    /**
     写入/更新缓存(同步) [按APP版本号缓存,不同版本APP,同一接口缓存数据互不干扰]
     - parameter jsonResponse: 要写入的数据(JSON)
     - parameter URL:          数据请求URL
     - parameter path:         一级文件夹路径path（必须设置）
     - parameter subPath:      二级文件夹路径subPath（可设置-可不设置）
     - returns: 是否写入成功
     */
    open func JSONResponseSyncSaveToCacheFile(_ jsonResponse: AnyObject,
                                              URL: String,
                                              path: String,
                                              subPath: String = "") -> Bool {
        
        let data = JSONToData(jsonResponse)
        let atPath =  cacheFilePath(with: URL,
                                    path: path,
                                    subPath: subPath)
        return FileManager.default.createFile(atPath:atPath,
                                              contents: data,
                                              attributes: nil)
    }
    
    /**
     写入/更新缓存(异步) [按APP版本号缓存,不同版本APP,同一接口缓存数据互不干扰]
     - parameter jsonResponse: 要写入的数据(JSON)
     - parameter URL:          数据请求URL
     - parameter subPath:      二级文件夹路径subPath（可设置-可不设置）
     - parameter completed:    异步完成回调(主线程回调)
     */
    open func JSONResponseAsyncSaveToCacheFile(_ jsonResponse: AnyObject,
                                               URL: String,
                                               path: String ,
                                               subPath: String = "",
                                               completed:@escaping (Bool) -> ()) {
        
        DispatchQueue.global().async{
            let result = self.JSONResponseSyncSaveToCacheFile(jsonResponse,
                                                              URL: URL,
                                                              path: path,
                                                              subPath: subPath)
            DispatchQueue.main.async(execute: {
                completed(result)
            })
        }
    }
    
    /**
     获取缓存的对象(同步)
     - parameter URL: 数据请求URL
     - parameter subPath:  二级文件夹路径subPath（可设置-可不设置）
     - returns: 缓存对象
     */
    open func JSONCache(with URL: String,subPath:String = "") -> AnyObject? {
        if let keyPath = UserDefaults.standard.string(forKey: MummyJSONDataCacheKeyPath) {
            let path: String = cacheFilePath(with: URL, path: keyPath,subPath: subPath)
            let fileManager: FileManager = FileManager.default
            if fileManager.fileExists(atPath: path, isDirectory: nil) == true {
                let data: Data = fileManager.contents(atPath: path)!
                return dataToJSON(data)
            }
        }
        return nil
    }
    
    /**
     获取总缓存路径
     - returns: 缓存路径
     - parameter subPath:   二级文件夹路径subPath（可设置-可不设置）
     */
    open func JSONCachePath() -> String {
        if let keyPath = UserDefaults.standard.string(forKey: MummyJSONDataCacheKeyPath) {
            let pathOfLibrary = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as NSString
            let path = pathOfLibrary.appendingPathComponent(keyPath)
            return path
        } else {
            return ""
        }
    }
    /**
     获取子缓存路径
     - returns: 子缓存路径
     */
    open func JSONCacheSubPath(_ subPath: String = "") -> String {
        let path = JSONCachePath() + "/" + subPath
        return path
    }
    
    /** 清除全部缓存*/
    open func clearAllJSONCache() -> Bool{
        let fileManager: FileManager = FileManager.default
        let path: String = JSONCachePath()
        if path.count == 0 { return false }
        do {
            try fileManager.removeItem(atPath: path)
            checkDirectory(JSONCachePath())
            return true
        } catch {
            print("clearCache failed , error = \(error)")
            return false
        }
    }
    /** 清除制定文件夹下全部缓存 */
    open func clearJSONCache(with url: String) -> Bool{
        let fileManager: FileManager = FileManager.default
        let path: String = JSONCacheSubPath(url)
        
        do {
            try fileManager.removeItem(atPath: path)
            checkDirectory(JSONCacheSubPath(url))
            return true
        } catch {
            print("clearCache failed , error = \(error)")
            return false
        }
    }
    /**
     获取缓存大小
     - returns: 缓存大小(单位:M)
     */
    open func cachedJSONAllSize()-> Float {
        
        let cachePath = self.JSONCachePath()
        do {
            let fileArr = try FileManager.default.contentsOfDirectory(atPath: cachePath)
            var size:Float = 0
            for file in fileArr{
                let path = cachePath + "/\(file)"
                let floder = try! FileManager.default.attributesOfItem(atPath: path)
                for (abc, bcd) in floder {
                    if abc == FileAttributeKey.size {
                        size += (bcd as AnyObject).floatValue
                    }
                }
            }
            let total = size / 1024.0 / 1024.0
            return total
        } catch {
            return 0;
        }
    }
    /**
     获取单个文件夹下缓存大小
     - returns: 子缓存大小(单位:M)
     */
    open func cacheJSONSizeWithUrl(_ Url: String)-> Float {
        
        let cachePath = self.JSONCacheSubPath(Url)
        do {
            let fileArr = try FileManager.default.contentsOfDirectory(atPath: cachePath)
            var size: Float = 0
            for file in fileArr {
                let path = cachePath + "/\(file)"
                let floder = try! FileManager.default.attributesOfItem(atPath: path)
                for (abc, bcd) in floder {
                    if abc == FileAttributeKey.size {
                        size += (bcd as AnyObject).floatValue
                    }
                }
            }
            let total = size / 1024.0 / 1024.0
            return total
        }catch{
            return 0
        }
    }
    
    
    
    // MARK: -- Private Methods
    
    fileprivate func cacheFilePath(with URL: String,
                                    path: String ,
                                    subPath:String = "") -> String {
        
        var newPath: String = ""
        if subPath.count == 0 {
            //保存最新的一级目录
            UserDefaults.standard.set(path, forKey: MummyJSONDataCacheKeyPath)
            UserDefaults.standard.synchronize()
            newPath = self.JSONCachePath()
        } else {
            newPath = self.JSONCacheSubPath(subPath)
        }
        self.checkDirectory(newPath)
        //check路径
        let cacheFileNameString: String = "URL:\(URL) AppVersion:\(appVersionString())"
        let cacheFileName: String = cacheFileNameString.MD5String()
        newPath = newPath + "/" + cacheFileName
        return newPath
    }
    
    fileprivate  func checkDirectory(_ path: String) {
        
        let fileManager: FileManager = FileManager.default
        var isDir = ObjCBool(false) //isDir判断是否为文件夹
        fileManager.fileExists(atPath: path, isDirectory: &isDir)
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            createBaseDirectory(at: path)
        } else {
            if !isDir.boolValue {
                do{
                    try fileManager.removeItem(atPath: path)
                    createBaseDirectory(at: path)
                }catch {
                    print("create cache directory failed, error = %@", error)
                }
            }
        }
    }
    
    fileprivate  func createBaseDirectory(at path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            print("path ="+path)
            self.addDoNotBackupAttribute(path)
        }catch {
            print("create cache directory failed, error = %@", error)
        }
    }
    
    fileprivate  func addDoNotBackupAttribute(_ path: String) {
        let url: URL = URL(fileURLWithPath: path)
        do{
            try  (url as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
        }catch {
            print("error to set do not backup attribute, error = %@", error)
        }
    }
    
    //    fileprivate class func md5String(from string: String) -> String {
    //        let str = string.cString(using: String.Encoding.utf8)
    //        let strLen = CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8))
    //        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    //        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen);
    //
    //        CC_MD5(str!, strLen, result);
    //        let hash = NSMutableString();
    //        for i in 0 ..< digestLen {
    //            hash.appendFormat("%02x", result[i]);
    //        }
    //        return String(format: hash as String)
    //    }
    
    fileprivate  func appVersionString() -> String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    
}

// MARK: -- UsersDafaults Protocol

extension MummyCaches: MummyCachesUserDefaultsable {}


// MARK: -- Other Class Extension

public extension String {
    
    func MD5String() -> String {
        if self.isEmpty {
            return self
        }
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen);
        
        CC_MD5(str!, strLen, result);
        let hash = NSMutableString();
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i]);
        }
        return String(format: hash as String)
    }
}




