import Foundation
@_exported import WepinCommon
import WepinCore
import UIKit

public struct WepinWidgetParams {
    public let viewController: UIViewController?    //TODO: - 필요 없는 항목. 메이저 버전 업데이트 시 삭제.-
    public let appId: String
    public let appKey: String
    public let domain: String?
    public let environment: String?
    
    public init(viewController: UIViewController?, appId: String, appKey: String, domain: String? = nil, environment: String? = nil) {
        self.viewController = viewController
        self.appId = appId
        self.appKey = appKey
        self.domain = domain
        self.environment = environment
    }
}

//public struct WepinWidgetAttribute : Codable{
//    public var defaultLanguage: String
//    public var defaultCurrency: String
//    
//    public init(defaultLanguage: String = "en",
//                defaultCurrency: String = "USD") {
//        self.defaultLanguage = defaultLanguage
//        self.defaultCurrency = defaultCurrency
//    }
//}

public typealias WepinWidgetAttribute = WepinAttribute




//public enum WepinLifeCycle {
//    case notInitialized
//    case initializing
//    case initialized
//    case login
//    case beforeLogin
//    case loginBeforeRegister
//}

public struct WepinAccount {
    public let network: String
    public let address: String
    public let contract: String?
    public let isAA: Bool?
    
    public init(network: String, address: String, contract: String? = nil, isAA: Bool? = false) {
        self.network = network
        self.address = address
        self.contract = contract
        self.isAA = isAA
    }
    
    static func fromAppAccountList(_ accounts: [AppAccount]) -> [WepinAccount] {
        return accounts.map { fromAppAccount($0) }
    }
    
    public static func fromAppAccount(_ account: AppAccount) -> WepinAccount {
        if let contract = account.contract, account.accountTokenId != nil {
            return WepinAccount(
                network: account.network,
                address: account.address,
                contract: contract,
                isAA: account.isAA
            )
        } else {
            return WepinAccount(
                network: account.network,
                address: account.address,
                contract: nil,
                isAA: account.isAA
            )
        }
    }
}

public struct WepinTokenBalanceInfo {
    public let contract: String
    public let symbol: String
    public let balance: String
    
    init(contract: String, symbol: String, balance: String) {
        self.contract = contract
        self.symbol = symbol
        self.balance = balance
    }
}

public struct WepinAccountBalanceInfo {
    public let network: String
    public let address: String
    public let symbol: String
    public let balance: String
    public let tokens: [WepinTokenBalanceInfo]
    
    init(network: String, address: String, symbol: String, balance: String, tokens: [WepinTokenBalanceInfo]) {
        self.network = network
        self.address = address
        self.symbol = symbol
        self.balance = balance
        self.tokens = tokens
    }
}

public struct WepinNFT {
    public let account: WepinAccount
    public let contract: WepinNFTContract
    public let name: String
    public let description: String
    public let externalLink: String
    public let imageUrl: String
    public let contentUrl: String?
    public let quantity: Int?
    public let contentType: String
    public let state: Int
}

public struct WepinNFTContract {
    public let name: String
    public let address: String
    public let scheme: String
    public let description: String?
    public let network: String
    public let externalLink: String?
    public let imageUrl: String?
}

public struct WepinTxData {
    public let toAddress: String
    public var amount: String
    
    public init(toAddress: String, amount: String) {
        self.toAddress = toAddress
        self.amount = amount
    }
}

public struct WepinSendResponse {
    public let txId: String
}

public struct WepinReceiveResponse{
    public let account: WepinAccount
}


//struct AppAccount: Codable {
//    let network: String
//    let address: String
//    let chainId: Int
//    let isEoa: Bool?
//}

