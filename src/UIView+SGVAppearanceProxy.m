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

#pragma mark - Public

+ (instancetype)sgv_appearance {
    return [self sgv_proxiedAppearanceIfNeededForAppearance:[self appearance]];
}

+ (instancetype)sgv_appearanceWhenContainedIn:(__unsafe_unretained Class<UIAppearanceContainer>)class {
    return [self sgv_proxiedAppearanceIfNeededForAppearance:[self appearanceWhenContainedIn:class, nil]];
}

+ (instancetype)sgv_appearanceAppliedOnlyOnce {
    return (UIView *)[[SGVAppearanceProxy alloc] initWithOriginalProxy:[self appearance]
                                                              forClass:self
                                                   applyAppearanceOnce:YES];
}

#pragma mark - Private

+ (instancetype)sgv_proxiedAppearanceIfNeededForAppearance:(id)appearance {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return (UIView *)[[SGVAppearanceProxy alloc] initWithOriginalProxy:appearance
                                                                  forClass:self
                                                       applyAppearanceOnce:NO];
    }
    return appearance;
}

@end
