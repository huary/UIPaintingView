//
//  UIPaintingView.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/1/31.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "UIPaintingView.h"

//
//#define MAX_STROKE_PAINT_TIME_INTERVAL (5.0)
#define MIN_DIFF_TIME                    (0.0001)

@interface UIPaintingView ()
//freq should be 1 - 60;
@property (nonatomic, assign) CGFloat displayFreq;
@property (nonatomic, assign) BOOL isPlaying;

@end


@implementation UIPaintingView

//@synthesize delegate = _delegate;
@dynamic delegate;

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self _setUpDefaultValue];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setUpDefaultValue];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setUpDefaultValue];
    }
    return self;
}

-(void)_setUpDefaultValue
{
    self.touchPaintEnabled = NO;
    
    //1-60
    self.displayFreq = 20;
    self.playRatio = 1.0;
    [NSPaintManager sharePaintManager].pointsMaxTimeInterval = 2.0;
    [NSPaintManager sharePaintManager].strokesMaxFreeTimeInterval = 5.0;
}

-(CGFloat)_getFreqTimeInterval
{
    return 1.0/self.displayFreq;
}

-(void)renderWithPoint:(NSPaintPoint*)paintPoint
{
    [self _renderWithPoint:paintPoint present:YES addNewStroke:YES lineColor:nil];
}

-(void)renderWithStroke:(NSPaintStroke*)stroke
{
    NSLog(@"strokeId=%ld",stroke.strokeId);
    [self _renderWithStroke:stroke lineColor:stroke.strokeColor];
}

-(void)_renderWithStroke:(NSPaintStroke*)stroke lineColor:(UIColor*)lineColor
{
    self.paintEvent.lastPaintStroke = stroke;
    for (NSPaintPoint *point in stroke.strokePoints) {
        [self _renderWithPoint:point present:NO addNewStroke:NO lineColor:lineColor];
    }
    self.paintEvent.lastPaintStroke.strokeId = stroke.strokeId;
}

-(BOOL)_shouldDisplayPoint:(NSPaintPoint*)point forPaintStroke:(NSPaintStroke*)stroke
{
    if (point.status != NSPaintStatusMove) {
        return YES;
    }
    NSTimeInterval timerInterval = [NSPaintPoint getTimeIntervalFrom:stroke.lastDisplayPoint to:point];
    if (timerInterval >= [self _getFreqTimeInterval]) {
        return YES;
    }
    return NO;
}

