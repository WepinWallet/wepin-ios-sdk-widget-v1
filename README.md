<br/>

<p align="center">
  <a href="https://www.wepin.io/">
      <picture>
        <source media="(prefers-color-scheme: dark)">
        <img alt="wepin logo" src="https://github.com/WepinWallet/wepin-web-sdk-v1/blob/main/assets/wepin_logo_color.png?raw=true" width="250" height="auto">
      </picture>
</a>
</p>

<br>


# WepinWidget iOS SDK

[![platform - ios](https://img.shields.io/badge/platform-iOS-000.svg?logo=apple&style=for-the-badge)](https://developer.apple.com/ios/)

[![Version](https://img.shields.io/cocoapods/v/WepinWidget.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)
[![License](https://img.shields.io/cocoapods/l/WepinWidget.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)
[![Platform](https://img.shields.io/cocoapods/p/WepinWidget.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)

Wepin Widget SDK for iOS. This package is exclusively available for use in iOS environments.

## ⏩ Get App ID and Key

After signing up for [Wepin Workspace](https://workspace.wepin.io/), go to the **Development Tools** tab, register your platform, and obtain your `App ID` and `App Key`.

## ⏩ Requirements
- iOS 13+
- Swift 5.x
- Xcode 16+

## ⏩ Installation

### CocoaPods

Add the following line to your `Podfile`:

```ruby
pod 'WepinWidget'
```

Then run:

```bash
pod install
```


## ⏩ Getting Started

### Add URL Scheme (Info.plist)

To handle OAuth redirection, add a URL scheme in your `Info.plist`.

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>wepin.{YOUR_APP_ID}</string>
    </array>
  </dict>
</array>
```

## ⏩ Initialize

### Step 1. Create Params

```swift
let params = WepinWidgetParams(
  appId: "WEPIN_APP_ID",
  appKey: "WEPIN_APP_KEY",
  viewController: self
)
let wepinWidget = try WepinWidget(wepinWidgetParams: params)
```

### Step 2. Initialize SDK

```swift
let attributes = WepinWidgetAttribute(defaultLanguage: "en", defaultCurrency: "USD")
let result = try await wepinWidget.initialize(attributes: attributes)
```

The `isInitialized()` method checks Wepin Widget Library is initialized.

#### Returns
- \<Bool>
    - true if Wepin Widget Library is already initialized.

### getStatus
```swift
try await wepin.getStatus()
```

The getStatus() method returns the lifecycle status of Wepin Widget SDK.

#### Returns
- \<WepinLifeCycle>: Returns the current lifecycle of the Wepin SDK, which is defined as follows:
     - `notInitialized`:  Wepin is not initialized.
     - `initializing`: Wepin is in the process of initializing.
     - `initialized`: Wepin is initialized.
     - `beforeLogin`: Wepin is initialized but the user is not logged in.
     - `login`:The user is logged in.
     - `loginBeforeRegister`: The user is logged in but not registered in Wepin.

#### Example
```swift
    do {
        let statusResult = try await widget.getStatus()
        self.lifecycle = statusResult
        return lifecycle
    } catch {
        self.lifecycle = .notInitialized
        return lifecycle
    }
```


## ⏩ Method
Methods can be used after initialization of Wepin Widget Library.

### login

The login variable is a Wepin login library that includes various authentication methods, allowing users to log in using different approaches. It supports email and password login, OAuth provider login, login using ID tokens or access tokens, and more. For detailed information on each method, please refer to the official library documentation at [wepin_ios_login_lib](https://github.com/WepinWallet/wepin-ios-sdk-login-v1).

#### Available Methods
- `loginWithOauthProvider`
- `signUpWithEmailAndPassword`
- `loginWithEmailAndPassword`
- `loginWithIdToken`
- `loginWithAccessToken`
- `getRefreshFirebaseToken`
- `loginWepin`
- `getCurrentWepinUser`
- `logout`

These methods support various login scenarios, allowing you to select the appropriate method based on your needs.

For detailed usage instructions and examples for each method, please refer to the official library documentation. The documentation includes explanations of parameters, return values, exception handling, and more.

#### Example
// Login With OAuth Provider
```swift
do {
    let oauthParams = WepinLoginOauth2Params(provider: "discord", clientId: self.discordClientId)
    let res = try await wepin!.login.loginWithOauthProvider(params: oauthParams, viewController: self)
    let privateKey = "private key for wepin id/access Token"
        //call loginWithIdToken() or loginWithAccessToken()
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
```

// Sign up and log in using email and password
```swift
do {
    let email = "EMAIL-ADDRESS"
    let password = "PASSWORD"
    let params = WepinLoginWithEmailParams(email: email, password: password)
    wepinLoginRes = try await wepin!.login.signUpWithEmailAndPassword(params: params)
    self.tvResult.text = String("Successed: \(wepinLoginRes)")
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
```

// Log in using an ID token
```swift
do {
    let token = "ID-TOKEN"
    let params = WepinLoginOauthIdTokenRequest(idToken: token)
    wepinLoginRes = try await wepin!.login.loginWithIdToken(params: params)
        
    self.tvResult.text = String("Successed: \(wepinLoginRes)")
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
```

// Log in to Wepin
```swift
do {
    let res = try await wepin!.login.loginWepin(params: wepinLoginRes)
    wepinLoginRes = nil
    self.tvResult.text = String("Successed: \(res)")
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
```

// Get the currently logged-in user
```swift
do {
    let res = try await wepin!.login.getCurrentWepinUser()
    self.tvResult.text = String("Successed: \(res)")
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
  ```

// Logout
```swift
do {
    let res = try await wepin!.login.logoutWepin()
    self.tvResult.text = String("Successed: \(res)")
} catch (let error){
    self.tvResult.text = String("Faild: \(error)")
}
```


For more details on each method and to see usage examples, please visit the official  [wepin_ios_login_lib documentation](https://github.com/WepinWallet/wepin-ios-sdk-login-v1).


### loginWithUI
```swift
try await wepin.loginWithUI(viewController: vc, loginProviders: [...], email: "optional")
```

The loginWithUI() method provides the functionality to log in using a widget and returns the information of the logged-in user. If a user is already logged in, the widget will not be displayed, and the method will directly return the logged-in user's information. To perform a login without the widget, use the loginWepin() method from the login variable instead.

> [!CAUTION]
> This method can only be used after the authentication key has been deleted from the [Wepin Workspace](https://workspace.wepin.io/).
> (Wepin Workspace > Development Tools menu > Login tab > Auth Key > Delete)
> > * The Auth Key menu is visible only if an authentication key was previously generated.

#### Parameters
- `viewController` \<UIViewController> - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.
- `loginProviders` \<[LoginProviderInfo]>: An array of login providers to configure the widget. If an empty array is provided, only the email login function is available.
  - `provider` \<String> - The OAuth login provider (e.g., 'google', 'naver', 'discord', 'apple').
  - `clientId` \<String> - The client ID of the OAuth login provider.
- `email` \<String> - __optional__ The email parameter allows users to log in using the specified email address when logging in through the widget.

#### Returns
- \<WepinUser> - An object containing the user's login status and information. The object includes:
  - `status` \<'success'|'fail'>  - The login status.
  - `userInfo` \<WepinUserInfo> __optional__ - The user's information, including:
    - `userId` \<String> - The user's ID.
    - `email` \<String> - The user's email.
    - `provider` \<WepinLoginProviders> - 'google'|'apple'|'naver'|'discord'|'email'|'external_token'
    - `use2FA` \<Bool> - Whether the user uses two-factor authentication.
  - `walletId` \<String> __optional__ - The user's wallet ID.
  - `userStatus`: \<WepinUserStatus> __optional__ - The user's status of wepin login. including:
    - `loginStatus`: \<WepinLoginStatus> - 'complete' | 'pinRequired' | 'registerRequired' - If the user's loginStatus value is not complete, it must be registered in the wepin.
    - `pinRequired`: <Bool> __optional__ 
  - `token`: \<WepinToken> __optional__ - The user's token of wepin.
    - `refresh`: \<String>
    - `access` \<String>

#### Exception
- WepinError...

#### Example
```swift
    // Login Provider 정보
let providerInfos: [LoginProviderInfo] = [
    LoginProviderInfo(provider: "google", clientId: "GOOGLE_CLIENT_ID"),
    LoginProviderInfo(provider: "apple", clientId: "APPLE_CLIENT_ID"),
    LoginProviderInfo(provider: "discord", clientId: "DISCORD_CLIENT_ID"),
    LoginProviderInfo(provider: "naver", clientId: "NAVER_CLIENT_ID"),
    LoginProviderInfo(provider: "facebook", clientId: "FACEBOOK_CLIENT_ID"),
    LoginProviderInfo(provider: "line", clientId: "LINE_CLIENT_ID")
]
let user = try await widget.loginWithUI(viewController: self, loginProviders: self.providerInfos)
```

### openWidget
```swift
try await wepin.openWidget(viewController: vc)
```

The openWidget() method displays the Wepin widget. If a user is not logged in, the widget will not open. Therefore, you must log in to Wepin before using this method. To log in to Wepin, use the loginWithUI method or loginWepin method from the login variable.

#### Parameters
- `viewController` \<UIViewController> - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

#### Returns
- <Bool>: true if the widget is successfully opened.

#### Exception
- WepinError...

#### Example
```swift
do {
    let result = try await widget.openWidget(viewController: self)
    updateStatus(result ? "Widget Opened" : "Open Widget Failed")
} catch {
    updateStatus("Error: \(error.localizedDescription)")
}
```

### closeWidget
```swift
try wepin.closeWidget()
```

The closeWidget() method closes the Wepin widget.

#### Parameters
- Void

#### Returns 
- Void

#### Exception
- WepinError...

#### Example
```swift
try wepinWidget?.closeWidget()
```

### register
```swift
try await wepin.register(viewController: vc)
```

The register method registers the user with Wepin. After joining and logging in, this method opens the Register page of the Wepin widget, allowing the user to complete registration (wipe and account creation) for the Wepin service.

This method is only available if the lifecycle of the WepinSDK is WepinLifeCycle.loginBeforeRegister. After calling the loginWepin() method in the login variable, if the loginStatus value in the userStatus is not 'complete', this method must be called.

#### Parameters
- `viewController` \<UIViewController> - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.

#### Returns
- \<WepinUser> - An object containing the user's login status and information. The object includes:
  - `status` \<'success'|'fail'>  - The login status.
  - `userInfo` \<WepinUserInfo> __optional__ - The user's information, including:
    - `userId` \<String> - The user's ID.
    - `email` \<String> - The user's email.
    - `provider` \<WepinLoginProviders> - 'google'|'apple'|'naver'|'discord'|'email'|'external_token'
    - `use2FA` \<Bool> - Whether the user uses two-factor authentication.
  - `walletId` \<String> __optional__ - The user's wallet ID.
  - `userStatus`: \<WepinUserStatus> __optional__ - The user's status of wepin login. including:
    - `loginStatus`: \<WepinLoginStatus> - 'complete' | 'pinRequired' | 'registerRequired' - If the user's loginStatus value is not complete, it must be registered in the wepin.
    - `pinRequired`: <Bool> __optional__ 
  - `token`: \<WepinToken> __optional__ - The user's token of wepin.
    - `refresh`: \<String>
    - `access` \<String>

#### Exception
- WepinError...

#### Example
```swift
do {
    let result = try await widget.register(viewController: self)
    self.updateStatus("Registered: \(result)")
} catch {
    self.updateStatus("Error: \(error.localizedDescription)")
}
```

### getAccounts
```swift
try await wepin.getAccounts(networks: ["network1"], withEoa: true)
```

The getAccounts() method returns user accounts. It is recommended to use this method without arguments to retrieve all user accounts. It can only be used after widget login.

#### Parameters
- `networks` <[String]> __optional__ - A list of network names to filter the accounts.
- `withEoa` <Bool> __optional__ Whether to include EOA accounts if AA accounts are included.

#### Returns
- \<[WepinAccount]> - a list of the user's accounts.
  - `address` \<String> - account's address
  - `network` \<String> - account's network
  - `contract` \<String> __optional__ - The token contract address.
  - `isAA` \<Bool> __optional__ - Whether it is an AA account or not.

#### Exception
- WepinError...

#### Example
```swift
do {
    let accounts = try await widget.getAccounts()
    self.updateStatus("Accounts: \(accounts)")
} catch {
    self.updateStatus("Error: \(error.localizedDescription)")
}
```

### getBalance
```swift
try await wepin.getBalance(accounts: [...])
```

The getBalance() method returns the balance information for specified accounts. It can only be used after the widget is logged in. To get the balance information for all user accounts, use the getBalance() method without any arguments.

#### Parameters
- `accounts` \<[WepinAccount]> __optional__ - a list of the user's accounts.
  - `address` \<String> - account's address
  - `network` \<String> - account's network
  - `contract` \<String> __optional__ - The token contract address.
  - `isAA` \<Bool> __optional__ - Whether it is an AA account or not.

#### Returns
- \<[WepinAccountBalanceInfo]> - a list of balance information for the specified accounts.
  - `network` \<String> - The network associated with the account.
  - `address` \<String> - The address of the account.
  - `symbol` \<String> - The symbol of the account's balance.
  - `balance` \<String> - The balance of the account.
  - `tokens` \<List\<WepinTokenBalanceInfo>> - A list of token balance information for the account.
    - `symbol` \<String> - The symbol of the token.
    - `balance` \<String> - The balance of the token.
    - `contract` \<String> - The contract address of the token.

#### Exception
- WepinError...

#### Example
```swift
do {
    let balance = try await widget.getBalance()
    self.updateStatus("Balance: \(balance)")
} catch {
    self.updateStatus("Error: \(error.localizedDescription)")
}
```


### getNFTs
```swift
try await wepin.getNFTs(refresh: true, networks: ["network1"])
```

The getNFTs() method returns user NFTs. It is recommended to use this method without the networks argument to get all user NFTs. This method can only be used after the widget is logged in.

#### Parameters
- `refresh` \<Bool> - A required parameter to indicate whether to refresh the NFT data.
- `networks` \<[String]> __optional__ - A list of network names to filter the NFTs.

#### Returns
- \<[WepinNFT]> - a list of the user's NFTs.
  - `account` \<[WepinAccount]> - a list of the user's accounts.
    - `address` \<String> - account's address
    - `network` \<String> - account's network
    - `contract` \<String> __optional__ - The token contract address.
    - `isAA` \<Bool> __optional__ - Whether it is an AA account or not.
  - `contract` \<WepinNFTContract>
    - `name` \<String> - The name of the NFT contract.
    - `address` \<String> - The contract address of the NFT.
    - `scheme` \<String> - The scheme of the NFT.
    - `description` \<String> __optional__ - A description of the NFT contract.
    - `network` \<String> - The network associated with the NFT contract.
    - `externalLink` \<String> __optional__  - An external link associated with the NFT contract.
    - `imageUrl` \<String> __optional__ - An image URL associated with the NFT contract.
  - `name` \<String> - The name of the NFT.
  - `description` \<String> - A description of the NFT.
  - `externalLink` \<String> - An external link associated with the NFT.
  - `imageUrl` \<String> - An image URL associated with the NFT.
  - `contentUrl` \<String> __optional__ - A URL pointing to the content associated with the NFT.
  - `quantity` \<int> - The quantity of the NFT.
  - `contentType` \<String> - The content type of the NFT.
  - `state` \<int> - The state of the NFT.

#### Exception
- WepinError...

#### Example
```swift
do {
    let nfts = try await widget.getNFTs(refresh: false)
    self.updateStatus("NFTs: \(nfts)")
} catch {
    self.updateStatus("Error: \(error.localizedDescription)")
}
```

### send
```swift
try await wepin.send(viewController: vc, account: account, txData: txData)
```

The send() method sends a transaction and returns the transaction ID information. This method can only be used after the widget is logged in.

#### Parameters
- `viewController` \<UIViewController> - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.
- `account` \<[WepinAccount]> - a list of the user's accounts.
    - `address` \<String> - account's address
    - `network` \<String> - account's network
    - `contract` \<String> __optional__ - The token contract address.
    - `isAA` \<Bool> __optional__ - Whether it is an AA account or not.
- `txData` <WepinTxData> __optional__ - The transaction data to be sent.
    - `to` \<String> - The address to which the transaction is being sent.
    - `amount` \<String> - The amount of the transaction.

#### Returns
- <WepinSendResponse> - A response containing the transaction ID.
    - `txId` \<String> - The ID of the sent transaction.

#### Exception
- WepinError...

#### Example
```swift
do {
     let result = try await widget.send(viewController: self, account: account)
    updateStatus("Send success: \(result)")
} catch {
    updateStatus("Error: \(error.localizedDescription)")
}
```

### receive
```swift
try await wepin.receive(viewController: vc, account: account)
```

The receive method opens the account information page associated with the specified account. This method can only be used after logging into Wepin.

#### Parameters
- `viewController` \<UIViewController> - The view controller from which the login widget (WebView) will be presented modally. It provides the display context to ensure the widget appears on the correct screen.
- `account` \<[WepinAccount]> - a list of the user's accounts.
    - `address` \<String> - account's address
    - `network` \<String> - account's network
    - `contract` \<String> __optional__ - The token contract address.
    - `isAA` \<Bool> __optional__ - Whether it is an AA account or not.
#### Returns
- <WepinReceiveResponse> - A WepinReceiveResponse object containing the information about the opened account.
    - `network` \<String> - The network associated with the account.
    - `address` \<String> - The address to the account.
    - `contract` \<String> __optional__ The contract address of the token.

#### Exception
- WepinError...

#### Example
```swift
do {
    let result = try await widget.receive(viewController: self, account: account)
    updateStatus("Receive success: \(result)")
} catch {
    updateStatus("Error: \(error.localizedDescription)")
}
```

### finalize
```swift
try await wepin.finalize()
```

The finalize() method finalizes the Wepin SDK, releasing any resources or connections it has established.

#### Parameters
- Void

#### Returns
- <Bool> - The SDK  has been finalized.

#### Exception
- WepinError...

#### Example
```swift
do {
    let result = try await widget.finalize()
    self.updateStatus("Finalized: \(result)")
} catch {
    self.updateStatus("Error: \(error.localizedDescription)")
}
```
