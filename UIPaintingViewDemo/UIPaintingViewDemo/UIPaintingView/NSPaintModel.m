//
//  NSPaintModel.m
//  UIPaintingViewDemo
//
//  Created by yuan on 2018/2/1.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "NSPaintModel.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, NSTimeActionType)
{
    NSTimeActionTypeTotal   = (1 << 0),
    NSTimeActionTypeFind    = (1 << 1),
    //began，end
    NSTimeActionTypeBE      = (1 << 2),
};

/***********************************************************************
 *GLLinePoint
 ***********************************************************************/
@implementation GLLinePoint

-(instancetype)initWithPoint:(CGPoint)point lineWidth:(CGFloat)lineWidth
{
    self = [super init];
    if (self) {
        self.point = point;
        self.lineWidth = lineWidth;
    }
    return self;
}

@end

/***********************************************************************
 *NSPaintPoint
 ***********************************************************************/
@implementation NSPaintPoint

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.point = [aDecoder decodeCGPointForKey:TYPE_STR(point)];
        self.pressure = [aDecoder decodeDoubleForKey:TYPE_STR(pressure)];
        self.status = [aDecoder decodeIntegerForKey:TYPE_STR(status)];
        self.timeInterval = [aDecoder decodeDoubleForKey:TYPE_STR(timeInterval)];
        self.lineWidth = [aDecoder decodeFloatForKey:TYPE_STR(lineWidth)];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeCGPoint:self.point forKey:TYPE_STR(point)];
    [aCoder encodeDouble:self.pressure forKey:TYPE_STR(pressure)];
    [aCoder encodeInteger:self.status forKey:TYPE_STR(status)];
    [aCoder encodeDouble:self.timeInterval forKey:TYPE_STR(timeInterval)];
    [aCoder encodeFloat:self.lineWidth forKey:TYPE_STR(lineWidth)];
}

-(instancetype)initWithPoint:(CGPoint)point status:(NSPaintStatus)stauts lineWidth:(CGFloat)lineWidth
{
    self = [super init];
    if (self) {
        self.point = point;
        self.status = stauts;
        self.lineWidth = lineWidth;
    }
    return self;
}

-(instancetype)initWithPoint:(CGPoint)point pressure:(CGFloat)pressure status:(NSPaintStatus)stauts timeInterval:(NSTimeInterval)timeInterval
{
    self = [super init];
    if (self) {
        self.point = point;
        self.pressure = pressure;
        self.status = stauts;
        self.timeInterval = timeInterval;
    }
    return self;
}

-(CGFloat)getLineWidth:(CGFloat)maxLineWidth
{
    if (self.lineWidth > 0) {
        return self.lineWidth;
    }
    return self.pressure * maxLineWidth / 100;
}

+(NSTimeInterval)getTimeIntervalFrom:(NSPaintPoint*)from to:(NSPaintPoint*)to
{
    return to.timeInterval - from.timeInterval;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"point=%@,pressure=%f,status=%ld,timerInterval=%f",NSStringFromCGPoint(self.point),self.pressure,self.status,self.timeInterval];
}

@end


/***********************************************************************
 *NSPaintStroke
 *绘画的笔画，单次存入的最小单元
 ***********************************************************************/
@interface NSPaintStroke ()
@property (nonatomic, assign) NSUInteger eventId;

-(void)save;
-(void)deleteFromFile;
+(void)deleteWithEventId:(NSUInteger)eventId strokeId:(NSUInteger)strokeId;

-(NSInteger)getPointIndexForTimeInterval:(NSTimeInterval)timeInterval fromIndex:(NSUInteger)fromIdx toIndex:(NSUInteger)toIdx;
@end