-(void)_renderWithPoint:(NSPaintPoint*)paintPoint present:(BOOL)present addNewStroke:(BOOL)addNew lineColor:(UIColor*)lineColor
{
    
    CGFloat lineWidth = [paintPoint getLineWidth:self.maxLineWidth];
    if (paintPoint.status == NSPaintStatusBegan) {
        GLLinePoint *from = [[GLLinePoint alloc] initWithPoint:paintPoint.point lineWidth:lineWidth];
        [self renderLineFromPoint:from toPoint:from lineColor:lineColor present:present];
        
        NSPaintStroke *newStroke = [[NSPaintStroke alloc] initWithEventId:self.paintEvent.eventId];
        [newStroke addPaintPoint:paintPoint];
        self.paintEvent.lastPaintStroke = newStroke;
        
//        NSLog(@"from=%@",NSStringFromCGPoint(from.point));
        if (present) {
            self.paintEvent.lastPaintStroke.lastDisplayPoint = paintPoint;
        }
    }
    else if (paintPoint.status == NSPaintStatusMove) {
        NSPaintPoint *lastPoint = self.paintEvent.lastPaintStroke.lastPaintPoint;
        CGFloat lastLineWidth = [lastPoint getLineWidth:self.maxLineWidth];
        GLLinePoint *from = [[GLLinePoint alloc] initWithPoint:lastPoint.point lineWidth:lastLineWidth];
        
        GLLinePoint *to = [[GLLinePoint alloc] initWithPoint:paintPoint.point lineWidth:lineWidth];

//    NSLog(@"2.from=%@,to=%@",NSStringFromCGPoint(from.point),NSStringFromCGPoint(to.point));
        
        if (present) {
            if (![self _shouldDisplayPoint:paintPoint forPaintStroke:self.paintEvent.lastPaintStroke]) {
                present = NO;
            }
        }
        
        [self renderLineFromPoint:from toPoint:to lineColor:lineColor present:present];
        
        [self.paintEvent.lastPaintStroke addPaintPoint:paintPoint];
        if (present) {
            self.paintEvent.lastPaintStroke.lastDisplayPoint = paintPoint;
            if (self.isPlaying && [self.delegate respondsToSelector:@selector(paintingView:playingPintStroke:paintPoint:)]) {
                [self.delegate paintingView:self playingPintStroke:self.paintEvent.lastPaintStroke paintPoint:paintPoint];
            }
        }
    }
    else {
        NSPaintPoint *lastPoint = self.paintEvent.lastPaintStroke.lastPaintPoint;
        CGFloat lastLineWidth = [lastPoint getLineWidth:self.maxLineWidth];
        GLLinePoint *from = [[GLLinePoint alloc] initWithPoint:lastPoint.point lineWidth:lastLineWidth];
        
        GLLinePoint *to = [[GLLinePoint alloc] initWithPoint:paintPoint.point lineWidth:lineWidth];
        
//    NSLog(@"3.from=%@,to=%@",NSStringFromCGPoint(from.point),NSStringFromCGPoint(to.point));
        
        [self renderLineFromPoint:from toPoint:to lineColor:lineColor present:present];
        
        if (addNew) {
            [self.paintEvent.lastPaintStroke addPaintPoint:paintPoint];
            [[NSPaintManager sharePaintManager] addPaintStrokeIntoCurrentCache:self.paintEvent.lastPaintStroke];
        }
        
        if (present) {
            self.paintEvent.lastPaintStroke.lastDisplayPoint = paintPoint;
        }
    }
    self.paintEvent.lastPaintStroke.lastPaintPoint = paintPoint;
}

-(CGFloat)_getPlayDiffTimeInterval:(NSTimeInterval)timeInterval
{
    if (self.playRatio > 0) {
        return timeInterval/self.playRatio;
    }
    return timeInterval;
}
/*
 *在调用前需要注意的是需要把stroke放到self.PaintEvent中的lastPaintStroke属性去
 */
