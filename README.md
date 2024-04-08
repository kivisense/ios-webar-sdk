# WebARSDK

- SDK需要系统的相机和相册权限，因此请在工程的`info.plist`中添加`NSCameraUsageDescription`和`NSPhotoLibraryAddUsageDescription`。

## 安装

### Cocoapods

```
pod 'WebARSDK'
```

## 使用

1. 导入头文件`#import <WebARSDK/WebARSDK.h>`

2. 主要使用的类为`WEBARView`，它继承自`UIView`，你可以使用`initWithFrame`方法初始化它，也支持`xib`与`storyboard`

   ```objective-c
   #import "ViewController.h"
   #import <WebARSDK/WebARSDK.h>
   
   @interface ViewController ()<WEBARViewDelegate>
   
   @property (nonatomic, strong) WEBARView *webARView;
   
   @end
   
   @implementation ViewController
   
   - (void)viewDidLoad {
       [super viewDidLoad];
   
       _webARView = [[WEBARView alloc] initWithFrame:[UIScreen mainScreen].bounds];
       _webARView.delegate = self;
       _webARView.parentViewController = self;
       [self.view addSubview:_webARView];
   
       [_webARView loadUrl:[NSURL URLWithString:@"https://www.kivicube.com/scenes/KnUpLGBbpOz4qmS3GgKYaX8A7njLesn6"]];
   }
   
   #pragma mark - WEBARViewDelegate
   
   - (void)webARViewCameraAuthFailed {
       UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"WebAR功能需要打开摄像头，请转到系统设置中授予相机权限" preferredStyle:UIAlertControllerStyleAlert];
       [alert addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
           if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
           }
       }]];
       [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
           [self.navigationController popViewControllerAnimated:YES];
       }]];
       [self presentViewController:alert animated:YES completion:nil];
   }
   
   @end
   
   ```

   

更多详情可以参考工程中`ARViewController`类中的实现。
