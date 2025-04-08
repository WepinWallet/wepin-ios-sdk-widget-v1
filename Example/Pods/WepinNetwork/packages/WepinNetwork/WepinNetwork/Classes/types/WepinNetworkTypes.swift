import Foundation

// MARK: - Network Protocol
public protocol NetworkRequest {
    func toDictionary() -> [String: Any]?
}

public protocol QueryParamsConvertible {
    func toQueryParams() -> String
}

//// MARK: - Base Response
//public protocol BaseResponse: Codable {
//    var success: Bool { get }
//}

// MARK: - Error
public struct ErrorResponse: Codable {
    public let statusCode: Int
    public let status: Int?
    public let timestamp: String
    public let path: String
    public let message: String
    public let remainPinTryCnt: Int?
    public let code: Int
    public let validationError: String?
}

// MARK: - Auth Related Types
public struct Token: Codable {
    public let refresh: String
    public let access: String
    
    public init(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
}

public struct LoginRequest: NetworkRequest, Codable {
    var idToken: String
    
    public init(idToken: String) {
        self.idToken = idToken
    }
    
    public func toDictionary() -> [String: Any]? {
        return ["idToken": idToken]
    }
}

public struct LoginResponse: Codable {
    public let loginStatus: String
    public let pinRequired: Bool?
    public let walletId: String?
    public let token: Token
    public let userInfo: AppUser
    public var success: Bool { return true }
}

// MARK: - User Related Types
public struct AppUser: Codable {
    public let userId: String
    public let email: String
    public let name: String
    public let locale: String
    public let currency: String
    public let lastAccessDevice: String
    public let lastSessionIP: String
    public let userJoinStage: Int
    public let profileImage: String
    public let userState: Int
    public let use2FA: Int

    var userJoinStageEnum: UserJoinStage? {
        return UserJoinStage(rawValue: userJoinStage)
    }

    var userStateEnum: UserState? {
        return UserState(rawValue: userState)
    }
}

public enum UserJoinStage: Int, Codable {
    case emailRequire = 1
    case pinRequire = 2
    case complete = 3
}

public enum UserState: Int, Codable {
    case active = 1
    case deleted = 2
}

// MARK: - Account Related Types
public struct GetAccountListRequest: NetworkRequest, QueryParamsConvertible, Codable {
    public let walletId: String
    public let userId: String
    public let locale: String
    
    public init(walletId: String, userId: String, locale: String) {
        self.walletId = walletId
        self.userId = userId
        self.locale = locale
    }

    public func toQueryParams() -> String {
        return [
            "walletId": walletId,
            "userId": userId,
            "locale": locale
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
         .joined(separator: "&")
    }
    
    public func toDictionary() -> [String: Any]? {
        return ["walletId": walletId, "userId": userId, "locale": locale]
    }
}

public struct GetAccountListResponse:  Codable {
    public let walletId: String
    public let accounts: [AppAccount]
    public let aa_accounts: [AppAccount]?

    enum CodingKeys: String, CodingKey {
        case walletId
        case accounts
        case aa_accounts // = "aa_accounts"
    }
}

// MARK: - NFT Related Types
public struct GetNFTListRequest: NetworkRequest, QueryParamsConvertible {
    public let walletId: String
    public let userId: String
    
    public init(walletId: String, userId: String) {
        self.walletId = walletId
        self.userId = userId
    }
    
    public func toQueryParams() -> String {
        return "walletId=\(walletId)&userId=\(userId)"
    }
    
    public func toDictionary() -> [String: Any]? {
        return ["walletId": walletId, "userId": userId]
    }
}

public struct GetNFTListResponse:  Codable {
    public let nfts: [AppNFT]
}

// MARK: - OAuth Related Types
public struct OAuthTokenRequest: NetworkRequest, Codable {
    public let code: String
    public let state: String?
    public let clientId: String
    public let redirectUri: String
    public let codeVerifier: String?
    
    public init(code: String, clientId: String, redirectUri: String, state: String? = nil, codeVerifier: String? = nil) {
        self.code = code
        self.state = state
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.codeVerifier = codeVerifier
    }
    
    public func toDictionary() -> [String: Any]? {
        var dict: [String: Any] = [
            "code": code,
            "clientId": clientId,
            "redirectUri": redirectUri
        ]
        state.map { dict["state"] = $0 }
        codeVerifier.map { dict["codeVerifier"] = $0 }
        return dict
    }
}

// MARK: - Encodable Extension
public extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }
}

// MARK: - RegisterRequest / RegisterResponse
public struct RegisterRequest: Codable {
    public let appId: String
    public let userId: String
    public let loginStatus: String
    public let walletId: String
    
    public init(appId: String, userId: String, loginStatus: String, walletId: String) {
        self.appId = appId
        self.userId = userId
        self.loginStatus = loginStatus
        self.walletId = walletId
    }
}

