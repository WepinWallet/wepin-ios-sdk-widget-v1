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


# WepinLogin iOS SDK

[![platform - ios](https://img.shields.io/badge/platform-iOS-000.svg?logo=apple&style=for-the-badge)](https://developer.apple.com/ios/)

[![Version](https://img.shields.io/cocoapods/v/WepinLogin.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)
[![License](https://img.shields.io/cocoapods/l/WepinLogin.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)
[![Platform](https://img.shields.io/cocoapods/p/WepinLogin.svg?style=for-the-badge)](https://cocoapods.org/pods/WepinLogin)

Wepin Login Library for iOS. This package is exclusively available for use in iOS environments.

## ⏩ Get App ID and Key
After signing up for [Wepin Workspace](https://workspace.wepin.io/), go to the development tools menu and enter the information for each app platform to receive your App ID and App Key.

## ⏩ Requirements
- iOS 13+
- Swift 5.x
- Xcode 16+

## ⏩ Installation

> ⚠️ Important Notice for v1.1.0 Update
>
> 🚨 Breaking Changes & Migration Guide 🚨
>
> This update includes major changes that may impact your app. Please read the following carefully before updating.
>
> 🔄 Storage Migration
> •    In rare cases, stored data may become inaccessible due to key changes.
> •    Starting from v1.0.0, if the key is invalid, stored data will be cleared, and a new key will be generated automatically.
> •    Existing data will remain accessible unless a key issue is detected, in which case a reset will occur.
> •    ⚠️ Downgrading to an older version after updating to v1.0.0 may prevent access to previously stored data.
> •    Recommended: Backup your data before updating to avoid any potential issues.
> 🔄 getSignForLogin deprecated
> • Starting from v1.1.0, getSignForLogin() is no longer supported because the 'sign' parameter has been removed from the login process. 
> • To log in without a signature, please delete the Auth Key in your Wepin Workspace (Development Tools > Login tab > Auth Key > Delete). The Auth Key menu is visible only if a key was previously generated. Refer to the latest developer guide for more information.

WepinLogin is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WepinLogin'
```

> ⚠️ **Notice** - Resolution for Build Errors 
>
> When building the WepinLogin library, the following error may occur:
> 
> ```SDK does not contain 'libarclite' at the path '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/arc/libarclite_iphonesimulator.a'; try increasing the minimum deployment target```
>
> This error can be resolved by changing the "Minimum Deployment Target" setting of the secp256k1 library.
> Please update the "Minimum Deployment Target" setting of the secp256k1 library project to an iOS version supported by Xcode.
> This should resolve the build error you are encountering.


## ⏩ Getting Started
### Import WepinLogin into your project.
```swift
import WepinLogin
```

###  Setting Info.plist
You must add the app's URL scheme to the Info.plist file. This is necessary for redirection back to the app after the authentication process.

The value of the URL scheme should be `'wepin.' + your Wepin app id`.

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <string>Editor</string>
  			<key>CFBundleURLName</key>
  			<string>unique name</string>
        <array>
            <string>wepin + your Wepin app id</string>
        </array>
    </dict>
</array>
```

## ⏩ Initialization
Before using the created instance, initialize it using the App ID and App Key.

  ```swift
let appKey: String = "Wepin-App-Key"
let appId: String = "Wepin-App-ID"
var wepin: WepinLogin? = nil
let initParam = WepinLoginParams(appId: appId, appKey: appKey)
wepin = WepinLogin(initParam)
 // Call initialize function
  do{
      let res = try await wepin!.initialize()
      self.tvResult.text = String("Successed: " + String(res!))
  } catch (let error){
      self.tvResult.text = String("Faild: \(error)")
  }
  ```

### isInitialized
```swift
let result = wepin!.isInitialized()
```
The `isInitialized()` method checks Wepin Login Library is initialized.

#### Returns
- \<Bool>
    - true if Wepin Login Library is already initialized.

## ⏩ Method
Methods can be used after initialization of Wepin Login Library.

### loginWithOauthProvider
```swift
await wepin!.loginWithOauthProvider(params)
```
An in-app browser will open and proceed to log in to the OAuth provider. To retrieve Firebase login information, you need to execute either the loginWithIdToken() or loginWithAccessToken() method. 

#### Parameters
- `params` \<WepinLoginOauth2Params> 
  - `provider` \<'google'|'naver'|'discord'|'apple'> - Provider for login
  - `clientId` \<String>
- `viewController` \<UIViewController>
#### Returns
- \<WepinLoginOauthResult>
  - `provider` \<String> - login provider
  - `token` \<String> - accessToken (if provider is "naver" or "discord") or idToken (if provider is "google" or "apple")
  - `type` \<WepinOauthTokenType> - type of token

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let oauthParams = WepinLoginOauth2Params(provider: "discord", clientId: self.discordClientId)
        let res = try await wepin!.loginWithOauthProvider(params: oauthParams, viewController: self)
        let privateKey = "private key for wepin id/access Token"
        //call loginWithIdToken() or loginWithAccessToken()
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### signUpWithEmailAndPassword
```swift
await wepin!.signUpWithEmailAndPassword(params: params)
```

This function signs up on Wepin Firebase with your email and password. It returns Firebase login information upon successful signup.

#### Parameters
- `params` \<WepinLoginWithEmailParams> 
  - `email` \<String> - User email
  - `password` \<String> -  User password
  - `locale` \<String> - __optional__ Language for the verification email (default value: "en")

#### Returns
- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - wepin firebase idToken
    - `refreshToken` <String> - wepin firebase refreshToken

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let email = "EMAIL-ADDRESS"
        let password = "PASSWORD"
        let params = WepinLoginWithEmailParams(email: email, password: password)
        wepinLoginRes = try await wepin!.signUpWithEmailAndPassword(params: params)
        self.tvResult.text = String("Successed: \(wepinLoginRes)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### loginWithEmailAndPassword
```swift
await wepin!.loginWithEmailAndPassword(params: params)
```

This function logs in to the Wepin Firebase using your email and password. It returns Firebase login information upon successful login.

#### Parameters
- `params` \<WepinLoginWithEmailParams> 
  - `email` \<String> - User email
  - `password` \<String> -  User password

#### Returns
- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - wepin firebase idToken
    - `refreshToken` `<String> - wepin firebase refreshToken

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let email = "EMAIL-ADDRESS"
        let password = "PASSWORD"
        let params = WepinLoginWithEmailParams(email: email, password: password)
        wepinLoginRes = try await wepin!.loginWithEmailAndPassword(params: params)
        self.tvResult.text = String("Successed: \(wepinLoginRes)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### loginWithIdToken
```swift
await wepin!.loginWithIdToken(params: params)
```

This function logs in to the Wepin Firebase using an external ID token. It returns Firebase login information upon successful login.

#### Parameters
- `params` \<WepinLoginOauthIdTokenRequest> 
  - `idToken` \<String> - ID token value to be used for login
  
> [!NOTE]
> Starting from WepinLogin version 1.1.0, the sign value is removed.
>
> Please remove the authentication key issued from the [Wepin Workspace](https://workspace.wepin.io/). 
>
> (Wepin Workspace > Development Tools menu > Login tab > Auth Key > Delete)
> > The Auth Key menu is visible only if an authentication key was previously generated.

#### Returns
- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - wepin firebase idToken
    - `refreshToken` `<String> - wepin firebase refreshToken

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let token = "ID-TOKEN"
        let params = WepinLoginOauthIdTokenRequest(idToken: token)
        wepinLoginRes = try await wepin!.loginWithIdToken(params: params)
        
        self.tvResult.text = String("Successed: \(wepinLoginRes)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### loginWithAccessToken
```swift
await wepin!.loginWithAccessToken(params: params)
```

This function logs in to the Wepin Firebase using an external access token. It returns Firebase login information upon successful login.

#### Parameters
- `params` \<WepinLoginOauthAccessTokenRequest> 
  - `provider` \<"naver"|"discord"> - Provider that issued the access token
  - `accessToken` \<String> - Access token value to be used for login

> [!NOTE]
> Starting from WepinLogin version 1.1.0, the sign value is removed.
>
> Please remove the authentication key issued from the [Wepin Workspace](https://workspace.wepin.io/). 
>
> (Wepin Workspace > Development Tools menu > Login tab > Auth Key > Delete)
> > The Auth Key menu is visible only if an authentication key was previously generated.

#### Returns
- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - wepin firebase idToken
    - `refreshToken` `<String> - wepin firebase refreshToken


#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let token = "ACCESS-TOKEN"
        let params = WepinLoginOauthAccessTokenRequest(provider: "discord", accessToken: token)
        wepinLoginRes = try await wepin!.loginWithAccessToken(params: params)
        self.tvResult.text = String("Successed: \(wepinLoginRes)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### getRefreshFirebaseToken
```swift
await wepin!.getRefreshFirebaseToken()
```

This method retrieves the current firebase token's information from the Wepin.

#### Parameters
- void

#### Returns
- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - wepin firebase idToken
    - `refreshToken` `<String> - wepin firebase refreshToken


#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let res = try await wepin!.getRefreshFirebaseToken()
        wepinLoginRes = res
        self.tvResult.text = String("Successed: \(res)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### loginWepin
```swift
await wepin!.loginWepin(params: wepinLoginRes)
```

This method logs the user into the Wepin application using the specified provider and token.

#### Parameters
The parameters should utilize the return values from the `loginWithEmailAndPassword()`, `loginWithIdToken()`, and `loginWithAccessToken()` methods within this module.

- \<WepinLoginResult>
  - `provider` \<WepinLoginProviders>
  - `token` \<WepinFBToken>
    - `idToken` \<String> - Wepin Firebase idToken
    - `refreshToken` `<String> - Wepin Firebase refreshToken

#### Returns
- \<WepinUser> - An object containing the user's login status and information. The object includes:
  - status \<'success'|'fail'>  - The login status.
  - userInfo \<WepinUserInfo> __optional__ - The user's information, including:
    - userId \<String> - The user's ID.
    - email \<String> - The user's email.
    - provider \<WepinLoginProviders> - 'google'|'apple'|'naver'|'discord'|'email'|'external_token'
    - use2FA \<Bool> - Whether the user uses two-factor authentication.
  - walletId \<String> __optional__ - The user's wallet ID.
  - userStatus: \<WepinUserStatus> __optional__ - The user's status of wepin login. including:
    - loginStatus: \<WepinLoginStatus> - 'complete' | 'pinRequired' | 'registerRequired' - If the user's loginStatus value is not complete, it must be registered in the wepin.
    - pinRequired: <Bool> __optional__ 
  - token: \<WepinToken> __optional__ - The user's token of wepin.
    - refresh: \<String>
    - access \<String>

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let res = try await wepin!.loginWepin(params: wepinLoginRes)
        wepinLoginRes = nil
        self.tvResult.text = String("Successed: \(res)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### getCurrentWepinUser
```swift
await wepin!.getCurrentWepinUser()
```

This method retrieves the current logged-in user's information from the Wepin.

#### Parameters
- void

#### Returns
- \<WepinUser> - An object containing the user's login status and information. The object includes:
  - status \<'success'|'fail'>  - The login status.
  - userInfo \<WepinUserInfo> __optional__ - The user's information, including:
    - userId \<String> - The user's ID.
    - email \<String> - The user's email.
    - provider \<WepinLoginProviders> - 'google'|'apple'|'naver'|'discord'|'email'|'external_token'
    - use2FA \<Bool> - Whether the user uses two-factor authentication.
  - walletId \<String> __optional__ - The user's wallet ID.
  - userStatus: \<WepinUserStatus> __optional__ - The user's status of wepin login. including:
    - loginStatus: \<WepinLoginStatus> - 'complete' | 'pinRequired' | 'registerRequired' - If the user's loginStatus value is not complete, it must be registered in the wepin.
    - pinRequired: <Bool> __optional__ 
  - token: \<WepinToken> __optional__ - The user's token of wepin.
    - refresh: \<String>
    - access \<String>

#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example

```swift
    do {
        let res = try await wepin!.getCurrentWepinUser()
        self.tvResult.text = String("Successed: \(res)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
  ```

### logoutWepin
```swift
await wepin!.logoutWepin()
```

The `logoutWepin()` method logs out the user logged into Wepin.

#### Parameters
 - void
#### Returns
- \<Bool>
  
#### Exception
- [Wepin Login Error](#WepinLoginError)

#### Example
```swift
    do {
        let res = try await wepin!.logoutWepin()
        self.tvResult.text = String("Successed: \(res)")
    } catch (let error){
        self.tvResult.text = String("Faild: \(error)")
    }
```

### getSignForLogin
> [!NOTE]
> Starting from WepinLogin version 1.1.0, getSignForLogin method no longer supported.

### finalize
```swift
wepin!.finalize()
```

The `finalize()` method finalizes the Wepin Login Library.

#### Parameters
 - void
#### Returns
 - void

#### Example
```swift
wepin!.finalize()
```

## ⏩ Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### WepinLoginError
| Error                        | Error Description                  |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `invalidParameters`        | One or more parameters provided are invalid or missing.                                             |
| `notInitialized`              | The WepinLoginLibrary has not been properly initialized.                                                                           |
| `invalidAppKey`            | The Wepin app key is invalid.                                                                       |
| `invalidLoginProvider`     | The login provider specified is not supported or is invalid.                                        |
| `invalidToken`              | The token does not exist.                                                                           |
| `invalidLoginSession`              | The login session information does not exist.                                                                           |
| `userCancelled`             | The user has cancelled the operation.                                                               |
| `unkonwError(message: String)`              | An unknown error has occurred, and the cause is not identified.                                     |
| `notConnectedInternet`     | The system is unable to detect an active internet connection.                                       |
| `failedLogin`               | The login attempt has failed due to incorrect credentials or other issues.                          |
| `alreadyLogout`             | The user is already logged out, so the logout operation cannot be performed again.                  |
| `alreadyInitialized`             | The WepinLoginLibrary is already initialized, so the logout operation cannot be performed again.                  |
| `invalidEmailDomain`       | The provided email address's domain is not allowed or recognized by the system.                     |
| `failedSendEmail`          | The system encountered an error while sending an email. This is because the email address is invalid or we sent verification emails too often. Please change your email or try again after 1 minute.                   |
| `requiredEmailVerified`    | Email verification is required to proceed with the requested operation.                             |
| `incorrectEmailForm`       | The provided email address does not match the expected format.                                      |
| `incorrectPasswordForm`    | The provided password does not meet the required format or criteria.                                |
| `notInitializedNetwork`    | The network or connection required for the operation has not been properly initialized.             |
| `requiredSignupEmail`      | The user needs to sign up with an email address to proceed.                                         |
| `failedEmailVerified`      | The WepinLoginLibrary encountered an issue while attempting to verify the provided email address.   |
| `failedPasswordStateSetting`      | The WepinLoginLibrary failed to set state of the password.  |
| `failedPasswordSetting`    | The WepinLoginLibrary failed to set the password.                                                   |
| `existedEmail`              | The provided email address is already registered in Wepin.                                          |

