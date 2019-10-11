//
//  WebARViewControllerTests.m
//  WebARSDKTests
//
//  Created by weily on 2018/11/21.
//  Copyright © 2018 kivisense. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WEBARViewController.h"

@interface WEBARViewController(unitTest)

-(id)scriptForCameraDeviceList:(NSArray *)arguments;

-(id)scriptForOpenCamera:(NSArray *)arguments;

-(id)scriptForCloseCamera:(NSArray *)arguments;

-(UIImage *)centerClip:(UIImage *)image size:(CGSize)size;

- (NSString *)removeSpaceAndNewline:(NSString *)str;

@end


@interface WebARViewControllerTests : XCTestCase

@property(nonatomic, strong) WEBARViewController *warViewController;

@end

@implementation WebARViewControllerTests

- (void)setUp {
    _warViewController = [[WEBARViewController alloc] init];
    if (@available(iOS 9.0, *)) {
        [_warViewController loadViewIfNeeded];
    } else {
        [_warViewController view];
    }
    // 这里设置成nil的目的是防止调用decidePolicyForNavigationAction方法reset相机设置，这会与有些测试中调用的openCamera方法起冲突
    _warViewController.webView.navigationDelegate = nil;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCameraDeviceList {
    XCTAssertTrue((![[_warViewController scriptForCameraDeviceList:@[]] isKindOfClass:[NSError class]]));
    XCTAssertTrue((![[_warViewController scriptForCameraDeviceList:@[@"1"]] isKindOfClass:[NSError class]]));
}

- (void)testOpenCamera {
    XCTAssertTrue(([[_warViewController scriptForOpenCamera:@[@"12", @"high"]] isKindOfClass:[NSError class]]));
    XCTAssertTrue(([[_warViewController scriptForOpenCamera:@[@"kiu", @"high"]] isKindOfClass:[NSError class]]));
    
    NSArray *devices = _warViewController.cameraView.uniqueOfDevices;
    NSString *cameraId = [devices.firstObject objectForKey:@"id"];
    XCTAssertTrue((![[_warViewController scriptForOpenCamera:@[cameraId, @"high"]] isKindOfClass:[NSError class]]));
    XCTAssertTrue((![[_warViewController scriptForOpenCamera:@[cameraId, @"low"]] isKindOfClass:[NSError class]]));
    XCTAssertTrue((![[_warViewController scriptForOpenCamera:@[cameraId, @"medium"]] isKindOfClass:[NSError class]]));
    XCTAssertTrue(([[_warViewController scriptForOpenCamera:@[cameraId, @"aa"]] isKindOfClass:[NSError class]]));
}

- (void)testCloseCamera {
    XCTAssertTrue((![[_warViewController scriptForCloseCamera:@[]] isKindOfClass:[NSError class]]));
    XCTAssertTrue((![[_warViewController scriptForCloseCamera:@[@"1"]] isKindOfClass:[NSError class]]));
}

- (void)testGetFrame {
    [_warViewController.cameraView openCamera];
    [self scriptForGetFrame:@[]];
    [self scriptForGetFrame:@[@"20", @"20"]];
    [self scriptForGetFrame:@[@"20", @"0"]];
    [self scriptForGetFrame:@[@"0", @"0"]];
    [self scriptForGetFrame:@[@"20"]];
    [self scriptForGetFrame:@[@"20", @"20", @"20"]];
}

-(void)scriptForGetFrame:(NSArray *)arguments{
    CGFloat width = 0;
    CGFloat height = 0;
    if(arguments.count == 2) {
        width = [arguments[0] floatValue];
        height = [arguments[1] floatValue];
    }else if(arguments.count == 0){
        
    }else {
        // 报错
        width = 1;
    }
    
    BOOL isDoubleZero = width == 0 && height == 0;
    BOOL isNoZero = width > 0 && height > 0;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"getFrame"];
    __weak typeof(self) weakSelf = self;
    if(isDoubleZero || isNoZero){
        [_warViewController.cameraView takePhoto:^(UIImage * _Nonnull image) {
            XCTAssertNotNil(image);
            UIImage *re = [weakSelf.warViewController centerClip:image size:CGSizeMake(width, height)];
            if(isDoubleZero){
                XCTAssertTrue(CGSizeEqualToSize(image.size, re.size), @"%@", arguments);
            }else if(isNoZero){
                XCTAssertTrue(CGSizeEqualToSize(CGSizeMake(width, height), re.size), @"%@", arguments);
            }else {
                XCTFail(@"%@", arguments);
            }
            [expectation fulfill];
        }];
    }else {
        [expectation fulfill];
    }
    
    [self waitForExpectations:@[expectation] timeout:15];
}

-(void)testTakePhotoMultiTimes {
    [_warViewController.cameraView openCamera];
    
    NSMutableArray *array = [NSMutableArray array];
    for(int i=0;i<10;i++){
        NSString *desc = [NSString stringWithFormat:@"getFrame%d", i];
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:desc];
        [array addObject:expectation];
    }
    
    [array enumerateObjectsUsingBlock:^(XCTestExpectation *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        float time = idx * 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.warViewController.cameraView takePhoto:^(UIImage * _Nonnull image) {
                XCTAssertNotNil(image);
                [obj fulfill];
            }];
        });
    }];

    [self waitForExpectations:array timeout:30];
}

-(void)testTakePhotoUseForLoop {
    [_warViewController.cameraView openCamera];
    
    NSMutableArray *array = [NSMutableArray array];
    for(int i=0;i<10;i++){
        NSString *desc = [NSString stringWithFormat:@"getFrame%d", i];
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:desc];
        [array addObject:expectation];
    }
    
    [array enumerateObjectsUsingBlock:^(XCTestExpectation *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.warViewController.cameraView takePhoto:^(UIImage * _Nonnull image) {
            XCTAssertNotNil(image);
            [obj fulfill];
        }];
    }];
    
    [self waitForExpectations:array timeout:30];
}

@end
