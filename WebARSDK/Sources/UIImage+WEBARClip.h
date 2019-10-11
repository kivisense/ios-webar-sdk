//
//  UIImage+WEBARClip.h
//  WebARSDK
//
//  Created by weily on 2018/11/21.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WEBARClip)

-(UIImage *)normalImage;

-(UIImage *)centerClipWith:(CGSize)size;

-(UIImage *)scaleTo:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
