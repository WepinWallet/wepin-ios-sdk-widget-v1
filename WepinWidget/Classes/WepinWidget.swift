import Foundation
import WepinNetwork
import UIKit
import WepinCommon
import WepinSession
import WepinLogin

public class WepinWidget {
    // MARK: - Properties
    private let platformType: String
    private var _isInitialized: Bool = false
    private let wepinWidgetManager: WepinWidgetManager
    private let wepinWidgetParams: WepinWidgetParams
    
    // 커스텀 getter: wepinWidgetManager.wepinLoginLib 값을 반환
    public var login: WepinLogin? {
        return wepinWidgetManager.wepinLoginLib
    }
    
    
    // MARK: - Initialization
    public init(wepinWidgetParams: WepinWidgetParams, platformType: String = "ios") throws {
        guard let _ = wepinWidgetParams.viewController else {
            throw WepinError.invalidParameter("ViewController is required")
        }
        guard !wepinWidgetParams.appId.isEmpty else {
            throw WepinError.invalidParameter("AppId is required")
        }
        guard !wepinWidgetParams.appKey.isEmpty else {
            throw WepinError.invalidParameter("AppKey is required")
        }
        
        self.wepinWidgetParams = wepinWidgetParams
        self.platformType = platformType
        self.wepinWidgetManager = WepinWidgetManager.shared
    }
    
    // MARK: - Public Methods
    public func initialize(attributes: WepinWidgetAttribute) async throws -> Bool {
        if _isInitialized {
            throw WepinError.alreadyInitialized
        }
        
        try await wepinWidgetManager.initialize(params: wepinWidgetParams, attributes: attributes, platformType: platformType)

        if !WepinNetwork.shared.isInitialized() {
            throw WepinError.networkNotInitialized
        }
        
        _ = await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle()
        
        do {
            _ = try await WepinNetwork.shared.getAppInfo()
            _isInitialized = true
            _ = try await getStatus()
        } catch {
            throw error
        }
        
        return _isInitialized
    }
    
    public func isInitialized() -> Bool {
        return _isInitialized
    }
    
    public func changeLanguage(_ language: String, currency: String? = nil) {
        wepinWidgetManager.wepinAttributes?.defaultLanguage = language
        if let currency = currency {
            wepinWidgetManager.wepinAttributes?.defaultCurrency = currency
        }
    }
    
    public func getStatus() async throws -> WepinLifeCycle {
        guard _isInitialized else {
            return .notInitialized
        }
        
        return await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle() ?? .notInitialized
    }
    
    public func openWidget(viewController: UIViewController) async throws -> Bool {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }
        
        let status = try await getStatus()
        
        if status != .login {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }
        