@implementation NSPaintStroke

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.strokeId = [aDecoder decodeIntegerForKey:TYPE_STR(strokeId)];
        self.strokeColor = [aDecoder decodeObjectForKey:TYPE_STR(strokeColor)];
        self.strokePoints = [aDecoder decodeObjectForKey:TYPE_STR(paintStroke)];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.strokeId forKey:TYPE_STR(strokeId)];
    [aCoder encodeObject:self.strokeColor forKey:TYPE_STR(strokeColor)];
    [aCoder encodeObject:self.strokePoints forKey:TYPE_STR(paintStroke)];
}

-(NSMutableArray<NSPaintPoint*>*)strokePoints
{
    if (_strokePoints == nil) {
        _strokePoints = [NSMutableArray array];
    }
    return _strokePoints;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.strokeId = 0;
    }
    return self;
}

-(instancetype)initWithEventId:(NSUInteger)eventId
{
    self = [self init];
    if (self) {
        self.eventId = eventId;
    }
    return self;
}

-(void)addPaintPoint:(NSPaintPoint*)paintPoint
{
    if (paintPoint) {
        [self.strokePoints addObject:paintPoint];        
    }
}

+(NSString*)_saveKey:(NSUInteger)eventId strokeId:(NSUInteger)strokeId
{
    return NEW_STRING_WITH_FORMAT(@"%ld_strokes/%ld",eventId,strokeId);
}

-(void)save
{
    [Utils saveObject:self to:[[self class] _saveKey:self.eventId strokeId:self.strokeId]];
}

-(void)deleteFromFile
{
    [Utils removeObjectFrom:[[self class] _saveKey:self.eventId strokeId:self.strokeId]];
}

+(void)deleteWithEventId:(NSUInteger)eventId strokeId:(NSUInteger)strokeId
{
    [Utils removeObjectFrom:[[self class] _saveKey:eventId strokeId:strokeId]];
}

+(NSPaintStroke*)loadWithEventId:(NSUInteger)eventId strokeId:(NSUInteger)strokeId
{
    id obj = (NSPaintStroke*)[Utils loadObjectFrom:[[self class] _saveKey:eventId strokeId:strokeId]];
    return obj;
}


-(NSTimeInterval)startTimeInterval
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.strokePoints)) {
        return 0;
    }
    NSPaintPoint *first = [self.strokePoints firstObject];
    return first.timeInterval;
}

-(NSTimeInterval)endTimeInterval
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.strokePoints)) {
        return 0;
    }
    NSPaintPoint *last = [self.strokePoints lastObject];
    return last.timeInterval;
}

-(NSTimeInterval)paintTimeInterval
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.strokePoints)) {
        return 0;
    }
    NSTimeInterval time = [self endTimeInterval] - [self startTimeInterval];
    if (time > [NSPaintManager sharePaintManager].pointsMaxTimeInterval) {
        time = [NSPaintManager sharePaintManager].pointsMaxTimeInterval;
    }
    return time;
}

-(NSInteger)getPointIndexForTimeInterval:(NSTimeInterval)timeInterval fromIndex:(NSUInteger)fromIdx toIndex:(NSUInteger)toIdx
{
    NSUInteger findIdx = (fromIdx + toIdx)/2;
    if (findIdx >= self.strokePoints.count) {
        return -1;
    }
    NSPaintPoint *findObj = self.strokePoints[findIdx];
    NSPaintPoint *nextObj = nil;
    if (findIdx + 1 < self.strokePoints.count) {
        nextObj = self.strokePoints[findIdx + 1];
    }
    else {
        return findIdx;
    }
    
    NSPaintPoint *first = self.strokePoints[0];
    NSTimeInterval start = [NSPaintPoint getTimeIntervalFrom:first to:findObj];
    NSTimeInterval end = [NSPaintPoint getTimeIntervalFrom:first to:nextObj];
    if (timeInterval >= start && timeInterval <= end) {
        return findIdx;
    }
    else if (timeInterval < start) {
        return [self getPointIndexForTimeInterval:timeInterval fromIndex:fromIdx toIndex:findIdx];
    }
    else if (timeInterval > end) {
        return [self getPointIndexForTimeInterval:timeInterval fromIndex:findIdx toIndex:toIdx];
    }
    return -1;
    
}

