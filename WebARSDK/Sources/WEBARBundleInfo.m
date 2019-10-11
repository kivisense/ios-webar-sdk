//
//  WEBARBundleInfo.m
//  WebARSDK
//
//  Created by weily on 2019/10/10.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import "WEBARBundleInfo.h"
#import "WEBARView.h"

#ifndef WebARSDKLocalizedString
#define WebARSDKLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"WEBARView", self.resourceBundle, comment)
#endif

@interface WEBARBundleInfo()

@property(nonatomic, strong) NSBundle *resourceBundle;

@end

@implementation WEBARBundleInfo

static WEBARBundleInfo *_instance = nil;

+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[WEBARBundleInfo alloc] init];
    });
    return _instance;
}

- (NSError *)error:(NSInteger)code{
    NSString *text = self.errorInfos[@(code)];
    NSDictionary *desc = @{NSLocalizedDescriptionKey: text};
    NSError *error = [NSError errorWithDomain:@"com.kivisense.WebARSDK" code:code userInfo:desc];
    return error;
}

-(NSString *)L10n:(NSString *)info {
    return WebARSDKLocalizedString(info, nil);
}

-(NSDictionary *)errorInfos {
    if(!_errorInfos){
        _errorInfos =@{
                       @2001: WebARSDKLocalizedString(@"Torch Not Supported",@"不支持手电筒"),
                       @2002: WebARSDKLocalizedString(@"Flash Not Supproted", @"不支持闪光灯"),
                       @2003: WebARSDKLocalizedString(@"Focus Not Supproted",@"不支持聚焦"),
                       @2004: WebARSDKLocalizedString(@"Didn't find the camera",@"未找到摄像头"),
                       @2006: WebARSDKLocalizedString(@"No Camera Permisson",@"没有相机权限"),
                       };
    }
    return _errorInfos;
}

-(NSBundle *)resourceBundle {
    if(!_resourceBundle){
        NSBundle *bundle = [NSBundle bundleForClass:WEBARView.class];
        NSString *resourcePath = [bundle pathForResource:@"WEBARView" ofType:@"bundle"];
        if (resourcePath){
            NSBundle *bundle2 = [NSBundle bundleWithPath:resourcePath];
            if (bundle2){
                bundle = bundle2;
            }
        }
        _resourceBundle = bundle;
    }
    return _resourceBundle;
}

@end