-(void)_playBackRenderStroke:(NSPaintStroke*)stroke
{
    if (stroke == nil || !IS_AVAILABLE_NSSET_OBJ(stroke.strokePoints)) {
        return;
    }
    NSInteger index = 0;
    if (stroke.lastPaintPoint) {
        index = [stroke.strokePoints indexOfObject:stroke.lastPaintPoint] + 1;
    }
    if (index >= stroke.strokePoints.count) {
        return;
    }
    
    NSPaintPoint *paintPoint = stroke.strokePoints[index];
    [self _renderWithPoint:paintPoint present:YES addNewStroke:NO lineColor:nil];
    stroke.lastPaintPoint = paintPoint;
    self.paintEvent.lastPaintStroke.strokeId = stroke.strokeId;

    if (paintPoint.status == NSPaintStatusBegan) {
        if ([self.delegate respondsToSelector:@selector(paintingView:startPlayPaintStroke:)]) {
            [self.delegate paintingView:self startPlayPaintStroke:stroke];
        }
    }
    else if (paintPoint.status == NSPaintStatusEnd) {
        if ([self.delegate respondsToSelector:@selector(paintingView:endPlayPaintStroke:)]) {
            [self.delegate paintingView:self endPlayPaintStroke:stroke];
        }
    }
    if (!self.isPlaying) {
        return ;
    }
    NSInteger nextIdx = index + 1;
    if (nextIdx < stroke.strokePoints.count) {
        NSPaintPoint *nextPoint = stroke.strokePoints[nextIdx];
        NSTimeInterval diff = [NSPaintPoint getTimeIntervalFrom:paintPoint to:nextPoint];
        if (diff > [NSPaintManager sharePaintManager].pointsMaxTimeInterval) {
            diff = [NSPaintManager sharePaintManager].pointsMaxTimeInterval;
        }
        diff = [self _getPlayDiffTimeInterval:diff];
//        NSLog(@"nextIdx=%@,diff1=%f",@(nextIdx),diff);
        if (diff <= MIN_DIFF_TIME) {
            dispatch_async_in_main_queue(^{
                [self _playBackRenderStroke:stroke];
            });
        }
        else {
            dispatch_after_in_main_queue(diff,^{
                [self _playBackRenderStroke:stroke];
            });
        }
    }
    else {
        NSPaintStroke *nextStroke = [[NSPaintManager sharePaintManager] nextPaintStrokeForStrokeId:stroke.strokeId];
        if (nextStroke == nil) {
            self.isPlaying = NO;
            return;
        }
        NSTimeInterval diff = [nextStroke startTimeInterval] - [stroke endTimeInterval];
//        NSLog(@"diff2=%f",diff);
        if (diff > [NSPaintManager sharePaintManager].strokesMaxFreeTimeInterval) {
            diff = [NSPaintManager sharePaintManager].strokesMaxFreeTimeInterval;
        }
        diff = [self _getPlayDiffTimeInterval:diff];
        if (diff <= MIN_DIFF_TIME) {
            dispatch_async_in_main_queue(^{
                [self _playBackWithPaintEvent:self.paintEvent];
            });
        }
        else {
            dispatch_after_in_main_queue(diff, ^{
                [self _playBackWithPaintEvent:self.paintEvent];
            });
        }
    }
}

-(void)_playBackWithPaintEvent:(NSPaintEvent*)paintEvent
{
    if (paintEvent == nil || !IS_AVAILABLE_NSSET_OBJ(paintEvent.strokeIds)) {
        return;
    }
    NSPaintStroke *paintStroke = nil;
    if (paintEvent.lastPaintStroke) {
        paintStroke = [[NSPaintManager sharePaintManager] nextPaintStrokeForStrokeId:paintEvent.lastPaintStroke.strokeId];
    }
    else {
        paintStroke = [[NSPaintManager sharePaintManager] firstPaintStroke];
    }
    if (paintStroke == nil) {
        self.isPlaying = NO;
        return;
    }
    self.isPlaying = YES;
    paintStroke.lastPaintPoint = nil;
    [self _playBackRenderStroke:paintStroke];
}

-(void)_cancelPrevPlay
{
    self.isPlaying = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_playBackRenderStroke:) object:self.paintEvent.lastPaintStroke];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector((_playBackWithPaintEvent:)) object:self.paintEvent];
}

-(void)playBack:(BOOL)fromStart
{
    [self _cancelPrevPlay];
    if (fromStart) {
        [self erase];
        self.paintEvent.lastPaintStroke = nil;
    }
    else {
        //将最后绘制的那一笔再绘制一次
        if (self.paintEvent.lastPaintStroke) {
            NSPaintStroke *prev = [[NSPaintManager sharePaintManager] prevPaintStrokeForStrokeId:self.paintEvent.lastPaintStroke.strokeId];
            if (prev) {
                self.paintEvent.lastPaintStroke = prev;
            }
        }
    }
    [self _playBackWithPaintEvent:self.paintEvent];
}

-(void)stopPlay
{
    [self _cancelPrevPlay];
}