@end


/***********************************************************************
 *NSPaintStroke (PlayBack)
 *回放时需要用到，存储上一次绘制的点
 ***********************************************************************/

@implementation NSPaintStroke (PlayBack)


-(void)setLastPaintPoint:(NSPaintPoint *)lastPaintPoint
{
    objc_setAssociatedObject(self, @selector(lastPaintPoint), lastPaintPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSPaintPoint*)lastPaintPoint
{
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setLastDisplayPoint:(NSPaintPoint *)lastDisplayPoint
{
    objc_setAssociatedObject(self, @selector(lastDisplayPoint), lastDisplayPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSPaintPoint*)lastDisplayPoint
{
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setStartPlayTimeInterval:(NSTimeInterval)startPlayTimeInterval
{
    objc_setAssociatedObject(self, @selector(startPlayTimeInterval), @(startPlayTimeInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSTimeInterval)startPlayTimeInterval
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}


-(void)setEndPlayTimeInterval:(NSTimeInterval)endPlayTimeInterval
{
    objc_setAssociatedObject(self, @selector(endPlayTimeInterval), @(endPlayTimeInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSTimeInterval)endPlayTimeInterval
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

@end

/***********************************************************************
 *NSPaintEvent
 *整个一次画画的所有的笔记
 ***********************************************************************/
@interface NSPaintEvent()
-(NSUInteger)saveWithPaintStroke:(NSPaintStroke*)paintStroke;
-(NSUInteger)deleteWithPaintStroke:(NSPaintStroke*)paintStroke;

-(void)save;

-(void)deleteFromFile;
+(void)deleteWithEventId:(NSUInteger)eventId;
@end

@implementation NSPaintEvent

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.eventId = USEC_FROM_DATE_SINCE1970([NSDate date]);
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.eventId = [aDecoder decodeIntegerForKey:TYPE_STR(eventId)];
        self.strokeIds = [aDecoder decodeObjectForKey:TYPE_STR(strokeIds)];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.eventId forKey:TYPE_STR(eventId)];
    [aCoder encodeObject:self.strokeIds forKey:TYPE_STR(strokeIds)];
}

-(NSMutableArray<NSNumber*>*)strokeIds
{
    if (_strokeIds == nil) {
        _strokeIds = [NSMutableArray array];
    }
    return _strokeIds;
}

-(NSUInteger)saveWithPaintStroke:(NSPaintStroke*)paintStroke
{
    if (paintStroke) {
        if (paintStroke.eventId != self.eventId) {
            return 0;
        }
        
        //不要坚持began和end
//        if (IS_AVAILABLE_NSSET_OBJ(paintStroke.strokePoints)) {
//            NSPaintPoint *first = [paintStroke.strokePoints firstObject];
//            NSPaintPoint *last = [paintStroke.strokePoints lastObject];
//            if (first.status != NSPaintStatusBegan || last.status != NSPaintStatusEnd) {
//                return 0;
//            }
//        }
        
        if (paintStroke.strokeId == 0) {
            NSUInteger strokeId = 1;
            if (IS_AVAILABLE_NSSET_OBJ(self.strokeIds)) {
                NSNumber *last = [self.strokeIds lastObject];
                strokeId = [last unsignedIntegerValue] + 1;
            }
            paintStroke.strokeId = strokeId;
            [self.strokeIds addObject:@(paintStroke.strokeId)];
        }
        else {
            if (![self _haveInForStrokeId:paintStroke.strokeId]) {
                [self.strokeIds addObject:@(paintStroke.strokeId)];
            }
        }
        [paintStroke save];
    }
    [self save];
    return paintStroke.strokeId;
}

-(NSUInteger)deleteWithPaintStroke:(NSPaintStroke*)paintStroke
{
    if (paintStroke) {
        NSInteger strokeId = paintStroke.strokeId;
        [self.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj integerValue] == strokeId) {
                [self.strokeIds removeObject:obj];
            }
        }];
        [paintStroke deleteFromFile];
    }
    [self save];
    return paintStroke.strokeId;
}

+(NSString*)_saveKey:(NSUInteger)eventId
{
    
    return NEW_STRING_WITH_FORMAT(@"event/%ld", eventId);
}

-(BOOL)_haveInForStrokeId:(NSUInteger)strokeId
{
    __block BOOL have = NO;
    [self.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj unsignedIntegerValue] == strokeId) {
            have = YES;
            *stop = YES;
        }
    }];
    return have;
}

