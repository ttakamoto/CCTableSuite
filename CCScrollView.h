//
//  CCScrollView.h
//  CCTable
//
//  http://www.opensource.org/licenses/mit-license.php
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCLayer.h"

typedef enum {
    CCScrollViewDirectionHorizontal,
    CCScrollViewDirectionVertical,
    CCScrollViewDirectionBoth
} CCScrollViewDirection;

@class CCScrollView;

@protocol CCScrollViewDelegate
<
          NSObject
>

-(void)scrollViewDidScroll:(CCScrollView *)view;

@end


/**
 * ScrollView support for cocos2d for iphone.
 * It provides scroll view functionalities to cocos2d projects natively.
 *
 * !!!Important!!!
 * If clipToBounds is YES, you must not add scroll views as descendants at any depth.
 */
@interface CCScrollView 
:          CCLayer {
@private
    /**
     * Determiens whether user touch is moved after begin phase.
     */
    BOOL touchMoved_;
    /**
     * max inset point to limit scrolling by touch
     */
    CGPoint maxInset_;
    /**
     * min inset point to limit scrolling by touch
     */
    CGPoint minInset_;
    /**
     * If YES, touches are being moved
     */
    BOOL isDragging_;
    /**
     * Determines whether the scroll view is allowed to bounce or not.
     */
    BOOL bounces_;
    /**
     * Determines whether it clips its children or not.
     */
    BOOL clipToBounds_;
    /**
     * scroll speed
     */
    CGPoint scrollDistance_;
    /**
     * Touch point
     */
    CGPoint touchPoint_;
    /**
     * Container holds scroll view contents
     */
    CCLayer *container_;
    /**
     * size to clip. CCNode boundingBox uses directly contentSize directly.
     * It's semantically different what it actually means to common scroll views.
     * Hence, this scroll view will use a separate size property.
     */
    CGSize viewSize_;
    /**
     * scroll direction
     */
    CCScrollViewDirection direction_;
    /**
     * delegate to respond to scroll event
     */
    id<CCScrollViewDelegate> delegate_;
}
/**
 * scroll view delegate
 */
@property (nonatomic, assign) id<CCScrollViewDelegate> delegate;
/**
 * If YES, the view is being dragged.
 */
@property (nonatomic, assign, readonly) BOOL isDragging;
/**
 * Determines whether the scroll view is allowed to bounce or not.
 */
@property (nonatomic, assign) BOOL bounces;
/**
 * direction allowed to scroll. CCScrollViewDirectionBoth by default.
 */
@property (nonatomic, assign) CCScrollViewDirection direction;
/**
 * If YES, it clips its children to the visible bounds (view size)
 * it is YES by default.
 */
@property (nonatomic, assign) BOOL clipToBounds;
/**
 * Content offset. Note that left-bottom point is the origin
 */
@property (nonatomic, assign) CGPoint contentOffset;
/**
 * ScrollView size which is different from contentSize. This size determines visible 
 * bounding box.
 */
@property (nonatomic, assign, setter=setViewSize:) CGSize viewSize;
/**
 * Returns an autoreleased scroll view object.
 *
 * @param size view size
 * @return autoreleased scroll view object
 */
+(id)scrollViewWithViewSize:(CGSize)size;
/**
 * Returns a scroll view object
 *
 * @param size view size
 * @return scroll view object
 */
-(id)initWithViewSize:(CGSize)size;
/**
 * Sets a new content offset. It ignores max/min offset. It just sets what's given. (just like UIKit's UIScrollView)
 *
 * @param offset new offset
 * @param If YES, the view scrolls to the new offset
 */
-(void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;
/**
 * Returns the current container's minimum offset. You may want this while you animate scrolling by yourself
 */
-(CGPoint)minContainerOffset;
/**
 * Returns the current container's maximum offset. You may want this while you animate scrolling by yourself
 */
-(CGPoint)maxContainerOffset;
@end
