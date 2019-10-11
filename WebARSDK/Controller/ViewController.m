//
//  ViewController.m
//  WebARDemo
//
//  Created by weily on 2019/1/9.
//  Copyright © 2019 kivisense. All rights reserved.
//

#import "ViewController.h"
#import "ARViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _textField.text = @"https://www.kivicube.com/scenes/KnUpLGBbpOz4qmS3GgKYaX8A7njLesn6";
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMiss)];
    [self.view addGestureRecognizer:gesture];
}

-(void)tapMiss {
    [self.view endEditing:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"AR"]) {
        ARViewController *vc = segue.destinationViewController;
        vc.url = _textField.text;
    }
}

@end
