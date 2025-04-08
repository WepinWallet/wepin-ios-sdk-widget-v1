import WepinCommon
import WepinNetwork

struct WepinLoginRequest: Codable {
    let idToken: String
}

struct WepinLoginResponse: Codable {
    let loginStatus: String
    let pinRequired: Bool?
    let walletId: String?
    let token: WepinToken
    let userInfo: WepinAppUser
}

public struct WepinToken: Codable {
    public let refresh: String
    public let access: String
}

struct WepinAppUser: Codable {
    let userId: String
    let email: String
    let name: String
    let currency: String
    let lastAccessDevice: String
    let lastSessionIP: String
    let userJoinStage: Int
    let profileImage: String
    let userState: Int
    let use2FA: Int
    
    func getUserJoinStageEnum() -> WepinUserJoinStage? {
        return WepinUserJoinStage(rawValue: userJoinStage)
    }
    
    func getUserStateEnum() -> WepinUserState? {
        return WepinUserState(rawValue: userState)
    }
}

enum WepinUserJoinStage: Int, Codable {
    case emailRequire = 1
    case pinRequire = 2
    case complete = 3
    
    static func fromStage(_ stage: Int) -> WepinUserJoinStage? {
        return WepinUserJoinStage(rawValue: stage)
    }
}

enum WepinUserState: Int, Codable {
    case active = 1
    case deleted = 2
    
    static func fromState(_ state: Int) -> WepinUserState? {
        return WepinUserState(rawValue: state)
    }
}

public struct WepinLoginParams: Codable {
    public var appId: String
    public var appKey: String
    public var baseUrl: String
    
    public init(appId: String, appKey: String) {
        self.appId = appId
        self.appKey = appKey

        self.baseUrl = try! WepinCommon.getWepinSdkUrl(appKey: appKey)["sdkBackend"] ?? ""
    }
}

public struct WepinLoginOauth2Params {
    let provider: String
    let clientId: String
    public init(provider: String, clientId: String) {
        self.provider = provider
        self.clientId = clientId
    }
}

public typealias WepinLoginOauthIdTokenRequest = LoginOauthIdTokenRequest
public typealias WepinLoginOauthAccessTokenRequest = LoginOauthAccessTokenRequest

public struct WepinLoginWithEmailParams {
    let email: String
    let password: String
    let locale: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
        self.locale = "en"
    }
    
    public init(email: String, password: String, locale: String?) {
        self.email = email
        self.password = password
        self.locale = locale ?? "en"
    }
}

public struct WepinLoginOauthResult {
    public let provider: String
    public let token: String
    public let type: WepinOauthTokenType
}

public enum WepinOauthTokenType: String {
    case idToken = "id_token"
    case accessToken = "accessToken"
}

public struct WepinFBToken {
    let idToken: String
    let refreshToken: String
}

public struct WepinLoginResult {
    public let provider: WepinLoginProviders
    public let token: WepinFBToken
}

public struct LoginProviderInfo {
    public let provider: String
    public let clientId: String
    public let clientSecret: String?
    
    public init(provider: String, clientId: String, clientSecret: String? = nil) {
        self.provider = provider
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}
