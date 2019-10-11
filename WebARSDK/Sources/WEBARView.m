//
//  WEBARView.m
//  WebARSDK
//
//  Created by weily on 2019/10/10.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import "WEBARView.h"
#import "UIImage+WEBARClip.h"
#import "WEBARBundleInfo.h"

static NSString *const kScriptMessage = @"__native_web_ar";

typedef  void (^ _Nullable JSCallBackBlock)(BOOL result, NSString *message, id data);

@interface WEBARView ()

@property (nonatomic, assign) BOOL isFirstWebLoad;
@property (nonatomic, assign) BOOL canUploadTakePhoto;

@property (nonatomic, assign) BOOL isCallAuthFailed;

@property (nonatomic, strong) NSMutableDictionary *callBackBlocks;

@end

@implementation WEBARView

- (void)dealloc {
    @try {
        [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    } @catch (NSException *exception) {
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    [self.webView setNavigationDelegate:nil];
    [self.webView setUIDelegate:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupViews];
}

- (void)setupViews {
    _isFirstWebLoad = YES;
    _canUploadTakePhoto = YES;

    _cameraView = [[WEBARCameraView alloc] initWithFrame:CGRectZero];
    [self insertSubview:_cameraView atIndex:0];

    [self configWebView];
    [self configProgressView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForegroundBack) name:UIApplicationWillEnterForegroundNotification object:nil];
}

// 进入程序时如果还没有相机权限则回调之前的callBack
-(void)applicationDidEnterForegroundBack{
    if(_isCallAuthFailed){
        if(self.delegate && [self.delegate respondsToSelector:@selector(webARViewCameraAuthFailed)]){
            [self.delegate webARViewCameraAuthFailed];
        }
        _isCallAuthFailed = NO;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat top = 0;
    
    if (@available(iOS 11.0, *)) {
        top += self.safeAreaInsets.top;
    }

    _cameraView.frame = self.bounds;
    _webView.frame = _cameraView.frame;
    _progressView.frame = CGRectMake(0, _webView.frame.origin.y + top, _webView.frame.size.width, 1);
}

- (void)configWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.mediaPlaybackRequiresUserAction = NO;
    config.allowsInlineMediaPlayback = YES;
    WEBARScriptMessageDelegate *delegate = [[WEBARScriptMessageDelegate alloc] initWithDelegate:self];
    [config.userContentController addScriptMessageHandler:delegate name:kScriptMessage];

    // 在原有的userAgent后添加信息
    // ios9以后可以单独为webView添加，但是在ios8及以下只能全局修改
    // https://stackoverflow.com/questions/26994491/set-useragent-in-wkwebview
    if (_customUserAgent.length == 0) {
        _customUserAgent = @"kivicube native webar/1.0";
    }else {
        _customUserAgent = [NSString stringWithFormat:@"%@;kivicube native webar/1.0", _customUserAgent];
    }

    NSString *userAgent = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *newUserAgent = [userAgent stringByAppendingString:_customUserAgent];
    if (@available(iOS 9.0, *)) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.customUserAgent = newUserAgent;
    } else {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    }

    _webView.scrollView.bounces = NO;
    _webView.opaque = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    [self insertSubview:_webView aboveSubview:_cameraView];
}

- (void)configProgressView {
    _progressView = [[UIProgressView alloc] init];
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.progressTintColor = [UIColor greenColor];
    _progressView.transform = CGAffineTransformScale(_progressView.transform, 1, 4);
    [self insertSubview:_progressView aboveSubview:_webView];
    [_webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)loadUrl:(NSURL *)url {
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - JS Call

- (void)callJS:(NSString *)method argument:(NSArray *)argument asyncCallback:(JSCallBackBlock)asyncCallback {
    NSString *callBackId = @"";
    if (asyncCallback != nil) {
        NSArray *keys = _callBackBlocks.allKeys;
        while (YES) {
            // 随机的callBackId
            int y = (arc4random() % 1001) + 2000;
            callBackId = [NSString stringWithFormat:@"%d", y];
            if (![keys containsObject:callBackId]) {
                _callBackBlocks[callBackId] = asyncCallback;
                break;
            }
        }
    }

    NSDictionary *dic = @{ @"method": method, @"arguments": argument ? : @[], @"callbackId": callBackId };
    NSString *json = [self convertToJsonData:dic];
    if (json.length > 0) {
        [_webView evaluateJavaScript:[NSString stringWithFormat:@"__WebAR.postMessage(%@)", json] completionHandler:nil];
    }
}

- (NSString *)convertToJsonData:(NSDictionary *)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;

    if (!jsonData) {
        NSLog(@"%@", error);
    } else {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = { 0, jsonString.length };
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];

    NSRange range2 = { 0, mutStr.length };
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];

    return mutStr;
}