-(void)save
{
    [Utils saveObject:self to:[[self class] _saveKey:self.eventId]];
}

-(void)deleteFromFile
{
    [self.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [NSPaintStroke deleteWithEventId:self.eventId strokeId:[obj unsignedIntegerValue]];
    }];
    [Utils removeObjectFrom:[[self class] _saveKey:self.eventId]];
}

+(void)deleteWithEventId:(NSUInteger)eventId
{
    NSPaintEvent *event = [NSPaintEvent loadWithEventId:eventId];
    [event deleteFromFile];
}

+(NSPaintEvent*)loadWithEventId:(NSUInteger)eventId
{
    id obj = (NSPaintEvent*)[Utils loadObjectFrom:[[self class] _saveKey:eventId]];
    return obj;
}

-(NSTimeInterval)getEventTimeInterval
{
    return [self _getEventTimeInterval:NSTimeActionTypeTotal strokeTimeInterval:-1 findStroke:NULL];
}

/*
 *这个接口有如下功能
 *type取如下值
 *1、可以获取总的播放时间(type:1)
 *2、根据timeInterval获取stroke(type:2,timeinterval,stroke:不为空，)
 *3、获取stroke的start和end的timeInterval(type:3,stroke)
 */
-(NSTimeInterval)_getEventTimeInterval:(NSTimeActionType)actionType strokeTimeInterval:(NSTimeInterval)strokeTimeInterval findStroke:(NSPaintStroke**)findStroke
{
    NSTimeInterval totalTimeInterval = 0;
    if (!IS_AVAILABLE_NSSET_OBJ(self.strokeIds)) {
        return totalTimeInterval;
    }
    NSTimeInterval prevTotal = 0;
    NSPaintStroke *findObj = nil;
    
    for (NSNumber *obj in self.strokeIds) {
        NSUInteger strokeId = [obj unsignedIntegerValue];
        
        NSPaintStroke *stroke = [[NSPaintManager sharePaintManager] paintStrokeForStrokeId:strokeId];
        
        prevTotal = totalTimeInterval;
        totalTimeInterval += [stroke paintTimeInterval];
        
        if (TYPE_AND(actionType, NSTimeActionTypeBE)) {
            NSPaintStroke *findTmp = *findStroke;
            if (findTmp && findTmp.strokeId == strokeId) {
                findTmp.startPlayTimeInterval = prevTotal;
                findTmp.endPlayTimeInterval = totalTimeInterval;
            }
        }
        
        NSPaintStroke *nextStroke = [[NSPaintManager sharePaintManager] nextPaintStrokeForStrokeId:stroke.strokeId];
        if (nextStroke) {
            NSTimeInterval freeDiff = [nextStroke startTimeInterval] - [stroke endTimeInterval];
            if (freeDiff > [NSPaintManager sharePaintManager].strokesMaxFreeTimeInterval) {
                freeDiff = [NSPaintManager sharePaintManager].strokesMaxFreeTimeInterval;
            }
            totalTimeInterval += freeDiff;
        }
        
        if (TYPE_AND(actionType, NSTimeActionTypeFind)) {
            if (strokeTimeInterval >= prevTotal && strokeTimeInterval < totalTimeInterval) {
                findObj = stroke;
                if (!TYPE_AND(actionType, NSTimeActionTypeTotal)) {
                    break;
                }
            }
            else if (strokeTimeInterval == totalTimeInterval) {
                if ([self.strokeIds lastObject] == obj) {
                    findObj = stroke;
                }
            }
        }
//        NSLog(@"strokeId=%ld,timeInterval=%f,pt=%f,tt=%f",strokeId,strokeTimeInterval,prevTotal,totalTimeInterval);
    }
    if (findStroke != NULL && TYPE_AND(actionType, NSTimeActionTypeFind)) {
        *findStroke = findObj;
    }
    return totalTimeInterval;
}