-(NSUInteger)_undoLastStroke
{
    if (self.isPlaying) {
        return 0;
    }
    NSUInteger strokeId = 0;
    NSPaintStroke *last = self.paintEvent.lastPaintStroke;
    NSPaintStroke *prevStroke = nil;
    if (last == nil) {
        strokeId = [[self.paintEvent.strokeIds lastObject] integerValue];
    }
    else {
        strokeId = last.strokeId;
    }
    prevStroke = [[NSPaintManager sharePaintManager] prevPaintStrokeForStrokeId:strokeId];
#if 1
    [self clearFrameBuffer];
    NSUInteger prevStrokeId = prevStroke.strokeId;
    __block BOOL haveRend = NO;
    [self.paintEvent.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger strokeId = [obj unsignedIntegerValue];
        if (strokeId <= prevStrokeId) {
            NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:[obj unsignedIntegerValue]];
            [self renderWithStroke:stroke];
            haveRend = YES;
        }
        else {
            *stop = YES;
        }
    }];
    [self presentRenderbuffer];
    if (!haveRend) {
        self.paintEvent.lastPaintStroke.lastPaintPoint = nil;
        self.paintEvent.lastPaintStroke = nil;
    }
    else {
        self.paintEvent.lastPaintStroke = prevStroke;
    }
#else
    [self _renderWithStroke:last lineColor:WHITE_COLOR];
    [self presentRenderbuffer];
    self.paintEvent.lastPaintStroke = prevStroke;
#endif
    return strokeId;
}

-(void)undo
{
    [self _undoLastStroke];
}

-(void)redo
{
    if (self.isPlaying) {
        return;
    }
    NSPaintStroke *last = self.paintEvent.lastPaintStroke;
    if ([[NSPaintManager sharePaintManager] isLastPaintStroke:last]) {
        return;
    }
    NSUInteger nextStrokeId = 1;
    if (last) {
        NSPaintStroke *nextStroke = [[NSPaintManager sharePaintManager] nextPaintStrokeForStrokeId:last.strokeId];
        nextStrokeId = nextStroke.strokeId;
    }
    NSUInteger lastStrokeId = last.strokeId;
//    [self clearFrameBuffer];
    
    [self.paintEvent.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger strokeId = [obj unsignedIntegerValue];
        if (strokeId <= lastStrokeId) {
            return ;
        }
        if (strokeId <= nextStrokeId) {
            NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:[obj unsignedIntegerValue]];
            [self renderWithStroke:stroke];
        }
        else {
            *stop = YES;
        }
    }];
    [self presentRenderbuffer];
}

-(void)deletePaint
{
    if (self.isPlaying) {
        [self stopPlay];
    }
    [[NSPaintManager sharePaintManager] deleteEventForEventId:self.paintEvent.eventId];
    [super erase];
}

-(void)deleteLastStroke
{
    if (self.isPlaying) {
        [self stopPlay];
    }
    if (!IS_AVAILABLE_NSSET_OBJ(self.paintEvent.strokeIds)) {
        return;
    }
#if 1
    NSUInteger lastStrokeId = [self _undoLastStroke];
    NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:lastStrokeId];
    [[NSPaintManager sharePaintManager] deletePaintStroke:stroke];
#else
    NSNumber *lastStrokeId = [self.paintEvent.strokeIds lastObject];
    NSInteger lastStrokeIdI = [lastStrokeId integerValue];
    [self clearFrameBuffer];

    [self.paintEvent.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger strokeId = [obj unsignedIntegerValue];
        if (strokeId < lastStrokeIdI) {
            NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:[obj unsignedIntegerValue]];
            [self renderWithStroke:stroke];
        }
        else {
            *stop = YES;
        }
    }];
    [self presentRenderbuffer];
    
     NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:lastStrokeIdI];
    [[NSPaintManager sharePaintManager] deletePaintStroke:stroke];
#endif
}

//-(void)testRender
//{
//    [self clearFrameBuffer];
//
//    [self.paintEvent.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:[obj unsignedIntegerValue]];
////        if (stroke.strokeId <= 1) {
//            [self renderWithStroke:stroke];
////        }
//    }];
//    [self presentRenderbuffer];
//
//}

@end
