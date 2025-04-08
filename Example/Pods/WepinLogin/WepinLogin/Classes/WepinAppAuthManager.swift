import Foundation
import AppAuth
import AuthenticationServices

struct WepinAuthUtils {
    static let kStateSizeBytes = 32
    static let kCodeVerifierBytes = 32

    static func generateCodeVerifier() -> String? {
        return OIDTokenUtilities.randomURLSafeString(withSize: UInt(kCodeVerifierBytes))
    }

    static func generateState() -> String? {
        return OIDTokenUtilities.randomURLSafeString(withSize: UInt(kStateSizeBytes))
    }

    static func codeChallengeS256(for codeVerifier: String) -> String? {
        let sha256Verifier = OIDTokenUtilities.sha256(codeVerifier)
        return OIDTokenUtilities.encodeBase64urlNoPadding(sha256Verifier)
    }
}

class WepinAppAuthManager {
    public static let shared = WepinAppAuthManager()

    func buildAuthorizationRequest(
        configuration: OIDServiceConfiguration,
        clientId: String,
        redirectUrl: String,
        scopes: [String],
        additionalParameters: [String: String]?
    ) -> OIDAuthorizationRequest {
        let codeVerifier =  WepinAuthUtils.generateCodeVerifier()
        let codeChallenge = codeVerifier != nil ? WepinAuthUtils.codeChallengeS256(for: codeVerifier!) : nil

        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            clientSecret: nil,
            scope: OIDScopeUtilities.scopes(with: scopes),
            redirectURL: URL(string: redirectUrl)!,
            responseType: OIDResponseTypeCode,
            state: WepinAuthUtils.generateState(),
            nonce: nil,
            codeVerifier: codeVerifier,
            codeChallenge: codeChallenge,
            codeChallengeMethod: codeChallenge != nil ? OIDOAuthorizationRequestCodeChallengeMethodS256 : nil,
            additionalParameters: additionalParameters
        )

        return request
    }

    func exchangeToken(
        authorizationCode: String,
        codeVerifier: String?,
        configuration: OIDServiceConfiguration,
        redirectURL: URL,
        clientId: String,
        scope: String?
    ) async throws -> OIDTokenResponse {
        let tokenRequest = OIDTokenRequest(
            configuration: configuration,
            grantType: OIDGrantTypeAuthorizationCode,
            authorizationCode: authorizationCode,
            redirectURL: redirectURL,
            clientID: clientId,
            clientSecret: nil,
            scope: scope,
            refreshToken: nil,
            codeVerifier: codeVerifier,
            additionalParameters: nil
        )

        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.perform(tokenRequest) { response, error in
                if let response = response {
                    continuation.resume(returning: response)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(domain: "Unknown", code: -1))
                }
            }
        }
    }

    func formatAuthorizationResponse(_ response: OIDAuthorizationResponse, withCodeVerifier codeVerifier: String?) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        var result: [String: Any] = [
            "authorizationCode": response.authorizationCode ?? "",
            "state": response.state ?? "",
            "accessToken": response.accessToken ?? "",
            "accessTokenExpirationDate": response.accessTokenExpirationDate != nil ? dateFormatter.string(from: response.accessTokenExpirationDate!) : "",
            "tokenType": response.tokenType ?? "",
            "idToken": response.idToken ?? "",
            "scopes": response.scope != nil ? response.scope!.components(separatedBy: " ") : [],
            "additionalParameters": response.additionalParameters as Any
        ]

        if let codeVerifier = codeVerifier {
            result["codeVerifier"] = codeVerifier
        }

        return result
    }

    func formatResponse(_ response: OIDTokenResponse) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        return [
            "accessToken": response.accessToken ?? "",
            "accessTokenExpirationDate": response.accessTokenExpirationDate != nil ? dateFormatter.string(from: response.accessTokenExpirationDate!) : "",
            "additionalParameters": response.additionalParameters as Any,
            "idToken": response.idToken ?? "",
            "refreshToken": response.refreshToken ?? "",
            "tokenType": response.tokenType ?? ""
        ]
    }

    func getCodeVerifier(from request: OIDAuthorizationRequest) -> String? {
        return request.codeVerifier
    }
    
    func getErrorCode(_ error: NSError, defaultCode: String) -> String {
        
        if error.domain == OIDOAuthAuthorizationErrorDomain {
            switch error.code {
            case OIDErrorCodeOAuth.invalidRequest.rawValue:
                return "invalid_request"
            case OIDErrorCodeOAuth.unauthorizedClient.rawValue:
                return "unauthorized_client"
            case OIDErrorCodeOAuth.accessDenied.rawValue:
                return "access_denied"
            case OIDErrorCodeOAuth.unsupportedResponseType.rawValue:
                return "unsupported_response_type"
            case OIDErrorCodeOAuth.invalidScope.rawValue:
                return "invalid_scope"
            case OIDErrorCodeOAuth.serverError.rawValue:
                return "server_error"
            case OIDErrorCodeOAuth.temporarilyUnavailable.rawValue:
                return "temporarily_unavailable"
            default:
                break
            }
        } else if error.domain == OIDOAuthTokenErrorDomain {
            switch error.code {
            case OIDErrorCodeOAuthToken.invalidRequest.rawValue:
                return "invalid_request"
            case OIDErrorCodeOAuthToken.invalidClient.rawValue:
                return "invalid_client"
            case OIDErrorCodeOAuthToken.invalidGrant.rawValue:
                return "invalid_grant"
            case OIDErrorCodeOAuthToken.unauthorizedClient.rawValue:
                return "unauthorized_client"
            case OIDErrorCodeOAuthToken.unsupportedGrantType.rawValue:
                return "unsupported_grant_type"
            case OIDErrorCodeOAuthToken.invalidScope.rawValue:
                return "invalid_scope"
            default:
                break
            }
        } else if error.domain == ASWebAuthenticationSessionErrorDomain {
            switch error.code {
            case ASWebAuthenticationSessionError.canceledLogin.rawValue:
                return "user_canceled"
            case ASWebAuthenticationSessionError.presentationContextNotProvided.rawValue:
                return "required_context"
            case ASWebAuthenticationSessionError.presentationContextNotProvided.rawValue:
                return "invalid_context"
            default:
                break;
            }
        }
        switch error.code {
        case OIDErrorCode.userCanceledAuthorizationFlow.rawValue:
            return "user_canceled"
        case OIDErrorCode.browserOpenError.rawValue:
            return "browser_open_error"
        case OIDErrorCode.networkError.rawValue:
            return "network_error"
        default:
            break
        }
        

        return defaultCode
    }

    func getErrorMessage(_ error: NSError) -> String {
        if let userInfo = error.userInfo as? [String: Any],
           let oauthError = userInfo[OIDOAuthErrorResponseErrorKey] as? [String: Any],
           let errorDescription = oauthError[OIDOAuthErrorFieldErrorDescription] as? String {
            return errorDescription
        } else {
            return error.localizedDescription
        }
    }
}