//获取落笔播放时间
-(NSTimeInterval)getStartPlayTimeIntervalForStroke:(NSPaintStroke*)stroke
{
    if (stroke == nil) {
        return 0;
    }
    [self _getEventTimeInterval:NSTimeActionTypeBE strokeTimeInterval:-1 findStroke:&stroke];
    return stroke.startPlayTimeInterval;
}

//获取抬笔播放时间
-(NSTimeInterval)getEndPlayTimeIntervalForStroke:(NSPaintStroke*)stroke
{
    if (stroke == nil) {
        return 0;
    }
    [self _getEventTimeInterval:NSTimeActionTypeBE strokeTimeInterval:-1 findStroke:&stroke];
    return stroke.endPlayTimeInterval;
}

-(BOOL)shouldSave
{
    return IS_AVAILABLE_NSSET_OBJ(self.strokeIds);
}

+(NSString*)getEventSnapshotImagePath
{
    NSString *path= [Utils applicationStoreInfoDirectory:TYPE_STR(eventImg)];
//    [Utils checkFileExistsAtPath:path];
    return path;
}

+(NSString*)getEventSnapshotImageNameForEventId:(NSUInteger)eventId
{
    return NEW_STRING_WITH_FORMAT(@"%ld.png",eventId);
}

+(NSString*)getEventSnapshotImageFullPathForEventId:(NSUInteger)eventId
{
    return [[NSPaintEvent getEventSnapshotImagePath] stringByAppendingPathComponent:[NSPaintEvent getEventSnapshotImageNameForEventId:eventId]];
}

@end


/***********************************************************************
 *NSPaintEvent (PlayBack)
 *回放时需要用到，存储上一次绘制的线
 ***********************************************************************/

//static void *key = @"2";

@implementation NSPaintEvent (PlayBack)

-(void)setLastPaintStroke:(NSPaintStroke *)lastPaintStroke
{
    objc_setAssociatedObject(self, @selector(lastPaintStroke), lastPaintStroke, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSPaintStroke*)lastPaintStroke
{
    return objc_getAssociatedObject(self, _cmd);
}

@end



/**************************************************************
 *NSPaintManager
 *************************************************************/
static NSPaintManager *_sharePaintManager_s = nil;
static dispatch_queue_t _paintDataQueue_s = NULL;

@interface NSPaintManager () <NSCacheDelegate>

//在用户登录的时候可以设置不同的storePathPrefix路径来存储不同的用户数据
@property (nonatomic, strong) NSString *storePathPrefix;
//这个其中的key就是eventId，他的Value不重要，现在value也是key中的只。
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,NSNumber*> *allEventIdDict;
//这个存储的是按笔画来的
@property (nonatomic, strong) NSCache *eventMemoryCache;
//当前正在cache的event
@property (nonatomic, strong) NSPaintEvent *cacheEvent;

@end

@implementation NSPaintManager

+(instancetype)sharePaintManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharePaintManager_s = [[super allocWithZone:NULL] init];
        [_sharePaintManager_s _setUpDefaultValue];
    });
    return _sharePaintManager_s;
}

+(id)allocWithZone:(struct _NSZone *)zone
{
    return [NSPaintManager sharePaintManager];
}

-(id)copyWithZone:(struct _NSZone *)zone
{
    return [NSPaintManager sharePaintManager];
}


-(void)_setUpDefaultValue
{
    //没有用户登录时的数据
    self.storePathPrefix = TYPE_STR(public);
    
    [self _loadSelfData];
    
    [self _loadEventIdList];
}

