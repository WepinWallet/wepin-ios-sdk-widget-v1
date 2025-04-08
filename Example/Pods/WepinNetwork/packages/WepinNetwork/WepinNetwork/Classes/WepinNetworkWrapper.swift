////
////  WepinNetworkWrapper.swift
////  WepinNetwork
////
////  Created by iotrust on 2025.03.14
////
//
//import Foundation
//
//@objcMembers
//public class WepinNetworkWrapper: NSObject {
//    
//    private var network: WepinNetwork?
//    
//    public override init() {
//        super.init()
//    }
//
//    @objc public func initialize(appKey: String, domain: String, sdkType: String, version: String, error: NSErrorPointer) -> Bool {
//        do {
//            self.network = try WepinNetwork(appKey: appKey, domain: domain, sdkType: sdkType, version: version)
//            return true
//        } catch let err as NSError {
//            error?.pointee = err
//            return false
//        }
//    }
//
//    @objc public func setAuthToken(access: String, refresh: String) {
//        network?.setAuthToken(access: access, refresh: refresh)
//    }
//
//    @objc public func clearAuthToken() {
//        network?.clearAuthToken()
//    }
//
//    @objc public func getAppInfo(completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                if let info = try await network?.getAppInfo() as? [String: Any] {
//                    completion(info as NSDictionary, nil)
//                } else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid App Info"]))
//                }
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//    
//    @objc public func getOAuthProviderInfo(completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let result = try await network?.getOAuthProviderInfo()
//                completion(result?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//    
//    @objc public func getRegex(completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let result = try await network?.getRegex()
//                completion(result?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getFirebaseConfig(completion: @escaping (String?, NSError?) -> Void) {
//        Task {
//            do {
//                let config = try await network?.getFirebaseConfig()
//                completion(config, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func logout(userId: String, completion: @escaping (Bool, NSError?) -> Void) {
//        Task {
//            do {
//                _ = try await network?.logout(userId: userId)
//                completion(true, nil)
//            } catch {
//                completion(false, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getAccessToken(userId: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                if let res = try await network?.getAccessToken(userId: userId) {
//                    completion(res.toDictionary() as? NSDictionary, nil)
//                } else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
//                }
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func checkEmailExist(email: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let result = try await network?.checkEmailExist(email: email)
//                completion(result?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getLoginStatus(userId: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let result = try await network?.getLoginStatus(userId: userId)
//                completion(result?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getAccountList(userId: String, walletId: String, locale: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let request = GetAccountListRequest(walletId: walletId, userId: userId, locale: locale)
//                let response = try await network?.getAccountList(request: request)
//                completion(response?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getAccountBalance(accountId: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let res = try await network?.getAccountBalance(accountId: accountId)
//                completion(res?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getNFTList(userId: String, walletId: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let req = GetNFTListRequest(walletId: walletId, userId: userId)
//                let res = try await network?.getNFTList(request: req)
//                completion(res?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func refreshNFTList(userId: String, walletId: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                let req = GetNFTListRequest(walletId: walletId, userId: userId)
//                let res = try await network?.refreshNFTList(request: req)
//                completion(res?.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//}
