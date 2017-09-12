//
//  CCScrollView.m
//  CCTable
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCScrollView.h"
#import "CCActionInterval.h"
#import "CCActionInstant.h"
#import "CGPointExtension.h"
#import "CCTouchDispatcher.h"
#import "CCDirector.h"
#import "cocos2d.h"
#import <OpenGLES/ES1/gl.h>

#define SCROLL_DEACCEL_RATE  0.95f
#define SCROLL_DEACCEL_DIST  1.0f
#define BOUNCE_DURATION      0.35f
#define BOUNCE_STEP          0.1
#define INSET_RATIO          0.3f

@interface CCScrollView()
/**
 * container is a protected property
 */
@property (nonatomic, retain) CCLayer *container_;
/**
 * initial touch point
 */
@property (nonatomic, assign) CGPoint touchPoint_;
/**
 * determines whether touch is moved after begin phase
 */
@property (nonatomic, assign) BOOL    touchMoved_;
@end

@interface CCScrollView (Private)

/**
 * Init this object with a given size to clip its content.
 *
 * @param size view size
 * @return initialized scroll view object
 */
-(id)initWithViewSize:(CGSize)size;
/**
 * Relocates the container at the proper offset, in bounds of max/min offsets.
 *
 * @param animated If YES, relocation is animated
 */
-(void)relocateContainer:(BOOL)animated;
/**
 * implements auto-scrolling behavior. change SCROLL_DEACCEL_RATE as needed to choose
 * deacceleration speed. it must be less than 1.0f.
 *
 * @param dt delta
 */
-(void)deaccelerateScrolling:(ccTime)dt;
/**
 * This method makes sure auto scrolling causes delegate to invoke its method
 */
-(void)performedAnimatedScroll:(ccTime)dt;
/**
 * Expire animated scroll delegate calls
 */
-(void)stoppedAnimatedScroll:(CCNode *)node;

@end


@implementation CCScrollView
@synthesize direction     = direction_;
@synthesize clipToBounds  = clipToBounds_;
@synthesize viewSize      = viewSize_;
@synthesize bounces       = bounces_;
@synthesize isDragging    = isDragging_;
@synthesize delegate      = delegate_;
@synthesize touchPoint_;
@synthesize touchMoved_;
@synthesize container_;

@dynamic contentOffset;

