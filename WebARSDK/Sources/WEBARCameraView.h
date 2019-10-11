//
//  WEBARCameraView.h
//  WebARSDK
//
//  Created by weily on 2018/11/6.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WEBARCameraView : UIView

@property(nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic, strong) AVCaptureDevice *captureDevice;
@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, copy) NSDictionary *errorInfos;

@property(nonatomic, assign) BOOL isConfigSession;

/**
 当前是否为前置摄像头，默认为NO
 */
@property(nonatomic, assign, readonly) BOOL isUsingFrontFacingCamera;

/**
 默认为关闭状态
 */
@property(nonatomic, assign, readonly) BOOL isOpenCamera;

/**
 初始化相机
*/
-(void)configSession;

/**
 重置session配置为默认状态，默认当进行页面跳转时，都会执行一次
 */
-(void)resetToNormal;

/**
 切换前后摄像头
 */
- (void)switchCamera;

/**
 根据ID切换摄像头

 @param uniqueId 摄像头ID
 */
-(NSError *)switchCameraTo:(NSString *)uniqueId;

/**
 打开默认或者之前关闭的摄像头
 */
-(void)openCamera;

/**
 关闭当前的摄像头
 */
-(void)closeCamera;

/**
 获取所有的摄像头ID

 @return 返回格式为 [{ id: 'front' }, { id: 'back' }, {id: 'other'}]
 */
-(NSArray *)uniqueOfDevices;

/**
 从视频帧中获取图片

 @param photoBlock image回调
 */
-(void)takePhoto:(void(^)(UIImage *image))photoBlock;


/**
 切换画面质量(如果支持，默认AVCaptureSessionPresetPhoto)

 @param preset AVCaptureSessionPreset
 */
-(void)changeSessionPreset:(AVCaptureSessionPreset)preset;

/**
 切换手电筒
 */
-(NSError *)switchTorch:(AVCaptureTorchMode)mode;

/**
 切换闪光灯
 */
-(NSError *)switchFlash:(AVCaptureFlashMode)mode;

/**
 聚焦
 */
-(NSError *)focus:(CGPoint)point;

/**
 自动聚焦(默认开启)
 */
-(NSError *)autoFocus;

@end

NS_ASSUME_NONNULL_END
