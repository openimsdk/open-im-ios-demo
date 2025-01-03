
#import <UIKit/UIKit.h>
#import "SCIndexViewConfiguration.h"

@protocol SCTableViewSectionIndexDelegate

/**
 当点击或者滑动索引视图时，回调这个方法
 
 @param tableView 列表视图
 @param section   索引位置
 */
- (void)tableView:(UITableView *)tableView didSelectIndexViewAtSection:(NSUInteger)section;

/**
 当滑动tableView时，索引位置改变，你需要自己返回索引位置时，实现此方法。
 不实现此方法，或者方法的返回值为 SCIndexViewInvalidSection 时，索引位置将由控件内部自己计算。
 
 @param tableView 列表视图
 @return          索引位置
 */
- (NSUInteger)sectionOfTableViewDidScroll:(UITableView *)tableView;

@end

@interface UITableView (SCIndexView)

@property (nonatomic, weak) id<SCTableViewSectionIndexDelegate> sc_indexViewDelegate;

@property (nonatomic, copy) NSArray<NSString *> *sc_indexViewDataSource;

@property (nonatomic, assign) BOOL sc_translucentForTableViewInNavigationBar;

@property (nonatomic, assign) NSUInteger sc_startSection;

@property (nonatomic, strong) SCIndexViewConfiguration *sc_indexViewConfiguration;

- (void)sc_refreshCurrentSectionOfIndexView;

@end
