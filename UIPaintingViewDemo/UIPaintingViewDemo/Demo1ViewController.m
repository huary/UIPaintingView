//
//  Demo1ViewController.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/7/3.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "Demo1ViewController.h"
#import "UIPaintingView.h"


@interface Demo1ViewController ()<UIPaintViewDelegate>

/** 注释 */
@property (nonatomic, strong) UIPaintingView *paintingView;

/* <#注释#> */
@property (nonatomic, strong) UIImageView *eraseImageView;

@end

@implementation Demo1ViewController

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

-(UIColor*)_getOtherColor:(UIColor*)color
{
    CGFloat r, g, b, a;
    [self.paintingView.brushColor getRed:&r green:&g blue:&b alpha:&a];
    r = 1 - r;
    g = 1 - g;
    b = 1 - b;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

-(UIImageView*)eraseImageView
{
    if (_eraseImageView == nil) {
        _eraseImageView = [UIImageView new];
        CGFloat w = self.paintingView.brushWidth;
        _eraseImageView.bounds = CGRectMake(0, 0, w, w);
        _eraseImageView.layer.cornerRadius = w/2;
        _eraseImageView.backgroundColor = [self _getOtherColor:self.paintingView.brushColor];
        [self.paintingView addSubview:_eraseImageView];
    }
    return _eraseImageView;
}

-(void)_btnAction:(UIButton*)sender
{
    [self.paintingView setGLBlendModel:NO];
    self.paintingView.brushColor = RED_COLOR;
    switch (sender.tag) {
        case 1:
        {
//            [self.paintingView redo];
//            self.paintingView.brushColor = RAND_COLOR;
            break;
        }
        case 2: {
            [self.paintingView undo];
//            [self.paintingView undoFaster];
//            [self.paintingView deleteLastStroke];
            break;
        }
        case 3: {
            //            CGRect rect = [self.cropView cropRectForType:NSCropRectTypeIn];
            //            [self.paintingView eraseInFrame:rect];
            
            //改为erase擦除
            [self.paintingView setGLBlendModel:YES];
            self.paintingView.brushWidth = 100;//100;
//            self.paintingView.brushColor = [self.paintingView.brushColor colorWithAlphaComponent:1.0];
            
            CGFloat r, g, b, a;
            [self.paintingView.brushColor getRed:&r green:&g blue:&b alpha:&a];
            NSLog(@"r=%f,g=%f,b=%f,a=%f",a,g,b,a);
            
//            [self.paintingView erase];
            break;
        }
        case 4: {
            [self.paintingView deletePaint];
            self.paintingView.paintEvent = [[NSPaintManager sharePaintManager] cacheForNewEvent];
            break;
        }
        case 5: {
            //            self.paintingView.playRatio = 5.0;
            [self.paintingView playBack:YES];
            //            sender.tag = 6;
            //            [sender setTitle:@"stop" forState:UIControlStateNormal];
            break;
        }
        case 6: {
            [self.paintingView playBack:NO];
            sender.tag = 5;
            [sender setTitle:@"play" forState:UIControlStateNormal];
            break;
        }
        case 100: {
            [[NSPaintManager sharePaintManager] save];
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
    
    CGRect frame = CGRectMake(0, closeBtn.bounds.size.height, SCREEN_WIDTH, SCREEN_HEIGHT -closeBtn.bounds.size.height - 3 * functionBtnHeight);
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:frame];
    imgView.image = [UIImage imageNamed:@"test.jpg"];
    imgView.contentMode = UIViewContentModeScaleToFill;
    [self.view addSubview:imgView];
    
    self.paintingView = [[UIPaintingView alloc] initWithFrame:frame];
    self.paintingView.backgroundColor = CLEAR_COLOR;
    self.paintingView.brushWidth = 20.0;
    self.paintingView.brushColor = RED_COLOR;
    self.paintingView.touchPaintEnabled = YES;
    self.paintingView.delegate = self;
//    [[NSPaintManager sharePaintManager] loadEventIdDataFromPathPrefix:@"test"];
    self.paintingView.paintEvent = [[NSPaintManager sharePaintManager] cacheForNewEvent];
    
    [self.view addSubview:self.paintingView];
    
    NSLog(@"eventId=%@",@(self.paintingView.paintEvent.eventId));
    
    CGFloat space = 15;
    NSInteger cnt = 5;
    CGFloat w = (SCREEN_WIDTH - (cnt + 1) * space)/cnt;
    
    CGFloat x = space;
    CGFloat y = CGRectGetMaxY(self.paintingView.frame) + 40;
    UIButton *btn = [self _createButton:@"Redo" frame:CGRectMake(x, y, w, functionBtnHeight) tag:1];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"Undo" frame:CGRectMake(x, y, w, functionBtnHeight) tag:2];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"Erase" frame:CGRectMake(x, y, w, functionBtnHeight) tag:3];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"delete" frame:CGRectMake(x, y, w, functionBtnHeight) tag:4];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"play" frame:CGRectMake(x, y, w, functionBtnHeight) tag:5];
    
    
    //    self.cropView = [[YZHUICropView alloc] initWithCropOverView:self.paintingView];
}

#pragma  mark
-(BOOL)paintingView:(GLPaintingView*)paintingView touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint currLoc = [touch locationInView:paintingView];
    
    if ([paintingView isInClearModel]) {
        self.eraseImageView.center = currLoc;
    }
    else {
        [_eraseImageView removeFromSuperview];
        _eraseImageView = nil;
    }
    
//    NSLog(@"start.loc=%@",NSStringFromCGPoint(currLoc));
    
    //    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusBegan lineWidth:self.paintingView.brushWidth];
    
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
    
    if ([paintingView isInClearModel]) {
        self.eraseImageView.center = currLoc;
    }
    else {
        [_eraseImageView removeFromSuperview];
        _eraseImageView = nil;
    }
    
    //    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusMove lineWidth:self.paintingView.brushWidth];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusMove timeInterval:timeInterval];
    
    [self.paintingView.paintEvent.lastRenderStroke addPaintPoint:paintPoint];
    
    return YES;
}

-(BOOL)paintingView:(GLPaintingView *)paintingView touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint prevLoc = [touch previousLocationInView:paintingView];
    CGPoint currLoc = [touch locationInView:paintingView];
    
    if ([paintingView isInClearModel]) {
        self.eraseImageView.center = currLoc;
    }
    else {
        [_eraseImageView removeFromSuperview];
        _eraseImageView = nil;
    }
    
//    NSLog(@"end.loc=%@",NSStringFromCGPoint(currLoc));
    
    NSPaintPoint *last = [[self.paintingView.paintEvent.lastRenderStroke paintPoints] lastObject];
    if (CGPointEqualToPoint(prevLoc, last.point)) {
        
        //        NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusEnd lineWidth:self.paintingView.brushWidth];
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
