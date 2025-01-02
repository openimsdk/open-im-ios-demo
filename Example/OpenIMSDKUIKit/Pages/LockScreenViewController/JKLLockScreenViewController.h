
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LockScreenMode) {
    LockScreenModeNormal = 0,       // [일반 모드]
    LockScreenModeNew,              // [신규 모드]
    LockScreenModeChange,           // [변경 모드]
    LockScreenModeVerification,     // [확인 모드]
};

@protocol JKLLockScreenViewControllerDelegate;
@protocol JKLLockScreenViewControllerDataSource;

@interface JKLLockScreenViewController : UIViewController

- (instancetype)initWithMode:(LockScreenMode)lockScreenMode;

@property (nonatomic, unsafe_unretained) LockScreenMode lockScreenMode;
@property (nonatomic, weak) id<JKLLockScreenViewControllerDelegate> delegate;
@property (nonatomic, weak) id<JKLLockScreenViewControllerDataSource> dataSource;

/**
 *  Tint color for the buttons
 */
@property (nonatomic, weak) UIColor *tintColor;

@end

@protocol JKLLockScreenViewControllerDelegate <NSObject>
@optional
- (void)unlockWasSuccessfulLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController pincode:(NSString *)pincode;    // support for number
- (void)unlockWasSuccessfulLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;                                // support for touch id
- (void)unlockWasCancelledLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
- (void)unlockWasFailureLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
@end

@protocol JKLLockScreenViewControllerDataSource <NSObject>
@required
- (BOOL)lockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController pincode:(NSString *)pincode;
@optional
- (BOOL)allowTouchIDLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
@end
