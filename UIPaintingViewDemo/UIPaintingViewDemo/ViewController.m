//
//  ViewController.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/6/4.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "ViewController.h"
#import "Demo1ViewController.h"
#import "Demo2ViewController.h"


@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupChildView];
}

-(UIButton*)_createButton:(NSString*)title frame:(CGRect)frame tag:(NSInteger)tag
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    button.frame = frame;
    button.backgroundColor = PURPLE_COLOR;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(_btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

-(void)_btnAction:(UIButton*)sender
{
    if (sender.tag == 1) {
        Demo1ViewController *d1 = [[Demo1ViewController alloc] init];
        [self presentViewController:d1 animated:YES completion:nil];
    }
    else if (sender.tag == 2) {
        Demo2ViewController *d2 = [[Demo2ViewController alloc] init];
        [self presentViewController:d2 animated:YES completion:nil];
    }
}

-(void)_setupChildView
{
    
    CGFloat w = SCREEN_WIDTH * 0.8;
    CGFloat h = 40;
    CGFloat s = 20;
    CGFloat x = (SCREEN_WIDTH - w)/2;
    CGFloat y = SCREEN_HEIGHT/2 - s/2 - h;
    UIButton *demo1Btn = [self _createButton:@"Demo1" frame:CGRectMake(x, y, w, h) tag:1];
    
    y = SCREEN_HEIGHT/2 + s/2;
    UIButton *demo2Btn = [self _createButton:@"Demo2" frame:CGRectMake(x, y, w, h) tag:2];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
