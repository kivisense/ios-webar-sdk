//
//  WEBARCameraView.m
//  WebARSDK
//
//  Created by weily on 2018/11/6.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import "WEBARCameraView.h"
#import "WEBARBundleInfo.h"

@interface WEBARCameraView()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, assign, readwrite) BOOL isUsingFrontFacingCamera;
@property(nonatomic, assign, readwrite) BOOL isOpenCamera;
@property(nonatomic, assign) BOOL isReset;

@property(nonatomic, assign) BOOL isTakingPhoto;

@property(nonatomic, copy) void(^photoBlock)(UIImage *);

@end

@implementation WEBARCameraView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        [self commonInit];
    }
    return self;
}

-(void)commonInit {
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.backgroundColor = [UIColor clearColor];
}

-(void)configSession {
    if(_session){
        [_session stopRunning];
        _session = nil;
    }
    
    _session = [[AVCaptureSession alloc] init];
    /// 画面质量
    if([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        _session.sessionPreset = AVCaptureSessionPreset1280x720;
    }

    _captureDevice = [self backCamera];
    [self switchFlash:AVCaptureFlashModeOff];
    _isUsingFrontFacingCamera = NO;
    NSError *error;
    if([_captureDevice lockForConfiguration:&error]) {
        /// 自动对焦
        [self autoFocus];
        [_captureDevice unlockForConfiguration];
    }
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    if([self.session canAddInput:deviceInput]){
        [self.session addInput:deviceInput];
    }
    
    if([self.session canAddOutput:self.videoDataOutput]){
        [self.session addOutput:self.videoDataOutput];
    }
    
    self.layer.masksToBounds = YES;
    
    if(_previewLayer){
        [_previewLayer removeFromSuperlayer];
    }
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.previewLayer];
    
    _isOpenCamera = NO;
    _isReset = YES;
    _isConfigSession = YES;
}

- (AVCaptureDevice *)frontCamera{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        if ([device position] == AVCaptureDevicePositionFront){
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)backCamera{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        if ([device position] == AVCaptureDevicePositionBack){
            return device;
        }
    }
    return nil;
}

-(void)resetToNormal {
    if(!_isReset){
        [self configSession];
    }
}

- (void)switchCamera {
    AVCaptureDevicePosition desiredPosition;
    
    if (self.isUsingFrontFacingCamera) {
        desiredPosition = AVCaptureDevicePositionBack;
    }else {
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
        if ([device position] == desiredPosition){
            [self.session beginConfiguration];
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            for (AVCaptureInput *oldInput in [self.session inputs]){
                [self.session removeInput:oldInput];
            }
            if([self.session canAddInput:input]){
                [self.session addInput:input];
            }
            [self.session commitConfiguration];
            self.captureDevice = device;
            self.isOpenCamera = YES;
            if(!self.session.isRunning){
                [self.session startRunning];
            }
            break;
        }
    }
    
    _isReset = NO;
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
}

-(NSError *)switchCameraTo:(NSString *)uniqueId {
    if([uniqueId isEqualToString:self.captureDevice.uniqueID] && _isOpenCamera){
        return nil;
    }
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
        if ([device.uniqueID isEqualToString:uniqueId]){
            [self.session beginConfiguration];
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            for (AVCaptureInput *oldInput in [self.session inputs]){
                [self.session removeInput:oldInput];
            }
            
            if([self.session canAddInput:input]){
                [self.session addInput:input];
            }
            [self.session commitConfiguration];
            self.captureDevice = device;
            self.isOpenCamera = YES;
            self.isUsingFrontFacingCamera = device.position == AVCaptureDevicePositionFront;
            if(!self.session.isRunning){
                [self.session startRunning];
            }
            _isReset = NO;
            return nil;
        }
    }
    return [WEBARBundleInfo.share error:2004];
}

-(void)openCamera {
    if(self.isOpenCamera){
        return;
    }
    [self.session beginConfiguration];

    for (AVCaptureInput *oldInput in [self.session inputs]){
        [self.session removeInput:oldInput];
    }

    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    if([self.session canAddInput:deviceInput]){
        [self.session addInput:deviceInput];
    }
    [self.session commitConfiguration];
    self.isOpenCamera = YES;
    _isReset = NO;
    if(!self.session.isRunning){
        [self.session startRunning];
    }
}

-(void)closeCamera {
    [self.session beginConfiguration];
    for (AVCaptureInput *oldInput in [self.session inputs]){
        [self.session removeInput:oldInput];
    }
    [self.session commitConfiguration];
    self.isOpenCamera = NO;
    _isReset = NO;
    [self.session stopRunning];
}

