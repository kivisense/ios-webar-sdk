//
//  ARViewController.m
//  WebARSDK
//
//  Created by weily on 2019/10/10.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import "ARViewController.h"
#import "WebARSDK.h"

@interface ARViewController ()<WEBARViewDelegate>

@property (weak, nonatomic) IBOutlet WEBARView *webARView;

@end

@implementation ARViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _webARView.delegate = self;
    _webARView.parentViewController = self;
    
    if(_url.length > 0){
        [_webARView loadUrl:[NSURL URLWithString:_url]];
    }
}

-(BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WEBARViewDelegate

-(void)webARViewCameraAuthFailed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"WebAR功能需要打开摄像头，请转到系统设置中授予相机权限" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
