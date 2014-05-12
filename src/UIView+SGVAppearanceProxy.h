//
//  UIView+SGVAppearanceProxy.h
//  SGVAppearanceProxy
//
//  Created by Alexander Gusev on 12/05/14.
//  Copyright (c) 2014 sanekgusev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SGVAppearanceProxy)

+ (instancetype)sgv_appearance;
+ (instancetype)sgv_appearanceAppliedOnlyOnce;

@end
