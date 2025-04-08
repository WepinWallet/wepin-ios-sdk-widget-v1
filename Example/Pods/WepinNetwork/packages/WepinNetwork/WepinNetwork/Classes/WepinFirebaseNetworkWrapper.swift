//import Foundation
//
//@objcMembers
//public class WepinFirebaseNetworkWrapper: NSObject {
//    private var network: WepinFirebaseNetwork?
//
//    @objc public static let shared = WepinFirebaseNetworkWrapper()
//
//    @objc public func initialize(firebaseKey: String) {
//        self.network = WepinFirebaseNetwork(firebaseKey: firebaseKey)
//    }
//
//    @objc public func signInWithCustomToken(_ token: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let result = try await network.signInWithCustomToken(token)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func signInWithEmail(email: String, password: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let req = EmailAndPasswordRequest(email: email, password: password)
//                let result = try await network.signInWithEmailPassword(req)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getCurrentUser(idToken: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let req = GetCurrentUserRequest(idToken: idToken)
//                let result = try await network.getCurrentUser(req)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func getRefreshIdToken(refreshToken: String, grantType: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let req = GetRefreshIdTokenRequest(refreshToken: refreshToken, grantType: grantType)
//                let result = try await network.getRefreshIdToken(req)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func resetPassword(oobCode: String, newPassword: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let req = ResetPasswordRequest(oobCode: oobCode, newPassword: newPassword)
//                let result = try await network.resetPassword(req)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func verifyEmail(idToken: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let req = VerifyEmailRequest(idToken: idToken)
//                let result = try await network.verifyEmail(req)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func updatePassword(idToken: String, password: String, completion: @escaping (NSDictionary?, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(nil, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let result = try await network.updatePassword(idToken: idToken, password: password)
//                completion(result.toDictionary() as NSDictionary?, nil)
//            } catch {
//                completion(nil, error as NSError)
//            }
//        }
//    }
//
//    @objc public func logout(completion: @escaping (Bool, NSError?) -> Void) {
//        Task {
//            do {
//                guard let network = self.network else {
//                    completion(false, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network not initialized"]))
//                    return
//                }
//                let result = try await network.logout()
//                completion(result, nil)
//            } catch {
//                completion(false, error as NSError)
//            }
//        }
//    }
//}
//
//extension SignInWithCustomTokenSuccess {
//    func toDictionary() -> [String: Any] {
//        return [
//            "idToken": idToken,
//            "refreshToken": refreshToken,
//            "expiresIn": expiresIn
//        ]
//    }
//}
//
//extension SignInResponse {
//    func toDictionary() -> [String: Any] {
//        return [
//            "idToken": idToken,
//            "email": email,
//            "refreshToken": refreshToken,
//            "expiresIn": expiresIn,
//            "localId": localId,
//            "registered": registered
//        ]
//    }
//}
