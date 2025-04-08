import Foundation
import UIKit
import WebKit
import SafariServices
import AppAuth
import AuthenticationServices
import WepinCommon
import WepinStorage
import WepinSession
import WepinNetwork

public typealias CompletionHandler = (_ result:Bool?, _ error:WepinError?) -> Void

public class WepinLogin {
    private var initParams: WepinLoginParams
    var initialized: Bool = false
    var providerInfo: [OAuthProviderInfo]? = nil
    var regex: WepinRegex? = nil
    var sdkType: String = ""
    var version: String = ""
    var domain: String  = ""
    
    let networkMonitor = NetworkMonitor.shared
    
    var safariVC: SFSafariViewController? = nil
    public static var WepinAuthorizationFlow: OIDExternalUserAgentSession?
    private var authSession: ASWebAuthenticationSession?
    
    public init(_ params: WepinLoginParams, sdkType: String? = "ios") {
        initParams = params
        version = Bundle(for: WepinLogin.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        domain = Bundle.main.bundleIdentifier ?? ""
        self.sdkType = "\(sdkType ?? "ios")-login"
        WepinStorage.shared.initManager(appId: initParams.appId, sdkType: sdkType)
        
    }
    
    public func initialize() async throws -> Bool? {
        if initialized {
            throw WepinError.alreadyInitialized
        }
        do {
            do {
                try WepinNetwork.shared.initialize(appKey: initParams.appKey, domain: domain, sdkType: self.sdkType, version: version)
            } catch {
                print("invalid wepin app key")
            }
            _ = try await WepinNetwork.shared.getAppInfo()
            let fireconfig = try await WepinNetwork.shared.getFirebaseConfig()
            WepinFirebaseNetwork.shared.initialize(firebaseKey: fireconfig)
            
            WepinSessionManager.shared.initialize(appId: initParams.appId, sdkType: self.sdkType)
            
            _ = await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle()
            providerInfo = try await WepinNetwork.shared.getOAuthProviderInfo()
            regex = try await WepinNetwork.shared.getRegex()
            initialized = true
            return initialized
        } catch {
            throw error
        }
    }
    
    public func isInitialized() -> Bool {
        return initialized
    }
    
    public func finalize() {
        WepinSessionManager.shared.clearSession()
        WepinSessionManager.shared.finalize()
        WepinFirebaseNetwork.shared.finalize()
        WepinNetwork.shared.finalize()
        initialized = false
    }
    
    private func prevCheck() throws {
        if !initialized {
            throw WepinError.notInitialized
        }
        
        if !networkMonitor.isConnected {
            throw WepinError.notConnectedInternet
        }
    }
    
    @MainActor
    public func loginWithOauthProvider(params: WepinLoginOauth2Params, viewController: UIViewController) async throws -> WepinLoginOauthResult {
        try prevCheck()
        
        WepinSessionManager.shared.clearSession()
        
        guard let provider = providerInfo?.first(where: {$0.isSupportProvider(provider: params.provider)}) else {
            throw WepinError.invalidLoginProvider
        }
        let rawAuthUrl = URL(string: provider.authorizationEndpoint)!
        let extractedScope = extractScopes(from: rawAuthUrl) ?? [OIDScopeEmail]
        let tokenEndpoint = URL(string: provider.tokenEndpoint)!
        
        var authUrlClean = rawAuthUrl
        if var components = URLComponents(url: rawAuthUrl, resolvingAgainstBaseURL: false) {
            components.query = nil
            if let cleanedUrl = components.url {
                authUrlClean = cleanedUrl
            }
        }
        
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authUrlClean, tokenEndpoint: tokenEndpoint)
        let scheme = "wepin.\(initParams.appId):/oauth2redirect"
        let redirectUrl = "\(initParams.baseUrl)user/oauth/callback?uri=\(customURLEncode(scheme))"
        var additParams = ["prompt": "select_account"]
        if params.provider == "apple" {
            additParams["response_mode"] = "form_post"
        }
        
        let request = WepinAppAuthManager.shared.buildAuthorizationRequest(
            configuration: configuration,
            clientId: params.clientId,
            redirectUrl: redirectUrl,
            scopes: extractedScope,
            additionalParameters: additParams)
        
        return try await withCheckedThrowingContinuation { continuation in
            let presentationContextProvider = WepinPresentationContextProvider(window: viewController.view.window)
            self.authSession = ASWebAuthenticationSession(url: request.externalUserAgentRequestURL(),
                                                          callbackURLScheme: "wepin.\(initParams.appId)") {callbackURL, error in
                guard let callbackURL = callbackURL else {
                    if let error = error as NSError? {
                        let code = WepinAppAuthManager.shared.getErrorCode(error, defaultCode: WepinError.loginFailed.errorDescription ?? "Unknown Error")
                        let message = WepinAppAuthManager.shared.getErrorMessage(error)
                        
                        continuation.resume(throwing: WepinError.unknown("\(code) - \(message)"))
                        
                        return
                    }
                    continuation.resume(throwing: WepinError.unknown("Unknown Error"))
                    return
                }
                
                
                let authResponse = OIDAuthorizationResponse(request: request, parameters: OIDURLQueryComponent(url: callbackURL)!.dictionaryValue)
                
                Task {
                    do {
                        if params.provider == "discord" {
                            let tokenResponse = try await WepinAppAuthManager.shared.exchangeToken(
                                authorizationCode: authResponse.authorizationCode!,
                                codeVerifier: request.codeVerifier,
                                configuration: configuration,
                                redirectURL: request.redirectURL!,
                                clientId: params.clientId,
                                scope: request.scope)
                            let token = WepinLoginOauthResult(
                                provider: params.provider,
                                token: tokenResponse.accessToken ?? "",
                                type: WepinOauthTokenType.accessToken
                            )
                            continuation.resume(returning: token)
                        } else {
                            let requestParams = OAuthTokenRequest(
                                code: authResponse.authorizationCode!,
                                clientId: params.clientId,
                                redirectUri: redirectUrl,
                                state: authResponse.state,
                                codeVerifier: request.codeVerifier
                            )
                            
                            let res = try await WepinNetwork.shared.oauthTokenRequest(provider: params.provider, request: requestParams)
                            
                            let tokenType: WepinOauthTokenType = provider.oauthSpec.contains("oidc") ? WepinOauthTokenType.idToken : WepinOauthTokenType.accessToken
                            let tokenValue = tokenType == .idToken ? res.id_token ?? "" : res.access_token
                        
                            let result = WepinLoginOauthResult(
                                provider: params.provider,
                                token: tokenValue,
                                type: tokenType
                            )
                            continuation.resume(returning: result)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            self.authSession?.presentationContextProvider = presentationContextProvider
            self.authSession?.start()
        }
    }
    
    public func signUpWithEmailAndPassword(params: WepinLoginWithEmailParams) async throws -> WepinLoginResult {
        try prevCheck()
        
        if (!WepinNetwork.shared.isInitialized() || !WepinFirebaseNetwork.shared.isInitialize()) {
            throw WepinError.networkNotInitialized
        }
        
        if !regex!.validateEmail(params.email) {
            throw WepinError.incorrectEmailForm
        }
        
        if !regex!.validatePassword(params.password) {
            throw WepinError.incorrectPasswordForm
        }
        
        WepinSessionManager.shared.clearSession()
        
        do {
            let checkEmailResponse = try await WepinNetwork.shared.checkEmailExist(email: params.email)
            if (checkEmailResponse.isEmailExist == true && checkEmailResponse.isEmailVerified == true && ((checkEmailResponse.providerIds.contains("password")) != nil)) {
                throw WepinError.existedEmail
            } else {
                let verifyResponse = try await WepinNetwork.shared.verify(request: VerifyRequest(type: "create", email: params.email, localeId: params.locale == "ko" ? 1 : 2))
//                if verifyResponse.result != nil {
                    if verifyResponse.oobReset != nil && verifyResponse.oobVerify != nil {
                        let resetPWres = try await WepinFirebaseNetwork.shared.resetPassword(ResetPasswordRequest(oobCode: verifyResponse.oobReset!, newPassword: params.password))
                        if resetPWres == nil || resetPWres.email.lowercased() != params.email.lowercased() {
                            throw WepinError.failedEmailVerification
                        }
                        return try await loginWithEmailAndResetPasswordState(params: params)
                    } else {
                        throw WepinError.requiredEmailVerified
                    }
//                }
                throw WepinError.failedEmailVerification
            }
        } catch (let wepinError) {
            throw wepinError
        }
    }
    
    public func loginWithEmailAndPassword(params: WepinLoginWithEmailParams) async throws -> WepinLoginResult {
        try prevCheck()
        if !regex!.validateEmail(params.email) {
            throw WepinError.incorrectEmailForm
        }
        if !regex!.validatePassword(params.password) {
            throw WepinError.incorrectPasswordForm
        }
        if (!WepinNetwork.shared.isInitialized() || !WepinFirebaseNetwork.shared.isInitialize()) {
            throw WepinError.networkNotInitialized
        }
        
        do {
            let checkEmailResponse = try await WepinNetwork.shared.checkEmailExist(email: params.email)
            if (checkEmailResponse.isEmailExist == true && checkEmailResponse.isEmailVerified == true && ((checkEmailResponse.providerIds.contains("password")) != nil)) {
                return try await loginWithEmailAndResetPasswordState(params: params)
            } else {
                throw WepinError.requiredSignupEmail
            }
        } catch let wepinError {
            throw wepinError
        }
    }
    
    private func loginWithEmailAndResetPasswordState(params: WepinLoginWithEmailParams) async throws -> WepinLoginResult {
        WepinSessionManager.shared.clearSession()
        var isChangedRequired = false
        do {
            let res = try await WepinNetwork.shared.getUserPasswordState(email: params.email)
            isChangedRequired = res.isPasswordResetRequired
        } catch {
            switch error {
            case let networkError as WepinError:
                switch networkError {
                case .networkError(let message):
                    if !isFirstEmailUser(errorString: message) {
                        throw error
                    } else {
                        isChangedRequired = true
                    }
                default: throw error
                    
                }
            default: throw error
            }
        }
        
        do {
            let encryptPW = hashPassword(params.password)
            let firstPW = isChangedRequired ? params.password : encryptPW
            let signInRes = try await WepinFirebaseNetwork.shared.signInWithEmailPassword(EmailAndPasswordRequest(email: params.email, password: firstPW))
            if signInRes.idToken == nil || signInRes.refreshToken == nil {
                throw WepinError.loginFailed
            }
            if (isChangedRequired) {
                let loginRes = try await WepinNetwork.shared.login(request: LoginRequest(idToken: signInRes.idToken))
                if loginRes.userInfo.userId == nil {
                    throw WepinError.loginFailed
                }
                WepinNetwork.shared.setAuthToken(access: loginRes.token.access, refresh: loginRes.token.refresh)
                let updatePwRes = try await WepinFirebaseNetwork.shared.updatePassword(idToken: signInRes.idToken, password: encryptPW)
                if updatePwRes == nil || updatePwRes.idToken == nil || updatePwRes.refreshToken == nil {
                    throw WepinError.failedPasswordSetting
                }
                
                let updatePWStateRes = try await WepinNetwork.shared.updateUserPasswordState(userId: loginRes.userInfo.userId, request: PasswordStateRequest(isPasswordResetRequired: false))
                if updatePWStateRes.isPasswordResetRequired != false {
                    throw WepinError.failedPasswordSetting
                }
                WepinNetwork.shared.clearAuthToken()
                
                let wepinToken = StorageDataType.FirebaseWepin(idToken: updatePwRes.idToken, refreshToken: updatePwRes.refreshToken, provider: WepinLoginProviders.email.rawValue)
                WepinStorage.shared.setStorage(key: "firebase:wepin", data: wepinToken)
                return WepinLoginResult(provider: WepinLoginProviders.email, token: WepinFBToken(idToken: updatePwRes.idToken, refreshToken: updatePwRes.refreshToken))
            } else {
                return WepinLoginResult(provider: WepinLoginProviders.email, token: WepinFBToken(idToken: signInRes.idToken, refreshToken: signInRes.refreshToken))
            }
        } catch let error {
            throw error
        }
    }
    
    public func loginWithIdToken(params: WepinLoginOauthIdTokenRequest) async throws -> WepinLoginResult {
        try prevCheck()
        
        if (!WepinNetwork.shared.isInitialized() || !WepinFirebaseNetwork.shared.isInitialize()) {
            throw WepinError.networkNotInitialized
        }
        
        WepinSessionManager.shared.clearSession()
        
        do {
            let res = try await WepinNetwork.shared.loginOAuthIdToken(request: params)
            if res.token == nil {
                throw WepinError.invalidToken
            }
            let fbRes = try await WepinFirebaseNetwork.shared.signInWithCustomToken((res.token)!)
            if fbRes == nil || fbRes.idToken == nil || (fbRes.refreshToken) == nil {
                throw WepinError.loginFailed
            }
            let fbToken = WepinFBToken(idToken: (fbRes.idToken), refreshToken: (fbRes.refreshToken))
            let wepinToken = StorageDataType.FirebaseWepin(idToken: (fbRes.idToken), refreshToken: (fbRes.refreshToken), provider: WepinLoginProviders.externalToken.rawValue)
            WepinStorage.shared.setStorage(key: "firebase:wepin", data: wepinToken)
            return WepinLoginResult(provider: WepinLoginProviders.externalToken, token: fbToken)
        } catch let wepinError {
            throw wepinError
        }
    }
    
    public func loginWithAccessToken(params: WepinLoginOauthAccessTokenRequest) async throws -> WepinLoginResult {
        try prevCheck()
        
        guard let info = providerInfo?.first(where: { $0.provider == params.provider }) else {
            throw WepinError.invalidLoginProvider
        }
        
        if info.oauthSpec.contains("oidc") {
            throw WepinError.invalidLoginProvider
        }
        
        if (!WepinNetwork.shared.isInitialized() || !WepinFirebaseNetwork.shared.isInitialize()) {
            throw WepinError.networkNotInitialized
        }
    
        WepinSessionManager.shared.clearSession()
    
        do {
            let res = try await WepinNetwork.shared.loginOAuthAccessToken(request: params)
            if res.token == nil {
                throw WepinError.invalidToken
            }
            let fbRes = try await WepinFirebaseNetwork.shared.signInWithCustomToken((res.token)!)
            if fbRes == nil || fbRes.idToken == nil || fbRes.refreshToken == nil {
                throw WepinError.loginFailed
            }
            let fbToken = WepinFBToken(idToken: (fbRes.idToken), refreshToken: (fbRes.refreshToken))
            let loginResult = WepinLoginResult(provider: WepinLoginProviders.externalToken, token: fbToken)
            let wepinToken = StorageDataType.FirebaseWepin(idToken: (fbRes.idToken), refreshToken: (fbRes.refreshToken), provider: WepinLoginProviders.externalToken.rawValue)
            
            WepinStorage.shared.setStorage(key: "firebase:wepin", data: wepinToken)
            return loginResult
        } catch let wepinError {
            throw wepinError
        }
    }
    
    public func getRefreshFirebaseToken(prevFBToken: WepinLoginResult? = nil) async throws -> WepinLoginResult {
        try prevCheck()
        
        if (!WepinNetwork.shared.isInitialized() || !WepinFirebaseNetwork.shared.isInitialize()) {
            throw WepinError.networkNotInitialized
        }
        
        do {
            if (prevFBToken != nil) {
                var response = try await WepinFirebaseNetwork.shared.getRefreshIdToken(GetRefreshIdTokenRequest(
                    refreshToken: prevFBToken!.token.refreshToken
                ))
                return WepinLoginResult(provider: prevFBToken!.provider, token: WepinFBToken(idToken: response.idToken, refreshToken: response.refreshToken))
            }
            
            let sessionExist = await WepinSessionManager.shared.checkExistFirebaseLoginSession()
            if (sessionExist) {
                let token = WepinStorage.shared.getStorage(key: "firebase:wepin") as? StorageDataType.FirebaseWepin
                
                if (token == nil) {
                    throw WepinError.invalidLoginSessionSimple
                }
                return WepinLoginResult(provider: WepinLoginProviders(rawValue: token!.provider)!, token: WepinFBToken(idToken: token!.idToken, refreshToken: token!.refreshToken))
            } else {
                throw WepinError.invalidLoginSessionSimple
            }
        } catch let wepinError {
            throw wepinError
        }
    }
    
    public func loginWepin(params: WepinLoginResult) async throws -> WepinUser {
        try prevCheck()
        
        if ((params.token.idToken.isEmpty) || (params.token.refreshToken.isEmpty)) {
            throw WepinError.invalidParameter("idToken and refreshToken are required")
        }
        
        do {
            let res = try await WepinNetwork.shared.login(request: LoginRequest(idToken: params.token.idToken))
            if (res.userInfo == nil) {
                throw WepinError.loginFailed
            }
            setWepinUser(request: params, response: res)
            return getWepinUser()!
        } catch {
            throw error
        }
    }
    
    public func getCurrentWepinUser() async throws -> WepinUser {
        try prevCheck()
        do {
            _ = await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle()
            let data = getWepinUser()
            if data != nil {
                return data!
            }
            throw WepinError.invalidLoginSessionSimple
        } catch let wepinError {
            throw wepinError
        }
    }
    
    public func logoutWepin() async throws -> Bool {
        try prevCheck()
        let userId = WepinStorage.shared.getStorage(key: "user_id")
        
        if userId == nil {
            throw WepinError.loginFailed
        }
        do {
            let res = try await WepinNetwork.shared.logout(userId: userId as! String)
            if (!res) {
                throw WepinError.loginFailed
            }
            WepinSessionManager.shared.clearSession()
            return true
        } catch {
            throw error
        }
    }
    
    
    @available(*, deprecated, message: "getSignForLogin() is no longer supported because the 'sign' parameter has been removed from the login process. To log in without a signature, please delete the Auth Key in your Wepin Workspace (Development Tools > Login tab > Auth Key > Delete). The Auth Key menu is visible only if a key was previously generated. Refer to the latest developer guide for more information.")
    public func getSignForLogin(privateKey: String, message: String) throws {
        let message = "getSignForLogin() is no longer supported because the 'sign' parameter has been removed from the login process. To log in without a signature, please delete the Auth Key in your Wepin Workspace (Development Tools > Login tab > Auth Key > Delete). The Auth Key menu is visible only if a key was previously generated. Refer to the latest developer guide for more information."
        print(message)
        throw WepinError.deprecated(message)
    }
 }
