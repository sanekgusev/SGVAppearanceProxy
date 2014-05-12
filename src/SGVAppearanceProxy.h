//
//  SGVAppearanceProxy.h
//  SGVAppearanceProxy
//
//  Created by Alexander Gusev on 12/05/14.
//  Copyright (c) 2014 sanekgusev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGVAppearanceProxy : NSProxy
@property (nonatomic, readonly) BOOL appliesAppearanceOnce;

- (id)initWithOriginalProxy:(id)originalProxy
                   forClass:(__unsafe_unretained Class<UIAppearance>)class
        applyAppearanceOnce:(BOOL)applyOnce;

@end
