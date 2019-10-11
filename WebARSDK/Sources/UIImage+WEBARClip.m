//
//  UIImage+WEBARClip.m
//  WebARSDK
//
//  Created by weily on 2018/11/21.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import "UIImage+WEBARClip.h"

@implementation UIImage (WEBARClip)

-(UIImage *)normalImage{
    CGSize normalSize = self.size;
    UIGraphicsBeginImageContext(normalSize);
    [self drawInRect:CGRectMake(0, 0, normalSize.width, normalSize.height)];
    UIImage* normalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalImage;
}

-(UIImage *)centerClipWith:(CGSize)size {
    
    if(size.width <= 0 || size.height <= 0){
        return self;
    }
    
    CGRect rect;
    if (self.size.width * size.height <= self.size.height * size.width) {
        CGFloat height = self.size.width * (size.height / size.width);
        CGFloat width  = height * (size.width / size.height);
        
        rect = CGRectMake(0, (self.size.height - height)/2, width, height);
    }else{
        CGFloat width  = self.size.height * (size.width / size.height);
        CGFloat height = width * (size.height / size.width);
        
        rect = CGRectMake((self.size.width - width)/2, 0, width, height);
    }
    
    CGImageRef sourceImageRef = [self CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    return newImage;
}

-(UIImage *)scaleTo:(CGSize)size {
    
    if(size.width <= 0 || size.height <= 0){
        return self;
    }
    
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

@end