public struct RegisterResponse: Codable {
    public let success: Bool
    public let walletId: String
}

// MARK: - PasswordState
public struct PasswordStateResponse: Codable {
    public var isPasswordResetRequired: Bool
}

public struct PasswordStateRequest: Codable {
    public var isPasswordResetRequired: Bool
    
    public init(isPasswordResetRequired: Bool) {
        self.isPasswordResetRequired = isPasswordResetRequired
    }
}

// MARK: - Terms Accepted
public struct ITermsAccepted: Codable {
    public let termsOfService: Bool
    public let privacyPolicy: Bool
    
    public init(termsOfService: Bool, privacyPolicy: Bool) {
        self.termsOfService = termsOfService
        self.privacyPolicy = privacyPolicy
    }
}

public struct UpdateTermsAcceptedRequest: Codable {
    public let termsAccepted: ITermsAccepted
    
    public init(termsAccepted: ITermsAccepted) {
        self.termsAccepted = termsAccepted
    }
}

public struct UpdateTermsAcceptedResponse: Codable {
    public let termsAccepted: ITermsAccepted
}

// MARK: - Verify
public struct VerifyRequest: Codable {
    public let type: String
    public let email: String
    public let localeId: Int?

    public init(type: String, email: String, localeId: Int? = 1) {
        self.type = type
        self.email = email
        self.localeId = localeId
    }
}

public struct VerifyResponse: Codable {
    public let result: Bool
    public let oobReset: String?
    public let oobVerify: String?
}

public struct CheckEmailExistResponse: Codable {
    public let isEmailExist: Bool
    public let isEmailVerified: Bool
    public let providerIds: [String]

    enum CodingKeys: String, CodingKey {
        case isEmailExist
        case isEmailVerified = "isEmailverified"
        case providerIds
    }
}

public struct GetAccessTokenResponse: Codable {
    public let token: String
}

public struct GetAccountBalanceResponse: Codable {
    public let decimals: Int
    public let symbol: String
    public let tokens: [TokenBalance]
    public let balance: String
}

public struct TokenBalance: Codable {
    public let contract: String
    public let name: String?
    public let decimals: Int
    public let symbol: String
    public let tokenId: Int
    public let balance: String
}

//public struct AppAccount: Codable {
//    public let accountId: String
//    public let address: String
//    public let eoaAddress: String?
//    public let addressPath: String
//    public let coinId: Int?
//    public let contract: String?
//    public let symbol: String
//    public let label: String
//    public let name: String
//    public let network: String
//    public let balance: String
//    public let decimals: String
//    public let iconUrl: String?
//    public let ids: String?
//    public let accountTokenId: String?
//    public let cmkId: Int?
//    public let isAA: Bool?
//
//    enum CodingKeys: String, CodingKey {
//        case accountId, address, eoaAddress, addressPath, coinId, contract, symbol
//        case label, name, network, balance, decimals, iconUrl, ids
//        case accountTokenId, cmkId, isAA
//    }
//}

public struct AppAccount: Codable {
    public let accountId: String
    public let address: String
    public let eoaAddress: String?
    public let addressPath: String
    public let coinId: Int?
    public let contract: String?
    public let symbol: String
    public let label: String
    public let name: String
    public let network: String
    public let balance: String
    public let decimals: Int?
    public let iconUrl: String?
    public let ids: String?
    public let accountTokenId: String?
    public let cmkId: Int?
    public let isAA: Bool?

    enum CodingKeys: String, CodingKey {
        case accountId
        case address
        case eoaAddress
        case addressPath
        case coinId
        case symbol
        case label
        case name
        case network
        case balance
        case decimals
        case iconUrl
        case ids
        case cmkId
        case accountTokenId
        case contract
        case isAA
    }
}

public struct AppNFT: Codable {
    public let contract: NFTContract
    public let id: String
    public let accountId: String
    public let name: String
    public let description: String
    public let tokenId: String
    public let externalLink: String
    public let imageUrl: String
    public let contentUrl: String?
    public let quantity: Int?
    public let contentType: Int
    public let state: Int

    public static let contentTypeMapping: [Int: String] = [
        1: "image",
        2: "video"
    ]
}

public struct NFTContract: Codable {
    public let coinId: Int
    public let name: String
    public let address: String
    public let scheme: Int
    public let description: String?
    public let network: String
    public let externalLink: String?
    public let imageUrl: String?

    public static let schemeMapping: [Int: String] = [
        1: "ERC721",
        2: "ERC1155",
        3: "SBT",
        4: "DNFT",
        5: "SOLANA_SFA",
        6: "KIP37",
        7: "KIP17"
    ]
}

public struct LoginOauthAccessTokenRequest: Codable {
    public let provider: String
    public let accessToken: String
    
