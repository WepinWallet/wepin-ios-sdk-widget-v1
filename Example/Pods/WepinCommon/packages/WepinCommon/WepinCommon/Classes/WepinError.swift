import Foundation

public enum WepinError: Error, LocalizedError {
    case notInitialized
    case alreadyInitialized
    case networkNotInitialized
    case invalidLoginSessionSimple
    case invalidLoginSession(String)
    case userNotFound
    case accountNotFound
    case loginFailed
    case invalidParameter(String)
    case invalidLoginProvider
    case invalidToken
    case requiredSignupEmail
    case failedEmailVerification
    case failedPasswordStateSetting
    case failedPasswordSetting
    case existedEmail
    case incorrectLifeCycle(String)
    case apiRequestError(String)
    case nftNotFound
    case balancesNotFound
    case failedSend
    case failedReceive
    case failedRegister
    case invalidAppKey
    case resultFailed
    case parsingFailed(String)
    case invalidRequest
    case networkError(String)
    case userCanceled
    case incorrectEmailForm
    case incorrectPasswordForm
    case deprecated(String)
    case requiredEmailVerified
    case notConnectedInternet
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidAppKey:
            return "Invalid App Key."
        case .notInitialized:
            return "Wepin SDK is not initialized."
        case .networkNotInitialized:
            return "Network manager is not initialized."
        case .resultFailed:
            return "The operation failed."
        case .invalidLoginSessionSimple:
            return "Invalid login session."
        case .invalidLoginSession(let message):
            return "Invalid login session.: \(message)"
        case .parsingFailed(let message):
            return "Failed to parse the response: \(message)"
        case .invalidRequest:
            return "The request is invalid."
        case .networkError(let message):
            return "Network error: \(message)"
        case .userNotFound:
            return "User not found."
        case .accountNotFound:
            return "Account not found."
        case .loginFailed:
            return "Login failed."
        case .incorrectLifeCycle(let message):
            return "Incorrect lifecycle state: \(message)"
        case .unknown(let detail):
            return "Unknown error: \(detail)"
        case .alreadyInitialized:
            return "Wepin SDK is already initialized."
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        case .invalidLoginProvider:
            return "Invalid login provider."
        case .invalidToken:
            return "Token does not exist."
        case .requiredSignupEmail:
            return "Required signup email."
        case .failedEmailVerification:
            return "Failed email verification."
        case .failedPasswordStateSetting:
            return "Failed password state setting."
        case .failedPasswordSetting:
            return "Failed password setting."
        case .existedEmail:
            return "Existed email."
        case .apiRequestError(let message):
            return "API request error: \(message)"
        case .nftNotFound:
            return "NFT not found."
        case .balancesNotFound:
            return "Balances not found."
        case .failedSend:
            return "Failed to send."
        case .failedReceive:
            return "Faild to Receive."
        case .failedRegister:
            return "Failed to Register"
        case .incorrectEmailForm:
            return "Incorrect Email Format"
        case .incorrectPasswordForm:
            return "Incorrect Password Format"
        case .deprecated(let message):
            return "This method is deprecated: \(message)"
        case .requiredEmailVerified:
            return "Email verification is required to proceed with the requested operation."
        case .notConnectedInternet:
            return "Not Connected To Internet"
        case .userCanceled:
            return "User Canceled"
        }
    }

    public var errorCode: Int {
        switch self {
        case .invalidAppKey: return WepinErrorCode.invalidAppKey.rawValue
        case .resultFailed: return WepinErrorCode.resultFailed.rawValue
        case .parsingFailed: return WepinErrorCode.parsingFailed.rawValue
        case .networkError: return WepinErrorCode.networkError.rawValue
        case .invalidRequest: return WepinErrorCode.invalidRequest.rawValue
        case .unknown: return WepinErrorCode.unknown.rawValue
        case .notInitialized: return WepinErrorCode.notInitialized.rawValue
        case .alreadyInitialized: return WepinErrorCode.alreadyInitialized.rawValue
        case .networkNotInitialized: return WepinErrorCode.networkNotInitialized.rawValue
        case .invalidLoginSessionSimple: return WepinErrorCode.invalidLoginSession.rawValue
        case .invalidLoginSession: return WepinErrorCode.invalidLoginSession.rawValue
        case .userNotFound: return WepinErrorCode.userNotFound.rawValue
        case .accountNotFound: return WepinErrorCode.accountNotFound.rawValue
        case .loginFailed: return WepinErrorCode.loginFailed.rawValue
        case .incorrectLifeCycle: return WepinErrorCode.incorrectLifeCycle.rawValue
        case .invalidParameter: return WepinErrorCode.invalidParameter.rawValue
        case .invalidLoginProvider: return WepinErrorCode.invalidLoginProvider.rawValue
        case .invalidToken: return WepinErrorCode.invalidToken.rawValue
        case .requiredSignupEmail: return WepinErrorCode.requiredSignupEmail.rawValue
        case .failedEmailVerification: return WepinErrorCode.failedEmailVerification.rawValue
        case .failedPasswordStateSetting: return WepinErrorCode.failedPasswordStateSetting.rawValue
        case .failedPasswordSetting: return WepinErrorCode.failedPasswordSetting.rawValue
        case .existedEmail: return WepinErrorCode.existedEmail.rawValue
        case .apiRequestError: return WepinErrorCode.apiRequestError.rawValue
        case .nftNotFound: return WepinErrorCode.nftNotFound.rawValue
        case .balancesNotFound: return WepinErrorCode.balancesNotFound.rawValue
        case .failedSend: return WepinErrorCode.failedSend.rawValue
        case .failedReceive: return WepinErrorCode.failedReceive.rawValue
        case .failedRegister: return WepinErrorCode.failedRegister.rawValue
        case .incorrectEmailForm: return WepinErrorCode.incorrectEmailForm.rawValue
        case .incorrectPasswordForm: return WepinErrorCode.incorrectPasswordForm.rawValue
        case .deprecated: return WepinErrorCode.deprecated.rawValue
        case .requiredEmailVerified: return WepinErrorCode.requiredEmailVerified.rawValue
        case .notConnectedInternet: return WepinErrorCode.notConnectedInternet.rawValue
        case .userCanceled: return WepinErrorCode.userCanceled.rawValue
        }
    }
    /// NSError conversion
    public var asNSError: NSError {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: self.localizedDescription
        ]
        return NSError(domain: "com.wepin.error", code: self.errorCode, userInfo: userInfo)
    }
}