        wepinWidgetManager.wepinWebViewManager?.openWidget(viewController: viewController)
        return true
    }
    
    public func closeWidget() throws {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }
        
        wepinWidgetManager.wepinWebViewManager?.closeWidget()
    }
    
    public func finalize() async throws -> Bool {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }
        wepinWidgetManager.finalize()
        _isInitialized = false
        return true
    }
    
    public func loginWithUI(viewController: UIViewController, loginProviders: [LoginProviderInfo], email: String? = nil) async throws -> WepinUser {
        wepinWidgetManager.wepinWebViewManager?.resetResponseWepinUserDeferred()
        wepinWidgetManager.currentViewController = viewController
        
        guard _isInitialized else {
            throw WepinError.notInitialized
        }
        
        var status = try await getStatus()
        
        if status == .login {
            if let user = WepinSessionManager.shared.getWepinUser() {
                return user
            } else {
                throw WepinError.userNotFound
            }
        } else {
//            wepinWidgetManager.wepinSessionManager?.lifecycle = .beforeLogin
            wepinWidgetManager.setSpecifiedEmail(email ?? "")
            
            if !loginProviders.isEmpty {
                wepinWidgetManager.wepinAttributes?.loginProviders = loginProviders.map { $0.provider }
                wepinWidgetManager.loginProviderInfos = loginProviders
            } else {
                wepinWidgetManager.wepinAttributes?.loginProviders = []
                wepinWidgetManager.loginProviderInfos = []
            }
            
            wepinWidgetManager.wepinWebViewManager?.openWidget(viewController: viewController)
            
            let result = try await wepinWidgetManager.wepinWebViewManager?.getResponseWepinUserDeferred() ?? false
            
            if result {
                if let user = WepinSessionManager.shared.getWepinUser() {
                    status = try await getStatus()
                    try closeWidget()
                    return user
                } else {
                    try closeWidget()
                    throw WepinError.loginFailed
                }
            } else {
                try closeWidget()
                throw WepinError.loginFailed
            }
        }
    }

    // register
    public func register(viewController: UIViewController) async throws -> WepinUser {
        wepinWidgetManager.currentViewController = viewController

        guard _isInitialized else {
            throw WepinError.notInitialized
        }

        let status = try await getStatus()
        guard status == .loginBeforeRegister else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not loginBeforeRegister")
        }

        guard let userInfo = WepinSessionManager.shared.getWepinUser() else {
            throw WepinError.incorrectLifeCycle("The userInfo is null")
        }

        guard let userStatus = userInfo.userStatus else {
            throw WepinError.invalidLoginSession("UserStatus is missing")
        }

        if userStatus.loginStatus == WepinLoginStatus.registerRequired && userStatus.pinRequired != true {
            guard let userId = userInfo.userInfo?.userId,
                  let walletId = userInfo.walletId else {
                throw WepinError.invalidLoginSession("UserID of WalletID is missing")
            }

            // ✅ register → updateTermsAccepted → checkLoginStatusAndGetLifeCycle → return updated user
            _ = try await WepinNetwork.shared.register(
                request: RegisterRequest(
                    appId: wepinWidgetManager.appId,
                    userId: userId,
                    loginStatus: userStatus.loginStatus.rawValue,
                    walletId: walletId
                )
            )

            _ = try await WepinNetwork.shared.updateTermsAccepted(
                userId: userId,
                request: UpdateTermsAcceptedRequest(
                    termsAccepted: ITermsAccepted(termsOfService: true, privacyPolicy: true)
                )
            )

            _ = await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle()

            guard let updatedUser = WepinSessionManager.shared.getWepinUser() else {
                throw WepinError.failedRegister
            }

            return updatedUser
        } else {
            // ✅ registerRequired가 아니면 widget 통해 등록
            let parameter: [String: Any] = [
                "loginStatus": userStatus.loginStatus.rawValue,
                "pinRequired": userStatus.pinRequired ?? false
            ]

            let result = try await wepinWidgetManager.wepinWebViewManager?.openWidgetWithCommand(
                viewController: viewController,
                command: Command.CMD_REGISTER_WEPIN,
                parameter: parameter
            )

            _ = await WepinSessionManager.shared.checkLoginStatusAndGetLifeCycle()

            if let result = result,
               let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let body = json["body"] as? [String: Any],
               let state = body["state"] as? String, state == "SUCCESS" {

                guard let updatedUser = WepinSessionManager.shared.getWepinUser() else {
                    throw WepinError.failedRegister
                }

                return updatedUser
            } else {
                throw WepinError.failedRegister
            }
        }
    }
    // send
    public func send(viewController: UIViewController, account: WepinAccount, txData: WepinTxData? = nil) async throws -> WepinSendResponse {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }

        guard let status = try? await getStatus(), status == .login else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }

        guard let userInfo = WepinSessionManager.shared.getWepinUser(),
              let userId = userInfo.userInfo?.userId,
              let walletId = userInfo.walletId,
              let localeId = wepinWidgetManager.wepinAttributes?.defaultLanguage else {
            throw WepinError.invalidLoginSession("The userId or walletId is null")
        }

        let accountList = try await WepinNetwork.shared.getAccountList(
            request: GetAccountListRequest(walletId: walletId, userId: userId, locale: localeId)
        )

        let detailAccounts = self.filterAccountList(
            accounts: accountList.accounts,
            aaAccounts: accountList.aa_accounts ?? [],
            withEoa: true
        )

        if detailAccounts.isEmpty {
            throw WepinError.accountNotFound
        }

        var sendTxData = txData
        if let amount = sendTxData?.amount, !amount.isEmpty {
            let normalized = try normalizeAmount(amount)
            sendTxData?.amount = normalized
        }

        let paramAccount: [String: Any] = [
            "address": account.address,
            "network": account.network,
            "contract": account.contract ?? NSNull()
        ]

        let parameter: [String: Any] = [
            "account": paramAccount,
            "from": account.address,
            "to": sendTxData?.toAddress ?? "",
            "value": sendTxData?.amount ?? ""
        ]

        wepinWidgetManager.currentViewController = viewController
        let result = try await wepinWidgetManager.wepinWebViewManager?.openWidgetWithCommand(
            viewController: viewController,
            command: Command.CMD_SEND_TRANSACTION_WITHOUT_PROVIDER,
            parameter: parameter
        )

        if let result = result,
           let jsonData = result.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
           let body = json["body"] as? [String: Any],
           let txId = body["data"] as? String {
            return WepinSendResponse(txId: txId)
        } else {
            throw WepinError.failedSend
        }
    }
    // receive
    public func receive(viewController: UIViewController, account: WepinAccount) async throws -> WepinReceiveResponse {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }

        guard let status = try? await getStatus(), status == .login else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }

        guard let userInfo = WepinSessionManager.shared.getWepinUser(),
              let userId = userInfo.userInfo?.userId,
              let walletId = userInfo.walletId,
              let localeId = wepinWidgetManager.wepinAttributes?.defaultLanguage else {
            throw WepinError.invalidLoginSession("The userId or walletId is null")
        }

        let accountList = try await WepinNetwork.shared.getAccountList(
            request: GetAccountListRequest(walletId: walletId, userId: userId, locale: localeId)
        )

        let detailAccounts = self.filterAccountList(
            accounts: accountList.accounts,
            aaAccounts: accountList.aa_accounts ?? [],
            withEoa: true
        )

        if detailAccounts.isEmpty {
            throw WepinError.accountNotFound
        }

        let paramAccount: [String: Any] = [
            "address": account.address,
            "network": account.network,
            "contract": account.contract ?? NSNull()
        ]

        let parameter: [String: Any] = [
            "account": paramAccount
        ]

        wepinWidgetManager.currentViewController = viewController
        do {
            let result = try await wepinWidgetManager.wepinWebViewManager?.openWidgetWithCommand(
                viewController: viewController,
                command: Command.CMD_RECEIVE_ACCOUNT,
                parameter: parameter
            )

            if let result = result,
               let jsonData = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let body = json["body"] as? [String: Any],
               let state = body["state"] as? String,
               state == "SUCCESS" {
                return WepinReceiveResponse(account: account)
            } else if let jsonData = result?.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let body = json["body"] as? [String: Any],
                      let errorMsg = body["data"] as? String {
                throw WepinError.unknown(errorMsg)
            } else {
                throw WepinError.failedReceive
            }

        } catch {
            if case WepinError.userCanceled = error {
                // ✅ 유저가 취소한 경우에도 정상 응답 리턴
                return WepinReceiveResponse(account: account)
            } else {
                // ❌ 다른 에러는 그대로 throw
                throw error
            }
        }
    }
    
    // MARK: - Account Methods
    public func getAccounts(networks: [String]? = nil, withEoa: Bool = false) async throws -> [WepinAccount] {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }
        
        let status = try await getStatus()
        
        guard status == .login else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }
        
        guard let userInfo = WepinSessionManager.shared.getWepinUser(),
                  let userId = userInfo.userInfo?.userId,
                  let walletId = userInfo.walletId,
                  let localeId = wepinWidgetManager.wepinAttributes?.defaultLanguage else {
                throw WepinError.invalidLoginSession("Required user information is missing")
            }
            
        let request = GetAccountListRequest(walletId: walletId, userId: userId, locale: localeId)
        
        let accountList = try await WepinNetwork.shared.getAccountList(request: request)
        
