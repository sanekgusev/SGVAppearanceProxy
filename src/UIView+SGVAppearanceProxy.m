//
//  UIView+SGVAppearanceProxy.m
//  SGVAppearanceProxy
//
//  Created by Alexander Gusev on 12/05/14.
//  Copyright (c) 2014 sanekgusev. All rights reserved.
//

#import "UIView+SGVAppearanceProxy.h"
#import "SGVAppearanceProxy.h"

@implementation UIView (SGVAppearanceProxy)

+ (instancetype)sgv_appearance {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return (UIView *)[[SGVAppearanceProxy alloc] initWithOriginalProxy:[self appearance]
                                                                  forClass:self
                                                       applyAppearanceOnce:NO];
    }
    return [self appearance];
}

+ (instancetype)sgv_appearanceAppliedOnlyOnce {
    return (UIView *)[[SGVAppearanceProxy alloc] initWithOriginalProxy:[self appearance]
                                                              forClass:self
                                                   applyAppearanceOnce:YES];
}

@end