@objc public enum WepinErrorCode: Int {
    case invalidAppKey = 1001
    case resultFailed = 1002
    case parsingFailed = 1003
    case networkError = 1004
    case invalidRequest = 1005
    case notInitialized = 1006
    case alreadyInitialized = 1007
    case networkNotInitialized = 1008
    case invalidLoginSession = 1009
    case userNotFound = 1010
    case accountNotFound = 1011
    case loginFailed = 1012
    case incorrectLifeCycle = 1013
    case invalidParameter = 1014
    case invalidLoginProvider = 1015
    case invalidToken = 1016
    case requiredSignupEmail = 1017
    case failedEmailVerification = 1018
    case failedPasswordStateSetting = 1019
    case failedPasswordSetting = 1020
    case existedEmail = 1021
    case apiRequestError = 1022
    case nftNotFound = 1023
    case balancesNotFound = 1024
    case failedSend = 1025
    case failedReceive = 1026
    case failedRegister = 1027
    case userCanceled = 1028
    case incorrectEmailForm = 1029
    case incorrectPasswordForm = 1030
    case deprecated = 1031
    case requiredEmailVerified = 1032
    case notConnectedInternet = 1033
    case unknown = 1099
}

// object C에서 사용할 수 있게 하기 위해..
@objc public class WepinErrorBridge: NSObject {
    @objc public static func convertToNSErrorWithCode(_ code: Int, message: String) -> NSError {
        let error: WepinError
        switch code {
        case WepinErrorCode.invalidAppKey.rawValue: error = .invalidAppKey
        case WepinErrorCode.resultFailed.rawValue: error = .resultFailed
        case WepinErrorCode.parsingFailed.rawValue: error = .parsingFailed(message)
        case WepinErrorCode.networkError.rawValue: error = .networkError(message)
        case WepinErrorCode.invalidRequest.rawValue: error = .invalidRequest
        case WepinErrorCode.unknown.rawValue: error = .unknown(message)
        case WepinErrorCode.notInitialized.rawValue: error = .notInitialized
        case WepinErrorCode.alreadyInitialized.rawValue: error = .alreadyInitialized
        case WepinErrorCode.networkNotInitialized.rawValue: error = .networkNotInitialized
        case WepinErrorCode.invalidLoginSession.rawValue: error = .invalidLoginSession(message)
        case WepinErrorCode.userNotFound.rawValue: error = .userNotFound
        case WepinErrorCode.accountNotFound.rawValue: error = .accountNotFound
        case WepinErrorCode.loginFailed.rawValue: error = .loginFailed
        case WepinErrorCode.incorrectLifeCycle.rawValue: error = .incorrectLifeCycle(message)
        case WepinErrorCode.invalidParameter.rawValue: error = .invalidParameter(message)
        case WepinErrorCode.invalidLoginProvider.rawValue: error = .invalidLoginProvider
        case WepinErrorCode.invalidToken.rawValue: error = .invalidToken
        case WepinErrorCode.requiredSignupEmail.rawValue: error = .requiredSignupEmail
        case WepinErrorCode.failedEmailVerification.rawValue: error = .failedEmailVerification
        case WepinErrorCode.failedPasswordStateSetting.rawValue: error = .failedPasswordStateSetting
        case WepinErrorCode.failedPasswordSetting.rawValue: error = .failedPasswordSetting
        case WepinErrorCode.existedEmail.rawValue: error = .existedEmail
        case WepinErrorCode.apiRequestError.rawValue: error = .apiRequestError(message)
        case WepinErrorCode.nftNotFound.rawValue: error = .nftNotFound
        case WepinErrorCode.balancesNotFound.rawValue: error = .balancesNotFound
        case WepinErrorCode.failedSend.rawValue: error = .failedSend
        case WepinErrorCode.failedReceive.rawValue: error = .failedReceive
        case WepinErrorCode.failedRegister.rawValue: error = .failedRegister
        case WepinErrorCode.incorrectEmailForm.rawValue: error = .incorrectEmailForm
        case WepinErrorCode.incorrectPasswordForm.rawValue: error = .incorrectPasswordForm
        case WepinErrorCode.deprecated.rawValue: error = .deprecated(message)
        case WepinErrorCode.requiredEmailVerified.rawValue: error = .requiredEmailVerified
        case WepinErrorCode.notConnectedInternet.rawValue: error = .notConnectedInternet
        case WepinErrorCode.userCanceled.rawValue: error = .userCanceled
        default: error = .unknown(message)
        }
        return error.asNSError
    }
}