//        if(accountList == nil) {
//            throw WepinError.accountNotFound
//        }
        
        let detailAccounts = self.filterAccountList(
            accounts: accountList.accounts,
            aaAccounts: accountList.aa_accounts ?? [],
            withEoa: withEoa
        )
        
        var accountInfo = WepinAccount.fromAppAccountList(detailAccounts)
        
        if let networks = networks {
            accountInfo = accountInfo.filter { networks.contains($0.network) }
        }
        
        return accountInfo
    }
    
    public func getBalance(accounts: [WepinAccount]? = nil) async throws -> [WepinAccountBalanceInfo] {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }

        let status = try await getStatus()
        guard status == .login else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }

        guard let userInfo = WepinSessionManager.shared.getWepinUser(),
              let userId = userInfo.userInfo?.userId,
              let walletId = userInfo.walletId,
              let localeId = wepinWidgetManager.wepinAttributes?.defaultLanguage else {
            throw WepinError.invalidLoginSession("The userId or walletId is null")
        }

        let accountList = try await WepinNetwork.shared.getAccountList(
            request: GetAccountListRequest(walletId: walletId, userId: userId, locale: localeId)
        )

        let detailAccounts = self.filterAccountList(
            accounts: accountList.accounts,
            aaAccounts: accountList.aa_accounts ?? [],
            withEoa: true
        )

        if detailAccounts.isEmpty {
            throw WepinError.accountNotFound
        }

        let isAllAccounts = accounts?.isEmpty ?? true
        let filteredAccounts = isAllAccounts ? detailAccounts : detailAccounts.filter { detail in
            return accounts?.contains(where: {
                $0.network == detail.network && $0.address == detail.address && detail.contract == nil
            }) ?? false
        }

        if filteredAccounts.isEmpty {
            throw WepinError.accountNotFound
        }

        // 병렬로 balance 가져오기
        var balanceInfos: [WepinAccountBalanceInfo] = []
        // 명확하게 Optional 타입 지정
        try await withThrowingTaskGroup(of: Optional<WepinAccountBalanceInfo>.self) { group in
            for account in filteredAccounts {
                group.addTask {
                    let balance = try await WepinNetwork.shared.getAccountBalance(accountId: account.accountId) //error 발생 시 nil Return
                    return self.filterAccountBalance(
                        detailAccounts: detailAccounts,
                        targetAccount: account,
                        balance: balance
                    )
                }
            }

            for try await result in group {
                if let info = result {
                    balanceInfos.append(info)
                }
            }
        }

        if balanceInfos.isEmpty {
            throw WepinError.balancesNotFound
        }

        return balanceInfos
    }
    
    public func getNFTs(refresh: Bool, networks: [String]? = nil) async throws -> [WepinNFT] {
        guard _isInitialized else {
            throw WepinError.notInitialized
        }

        let status = try await getStatus()
        guard status == .login else {
            throw WepinError.incorrectLifeCycle("The LifeCycle is not login")
        }

        guard let userInfo = WepinSessionManager.shared.getWepinUser(),
              let userId = userInfo.userInfo?.userId,
              let walletId = userInfo.walletId,
              let localeId = wepinWidgetManager.wepinAttributes?.defaultLanguage else {
            throw WepinError.incorrectLifeCycle("The userId or walletId is null")
        }

        let accountList = try await WepinNetwork.shared.getAccountList(
            request: GetAccountListRequest(walletId: walletId, userId: userId, locale: localeId)
        )

        let detailAccounts = self.filterAccountList(
            accounts: accountList.accounts,
            aaAccounts: accountList.aa_accounts ?? [],
            withEoa: true
        )

        if detailAccounts.isEmpty {
            throw WepinError.accountNotFound
        }

        let nftRequest = GetNFTListRequest(walletId: walletId, userId: userId)

        let detailNFTList: GetNFTListResponse? = try await {
            if refresh {
                return try await WepinNetwork.shared.refreshNFTList(request: nftRequest)
            } else {
                return try await WepinNetwork.shared.getNFTList(request: nftRequest)
            }
        }()

        guard let nftList = detailNFTList?.nfts, !nftList.isEmpty else {
            return []
        }

        let allNetworks = networks?.isEmpty ?? true
        let availableAccounts = detailAccounts.filter {
            allNetworks || (networks?.contains($0.network) ?? false)
        }

        let filteredNFTs = nftList.compactMap { self.filterNft(nft: $0, availableAccounts: availableAccounts) }

        return filteredNFTs
    }
    
    // ... 나머지 메서드들도 동일한 패턴으로 구현 ...
}

