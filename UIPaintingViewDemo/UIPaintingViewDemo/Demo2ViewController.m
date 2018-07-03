//
//  Demo2ViewController.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/7/3.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "Demo2ViewController.h"
#import "UIPaintingView.h"


@interface Demo2ViewController ()<UIPaintViewDelegate>

@property (nonatomic, strong) UIPaintingView *paintingView;

@property (nonatomic, strong) UIPaintingView *playbackView;



@end

@implementation Demo2ViewController

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

-(UIPaintingView*)playbackView
{
    if (_playbackView == nil) {
//        _playbackView = [[UIPaintingView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.paintingView.frame) + 10, SCREEN_WIDTH, self.paintingView.frame.size.height)];
        _playbackView = [[UIPaintingView alloc] initWithFrame:self.paintingView.bounds];
//        _playbackView = [[UIPaintingView alloc] initWithFrame:self.paintingView.frame];
        _playbackView.backgroundColor = LIGHT_GRAY_COLOR;
        _playbackView.brushWidth = 3.0;
        _playbackView.brushColor = PURPLE_COLOR;
        _playbackView.touchPaintEnabled = NO;
        [self.paintingView addSubview:_playbackView];
//        [self.view addSubview:_playbackView];
    }
    return _playbackView;
}

-(void)_btnAction:(UIButton*)sender
{
    switch (sender.tag) {
        case 1:
        {
            self.playbackView.paintEvent = [[NSPaintManager sharePaintManager] cacheForEventId:self.paintingView.paintEvent.eventId];
            dispatch_after_in_main_queue(0.3, ^{
                [self.playbackView playBack:YES];
            });
            break;
        }
        case 2: {
            [self.playbackView removeFromSuperview];
            self.playbackView = nil;
            [self.paintingView erase];
            self.paintingView.brushColor = ORANGE_COLOR;
            self.paintingView.brushWidth = 8.0;
//            self.paintingView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.paintingView.frame.size.height + 64);
            break;
        }
        case 3: {

            break;
        }
        case 4: {

            break;
        }
        case 5: {
            break;
        }
        case 6: {
            break;
        }
        case 100: {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        default:
            break;
    }
}

-(void)_setupChildView
{
    self.view.backgroundColor = WHITE_COLOR;

    CGFloat functionBtnHeight = 40;
    
    UIButton *closeBtn = [self  _createButton:@"关闭" frame:CGRectMake(0, 0, 60, 64) tag:100];

    
    CGFloat Vspace = 10;
    CGFloat paintingViewH = (SCREEN_HEIGHT - closeBtn.bounds.size.height - 2 * functionBtnHeight - Vspace)/2;
    
    self.paintingView = [[UIPaintingView alloc] initWithFrame:CGRectMake(0, closeBtn.bounds.size.height, SCREEN_WIDTH, paintingViewH)];
    self.paintingView.backgroundColor = LIGHT_GRAY_COLOR;
    self.paintingView.brushWidth = 3.0;
    self.paintingView.brushColor = RED_COLOR;
    self.paintingView.touchPaintEnabled = YES;
    self.paintingView.delegate = self;
    self.paintingView.paintEvent = [[NSPaintManager sharePaintManager] cacheForNewEvent];
    [self.view addSubview:self.paintingView];
    
    NSLog(@"paintingView=%@",self.paintingView)
    
    CGFloat space = 15;
    NSInteger cnt = 2;
    CGFloat w = (SCREEN_WIDTH - (cnt + 1) * space)/cnt;
    
    CGFloat x = space;
    CGFloat y = CGRectGetMaxY(self.paintingView.frame) + paintingViewH + Vspace + (SCREEN_HEIGHT - CGRectGetMaxY(self.paintingView.frame) - paintingViewH - Vspace - functionBtnHeight)/2;
    
    UIButton *btn = [self _createButton:@"play" frame:CGRectMake(x, y, w, functionBtnHeight) tag:1];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"remove" frame:CGRectMake(x, y, w, functionBtnHeight) tag:2];


}

#pragma  mark
-(BOOL)paintingView:(GLPaintingView*)paintingView touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint currLoc = [touch locationInView:paintingView];
    
//    NSLog(@"start.loc=%@",NSStringFromCGPoint(currLoc));
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusBegan timeInterval:timeInterval];
    
    NSPaintStroke *newStroke = [[NSPaintStroke alloc] initWithEventId:self.paintingView.paintEvent.eventId];
    newStroke.strokeColor = self.paintingView.brushColor;
    [newStroke addPaintPoint:paintPoint];
    
    self.paintingView.paintEvent.lastRenderStroke = newStroke;
    
    return YES;
}

-(BOOL)paintingView:(GLPaintingView*)paintingView touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint currLoc = [touch locationInView:paintingView];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusMove timeInterval:timeInterval];
    
    [self.paintingView.paintEvent.lastRenderStroke addPaintPoint:paintPoint];
    
    return YES;
}

-(BOOL)paintingView:(GLPaintingView *)paintingView touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint prevLoc = [touch previousLocationInView:paintingView];
    CGPoint currLoc = [touch locationInView:paintingView];
    
//    NSLog(@"end.loc=%@",NSStringFromCGPoint(currLoc));
    
    NSPaintPoint *last = [[self.paintingView.paintEvent.lastRenderStroke paintPoints] lastObject];
    if (CGPointEqualToPoint(prevLoc, last.point)) {
        
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusEnd timeInterval:timeInterval];
        
        [self.paintingView.paintEvent.lastRenderStroke addPaintPoint:paintPoint];
    }
    [[NSPaintManager sharePaintManager] addPaintStrokeInCurrentCacheEvent:self.paintingView.paintEvent.lastRenderStroke];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
