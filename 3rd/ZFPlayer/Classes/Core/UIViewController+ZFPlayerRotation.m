






















#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ZFLandscapeWindow.h"
#import "ZFLandscapeRotationManager.h"

API_AVAILABLE(ios(13.0)) @implementation UIViewController (ZFPlayerFixSafeArea)

- (void)zf_setContentOverlayInsets:(UIEdgeInsets)insets andLeftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin {
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    UIWindow *otherWindow = self.view.window;
    if ([keyWindow isKindOfClass:ZFLandscapeWindow.class] && otherWindow != nil) {
        ZFLandscapeRotationManager *manager = ((ZFLandscapeWindow *)keyWindow).rotationManager;
        UIWindow *superviewWindow = manager.containerView.window;
        if (superviewWindow != otherWindow) {
            [self zf_setContentOverlayInsets:insets andLeftMargin:leftMargin rightMargin:rightMargin];
        }
    } else {
        [self zf_setContentOverlayInsets:insets andLeftMargin:leftMargin rightMargin:rightMargin];
    }
}

@end

@implementation UITabBarController (ZFPlayerRotation)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(selectedIndex)
        };
        
        for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"zf_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            [self hookClass:self.class originalSelector:originalSelector swizzledSelector:swizzledSelector];
        }
        
        double systemVersion = [UIDevice currentDevice].systemVersion.doubleValue;
        if (systemVersion >= 13.0 && systemVersion < 16.0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

            NSData *data = [NSData.alloc initWithBase64EncodedString:@"X3NldENvbnRlbnRPdmVybGF5SW5zZXRzOmFuZExlZnRNYXJnaW46cmlnaHRNYXJnaW46" options:kNilOptions];
            NSString *method = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            SEL originalSelector = NSSelectorFromString(method);
#pragma clang diagnostic pop
            SEL swizzledSelector = @selector(zf_setContentOverlayInsets:andLeftMargin:rightMargin:);
            
            [self hookClass:UIViewController.class originalSelector:originalSelector swizzledSelector:swizzledSelector];
        }
    });
}

+ (void)hookClass:(Class)cls originalSelector:(SEL)orlSelector swizzledSelector:(SEL)swzdSelector {
    Method originalMethod = class_getInstanceMethod(cls, orlSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swzdSelector);
    if (class_addMethod(self, orlSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(self, swzdSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (NSInteger)zf_selectedIndex {
    NSInteger index = [self zf_selectedIndex];
    if (index > self.viewControllers.count) return 0;
    return index;
}

/**
 * If the root view of the window is a UINavigationController, you call this Category first, and then UIViewController called.
 * All you need to do is revisit the following three methods on a page that supports directions other than portrait.
 */

- (BOOL)shouldAutorotate {
    return [[self viewControllerRotation] shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[self viewControllerRotation] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self viewControllerRotation] preferredInterfaceOrientationForPresentation];
}

- (UIViewController *)viewControllerRotation {
    UIViewController *vc = self.viewControllers[self.selectedIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return nav.topViewController;
    } else {
        return vc;
    }
}


@end

@implementation UINavigationController (ZFPlayerRotation)

/**
 * If the root view of the window is a UINavigationController, you call this Category first, and then UIViewController called.
 * All you need to do is revisit the following three methods on a page that supports directions other than portrait.
 */

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

@end