    public init(provider: String, accessToken: String) {
        self.provider = provider
        self.accessToken = accessToken
    }
}

public struct LoginOauthIdTokenRequest: Codable {
    public var idToken: String
    
    public init(idToken: String) {
        self.idToken = idToken
    }
}

public struct LoginOauthIdTokenResponse: Codable {
    public let result: Bool
    public let token: String?
    public let signVerifyResult: Bool?
    public let error: String?
}

public struct LoginStatusResponse: Codable {
    public let loginStatus: String
    public let pinRequired: Bool?
}

public struct OAuthTokenResponse: Codable {
    public let id_token: String?
    public let access_token: String
    public let token_type: String
    public let expires_in: ExpiresIn?
    public let refresh_token: String?
    public let scope: String?
    
    public enum ExpiresIn: Codable {
        case int(Int)
        case string(String)
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Int.self) {
                self = .int(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                throw DecodingError.typeMismatch(ExpiresIn.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String for expres_in"))
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .int(let value):
                try container.encode(value)
            case .string(let value):
                try container.encode(value)
            }
        }
    }
}

public struct OAuthProviderInfo: Codable {
    public let provider: String
    public let authorizationEndpoint: String
    public let tokenEndpoint: String
    public let oauthSpec: [String]
    
    public func isSupportProvider(provider: String) -> Bool {
        return self.provider == provider
    }
}

import Foundation

public struct WepinRegex: Codable {
    public let emailRegex: NSRegularExpression
    public let passwordRegex: NSRegularExpression
    public let pinRegex: NSRegularExpression

    // ✅ 문자열 저장 (Codable 지원)
    private let emailPattern: String
    private let passwordPattern: String
    private let pinPattern: String

    // ✅ 기본 정규식 패턴 설정
    private static let defaultEmailPattern = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
    private static let defaultPasswordPattern = "^(?=.*[a-zA-Z])(?=.*[0-9]).{8,128}$"
    private static let defaultPinPattern = "^\\d{6,8}$"

    // ✅ 정규식 생성 실패 시 기본 패턴을 사용
    private static func createRegex(from pattern: String, defaultPattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            return try! NSRegularExpression(pattern: defaultPattern) // 기본값으로 초기화 (실패 가능성 없음)
        }
    }

    // ✅ `init`에서 에러 발생 시 기본값 사용
    public init(emailRegex: String, passwordRegex: String, pinRegex: String) {
        self.emailPattern = emailRegex
        self.passwordPattern = passwordRegex
        self.pinPattern = pinRegex

        self.emailRegex = WepinRegex.createRegex(from: emailRegex, defaultPattern: WepinRegex.defaultEmailPattern)
        self.passwordRegex = WepinRegex.createRegex(from: passwordRegex, defaultPattern: WepinRegex.defaultPasswordPattern)
        self.pinRegex = WepinRegex.createRegex(from: pinRegex, defaultPattern: WepinRegex.defaultPinPattern)
    }

    // ✅ Codable을 위한 키 정의
    private enum CodingKeys: String, CodingKey {
        case email
        case password
        case pin
    }

    // ✅ Decodable 구현 (디코딩 시 기본값 적용)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let emailPattern = try container.decode(String.self, forKey: .email)
        let passwordPattern = try container.decode(String.self, forKey: .password)
        let pinPattern = try container.decode(String.self, forKey: .pin)

        self.emailPattern = emailPattern
        self.passwordPattern = passwordPattern
        self.pinPattern = pinPattern

        self.emailRegex = WepinRegex.createRegex(from: emailPattern, defaultPattern: WepinRegex.defaultEmailPattern)
        self.passwordRegex = WepinRegex.createRegex(from: passwordPattern, defaultPattern: WepinRegex.defaultPasswordPattern)
        self.pinRegex = WepinRegex.createRegex(from: pinPattern, defaultPattern: WepinRegex.defaultPinPattern)
    }

    // ✅ Encodable 구현 (인코딩 시 저장)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emailPattern, forKey: .email)
        try container.encode(passwordPattern, forKey: .password)
        try container.encode(pinPattern, forKey: .pin)
    }
    
    public func validateEmail(_ email: String?) -> Bool {
        guard let email = email, emailRegex.firstMatch(in: email, range: NSRange(location: 0, length: email.count)) != nil else {
            return false
        }
        return true
    }
    
    public func validatePassword(_ password: String?) -> Bool {
        guard let password = password, passwordRegex.firstMatch(in: password, range: NSRange(location: 0, length: password.count)) != nil else {
            return false
        }
        return true
    }
    
    public func validatePin(_ pin: String?) -> Bool {
        guard let pin = pin, pinRegex.firstMatch(in: pin, range: NSRange(location: 0, length: pin.count)) != nil else {
            return false
        }
        return true
    }
}
