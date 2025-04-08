#import "WepinCommonBridge.h"
#import <WepinCommon/WepinCommon-Swift.h>

@implementation WepinCommonBridge

+ (NSDictionary<NSString *, NSString *> *)getWepinSdkUrlWithAppKey:(NSString *)appKey error:(NSError **)error {
    NSError *swiftError = nil;
    NSDictionary<NSString *, NSString *> *result = [WepinCommon getWepinSdkUrlWithAppKey:appKey error:&swiftError];
    if (swiftError && error) {
        *error = swiftError;
    }
    return result;
}

+ (NSString *)getBalanceWithDecimal:(NSString *)balance decimals:(NSInteger)decimals {
    return [WepinCommon getBalanceWithDecimalWithBalance:balance decimals:decimals];
}

@end
