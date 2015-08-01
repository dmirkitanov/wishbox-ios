//
//  StikeThroughLabel.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "StrikeThroughLabel.h"

@implementation StrikeThroughLabel

- (void)drawRect:(CGRect)rect {
    if (!isEmpty(self.text)) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetRGBStrokeColor(ctx, 107.0f/255.0f, 0.0f/255.0f, 0.0f/255.0f, 1.0f); // RGBA
        CGContextSetLineWidth(ctx, 1.0f);
        
        CGContextMoveToPoint(ctx, 0, self.bounds.size.height/2);
        CGContextAddLineToPoint(ctx, self.bounds.size.width, self.bounds.size.height/2);
        
        CGContextStrokePath(ctx);
    }
    
    [super drawRect:rect];
}

@end