#pragma mark - Observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView) {
        [self.progressView setAlpha:1.0f];
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];

        if (self.webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    /// 当跳转页面的时候，默认重置camera
    if (!_isFirstWebLoad) {
        [self.cameraView resetToNormal];
    } else {
        _isFirstWebLoad = NO;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    id info = message.body;

    if ([info isKindOfClass:[NSDictionary class]] && [name isEqualToString:kScriptMessage]) {
        NSDictionary *json = info;
        NSString *method = json[@"method"];
        NSArray *arguments = json[@"arguments"];
        NSString *callBackString = json[@"callbackId"];
        int callBackId = [callBackString intValue];

        if ([method isEqualToString:@"callback"]) {
            JSCallBackBlock block = _callBackBlocks[callBackString];
            if (block != nil && arguments.count == 3) {
                BOOL result = [arguments[1] boolValue];
                NSString *message;
                id data;
                if (result) {
                    message = @"";
                    data = arguments[2];
                } else {
                    message = [NSString stringWithFormat:@"%@", arguments[2]];
                    data = nil;
                }
                block(result, message, data);
                [_callBackBlocks removeObjectForKey:callBackString];
            }
            return;
        }

        if ([@[@"cameraDeviceList", @"openCamera", @"getFrame", @"closeCamera"] containsObject:method]) {
            if (!_cameraView.isConfigSession) {
                [_cameraView configSession];
            }
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   if (granted) {
                       id data;
                       if ([method isEqualToString:@"cameraDeviceList"]) { //获取摄像头设备列表
                           data = [self scriptForCameraDeviceList:arguments];
                       } else if ([method isEqualToString:@"openCamera"]) { //打开某个摄像头
                           data = [self scriptForOpenCamera:arguments];
                       } else if ([method isEqualToString:@"getFrame"]) { //拍照
                           [self scriptForGetFrame:arguments callBackId:callBackId];
                       } else if ([method isEqualToString:@"closeCamera"]) { //关闭相机
                           data = [self scriptForCloseCamera:arguments];
                       }
                       if ([data isKindOfClass:[NSError class]]) {
                           [self callBack:data callBackId:callBackId data:@"''"];
                       } else if ([data isKindOfClass:[NSString class]]) {
                           [self callBack:nil callBackId:callBackId data:data];
                       }
                   } else {
                       self.isCallAuthFailed = YES;
                       if(self.delegate && [self.delegate respondsToSelector:@selector(webARViewCameraAuthFailed)]){
                           [self.delegate webARViewCameraAuthFailed];
                       }
                   }
               });
            }];
        }
    }
}

- (id)scriptForCameraDeviceList:(NSArray *)arguments {
    NSMutableString *data = @"[".mutableCopy;
    NSArray *devices = _cameraView.uniqueOfDevices;
    for (NSDictionary *dic in devices) {
        NSMutableString *item = @"{".mutableCopy;
        for (NSString *key in dic.allKeys) {
            NSString *str = [NSString stringWithFormat:@"%@:'%@',", key, dic[key]];
            [item appendString:str];
        }
        // 干掉最后的一个,
        [item replaceCharactersInRange:NSMakeRange(item.length - 1, 1) withString:@""];
        [item appendString:@"},"];
        [data appendString:item];
    }
    // 干掉最后的一个,
    [data replaceCharactersInRange:NSMakeRange(data.length - 1, 1) withString:@""];
    [data appendString:@"]"];

    return data;
}

- (id)scriptForOpenCamera:(NSArray *)arguments {
    if (arguments.count != 2) {
        return [WEBARBundleInfo.share error:2005];
    } else {
        NSString *cameraId = arguments[0];
        NSString *preset = arguments[1];
        if (![@[@"high", @"medium", @"low"] containsObject:preset]) {
            return [WEBARBundleInfo.share error:2005];
        }
        NSError *error = [_cameraView switchCameraTo:cameraId];
        if (error == nil) {
            [self changePreset:preset];
            return @"''";
        } else {
            return error;
        }
    }
}

- (id)scriptForCloseCamera:(NSArray *)arguments {
    [_cameraView closeCamera];
    return @"''";
}