// MARK: - Helper Extensions
extension WepinWidget {
    private func filterAccountList(
        accounts: [AppAccount],
        aaAccounts: [AppAccount],
        withEoa: Bool = false
    ) -> [AppAccount] {
        if aaAccounts.isEmpty {
            return accounts
        }

        if withEoa {
            return accounts + aaAccounts
        } else {
            return accounts.map { account in
                // 조건 분리로 컴파일러 부하 줄이기
                let matched = aaAccounts.first { aa in
                    let coinMatch = aa.coinId == account.coinId
                    let contractMatch = aa.contract == account.contract
                    let addressMatch = aa.eoaAddress == account.address
                    return coinMatch && contractMatch && addressMatch
                }
                return matched ?? account
            }
        }
    }
    
    private func filterAccountBalance(
        detailAccounts: [AppAccount],
        targetAccount: AppAccount,
        balance: GetAccountBalanceResponse
    ) -> WepinAccountBalanceInfo? {
        let accTokens = detailAccounts.filter {
            $0.accountId == targetAccount.accountId && $0.accountTokenId != nil
        }

        let findTokens: [WepinTokenBalanceInfo] = balance.tokens.compactMap { token -> WepinTokenBalanceInfo? in
            if accTokens.contains(where: { $0.contract == token.contract }) {
                return WepinTokenBalanceInfo(
                    contract: token.contract,
                    symbol: token.symbol,
                    balance: WepinCommon.getBalanceWithDecimal(balance: token.balance, decimals: token.decimals)
                )
            } else {
                return nil
            }
        }

        return WepinAccountBalanceInfo(
            network: targetAccount.network,
            address: targetAccount.address,
            symbol: targetAccount.symbol,
            balance: WepinCommon.getBalanceWithDecimal(balance: balance.balance, decimals: balance.decimals),
            tokens: findTokens
        )
    }
    