-(void)_loadSelfData
{
//    NSNumber *time = (NSNumber*)[Utils loadObjectFrom:[[self class] _saveKey]];
//    self.strokesMaxFreeTimeInterval = [time doubleValue];
    
    self.pointsMaxTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:TYPE_STR(pointsMaxTimeInterval)];
    self.strokesMaxFreeTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:TYPE_STR(strokesMaxFreeTimeInterval)];
}

-(void)_saveSelfData
{
//    [Utils saveObject:@(self.strokesMaxFreeTimeInterval) to:[[self class] _saveKey]];
    
    [[NSUserDefaults standardUserDefaults] setDouble:self.pointsMaxTimeInterval forKey:TYPE_STR(strokesMaxFreeTimeInterval)];
    [[NSUserDefaults standardUserDefaults] setDouble:self.strokesMaxFreeTimeInterval forKey:TYPE_STR(strokesMaxFreeTimeInterval)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSMutableDictionary<NSNumber*,NSNumber*>*)allEventIdDict
{
    if (_allEventIdDict == nil) {
        _allEventIdDict = [NSMutableDictionary dictionary];
    }
    return _allEventIdDict;
}

-(void)_saveLastCacheEvent
{
    if (self.cacheEvent) {
        NSUInteger eventId = self.cacheEvent.eventId;
        [self.allEventIdDict setObject:@(eventId) forKey:@(eventId)];
    }
    [self.cacheEvent save];
    [self _clearMemoryCache];
}

-(NSCache*)eventMemoryCache
{
    if (_eventMemoryCache == nil) {
        _eventMemoryCache = [[NSCache alloc] init];
        _eventMemoryCache.delegate = self;
        _eventMemoryCache.name = @"EventStrokeCache";
    }
    return _eventMemoryCache;
}

-(NSString*)storePathPrefix
{
    if (!IS_AVAILABLE_NSSTRNG(_storePathPrefix)) {
        _storePathPrefix = TYPE_STR(public);
    }
    return _storePathPrefix;
}

-(NSString*)_eventListSaveKay
{
    return NEW_STRING_WITH_FORMAT(@"PMData/%@_data",self.storePathPrefix);
}

-(void)_loadEventIdList
{
    self.allEventIdDict = (NSMutableDictionary*)[Utils loadObjectFrom:[self _eventListSaveKay]];
}

-(void)_saveEventIdList
{
    [Utils saveObject:self.allEventIdDict to:[self _eventListSaveKay]];
}

-(void)save
{
    [self _saveLastCacheEvent];
    
    [self _saveEventIdList];
        
    [self _saveSelfData];
}

-(void)loadEventIdDataFromPathPrefix:(NSString*)pathPrefix
{
    [self save];
    
    self.storePathPrefix = pathPrefix;
    
    [self _loadEventIdList];
    
    //清除缓存的东西，切换当前cache的event
    [self _clearMemoryCache];
    
    self.cacheEvent = nil;
}

-(NSPaintEvent*)currentCacheEvent
{
    return self.cacheEvent;
}

-(NSPaintEvent*)cacheForNewEvent
{
    NSPaintEvent *event = [[NSPaintEvent alloc] init];
    [self _saveLastCacheEvent];
    self.cacheEvent = event;
    return event;
}

-(NSPaintEvent*)cacheForEventId:(NSUInteger)eventId
{
    if (self.cacheEvent.eventId == eventId) {
        return self.cacheEvent;
    }
    
    //将原来的进行存储
    [self _saveLastCacheEvent];
    
    //加载所有此eventId所有的stroke到cache里面
    NSPaintEvent *event = [NSPaintEvent loadWithEventId:eventId];
    [event.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSPaintStroke *stroke = [NSPaintStroke loadWithEventId:eventId strokeId:[obj unsignedIntegerValue]];
        if (stroke) {
            [self.eventMemoryCache setObject:stroke forKey:@(stroke.strokeId)];
        }
    }];
    self.cacheEvent = event;
    return event;
}

