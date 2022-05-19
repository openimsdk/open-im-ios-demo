
#import <Foundation/Foundation.h>
#import "PinYin4Objc.h"

@class WPFPerson;

typedef NS_ENUM(NSUInteger, MatchType) {
    MatchTypeChinese,       MatchTypeComplate,      MatchTypeInitial,   };

@interface WPFSearchResultModel : NSObject



@property (nonatomic, assign) NSRange highlightedRange;


@property (nonatomic, assign) MatchType matchType;

@end

@interface WPFPinYinTools : NSObject



+ (BOOL)isChinese:(NSString *)string;


+ (BOOL)includeChinese:(NSString *)string;


+ (NSString *)firstCharactor:(NSString *)aString withFormat:(HanyuPinyinOutputFormat *)pinyinFormat;



+ (HanyuPinyinOutputFormat *)getOutputFormat;

+ (WPFSearchResultModel *)searchEffectiveResultWithSearchString:(NSString *)searchStrLower
                                                         Person:(WPFPerson *)person;


+ (NSArray *)sortingRules;

@end
