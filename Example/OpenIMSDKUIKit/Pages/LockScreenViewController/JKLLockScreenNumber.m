//
//  JKLLockScreenNumber.m
//

#import "JKLLockScreenNumber.h"

static const CGFloat LSNContextSetLineWidth = 0.8f;

@implementation JKLLockScreenNumber

- (void)setHighlighted:(BOOL)highlighted {
    if (super.highlighted != highlighted) {
        super.highlighted = highlighted;
        
        [self setNeedsDisplay];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGFloat height = CGRectGetHeight(rect);
    CGRect  inset  = CGRectInset(CGRectMake(0, 0, height, height), 1, 1);

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIControlState state = [self state];

    CGContextSetLineWidth(context, LSNContextSetLineWidth);
    if (state == UIControlStateHighlighted) {
        CGColorRef fillColorRef = [UIColor systemGray2Color].CGColor;

        CGContextSetFillColorWithColor(context, fillColorRef);
        CGContextFillEllipseInRect (context, inset);
        CGContextFillPath(context);
    }
    else {
        CGColorRef fillColorRef = [UIColor grayColor].CGColor;
        CGContextSetFillColorWithColor(context, fillColorRef);
        CGContextFillEllipseInRect (context, inset);
        CGContextFillPath(context);
        
//        CGColorRef colorRef  = [self tintColor].CGColor;
//        CGContextSetStrokeColorWithColor(context, colorRef);
//        CGContextAddEllipseInRect(context, inset);
//        CGContextStrokePath(context);
    }
}

@end
