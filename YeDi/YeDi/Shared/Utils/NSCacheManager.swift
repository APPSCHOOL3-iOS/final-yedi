//
//  AsyncImage.swift
//  YeDi
//
//  Created by 김성준 on 10/12/23.
//

import SwiftUI

final class NSCacheManager {
    static var sharedNSCache: NSCacheManager = NSCacheManager()
    private init() {  memoryCache.delegate = delegate }
    private let delegate = CacheDelegate()
    
    let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        #if DEBUG
        let limitCount = 200
        #else
        let limitCount = 50
        #endif
        cache.countLimit = limitCount
        return cache
    }()
}

class CacheDelegate: NSObject, NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        print("An object was evicted from the cache:", obj)
    }
}