-(void)_clearMemoryCache
{
    self.eventMemoryCache.delegate = nil;
    [self.eventMemoryCache removeAllObjects];
    self.eventMemoryCache.delegate = self;
}

-(void)removeCurrentCacheEvent
{
    [self save];
    [self _clearMemoryCache];
    self.cacheEvent = nil;
}

-(NSUInteger)addPaintStrokeIntoCurrentCache:(NSPaintStroke*)paintStroke
{
    if (!paintStroke) {
        return 0;
    }
    if (self.cacheEvent.eventId != paintStroke.eventId) {
        return 0;
    }
    NSUInteger strokeId = [self.cacheEvent saveWithPaintStroke:paintStroke];
    if (strokeId > 0) {
        [self.eventMemoryCache setObject:paintStroke forKey:@(paintStroke.strokeId)];
    }
//    NSPaintStroke *stroke = [self.eventMemoryCache objectForKey:@(paintStroke.strokeId)];
    return strokeId;
}

-(NSUInteger)deletePaintStroke:(NSPaintStroke*)paintStroke
{
    if (!paintStroke) {
        return 0;
    }
    if (self.cacheEvent.eventId != paintStroke.eventId) {
        return 0;
    }
    NSUInteger strokeId = [self.cacheEvent deleteWithPaintStroke:paintStroke];
    if (strokeId > 0) {
        [self.eventMemoryCache removeObjectForKey:@(paintStroke.strokeId)];
    }
    return strokeId;
}

-(NSPaintStroke*)firstPaintStroke
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.cacheEvent.strokeIds)) {
        return nil;
    }
    NSUInteger strokeId = [[self.cacheEvent.strokeIds firstObject] unsignedIntegerValue];
    return [self paintStrokeForStrokeId:strokeId];
}


-(NSPaintStroke*)lastPaintStroke
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.cacheEvent.strokeIds)) {
        return nil;
    }
    NSUInteger strokeId = [[self.cacheEvent.strokeIds lastObject] unsignedIntegerValue];
    return [self paintStrokeForStrokeId:strokeId];
}


-(NSPaintStroke*)paintStrokeForStrokeId:(NSUInteger)strokeId
{
    if (strokeId == 0) {
        return nil;
    }
    NSPaintStroke *stroke = [self.eventMemoryCache objectForKey:@(strokeId)];
    if (stroke == nil) {
        stroke = [NSPaintStroke loadWithEventId:self.cacheEvent.eventId strokeId:strokeId];
        if (stroke) {
            [self.eventMemoryCache setObject:stroke forKey:@(stroke.strokeId)];
        }
    }
    return stroke;
}

-(NSUInteger)_getStrokeIdForCurrentStrokeId:(NSUInteger)strokeId isNext:(BOOL)isNext
{
    __block BOOL haveFind = NO;
    __block NSUInteger findIdx = 0;
    [self.cacheEvent.strokeIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj unsignedIntegerValue] == strokeId) {
            findIdx = idx;
            haveFind = YES;
            *stop = YES;
        }
    }];
    if (haveFind == NO) {
        return 0;
    }
    NSUInteger retStrokeId = 0;
    if (isNext) {
        NSUInteger newIdx = findIdx + 1;
        if (newIdx >= self.cacheEvent.strokeIds.count) {
            return 0;
        }
        retStrokeId = [self.cacheEvent.strokeIds[newIdx] unsignedIntegerValue];
    }
    else {
        if (findIdx == 0) {
            return 0;
        }
        retStrokeId = [self.cacheEvent.strokeIds[findIdx-1] unsignedIntegerValue];
    }
    return retStrokeId;
}

//从当前的strokeId获取下一个paintStroke
-(NSPaintStroke*)nextPaintStrokeForStrokeId:(NSUInteger)strokeId
{
    NSUInteger newStrokeId = [self _getStrokeIdForCurrentStrokeId:strokeId isNext:YES];
    return [self paintStrokeForStrokeId:newStrokeId];
}