- (void)scriptForGetFrame:(NSArray *)arguments callBackId:(int)callBackId {
    CGFloat width = 0;
    CGFloat height = 0;
    if (arguments.count == 2) {
        width = [arguments[0] floatValue];
        height = [arguments[1] floatValue];
    } else if (arguments.count == 0) {
    } else {
        // 报错
        width = 1;
    }

    if (_canUploadTakePhoto) {
        __weak typeof(self) weakSelf = self;
        if ((width == 0 && height == 0) || (width > 0 && height > 0)) {
            _canUploadTakePhoto = NO;
            [_cameraView takePhoto:^(UIImage *_Nonnull image) {
                UIImage *re = [weakSelf centerClip:image size:CGSizeMake(width, height)];
                NSString *imageString = [weakSelf removeSpaceAndNewline:[UIImageJPEGRepresentation(re, 0.6) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
                NSString *data = [NSString stringWithFormat:@"{frame: '%@', width: %d, height: %d}", imageString, @(re.size.width).intValue, @(re.size.height).intValue];
                [weakSelf callBack:nil callBackId:callBackId data:data completionHandler:^{
                    weakSelf.canUploadTakePhoto = YES;
                }];
            }];
        } else {
            _canUploadTakePhoto = YES;
            [self callBack:[WEBARBundleInfo.share error:2005] callBackId:callBackId data:@"''"];
        }
    }
}

- (void)callBack:(NSError *)error callBackId:(int)callBackId data:(NSString *)data {
    [self callBack:error callBackId:callBackId data:data completionHandler:nil];
}

- (void)callBack:(NSError *)error callBackId:(int)callBackId data:(NSString *)data completionHandler:(void (^)(void))completionHandler {
    NSString *callBack;
    if (error) {
        callBack = [NSString stringWithFormat:@"__WebAR.callback(%d,false,'%@')", callBackId, error.localizedDescription];
    } else {
        callBack = [NSString stringWithFormat:@"__WebAR.callback(%d,true,%@)", callBackId, data];
    }
    [self.webView evaluateJavaScript:callBack completionHandler:^(id _Nullable re, NSError *_Nullable error) {
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (void)changePreset:(NSString *)preset {
    if ([preset isEqualToString:@"high"]) {
        [_cameraView changeSessionPreset:AVCaptureSessionPreset1280x720];
    } else if ([preset isEqualToString:@"medium"]) {
        [_cameraView changeSessionPreset:AVCaptureSessionPresetiFrame960x540];
    } else if ([preset isEqualToString:@"low"]) {
        [_cameraView changeSessionPreset:AVCaptureSessionPreset640x480];
    }
}

- (UIImage *)centerClip:(UIImage *)image size:(CGSize)size {
    if (size.width <= 0 || size.height <= 0 || !image) {
        return image;
    }

    UIImage *normalImage = [image normalImage];
    UIImage *newImage = [normalImage centerClipWith:size];
    UIImage *scaledImage = [newImage scaleTo:size];
    return scaledImage;
}

- (NSString *)removeSpaceAndNewline:(NSString *)str {
    NSString *temp = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return temp;
}

#pragma mark - WKUIDelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // Get host name of url.
    NSString *host = webView.URL.host;
    // Init the alert view controller.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:host ?: [WEBARBundleInfo.share L10n:@"message"] message:message preferredStyle:UIAlertControllerStyleAlert];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[WEBARBundleInfo.share L10n:@"confirm"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];

    // Add actions.
    [alert addAction:okAction];
    [_parentViewController presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:host ?: [WEBARBundleInfo.share L10n:@"message"] message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[WEBARBundleInfo.share L10n:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[WEBARBundleInfo.share L10n:@"confirm"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [_parentViewController presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *__nullable result))completionHandler {
    // Get the host of url.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:prompt ? : [WEBARBundleInfo.share L10n:@"message"] message:host preferredStyle:UIAlertControllerStyleAlert];
    // Add text field.
    [alert addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
        textField.placeholder = defaultText ? : [WEBARBundleInfo.share L10n:@"input"];
        textField.font = [UIFont systemFontOfSize:12];
    }];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[WEBARBundleInfo.share L10n:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(@"");
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[WEBARBundleInfo.share L10n:@"confirm"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string ? : defaultText);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [_parentViewController presentViewController:alert animated:YES completion:nil];
}

@end

@implementation WEBARScriptMessageDelegate

-(instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if(self){
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