#pragma mark -
#pragma mark init
+(id)scrollViewWithViewSize:(CGSize)size {
    return [[[CCScrollView alloc] initWithViewSize:size] autorelease];
}
-(id)initWithViewSize:(CGSize)size {
    if ((self = [super init])) {
        self.container_  = [CCLayer node];
        self.viewSize    = size;
        
        delegate_              = nil;
        bounces_               = YES;
        clipToBounds_          = YES;
        container_.contentSize = CGSizeZero;
        direction_             = CCScrollViewDirectionBoth;
        container_.position    = ccp(0.0f, 0.0f);
        
        [self addChild:container_];
        [[[CCDirector sharedDirector] touchDispatcher] addStandardDelegate:self priority:0];
    }
    return self;
}
-(id)init {
    //CCAssert(NO, @"CCScrollView: DO NOT initialize CCScrollview directly.");
    return nil;
}
- (void) cleanup {
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}
#pragma mark -
#pragma mark Properties
-(void)setContentOffset:(CGPoint)offset {
    [self setContentOffset:offset animated:NO];
}
-(void)setContentOffset:(CGPoint)offset animated:(BOOL)animated {
    if (animated) { //animate scrolling
        NSAutoreleasePool  *pool;
        CCFiniteTimeAction *scroll, *expire;
        
        pool   = [NSAutoreleasePool new];
        scroll = [CCMoveTo actionWithDuration:BOUNCE_DURATION position:offset];
        expire = [CCCallFunc actionWithTarget:self selector:@selector(stoppedAnimatedScroll:)];
        [container_ runAction:[CCSequence actions:scroll, expire, nil]];
        [self schedule:@selector(performedAnimatedScroll:)];
        [pool drain];
    } else { //set the container position directly
        container_.position = offset;
        [delegate_ scrollViewDidScroll:self];
    }
}
-(CGPoint)contentOffset {
    return container_.position;
}
-(void)setViewSize:(CGSize)size {
    if (!CGSizeEqualToSize(viewSize_, size)) {
        viewSize_ = size;
        maxInset_ = [self maxContainerOffset];
        maxInset_ = ccp(maxInset_.x + viewSize_.width * INSET_RATIO,
                        maxInset_.y + viewSize_.height * INSET_RATIO);
        minInset_ = [self minContainerOffset];
        minInset_ = ccp(minInset_.x - viewSize_.width * INSET_RATIO,
                        minInset_.y - viewSize_.height * INSET_RATIO);
    }
}
#pragma mark -
#pragma mark Private
-(void)relocateContainer:(BOOL)animated {
    CGPoint oldPoint, min, max;
    CGFloat newX, newY;
    
    min = [self minContainerOffset];
    max = [self maxContainerOffset];
    
    oldPoint = container_.position;
    newX     = MIN(oldPoint.x, max.x);
    newX     = MAX(newX, min.x);
    newY     = MIN(oldPoint.y, max.y);
    newY     = MAX(newY, min.y);
    if (newY != oldPoint.y || newX != oldPoint.x) {
        [self setContentOffset:ccp(newX, newY) animated:animated];
    }
}
-(CGPoint)maxContainerOffset {
    return ccp(0.0f, 0.0f);
}
-(CGPoint)minContainerOffset {
    return ccp(viewSize_.width - self.contentSize.width, viewSize_.height - self.contentSize.height);
}
-(void)deaccelerateScrolling:(ccTime)dt {
    if (isDragging_) {
        [self unschedule:@selector(deaccelerateScrolling:)];
        return;
    }
    
    CGFloat newX, newY;
    CGPoint maxInset, minInset;
    
    container_.position = ccpAdd(container_.position, scrollDistance_);
    
    if (bounces_) {
        maxInset = maxInset_;
        minInset = minInset_;
    } else {
        maxInset = [self maxContainerOffset];
        minInset = [self minContainerOffset];
    }
    
    //check to see if offset lies within the inset bounds
    newX     = MIN(container_.position.x, maxInset.x);
    newX     = MAX(newX, minInset.x);
    newY     = MIN(container_.position.y, maxInset.y);
    newY     = MAX(newY, minInset.y);
    
    scrollDistance_     = ccpSub(scrollDistance_, ccp(newX - container_.position.x, newY - container_.position.y));
    scrollDistance_     = ccpMult(scrollDistance_, SCROLL_DEACCEL_RATE);
    [self setContentOffset:ccp(newX,newY)];
    
    if ((fabsf(scrollDistance_.x) <= SCROLL_DEACCEL_DIST &&
         fabsf(scrollDistance_.y) <= SCROLL_DEACCEL_DIST) ||
        newX == maxInset.x || newX == minInset.x ||
        newY == maxInset.y || newY == minInset.y) {
        [self unschedule:@selector(deaccelerateScrolling:)];
        [self relocateContainer:YES];
    }
}
-(void)stoppedAnimatedScroll:(CCNode *)node {
    [self unschedule:@selector(performedAnimatedScroll:)];
}
-(void)performedAnimatedScroll:(ccTime)dt {
    if (isDragging_) {
        [self unschedule:@selector(performedAnimatedScroll:)];
        return;
    }
    [delegate_ scrollViewDidScroll:self];
}
#pragma mark -
#pragma mark overriden
-(CGSize)contentSize {
    return CGSizeMake(self.scaleX * container_.contentSize.width, self.scaleY * container_.contentSize.height); 
}
-(void)setContentSize:(CGSize)size {
    container_.contentSize = size;
    maxInset_ = [self maxContainerOffset];
    maxInset_ = ccp(maxInset_.x + viewSize_.width * INSET_RATIO,
                    maxInset_.y + viewSize_.height * INSET_RATIO);
    minInset_ = [self minContainerOffset];
    minInset_ = ccp(minInset_.x - viewSize_.width * INSET_RATIO,
                    minInset_.y - viewSize_.height * INSET_RATIO);
}
/**
 * make sure all children go to the container
 */
-(void) addChild:(CCNode *)node  z:(int)z tag:(int)aTag {
    node.ignoreAnchorPointForPosition = NO;
    node.anchorPoint           = ccp(0.0f, 0.0f);
    if (container_ != node) {
        [container_ addChild:node z:z tag:aTag];
    } else {
        [super addChild:node z:z tag:aTag];
    }
}

/**
 * clip this view so that outside of the visible bounds can be hidden.
 */
