//
//  WepinStorageWrapper.swift
//  WepinStorage
//
//  Created by iotrust on 6/13/24.
//

import Foundation

@objcMembers
public class WepinStorageWrapper: NSObject {

    public static let shared = WepinStorageWrapper()

    private let storage = WepinStorage.shared

    @objc public func initialize(appId: String, sdkType: String = "ios") {
        storage.initManager(appId: appId, sdkType: sdkType)
    }

    @objc public func setStringValue(_ value: String, forKey key: String) {
        storage.setStorage(key: key, data: value)
    }

    @objc public func getStringValue(forKey key: String) -> String? {
        return storage.getStorage(key: key) as? String
    }

    @objc public func deleteValue(forKey key: String) {
        storage.deleteStorage(key: key)
    }

    @objc public func getAllStorageAsDictionary() -> NSDictionary {
        return storage.getAllStorage() as NSDictionary
    }

    @objc public func clearAllStorage() {
        storage.deleteAllStorage()
    }
}
