//
//  UIViewController+JSBaseViewController.m
//  JSMethodSwizzlingDemo
//
//  Created by jason on 15/9/23.
//  Copyright (c) 2015年 jason. All rights reserved.
//

#import "UIViewController+JSBaseViewController.h"
#import <objc/runtime.h>

#import "TmpViewController.h"

@implementation UIViewController (JSBaseViewController)

+(void)load
{
#if !JSMethodSwizzlingDemoUseAspectsFromCocoaPods
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(JSBaseViewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
#endif
}

-(void)JSBaseViewWillAppear:(BOOL)animated
{
    [self JSBaseViewWillAppear:animated];
    NSLog(@"viewWillAppear: %@", self);
    if ([self isKindOfClass:[TmpViewController class]]) {
        NSLog(@"Now will goto TmpViewController");
    }
}

@end
