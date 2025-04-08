#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WepinCommonBridge : NSObject

+ (NSDictionary<NSString *, NSString *> *)getWepinSdkUrlWithAppKey:(NSString *)appKey error:(NSError **)error;
+ (NSString *)getBalanceWithDecimal:(NSString *)balance decimals:(NSInteger)decimals;

@end

NS_ASSUME_NONNULL_END
