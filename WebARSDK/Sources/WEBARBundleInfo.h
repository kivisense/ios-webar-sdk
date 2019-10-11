//
//  WEBARBundleInfo.h
//  WebARSDK
//
//  Created by weily on 2019/10/10.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WEBARBundleInfo : NSObject

+(instancetype)share;

@property(nonatomic, copy) NSDictionary *errorInfos;

- (NSError *)error:(NSInteger)code;
- (NSString *)L10n:(NSString *)info;

@end

NS_ASSUME_NONNULL_END