-(NSArray *)uniqueOfDevices {
    NSMutableArray *array = [NSMutableArray array];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        NSString *position = device.position == AVCaptureDevicePositionFront ? @"front" : @"back";
        NSDictionary *dic = @{@"position": position, @"id": device.uniqueID};
        [array addObject:dic];
    }
    return array.copy;
}

-(void)changeSessionPreset:(AVCaptureSessionPreset)preset {
    if([_captureDevice supportsAVCaptureSessionPreset:preset]){
        [self.session beginConfiguration];
        [self.session setSessionPreset:preset];
        [self.session commitConfiguration];
        _isReset = NO;
    }
}

-(void)takePhoto:(void (^)(UIImage * _Nonnull))photoBlock {
    if(_isOpenCamera && !_isTakingPhoto){
        _isTakingPhoto = YES;
        _photoBlock = photoBlock;
    }
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(_photoBlock != nil && _isTakingPhoto) {
        CGImageRef cgImage = [self imageFromSampleBuffer:sampleBuffer];
        /// fix orientation
        /// https://stackoverflow.com/questions/3561738/why-avcapturesession-output-a-wrong-orientation
        UIImageOrientation imageOrientation;
        if(_isUsingFrontFacingCamera){
            imageOrientation = UIImageOrientationLeftMirrored;
        }else {
            imageOrientation = UIImageOrientationRight;
        }
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:imageOrientation];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.photoBlock(image);
            self.isTakingPhoto = NO;
            CGImageRelease(cgImage);
        });
    }
}

///https://stackoverflow.com/questions/3305862/uiimage-created-from-cmsamplebufferref-not-displayed-in-uiimageview
- (CGImageRef)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{ // Create a CGImageRef from sample buffer data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    
    return newImage;
}

-(NSError *)switchTorch:(AVCaptureTorchMode)mode {
    if (!_captureDevice.hasTorch){
        return [WEBARBundleInfo.share error:2001];
    }
    
    if(_captureDevice.flashMode == AVCaptureFlashModeOn){
        [self configFlash:AVCaptureFlashModeOff];
    }
    return [self configTorch:mode];
}

-(NSError *)configTorch:(AVCaptureTorchMode)mode {
    if ([_captureDevice isTorchModeSupported:mode]) {
        NSError *error;
        if ([_captureDevice lockForConfiguration:&error]) {
            _captureDevice.torchMode = mode;
            [_captureDevice unlockForConfiguration];
            _isReset = NO;
        }
        return error;
    }
    return [WEBARBundleInfo.share error:2001];
}

-(NSError *)switchFlash:(AVCaptureFlashMode)mode {
    if(!_captureDevice.hasFlash){
        return [WEBARBundleInfo.share error:2002];
    }
    
    if(_captureDevice.torchMode == AVCaptureTorchModeOn){
        [self configTorch:AVCaptureTorchModeOff];
    }
    return [self configFlash:mode];
}

-(NSError *)configFlash:(AVCaptureFlashMode)mode {
    if([_captureDevice isFlashModeSupported:mode]){
        NSError *error;
        if([_captureDevice lockForConfiguration:&error]){
            _captureDevice.flashMode = mode;
            [_captureDevice unlockForConfiguration];
            _isReset = NO;
        }
        return error;
    }
    return [WEBARBundleInfo.share error:2002];
}

-(NSError *)focus:(CGPoint)point {
    BOOL isSupport = _captureDevice.isFocusPointOfInterestSupported && [_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus];
    if(isSupport){
        NSError *error;
        if([_captureDevice lockForConfiguration:&error]){
            _captureDevice.focusPointOfInterest = point;
            _captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
            [_captureDevice unlockForConfiguration];
            _isReset = NO;
        }
        return error;
    }else {
        return [WEBARBundleInfo.share error:2003];
    }
}

-(NSError *)autoFocus {
    BOOL isSupport = _captureDevice.isFocusPointOfInterestSupported && [_captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
    if(isSupport){
        NSError *error;
        if([_captureDevice lockForConfiguration:&error]){
            _captureDevice.focusPointOfInterest = CGPointMake(0.5f, 0.5f);
            _captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [_captureDevice unlockForConfiguration];
        }
        return error;
    }else {
        return [WEBARBundleInfo.share error:2003];
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.layer.bounds;
}

#pragma mark - getter

-(AVCaptureVideoDataOutput *)videoDataOutput {
    if(!_videoDataOutput){
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("WEBARVideoDataOutputQueue", NULL);
        [_videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        _videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) };
        [[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    }
    return _videoDataOutput;
}

@end
