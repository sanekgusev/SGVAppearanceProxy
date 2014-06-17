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
        SGVRetainInvocationArgumentsIfNeeded(invocation);
#       pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_originalProxy performSelector:uniqueSelector withObject:invocation];
#       pragma clang diagnostic pop
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
    [SGVCopyInvocationIfNeeded(originalInvocation) invokeWithTarget:self];
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
    [SGVCopyInvocationIfNeeded(originalInvocation) invokeWithTarget:self];
}

#pragma mark - Private

- (BOOL)addCustomSetterMethodToClass:(Class)class withSelector:(SEL)selector {
    return class_addMethod(class,
                           selector,
                           (IMP)(_appliesAppearanceOnce ? SGVAppearanceProxyCustomSetterOnlyOnceIMP :
                                 SGVAppearanceProxyCustomSetterIMP),
                           CustomSetterTypeEncoding);
}

static NSInvocation *SGVCopyInvocation(NSInvocation *invocation) {
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInvocation *copiedInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [copiedInvocation setTarget:[invocation target]];
    [copiedInvocation setSelector:[invocation selector]];

    for (NSUInteger i = 2; i < [methodSignature numberOfArguments]; i++) {
        const char *objcType = [methodSignature getArgumentTypeAtIndex:i];
        NSUInteger argumentSize;
        NSGetSizeAndAlignment(objcType, &argumentSize, NULL);
        uint8_t argumentData[argumentSize];
        [invocation getArgument:argumentData atIndex:i];
        [copiedInvocation setArgument:argumentData atIndex:i];
    }

    return copiedInvocation;
}

static NSInvocation *SGVCopyInvocationIfNeeded(NSInvocation *invocation) {
    if ([invocation argumentsRetained]) {
        invocation = SGVCopyInvocation(invocation);
    }
    return invocation;
}

static BOOL SGVInvocationContainsObjectArguments(NSInvocation *invocation) {
    NSMethodSignature *methodSignature = [invocation methodSignature];
    for (NSUInteger i = 2; i < [methodSignature numberOfArguments]; i++) {
        const char *objcType = [methodSignature getArgumentTypeAtIndex:i];
        if (strcmp(objcType, @encode(id)) == 0) {
            return YES;
        }
    }
    return NO;
}

static void SGVRetainInvocationArgumentsIfNeeded(NSInvocation *invocation) {
    if (SGVInvocationContainsObjectArguments(invocation)) {
        [invocation retainArguments];
    }
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

@end