//从当前的strokeId获取上一个paintStroke
-(NSPaintStroke*)prevPaintStrokeForStrokeId:(NSUInteger)strokeId
{
    NSUInteger newStrokeId = [self _getStrokeIdForCurrentStrokeId:strokeId isNext:NO];
    return [self paintStrokeForStrokeId:newStrokeId];
}


//是否是第一笔
-(BOOL)isFirstPaintStroke:(NSPaintStroke*)stroke
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.cacheEvent.strokeIds)) {
        return NO;
    }
    NSUInteger strokeId = [[self.cacheEvent.strokeIds firstObject] unsignedIntegerValue];
    if (stroke.strokeId == strokeId) {
        return YES;
    }
    return NO;
}

//是否是最后一笔
-(BOOL)isLastPaintStroke:(NSPaintStroke*)stroke
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.cacheEvent.strokeIds)) {
        return NO;
    }
    NSUInteger strokeId = [[self.cacheEvent.strokeIds lastObject] unsignedIntegerValue];
    if (stroke.strokeId == strokeId) {
        return YES;
    }
    return NO;
}

-(NSPaintStroke*)getStrokeForTimeInterval:(NSTimeInterval)timeInterval paintPointIndex:(NSUInteger*)paintPointIndex
{
    if (!IS_AVAILABLE_NSSET_OBJ(self.cacheEvent.strokeIds)) {
        return nil;
    }
    NSPaintStroke *stroke = nil;
    [self.cacheEvent _getEventTimeInterval:NSTimeActionTypeFind strokeTimeInterval:timeInterval findStroke:&stroke];
    
    if (paintPointIndex != NULL) {
        NSTimeInterval start = [self.cacheEvent getStartPlayTimeIntervalForStroke:stroke];
        timeInterval = timeInterval - start;
        NSInteger idex = [stroke getPointIndexForTimeInterval:timeInterval fromIndex:0 toIndex:stroke.strokePoints.count-1];
        if (paintPointIndex) {
            *paintPointIndex = idex;
        }
    }
    
    return stroke;
}

//移除掉当前的cacheEvent
-(void)deleteCurrentCacheEvent
{
    [self deleteEventForEventId:self.cacheEvent.eventId];
}

//根据eventId移除Event
-(void)deleteEventForEventId:(NSUInteger)eventId
{
    if (eventId == self.cacheEvent.eventId) {
        [self _clearMemoryCache];
        self.cacheEvent = nil;
    }
    [NSPaintEvent deleteWithEventId:eventId];
    [self.allEventIdDict removeObjectForKey:@(eventId)];
    [self save];
}

-(NSArray<NSNumber*>*)getAllEventId
{
    return [self.allEventIdDict allKeys];
}

+(dispatch_queue_t)_dataExecuteQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _paintDataQueue_s = dispatch_queue_create("paintDataQueue", DISPATCH_QUEUE_SERIAL);
    });
    return _paintDataQueue_s;
}

-(void)_addDataExecute:(DataExecuteBlock)executeBlock inQueue:(dispatch_queue_t)queue completionBlock:(DataExecuteCompletionBlock)completionBlock
{
    dispatch_async(queue, ^{
        id retObj = nil;
        if (executeBlock) {
            retObj = executeBlock();
        }
        if (completionBlock) {
            dispatch_async_in_main_queue(^{
                completionBlock(retObj);
            });
        }
    });
}

-(void)addDataExecuteBlock:(DataExecuteBlock)executeBlock completionBlock:(DataExecuteCompletionBlock)completionBlock
{
    [self _addDataExecute:executeBlock inQueue:[[self class] _dataExecuteQueue] completionBlock:completionBlock];
}

#pragma mark NSCacheDelegate
-(void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    NSPaintStroke *stroke = obj;
    
    [stroke save];
}
@end

