import Foundation
import UIKit
import WepinCommon
import WepinLogin

@objcMembers
public class WepinWidgetWrapper: NSObject {
    private var widget: WepinWidget?

    public static let shared = WepinWidgetWrapper()

    @objc public func initialize(params: NSDictionary, attributes: NSDictionary, completion: @escaping (Bool, NSError?) -> Void) {
        guard let appId = params["appId"] as? String,
              let appKey = params["appKey"] as? String,
              let viewController = params["viewController"] as? UIViewController else {
            completion(false, NSError(domain: "Wepin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid parameters"]))
            return
        }

        let wepinParams = WepinWidgetParams(viewController: viewController, appId: appId, appKey: appKey)
        let wepinAttributes = WepinWidgetAttribute.from(dictionary: attributes)

        Task {
            do {
                self.widget = try WepinWidget(wepinWidgetParams: wepinParams)
                let result = try await self.widget?.initialize(attributes: wepinAttributes)
                completion(result ?? false, nil)
            } catch {
                completion(false, error as NSError)
            }
        }
    }

    @objc public func isInitialized() -> Bool {
        return widget?.isInitialized() ?? false
    }

    @objc public func changeLanguage(language: String, currency: String?) {
        widget?.changeLanguage(language, currency: currency)
    }

    @objc public func getStatus(completion: @escaping (NSString?, NSError?) -> Void) {
        Task {
            do {
                let status = try await widget?.getStatus()
                completion(status?.rawValue as NSString?, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func openWidget(viewController: UIViewController, completion: @escaping (Bool, NSError?) -> Void) {
        Task {
            do {
                let result = try await widget?.openWidget(viewController: viewController)
                completion(result ?? false, nil)
            } catch {
                completion(false, error as NSError)
            }
        }
    }

    @objc public func closeWidget() {
        try? widget?.closeWidget()
    }

    @objc public func finalize(completion: @escaping (Bool, NSError?) -> Void) {
        Task {
            do {
                let result = try await widget?.finalize()
                completion(result ?? false, nil)
            } catch {
                completion(false, error as NSError)
            }
        }
    }

    @objc public func loginWithUI(viewController: UIViewController, email: String?, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task<Void, Never> {
            do {
                let user: WepinUser? = try await widget?.loginWithUI(viewController: viewController, loginProviders: [], email: email)
                completion(user?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func register(viewController: UIViewController, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task<Void, Never> {
            do {
                let user: WepinUser? = try await widget?.register(viewController: viewController)
                completion(user?.toDictionary() as NSDictionary?, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func send(viewController: UIViewController, accountWrapper: WepinAccountWrapper, txDataWrapper: WepinTxDataWrapper?, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task<Void, Never> {
            do {
                let result = try await widget?.send(viewController: viewController,
                                                    account: accountWrapper.account,
                                                    txData: txDataWrapper?.toWepinTxData())
                completion(result?.toDictionary()as NSDictionary?, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func receive(viewController: UIViewController, accountWrapper: WepinAccountWrapper, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        Task<Void, Never> {
            do {
                let result = try await widget?.receive(viewController: viewController,
                                                       account: accountWrapper.account)
                completion(result?.toDictionary()as NSDictionary?, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func getAccounts(networks: [String]?, withEoa: Bool, completion: @escaping ([NSDictionary]?, NSError?) -> Void) {
        Task {
            do {
                let result = try await widget?.getAccounts(networks: networks, withEoa: withEoa)
                let dictArray = result?.map { $0.toDictionary() as NSDictionary }
                completion(dictArray, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
    
    @objc public func getBalance(completion: @escaping ([NSDictionary]?, NSError?) -> Void) {
        Task {
            do {
                guard let result = try await widget?.getBalance() else {
                    completion([], nil)
                    return
                }
                let dictArray = result.map { $0.toDictionary() as NSDictionary }
                completion(dictArray, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc public func getNFTs(refresh: Bool, completion: @escaping ([NSDictionary]?, NSError?) -> Void) {
        Task {
            do {
                guard let result = try await widget?.getNFTs(refresh: refresh) else {
                    completion([], nil)
                    return
                }
                let dictArray = result.map { $0.toDictionary() as NSDictionary }
                completion(dictArray, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
}

// MARK: - Dictionary Conversion Extensions

//extension WepinUser {
//    func toDictionary() -> [String: Any] {
//        var dict: [String: Any] = [
//            "status": status
//        ]
//        
//        if let userInfo = userInfo {
//            dict["userInfo"] = [
//                "userId": userInfo.userId,
//                "email": userInfo.email,
//                "provider": userInfo.provider,
//                "use2FA": userInfo.use2FA
//            ]
//        } else {
//            dict["userInfo"] = NSNull()
//        }
//        
//        dict["walletId"] = walletId ?? NSNull()
//        
//        if let userStatus = userStatus {
//            dict["userStatus"] = [
//                "loginStatus": userStatus.loginStatus,
//                "pinRequired": userStatus.pinRequired ?? false
//            ]
//        } else {
//            dict["userStatus"] = NSNull()
//        }
//        
//        if let token = token {
//            dict["token"] = [
//                "accessToken": token.accessToken,
//                "refreshToken": token.refreshToken
//            ]
//        } else {
//            dict["token"] = NSNull()
//        }
//        
//        return dict
//    }
//}

extension WepinAccount {
    func toDictionary() -> [String: Any] {
        return [
            "network": network,
            "address": address,
            "contract": contract ?? NSNull(),
            "isAA": isAA ?? false
        ]
    }
}

extension WepinWidgetAttribute {
    static func from(dictionary: NSDictionary) -> WepinWidgetAttribute {
        let language = dictionary["defaultLanguage"] as? String ?? "en"
        let currency = dictionary["defaultCurrency"] as? String ?? "USD"
        return WepinWidgetAttribute(defaultLanguage: language, defaultCurrency: currency)
    }
}

extension WepinAccountBalanceInfo {
    func toDictionary() -> [String: Any] {
        return [
            "network": network,
            "address": address,
            "symbol": symbol,
            "balance": balance,
            "tokens": tokens.map { $0.toDictionary() }
        ]
    }
}

extension WepinTokenBalanceInfo {
    func toDictionary() -> [String: Any] {
        return [
            "contract": contract,
            "symbol": symbol,
            "balance": balance
        ]
    }
}

extension WepinNFTContract {
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "address": address,
            "scheme": scheme,
            "network": network,
            "description": description ?? NSNull(),
            "externalLink": externalLink ?? NSNull(),
            "imageUrl": imageUrl ?? NSNull()
        ]
    }
}

extension WepinNFT {
    func toDictionary() -> [String: Any] {
        return [
            "account": account.toDictionary(),
            "contract": contract.toDictionary(),
            "name": name,
            "description": description,
            "externalLink": externalLink,
            "imageUrl": imageUrl,
            "contentUrl": contentUrl ?? "",
            "quantity": quantity ?? 0,
            "contentType": contentType,
            "state": state
        ]
    }
}


extension WepinSendResponse {
    func toDictionary() -> [String: Any] {
        return ["txId": txId]
    }
}

extension WepinReceiveResponse {
    func toDictionary() -> [String: Any] {
        return ["account": account.toDictionary()]
    }
}

@objcMembers
public class WepinAccountWrapper: NSObject {
    public let account: WepinAccount

    public init(network: String, address: String, contract: String? = nil, isAA: Bool? = nil) {
        self.account = WepinAccount(network: network, address: address, contract: contract, isAA: isAA)
    }

    public init(account: WepinAccount) {
        self.account = account
    }

    public func toDictionary() -> NSDictionary {
        return account.toDictionary() as NSDictionary
    }
}

@objcMembers
public class WepinTxDataWrapper: NSObject {
    public let toAddress: String
    public let amount: String

    public init(toAddress: String, amount: String) {
        self.toAddress = toAddress
        self.amount = amount
    }

    public func toWepinTxData() -> WepinTxData {
        return WepinTxData(toAddress: toAddress, amount: amount)
    }

    public func toDictionary() -> NSDictionary {
        return [
            "toAddress": toAddress,
            "amount": amount
        ]
    }
}
