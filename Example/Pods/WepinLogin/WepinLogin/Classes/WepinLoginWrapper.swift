//
//  WepinLoginWrapper.swift
//  Pods
//
//  Created by iotrust on 3/24/25.
//

import Foundation
import WepinCommon

@objc public class WepinLoginWrapper: NSObject {
    private var login: WepinLogin?
    
//    public static let shared = WepinLoginWrapper()
    @objc public init(appId: String, appKey: String, sdkType: String = "ios") {
        super.init()
        let params = WepinLoginParams(appId: appId, appKey: appKey)
        self.login = WepinLogin(params, sdkType: sdkType)
    }
    
    @objc public func initialize(completion: @escaping (Bool, NSError?) -> Void) {
        Task {
            do {
                let result = try await self.login?.initialize()
                completion(result ?? false, nil)
            } catch {
                completion(false, error as NSError)
            }
        }
    }
    
    @objc public func isInitialize() -> Bool {
        return self.login?.isInitialized() ?? false
    }
    
    @objc public func finalizeLogin() {
        login?.finalize()
    }
    
    @objc public func loginWithOauthProviders(params: NSDictionary, viewController: UIViewController, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let provider = params["provider"] as? String,
              let clientId = params["clientId"] as? String else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters"]))
            return
        }
        
        Task {
            let loginWithOauthParams = WepinLoginOauth2Params(provider: provider, clientId: clientId)
            do {
                let result: WepinLoginOauthResult? = try await login?.loginWithOauthProvider(params: loginWithOauthParams, viewController: viewController)
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func signUpEmailAndPassword(params: NSDictionary, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let email = params["email"] as? String,
              let password = params["password"] as? String else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters"]))
            return
        }
        
        let locale: String?
        if let rawLocale = params["locale"] {
            locale = rawLocale is NSNull ? nil : rawLocale as? String
        } else {
            locale = nil
        }
        
        Task {
            let params = WepinLoginWithEmailParams(email: email, password: password, locale: locale)
            do {
                let result: WepinLoginResult? = try await login?.signUpWithEmailAndPassword(params: params)
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func loginWithEmailAndPassword(params: NSDictionary, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let email = params["email"] as? String,
              let password = params["password"] as? String,
              let locale = params["locale"] as? String? else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters"]))
            return
        }
        
        Task {
            let params = WepinLoginWithEmailParams(email: email, password: password, locale: locale)
            do {
                let result: WepinLoginResult? = try await login?.loginWithEmailAndPassword(params: params)
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func loginWithIdToken(params: NSDictionary, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let idToken = params["idToken"] as? String else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters - params: \(params)"]))
            return
        }
        
        Task {
            let params = WepinLoginOauthIdTokenRequest(idToken: idToken)
            do {
                let result: WepinLoginResult? = try await login?.loginWithIdToken(params: params)
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func loginWithAccessToken(params: NSDictionary, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let provider = params["provider"] as? String,
              let accessToken = params["idToken"] as? String else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters"]))
            return
        }
        
        Task {
            let params = WepinLoginOauthAccessTokenRequest(provider: provider, accessToken: accessToken)
            do {
                let result: WepinLoginResult? = try await login?.loginWithAccessToken(params: params)
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func getRefreshFirebaseToken(completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let result: WepinLoginResult? = try await login?.getRefreshFirebaseToken()
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func loginWepin(params: NSDictionary, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        guard let providerRaw = params["provider"] as? String,
              let provider = WepinLoginProviders(rawValue: providerRaw),
              let tokenDict = params["token"] as? NSDictionary,
              let token = WepinFBToken(dictionary: tokenDict) else {
            completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Parameters params: \(params)"]))
            return
        }
        
        Task {
            let params = WepinLoginResult(provider: provider, token: token)
            do {
                let result: WepinUser? = try await login?.loginWepin(params: params)
                completion(["wepinUser": result?.toDictionary() as Any] as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func getCurrentWepinUser(completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task {
            do {
                let result: WepinUser? = try await login?.getCurrentWepinUser()
                completion(result?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
    
    @objc public func logoutWepin(completion: @escaping (Bool, NSError?) -> Void) {
        Task {
            do {
                let result: Bool? = try await login?.logoutWepin()
                completion(result ?? false, nil)
            } catch {
                completion(false, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: error]))
            }
        }
    }
}

extension WepinLoginOauthResult {
    public func toDictionary() -> [String: Any] {
        return [
            "provider": provider,
            "token": token,
            "type": type.rawValue
        ]
    }
}

extension WepinFBToken {
    init?(dictionary: NSDictionary) {
        guard let idToken = dictionary["idToken"] as? String,
              let refreshToken = dictionary["refreshToken"] as? String else {
            return nil
        }
        self.idToken = idToken
        self.refreshToken = refreshToken
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "idToken": idToken,
            "refreshToken": refreshToken
        ]
    }
}

extension WepinLoginResult {
    func toDictionary() -> [String: Any] {
        return [
            "provider": provider.rawValue,
            "token": token.toDictionary()
        ]
    }
}
