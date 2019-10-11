//
//  WebARSDKTests.m
//  WebARSDKTests
//
//  Created by weily on 2018/11/6.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WEBARCameraView.h"
#import "UIImage+WEBARClip.h"

@interface WebARSDKTests : XCTestCase

@property(nonatomic, strong) WEBARCameraView *cameraView;

@end

@implementation WebARSDKTests

- (void)setUp {
    _cameraView = [[WEBARCameraView alloc] initWithFrame:CGRectZero];
    [_cameraView openCamera];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUniqueOfDevices {
    NSArray *devices = _cameraView.uniqueOfDevices;
    XCTAssertTrue(devices.count > 0);
    
    {
        NSString *cameraId = [devices.firstObject objectForKey:@"id"];
        [_cameraView switchCameraTo:cameraId];
        XCTAssertTrue([_cameraView.captureDevice.uniqueID isEqualToString:cameraId]);
    }
    
    {
        NSString *cameraId = [devices[1] objectForKey:@"id"];
        [_cameraView switchCameraTo:cameraId];
        XCTAssertTrue([_cameraView.captureDevice.uniqueID isEqualToString:cameraId]);
    }
}

-(void)testFlashOn {
    if([_cameraView.captureDevice isFlashModeSupported:AVCaptureFlashModeOn]){
        [_cameraView openCamera];
        [_cameraView switchFlash:AVCaptureFlashModeOn];
        XCTAssertTrue(_cameraView.captureDevice.flashMode == AVCaptureFlashModeOn);
    }
}

-(void)testFlashOff {
    [_cameraView openCamera];
    [_cameraView switchFlash:AVCaptureFlashModeOff];
    XCTAssertTrue(_cameraView.captureDevice.flashMode == AVCaptureFlashModeOff);
}

-(void)testTorchOn {
    if([_cameraView.captureDevice isTorchModeSupported:AVCaptureTorchModeOn]){
        [_cameraView openCamera];
        [_cameraView switchTorch:AVCaptureTorchModeOn];
        XCTAssertTrue(_cameraView.captureDevice.torchMode == AVCaptureTorchModeOn);
    }
}

-(void)testTorchOff {
    [_cameraView openCamera];
    [_cameraView switchTorch:AVCaptureTorchModeOff];
    XCTAssertTrue(_cameraView.captureDevice.torchMode == AVCaptureFlashModeOff);
}

-(void)testOpenCloseCamera {
    [_cameraView openCamera];
    XCTAssertTrue(_cameraView.session.inputs.count > 0);
    [_cameraView closeCamera];
    XCTAssertTrue(_cameraView.session.inputs.count == 0);
    
    [_cameraView closeCamera];
    [_cameraView closeCamera];
    XCTAssertTrue(_cameraView.session.inputs.count == 0);
}

-(void)testTakePhoto {
    [_cameraView openCamera];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"take photo"];
    [_cameraView takePhoto:^(UIImage * _Nonnull image) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:15];
}

-(void)testTakePhotoWhenClose {
    [_cameraView closeCamera];
    [_cameraView takePhoto:^(UIImage * _Nonnull image) {
        XCTFail();
    }];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"take photo"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:15];
}

-(void)testImageClip {
    [_cameraView openCamera];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"take photo"];
    [_cameraView takePhoto:^(UIImage * _Nonnull image) {
        XCTAssertNotNil(image);
        UIImage *normalImage = [image normalImage];
        {
            CGSize size = CGSizeMake(100, 100);
            UIImage *newImage = [normalImage centerClipWith:size];
            UIImage *scaledImage = [newImage scaleTo:size];
            
            XCTAssertTrue(CGSizeEqualToSize(size, scaledImage.size));
        }
        
        {
            CGSize size = CGSizeZero;
            UIImage *newImage = [normalImage centerClipWith:size];
            UIImage *scaledImage = [newImage scaleTo:size];
            
            XCTAssertTrue(CGSizeEqualToSize(image.size, scaledImage.size));
        }
        
        {
            CGSize size = CGSizeMake(10, 100);
            UIImage *newImage = [normalImage centerClipWith:size];
            UIImage *scaledImage = [newImage scaleTo:size];
            
            XCTAssertTrue(CGSizeEqualToSize(size, scaledImage.size));
        }
        
        {
            CGSize size = CGSizeMake(100, 10);
            UIImage *newImage = [normalImage centerClipWith:size];
            UIImage *scaledImage = [newImage scaleTo:size];
            
            XCTAssertTrue(CGSizeEqualToSize(size, scaledImage.size));
        }
        
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:15];
}

@end
