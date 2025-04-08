import Foundation

@objc public enum WepinKeyType: Int {
    case DEV
    case STAGE
    case PROD

    public static func fromAppKey(_ appKey: String) -> WepinKeyType? {
        if appKey.hasPrefix("ak_dev_") {
            return .DEV
        } else if appKey.hasPrefix("ak_stage_") {
            return .STAGE
        } else if appKey.hasPrefix("ak_prod_") {
            return .PROD
        }
        return nil
    }
}

@objcMembers
public class WepinCommon: NSObject {

    @objc
    public static func getWepinSdkUrl(appKey: String) throws -> [String: String] {
        guard let keyType = WepinKeyType.fromAppKey(appKey) else {
            throw WepinError.invalidAppKey
        }

        switch keyType {
        case .DEV:
            return [
                "wepinWebview": "https://dev-v1-widget.wepin.io/",
                "sdkBackend": "https://dev-sdk.wepin.io/v1/",
                "wallet": "https://dev-app.wepin.io/"
            ]
        case .STAGE:
            return [
                "wepinWebview": "https://stage-v1-widget.wepin.io/",
                "sdkBackend": "https://stage-sdk.wepin.io/v1/",
                "wallet": "https://stage-app.wepin.io/"
            ]
        case .PROD:
            return [
                "wepinWebview": "https://v1-widget.wepin.io/",
                "sdkBackend": "https://sdk.wepin.io/v1/",
                "wallet": "https://app.wepin.io/"
            ]
        }
    }

    @objc 
    public static func getBalanceWithDecimal(balance: String, decimals: Int) -> String {
        guard decimals > 0, !balance.isEmpty, let parsed = Decimal(string: balance) else {
            return "0"
        }

        var balanceValue = parsed  // 👉 inout 처리를 위해 var
        var divisor = pow10(decimals)

        var wholePart = Decimal()
        NSDecimalDivide(&wholePart, &balanceValue, &divisor, .plain)

        // 소수부 계산
        let remainder = balanceValue - (wholePart * divisor)

        let wholeString = NSDecimalNumber(decimal: wholePart).stringValue

        guard remainder != 0 else {
            return wholeString
        }

        let fractionalString = NSDecimalNumber(decimal: remainder).stringValue
        var trimmedFraction = ""

        if let dotIndex = fractionalString.firstIndex(of: ".") {
            let fractionalOnly = fractionalString[fractionalString.index(after: dotIndex)...]
            let padded = fractionalOnly.padding(toLength: decimals, withPad: "0", startingAt: 0)
            trimmedFraction = String(padded.reversed().drop(while: { $0 == "0" }).reversed())
        }

        return trimmedFraction.isEmpty ? wholeString : "\(wholeString).\(trimmedFraction)"
    }

    private static func pow10(_ exponent: Int) -> Decimal {
        var result = Decimal(1)
        for _ in 0..<exponent {
            result *= 10
        }
        return result
    }
}
