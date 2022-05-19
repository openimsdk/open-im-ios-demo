
#import <Foundation/Foundation.h>

@interface WPFPinYinDataManager : NSObject

/** 添加解析的单个数据源,id标识符是为了防止重名 */
+ (void)addInitializeString:(NSString *)string identifer:(NSString *)identifier;

/** 获取已解析的数据源 */
+ (NSArray *)getInitializedDataSource;

@end
