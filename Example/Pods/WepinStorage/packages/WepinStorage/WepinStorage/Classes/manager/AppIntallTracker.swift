//
//  AppIntallTracker.swift
//  Pods
//
//  Created by musicgi on 3/11/25.
//


import Foundation
import Security

enum AppInstallState {
    case firstInstall
    case reInstall
    case update
    case normalRun
}

class AppInstallTracker {

    private static let userDefaultsKey = "wepin_app_install_tracker"
    private static let keychainKey = "wepin_install_id_keychain"
    
    /// 고유 UUID 생성 및 저장
   private static func generateInstallId() -> String {
       return UUID().uuidString
   }
    
    /// Keychain에 저장
       private static func saveInstallIdToKeychain(_ id: String) {
           let data = id.data(using: .utf8)!
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: keychainKey,
               kSecValueData as String: data
           ]
           SecItemDelete(query as CFDictionary)
           SecItemAdd(query as CFDictionary, nil)
       }
    
    static func deleteInstallIdFromKeychain() {
        let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keychainKey
            ]
            SecItemDelete(query as CFDictionary)
        
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)

    }
    
    /// Keychain에서 불러오기
        static func getInstallIdFromKeychain() -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keychainKey,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let data = result as? Data, let id = String(data: data, encoding: .utf8) {
                return id
            }
            return nil
        }


    static func detectInstallState(hasLoginInfo: Bool) -> AppInstallState {
        let userDefaults = UserDefaults.standard
        let hasTracked = userDefaults.bool(forKey: userDefaultsKey)
        let installIdFromKeychain = getInstallIdFromKeychain()
        
        if hasTracked {
            // 이미 로직 포함 앱이 실행된 적 있음 → 업데이트 or 정상 실행
            return .normalRun
        } else {
            // UserDefaults 없음 → 앱 첫 실행 (로직 포함 앱 처음 설치 or 기존 앱에서 업데이트)
            userDefaults.set(true, forKey: userDefaultsKey)

            // ✅ 기존 앱에서 업데이트된 상황
            if hasLoginInfo {
                if installIdFromKeychain != nil {
                    return .reInstall
                } else {
                    return .update
                }
            } else {
                // ✅ 완전한 첫 설치
                return .firstInstall
            }
        }
    }
    static func prepareInstallIdIfNeeded() {
            if getInstallIdFromKeychain() == nil {
                let newId = generateInstallId()
                saveInstallIdToKeychain(newId)
            }
        }
}