-(void)beforeDraw {
    if (clipToBounds_) {
        GLfloat planeTop[]    = {0.0f, -1.0f, 0.0f, viewSize_.height};
        GLfloat planeBottom[] = {0.0f, 1.0f, 0.0f, 0.0f};
        GLfloat planeLeft[]   = {1.0f, 0.0f, 0.0f, 0.0f};
        GLfloat planeRight[]  = {-1.0f, 0.0f, 0.0f, viewSize_.width};
        
        glClipPlanef(GL_CLIP_PLANE0, planeTop);
        glClipPlanef(GL_CLIP_PLANE1, planeBottom);
        glClipPlanef(GL_CLIP_PLANE2, planeLeft);
        glClipPlanef(GL_CLIP_PLANE3, planeRight);
        glEnable(GL_CLIP_PLANE0);
        glEnable(GL_CLIP_PLANE1);
        glEnable(GL_CLIP_PLANE2);
        glEnable(GL_CLIP_PLANE3);
    }
}
/**
 * retract what's done in beforeDraw so that there's no side effect to
 * other nodes.
 */
-(void)afterDraw {
    if (clipToBounds_) {
        glDisable(GL_CLIP_PLANE0);
        glDisable(GL_CLIP_PLANE1);
        glDisable(GL_CLIP_PLANE2);
        glDisable(GL_CLIP_PLANE3);
    }
}
#pragma mark -
#pragma mark touch events
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.visible) {
        return;
    }
    CGRect frame;
    
    frame = CGRectMake(self.position.x, self.position.y, viewSize_.width, viewSize_.height);
    //dispatch does not know about clipping. reject touches outside visible bounds.
    for (UITouch *touch in [touches allObjects]) {
        if (!CGRectContainsPoint(frame, [self convertToWorldSpace:[self convertTouchToNodeSpace:touch]])) {
            touchPoint_ = ccp(-1.0f, -1.0f); 
            isDragging_ = NO;
            return;
        }
    }
    
    if ([touches count] == 1) { // scrolling
        touchPoint_ = [self convertTouchToNodeSpace:[touches anyObject]];
    } else { // 2 or more touches would mean something else?
        //invalidate initial values
        touchPoint_ = ccp(-1.0f, -1.0f);
    } 
    touchMoved_     = NO;
    isDragging_     = YES; //dragging started
    scrollDistance_ = ccp(0.0f, 0.0f);
}
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.visible) {
        return;
    }
    touchMoved_ = YES;
    if ([touches count] == 1 && !CGPointEqualToPoint(ccp(-1.0f,-1.0f), touchPoint_) && isDragging_) { // scrolling
        CGPoint moveDistance, newPoint, maxInset, minInset;
        CGRect  frame;
        CGFloat newX, newY;
        
        frame        = CGRectMake(self.position.x, self.position.y, viewSize_.width, viewSize_.height);
        newPoint     = [self convertTouchToNodeSpace:[touches anyObject]];
        moveDistance = ccpSub(newPoint, touchPoint_);
        touchPoint_  = newPoint;
        
        if (CGRectContainsPoint(frame, [self convertToWorldSpace:newPoint])) {
            switch (direction_) {
                case CCScrollViewDirectionVertical:
                    moveDistance = ccp(0.0f, moveDistance.y);
                    break;
                case CCScrollViewDirectionHorizontal:
                    moveDistance = ccp(moveDistance.x, 0.0f);
                    break;
                default:
                    break;
            }
            container_.position = ccpAdd(container_.position, moveDistance);
            
            if (bounces_) {
                maxInset = maxInset_;
                minInset = minInset_;
            } else {
                maxInset = [self maxContainerOffset];
                minInset = [self minContainerOffset];
            }
            
            //check to see if offset lies within the inset bounds
            newX     = MIN(container_.position.x, maxInset.x);
            newX     = MAX(newX, minInset.x);
            newY     = MIN(container_.position.y, maxInset.y);
            newY     = MAX(newY, minInset.y);
            
            scrollDistance_     = ccpSub(moveDistance, ccp(newX - container_.position.x, newY - container_.position.y));
            [self setContentOffset:ccp(newX, newY)];
        }
    }
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.visible) {
        return;
    }
    isDragging_ = NO;
    if ([touches count] == 1 && !CGPointEqualToPoint(ccp(-1.0f,-1.0f), touchPoint_) && touchMoved_) {
        [self schedule:@selector(deaccelerateScrolling:)];
    }
}
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.visible) {
        return;
    }
    [self ccTouchesEnded:touches withEvent:event];
}
@end
