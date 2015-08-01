//
//  Utils.h
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//


// DLog* methods
#ifdef DEBUG
#include <libgen.h>
#define DLog(format, ...) NSLog((@"[%s:%d %@] " format),basename(__FILE__),__LINE__,NSStringFromSelector(_cmd),##__VA_ARGS__)
#define DLogv(var) NSLog(@"[%s:%d %@] "# var "=%@",basename(__FILE__),__LINE__,NSStringFromSelector(_cmd), var )
#else
#define DLog(...) /* */
#define DLogv(var) /* */
#endif


// isEmpty method
#ifdef __OBJC__
static inline BOOL isEmpty(id thing)
{
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}
#endif


#define isPad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define isPhone() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)


#define AbstractMethod() @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] userInfo:nil]


#define UIColorFromRGB(rgbValue) [UIColor \
    colorWithRed: ((float)(((rgbValue) & 0xFF0000) >> 16)) / 255.0 \
    green: ((float)(((rgbValue) & 0xFF00) >> 8)) / 255.0 \
    blue: ((float)((rgbValue) & 0xFF)) / 255.0 alpha: 1.0]

#define UIColorFromRGBWithAlpha(rgbValue, a) [UIColor \
    colorWithRed: ((float)(((rgbValue) & 0xFF0000) >> 16)) / 255.0 \
    green: ((float)(((rgbValue) & 0xFF00) >> 8)) / 255.0 \
    blue: ((float)((rgbValue) & 0xFF)) / 255.0 alpha: (a)]