    private func filterNft(
        nft: AppNFT,
        availableAccounts: [AppAccount]
    ) -> WepinNFT? {
        guard let matchedAccount = availableAccounts.first(where: { $0.accountId == nft.accountId }) else {
            return nil
        }

        let contract = WepinNFTContract(
            name: nft.contract.name,
            address: nft.contract.address,
            scheme: NFTContract.schemeMapping[nft.contract.scheme] ?? nft.contract.scheme.description,
            description: nft.contract.description,
            network: nft.contract.network,
            externalLink: nft.contract.externalLink,
            imageUrl: nft.contract.imageUrl
        )

        return WepinNFT(
            account: WepinAccount.fromAppAccount(matchedAccount),
            contract: contract,
            name: nft.name,
            description: nft.description,
            externalLink: nft.externalLink,
            imageUrl: nft.imageUrl,
            contentUrl: nft.contentUrl,
            quantity: nft.quantity,
            contentType: AppNFT.contentTypeMapping[nft.contentType] ?? nft.contentType.description,
            state: nft.state
        )
    }
    
    private func normalizeAmount(_ amount: String) throws -> String {
        let pattern = #"^\d+(\.\d+)?$"#
        let regex = try NSRegularExpression(pattern: pattern)

        let range = NSRange(location: 0, length: amount.utf16.count)
        if regex.firstMatch(in: amount, options: [], range: range) != nil {
            return amount
        } else {
            throw WepinError.invalidParameter("Invalid amount format: \(amount)")
        }
    }
}
