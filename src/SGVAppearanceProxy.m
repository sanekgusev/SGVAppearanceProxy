//
//  SGVAppearanceProxy.m
//  SGVAppearanceProxy
//
//  Created by Alexander Gusev on 12/05/14.
//  Copyright (c) 2014 sanekgusev. All rights reserved.
//

#import "SGVAppearanceProxy.h"
#import <objc/runtime.h>

static const void *kAlreadyInvokedKey = &kAlreadyInvokedKey;
static char *CustomSetterTypeEncoding;

@interface SGVAppearanceProxy() {
    id _originalProxy;
    __unsafe_unretained Class _class;
}

@end

@implementation SGVAppearanceProxy

#pragma mark - Init/dealloc

- (id)initWithOriginalProxy:(id)originalProxy
                   forClass:(__unsafe_unretained Class<UIAppearance>)class
        applyAppearanceOnce:(BOOL)applyOnce {
    NSCParameterAssert(originalProxy);
    BOOL isUIViewSubclass = [(id)class isSubclassOfClass:[UIView class]];
    NSCAssert(isUIViewSubclass, @"class should be a suclass of UIView");
    if (!originalProxy || !isUIViewSubclass) {
        return nil;
    }
    _originalProxy = originalProxy;
    _class = class;
    _appliesAppearanceOnce = applyOnce;
    SGVGenerateTypeEncodingString();
    return self;
}

#pragma mark - Forwarding

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL uniqueSelector = SGVGeneratedUniqueSelectorForCustomSetter();
    if ([self addCustomSetterMethodToClass:_class withSelector:uniqueSelector]) {
        [invocation retainArguments];
        [SGVCustomSetterInvocationForInvocationAndUniqueSelector(invocation, uniqueSelector)
         invokeWithTarget:_originalProxy];
    }
    else {
        NSCAssert(NO, @"new method should be added successfully");
        [invocation invokeWithTarget:_originalProxy];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_originalProxy methodSignatureForSelector:sel];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (_appliesAppearanceOnce) {
        return nil;
    }
    NSMethodSignature *methodSignature = [_originalProxy methodSignatureForSelector:aSelector];
    if (!methodSignature) {
        return nil;
    }
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    if (numberOfArguments > 3 ||
        (numberOfArguments > 2 && strcmp([methodSignature getArgumentTypeAtIndex:2], @encode(id)) != 0)) {
        return nil;
    }
    return _originalProxy;
}

#pragma mark - Setter Functions

static void SGVAppearanceProxyCustomSetterOnlyOnceIMP(id self,
                                                      SEL _cmd,
                                                      NSInvocation *originalInvocation) {
    NSMutableSet *alreadyInvokedInvocations = objc_getAssociatedObject(self,
                                                                       kAlreadyInvokedKey);
    if ([alreadyInvokedInvocations containsObject:originalInvocation]) {
        return;
    }
    [originalInvocation invokeWithTarget:self];
    originalInvocation.target = nil;
    if (!alreadyInvokedInvocations) {
        alreadyInvokedInvocations = [NSMutableSet new];
    }
    [alreadyInvokedInvocations addObject:originalInvocation];
    objc_setAssociatedObject(self,
                             kAlreadyInvokedKey,
                             alreadyInvokedInvocations,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void SGVAppearanceProxyCustomSetterIMP(id self,
                                              SEL _cmd,
                                              NSInvocation *originalInvocation) {
    [originalInvocation invokeWithTarget:self];
    originalInvocation.target = nil;
}

#pragma mark - Private

- (BOOL)addCustomSetterMethodToClass:(Class)class withSelector:(SEL)selector {
    return class_addMethod(class,
                           selector,
                           (IMP)(_appliesAppearanceOnce ? SGVAppearanceProxyCustomSetterOnlyOnceIMP :
                                 SGVAppearanceProxyCustomSetterIMP),
                           CustomSetterTypeEncoding);
}

static void SGVGenerateTypeEncodingString() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *customSetterTypeEncodingString = [[NSString alloc] initWithFormat:@"%s%s%s%s",
                                                    @encode(void), @encode(id), @encode(SEL), @encode(id)];
        const char *UTF8String = [customSetterTypeEncodingString UTF8String];
        size_t length = strlen(UTF8String);
        CustomSetterTypeEncoding = malloc(length + 1);
        CustomSetterTypeEncoding = strncpy(CustomSetterTypeEncoding,
                                           UTF8String,
                                           length + 1);
    });
}

static SEL SGVGeneratedUniqueSelectorForCustomSetter() {
    char selectorStr[41];
    snprintf(selectorStr, sizeof(selectorStr),
             "set%s:",
             [[[NSUUID UUID] UUIDString] UTF8String]);
    return sel_registerName(selectorStr);
}

static NSInvocation *SGVCustomSetterInvocationForInvocationAndUniqueSelector(NSInvocation *invocation,
                                                                             SEL selector) {
    static NSMethodSignature *MethodSignature = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MethodSignature = [NSMethodSignature signatureWithObjCTypes:CustomSetterTypeEncoding];
        NSCAssert([MethodSignature numberOfArguments] == 3, @"number of arguments should be 3");
    });
    NSInvocation *customSetterInvocation = [NSInvocation invocationWithMethodSignature:MethodSignature];
    [customSetterInvocation setSelector:selector];

    [customSetterInvocation setArgument:&invocation atIndex:2];
    [customSetterInvocation retainArguments];

    return customSetterInvocation;
}

@end
