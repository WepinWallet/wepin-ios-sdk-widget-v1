import Foundation
import UIKit

public struct WepinAttribute : Codable{
    public var defaultLanguage: String
    public var defaultCurrency: String
    
    public init(defaultLanguage: String = "en",
                defaultCurrency: String = "USD") {
        self.defaultLanguage = defaultLanguage
        self.defaultCurrency = defaultCurrency
    }
}

public enum WepinLifeCycle: String {
    case notInitialized = "notInitialized"
    case initializing = "initializing"
    case initialized = "initialized"
    case login = "login"
    case beforeLogin = "beforeLogin"
    case loginBeforeRegister = "loginBeforeRegister"
}

public struct WepinUser: Codable {
    public let status: String
    public let userInfo: UserInfo?
    public let walletId: String?
    public let userStatus: WepinUserStatus?
    public let token: WepinToken?
    
    public init(status: String, userInfo: UserInfo?, walletId: String?, userStatus: WepinUserStatus?, token: WepinToken?) {
        self.status =  status
        self.userInfo = userInfo
        self.walletId = walletId
        self.userStatus = userStatus
        self.token = token
    }
    
    public struct UserInfo: Codable {
        public let userId: String
        public let email: String
        public let provider: WepinLoginProviders
        public let use2FA: Bool
        
        public init(userId: String, email: String, provider: String, use2FA: Bool) {
            self.userId = userId
            self.email = email
            self.provider = WepinLoginProviders.fromValue(provider)!
            self.use2FA = use2FA
        }
    }
    
    public struct WepinToken: Codable {
        public let access: String
        public let refresh: String
        
        public init(access: String, refresh: String) {
            self.access = access
            self.refresh = refresh
        }
    }
    
    public struct WepinUserStatus: Codable {
        public let loginStatus: WepinLoginStatus
        public let pinRequired: Bool?
        
        public init(loginStatus: String, pinRequired: Bool?) {
            self.loginStatus = WepinLoginStatus.fromValue(loginStatus)!
            self.pinRequired = pinRequired
        }
    }
}

public enum WepinLoginStatus: String, Codable {
    case complete = "complete"
    case pinRequired = "pinRequired"
    case registerRequired = "registerRequired"
    
    static func fromValue(_ value: String) -> WepinLoginStatus? {
        return WepinLoginStatus(rawValue: value)
    }
}


public enum WepinLoginProviders: String, Codable {
    case google = "google"
    case apple = "apple"
    case naver = "naver"
    case discord = "discord"
    case facebook = "facebook"
    case line = "line"
    case kakao = "kakao"
    case email = "email"
    case externalToken = "external_token"
    
    public static func fromValue(_ value: String) -> WepinLoginProviders? {
        return WepinLoginProviders(rawValue: value)
    }
}

public class WepinAttributeWithProviders : Codable {
    public var defaultLanguage: String
    public var defaultCurrency: String
    public var loginProviders: [String]

    public init(defaultLanguage: String = "en",
                defaultCurrency: String = "USD",
                loginProviders: [String]? = []) {
        self.loginProviders = loginProviders ?? []
        self.defaultLanguage = defaultLanguage
        self.defaultCurrency = defaultCurrency
    }
    
    func toDictionary() -> [String: AnyCodable] {
            let dict: [String: AnyCodable] = [
                "defaultLanguage": AnyCodable(defaultLanguage),
                "defaultCurrency": AnyCodable(defaultCurrency),
                "loginProviders": AnyCodable(loginProviders) // ← 바로 넣기
            ]
            return dict
        }
}

