//
//  WEBARView.h
//  WebARSDK
//
//  Created by weily on 2019/10/10.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "WEBARCameraView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WEBARViewDelegate <NSObject>

/**
相机权限请求失败时的回调
*/
-(void)webARViewCameraAuthFailed;

@end

@interface WEBARView : UIView<WKScriptMessageHandler,WKNavigationDelegate, WKUIDelegate>

@property(nonatomic, weak) id <WEBARViewDelegate> delegate;

@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) WEBARCameraView *cameraView;

@property(nonatomic, weak) UIViewController *parentViewController;

/**
 在原有的userAgent后添加自定义agent
 */
@property(nonatomic, copy) NSString *customUserAgent;

/**
 加载url
*/
-(void)loadUrl:(NSURL *)url;

@end

@interface WEBARScriptMessageDelegate: NSObject<WKScriptMessageHandler>

@property(nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

-(instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

NS_ASSUME_NONNULL_END
