//
//  UIPaintingView.h
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/1/31.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "GLPaintingView.h"
#import "NSPaintModel.h"

@class UIPaintingView;
@protocol UIPaintViewDelegate <GLPaintingViewDelegate>

@optional;
-(void)paintingView:(UIPaintingView*)paintingView startPlayPaintStroke:(NSPaintStroke*)paintStroke;
-(void)paintingView:(UIPaintingView*)paintingView playingPintStroke:(NSPaintStroke*)paintStroke paintPoint:(NSPaintPoint*)paintPoint;
-(void)paintingView:(UIPaintingView*)paintingView endPlayPaintStroke:(NSPaintStroke*)paintStroke;
@end


@interface UIPaintingView : GLPaintingView

@property (nonatomic, strong) NSPaintEvent *paintEvent;

@property (nonatomic, assign) CGFloat maxLineWidth;

@property (nonatomic, weak) id<UIPaintViewDelegate> delegate;

//播放速率，默认为1.0
@property (nonatomic, assign) CGFloat playRatio;

-(void)renderWithPoint:(NSPaintPoint*)paintPoint;
-(void)renderWithStroke:(NSPaintStroke*)stroke;

-(void)playBack:(BOOL)fromStart;

-(void)stopPlay;

-(void)undo;

-(void)redo;

//删除绘画，连数据也一起删除
-(void)deletePaint;

-(void)deleteLastStroke;

//-(void)testRender;

@end
