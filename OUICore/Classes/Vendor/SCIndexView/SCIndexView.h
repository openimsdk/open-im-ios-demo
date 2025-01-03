
#import <UIKit/UIKit.h>
#import "SCIndexViewConfiguration.h"

@class SCIndexView;

@protocol SCIndexViewDelegate <NSObject>

@optional

/**
 当点击或者滑动索引视图时，回调这个方法

 @param indexView 索引视图
 @param section   索引位置
 */
- (void)indexView:(SCIndexView *)indexView didSelectAtSection:(NSUInteger)section;

/**
 当滑动tableView时，索引位置改变，你需要自己返回索引位置时，实现此方法。
 不实现此方法，或者方法的返回值为 SCIndexViewInvalidSection 时，索引位置将由控件内部自己计算。

 @param indexView 索引视图
 @param tableView 列表视图
 @return          索引位置
 */
- (NSUInteger)sectionOfIndexView:(SCIndexView *)indexView tableViewDidScroll:(UITableView *)tableView;

@end

@interface SCIndexView : UIControl

@property (nonatomic, weak) id<SCIndexViewDelegate> delegate;

@property (nonatomic, copy) NSArray<NSString *> *dataSource;

@property (nonatomic, assign) NSInteger currentSection;

@property (nonatomic, assign) BOOL translucentForTableViewInNavigationBar;

@property (nonatomic, assign) NSUInteger startSection;

@property (nonatomic, strong, readonly) SCIndexViewConfiguration *configuration;

- (instancetype)initWithTableView:(UITableView *)tableView configuration:(SCIndexViewConfiguration *)configuration;

- (void)refreshCurrentSection;

@end
