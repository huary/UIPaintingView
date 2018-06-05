//
//  ViewController.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/6/4.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "ViewController.h"
#import "UIPaintingView.h"

@interface ViewController ()<UIPaintViewDelegate>

/** 注释 */
@property (nonatomic, strong) UIPaintingView *paintingView;

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
    switch (sender.tag) {
        case 1:
        {
            [self.paintingView redo];
            break;
        }
        case 2: {
            [self.paintingView undo];
            break;
        }
        case 3: {
            [self.paintingView erase];
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
        default:
            break;
    }
}

-(void)_setupChildView
{
    CGFloat functionBtnHeight = 40;
    
    self.paintingView = [[UIPaintingView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - functionBtnHeight)];
    self.paintingView.backgroundColor = LIGHT_GRAY_COLOR;
    self.paintingView.brushWidth = 2.0;
    self.paintingView.brushColor = RED_COLOR;
    self.paintingView.touchPaintEnabled = YES;
    self.paintingView.delegate = self;
    self.paintingView.paintEvent = [[NSPaintManager sharePaintManager] cacheForNewEvent];
    [self.view addSubview:self.paintingView];
    
    CGFloat space = 15;
    NSInteger cnt = 5;
    CGFloat w = (SCREEN_WIDTH - (cnt + 1) * space)/cnt;
    
    CGFloat x = space;
    CGFloat y = CGRectGetMaxY(self.paintingView.frame);
    UIButton *btn = [self _createButton:@"Redo" frame:CGRectMake(x, y, w, functionBtnHeight) tag:1];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"Undo" frame:CGRectMake(x, y, w, functionBtnHeight) tag:2];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"Erase" frame:CGRectMake(x, y, w, functionBtnHeight) tag:3];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"delete" frame:CGRectMake(x, y, w, functionBtnHeight) tag:4];
    
    x = CGRectGetMaxX(btn.frame) + space;
    btn = [self _createButton:@"play" frame:CGRectMake(x, y, w, functionBtnHeight) tag:5];
    
    
}

#pragma  mark 
-(BOOL)paintingView:(GLPaintingView*)paintingView touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint currLoc = [touch locationInView:paintingView];
    
    NSLog(@"start.loc=%@",NSStringFromCGPoint(currLoc));
    
//    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusBegan lineWidth:self.paintingView.brushWidth];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusBegan timeInterval:timeInterval];
    
    NSPaintStroke *newStroke = [[NSPaintStroke alloc] initWithEventId:self.paintingView.paintEvent.eventId];
    newStroke.strokeColor = self.paintingView.brushColor;
    [newStroke addPaintPoint:paintPoint];
    
    self.paintingView.paintEvent.lastPaintStroke = newStroke;
    
    return YES;
}

-(BOOL)paintingView:(GLPaintingView*)paintingView touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint currLoc = [touch locationInView:paintingView];
    
//    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusMove lineWidth:self.paintingView.brushWidth];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusMove timeInterval:timeInterval];
    
    [self.paintingView.paintEvent.lastPaintStroke addPaintPoint:paintPoint];
    
    return YES;
}

-(BOOL)paintingView:(GLPaintingView *)paintingView touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint prevLoc = [touch previousLocationInView:paintingView];
    CGPoint currLoc = [touch locationInView:paintingView];
    
    NSLog(@"end.loc=%@",NSStringFromCGPoint(currLoc));
    
    NSPaintPoint *last = [[self.paintingView.paintEvent.lastPaintStroke paintPoints] lastObject];
    if (CGPointEqualToPoint(prevLoc, last.point)) {
        
//        NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc status:NSPaintStatusEnd lineWidth:self.paintingView.brushWidth];
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        NSPaintPoint *paintPoint = [[NSPaintPoint alloc] initWithPoint:currLoc pressure:0 status:NSPaintStatusEnd timeInterval:timeInterval];
        
        [self.paintingView.paintEvent.lastPaintStroke addPaintPoint:paintPoint];
    }
    [[NSPaintManager sharePaintManager] addPaintStrokeIntoCurrentCache:self.paintingView.paintEvent.lastPaintStroke];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
