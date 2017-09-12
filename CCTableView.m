//
//  CCTableView.m
//  CCTable
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCTableView.h"
#import "CCTableViewCell.h"
#import "CCMenu.h"
#import "CGPointExtension.h"
#import "CCLayer.h"

@interface CCScrollView()
@property (nonatomic, assign) BOOL    touchMoved_;
@property (nonatomic, retain) CCLayer *container_;
@property (nonatomic, assign) CGPoint touchPoint_;

@end

@interface CCTableView ()

-(NSUInteger)_indexFromOffset:(CGPoint)offset;
-(CGPoint)_offsetFromIndex:(NSUInteger)index;
-(void)_updateContentSize;

@end

@interface CCTableView (Private)
- (CCTableViewCell *)_cellWithIndex:(NSUInteger)cellIndex;
- (void)_moveCellOutOfSight:(CCTableViewCell *)cell;
- (void)_evictCell;
- (void)_setIndex:(NSUInteger)index forCell:(CCTableViewCell *)cell;
- (void)_addCellIfNecessary:(CCTableViewCell *)cell;
@end

@implementation CCTableView
@synthesize tDelegate  = tDelegate_;
@synthesize dataSource = dataSource_;
@synthesize isEnabled;

+(id)tableViewWithDataSource:(id<CCTableViewDataSource>)dataSource size:(CGSize)size {
    CCTableView *table;
    table = [[[CCTableView alloc] initWithViewSize:size] autorelease];
    table.dataSource = dataSource;
    [table _updateContentSize];
    return table;
}
+(id)scrollViewWithViewSize:(CGSize)size {
    CCLOG(@"%s: %s: You can not use this method", __FILE__, __FUNCTION__);
    return nil;
}
-(id)initWithViewSize:(CGSize)size {
    if ((self = [super initWithViewSize:size])) {
        cellsUsed_      = [NSMutableArray new];
        cellsFreed_     = [NSMutableArray new];
        isEnabled       = YES;
        tDelegate_      = nil;
        self.direction  = CCScrollViewDirectionVertical;
        
        [super setDelegate:self];
    }
    return self;
}
#pragma mark -
#pragma mark properties
-(void)setDelegate:(id<CCScrollViewDelegate>)delegate {
    if (delegate) {
        CCLOG(@"%s: %s: you cannot set this delegate. use tDelegate instead.", __FILE__, __FUNCTION__);
    }
}
#pragma mark -
#pragma mark public
-(void)reloadData {
    NSAutoreleasePool *pool;
    
    pool = [NSAutoreleasePool new];
    for (CCTableViewCell *cell in cellsUsed_) {
        [cellsFreed_ addObject:cell];
        cell.idx            = NSNotFound;
        cell.node.visible   = NO;
    }
    [cellsUsed_ release];
    cellsUsed_ = [NSMutableArray new];
    
    if ([dataSource_ numberOfCellsInTableView:self] > 0) {
        [self scrollViewDidScroll:self];
    }
    [self _updateContentSize];
    [pool drain];
}
-(void)updateCellAtIndex:(NSUInteger)idx {
    if (idx == NSNotFound || idx > [dataSource_ numberOfCellsInTableView:self]-1) {
        CCLOG(@"%s: %s: invalid index", __FILE__, __FUNCTION__);
        return;
    }
    
    NSAutoreleasePool *pool;
    CCTableViewCell   *cell;
    
    pool = [NSAutoreleasePool new];
    cell = [self _cellWithIndex:idx];
    if (cell) {
        [self _moveCellOutOfSight:cell];
    } 
    cell = [dataSource_ table:self cellAtIndex:idx];
    [self _addCellIfNecessary:cell];
    [self _setIndex:idx forCell:cell];
    [cellsUsed_ addObject:cell];
    [pool drain];
}
-(void)insertCellAtIndex:(NSUInteger)idx {
    if (idx == NSNotFound || idx > [dataSource_ numberOfCellsInTableView:self]-1) {
        CCLOG(@"%s: %s: invalid index", __FILE__, __FUNCTION__);
        return;
    }
    NSAutoreleasePool *pool;
    NSArray           *movingCells;
    NSPredicate       *pred;
    CCTableViewCell   *cell = nil;
    NSUInteger        newIdx;
    
    pool        = [NSAutoreleasePool new];
    pred        = [NSPredicate predicateWithFormat:@"idx >= %i",idx];
    movingCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    //Pushing existing cells down.
    for (CCTableViewCell *tCell in movingCells) {
        newIdx = cell.idx + 1;
        [self _setIndex:newIdx forCell:tCell];
    }
    
    //insert a new cell
    cell = [dataSource_ table:self cellAtIndex:idx];
    [self _addCellIfNecessary:cell];
    [self _setIndex:idx forCell:cell];
    [cellsUsed_ addObject:cell];
    
    [self _updateContentSize];
    [pool drain];
}
-(void)removeCellAtIndex:(NSUInteger)idx {
    if (idx == NSNotFound || idx > [dataSource_ numberOfCellsInTableView:self]-1) {
        CCLOG(@"%s: %s: invalid index", __FILE__, __FUNCTION__);
        return;
    }
    
    CCTableViewCell   *cell;
    NSAutoreleasePool *pool;
    NSUInteger        newIdx;
    NSArray           *movingCells;
    NSPredicate       *pred;
    
    pool = [NSAutoreleasePool new];
    cell = [self _cellWithIndex:idx];
    if (!cell) {
        [pool drain];
        return;
    }
    //remove first
    [self _moveCellOutOfSight:cell];
    
    //pulling cells up
    pred        = [NSPredicate predicateWithFormat:@"idx > %i", idx];
    movingCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    for (cell in movingCells) {
        newIdx = cell.idx - 1;
        [self _setIndex:newIdx forCell:cell];
    }
    
    [pool drain];
}
-(CCTableViewCell *)dequeueCell {
    CCTableViewCell *cell;
    
    [self _evictCell];
    if ([cellsFreed_ count] == 0) {
        cell = nil;
    } else {
        cell = [[cellsFreed_ objectAtIndex:0] retain];
        [cellsFreed_ removeObjectAtIndex:0];
    }
    return [cell autorelease];
}
#pragma mark -
#pragma mark private
- (void)_addCellIfNecessary:(CCTableViewCell *)cell {
    if (cell.node.parent != self.container_) {
        //CCAssert(!cell.node.parent, @"CCTableView: _addCellIfNecessary: cell from another table view is returned from data source");
        [self.container_ addChild:cell.node];
    }
}
- (void)_updateContentSize {
    CGSize     size, cellSize;
    NSUInteger cellCount;
    
    cellSize  = [[dataSource_ cellClassForTable:self] cellSize];
    cellCount = [dataSource_ numberOfCellsInTableView:self];
    
    switch (self.direction) {
        case CCScrollViewDirectionHorizontal:
            size = CGSizeMake(cellCount * cellSize.width, self.viewSize.height);
            if (size.width < self.viewSize.width) {
                size.width = self.viewSize.width;
            }
            break;
        default:
            size = CGSizeMake(self.viewSize.width, cellCount * cellSize.height);
            if (size.height < self.viewSize.height) {
                size.height = self.viewSize.height;
            }
            break;
    }
    [self setContentSize:size];
}
- (CGPoint)_offsetFromIndex:(NSUInteger)index {
    CGPoint offset;
    CGSize  cellSize;
    
    //CCAssert(index != NSNotFound, @"CCTableView: _offsetFromIndex: invalid index");
    
    cellSize = [[dataSource_ cellClassForTable:self] cellSize];
    switch (self.direction) {
        case CCScrollViewDirectionHorizontal:
            offset = ccp(cellSize.width * index, 0.0f);
            break;
        default:
            offset = ccp(0.0f, cellSize.height * index);
            break;
    }
    
    return offset;
}
- (NSUInteger)_indexFromOffset:(CGPoint)offset {
    NSInteger  index;
    CGSize     cellSize;
    
    cellSize = [[dataSource_ cellClassForTable:self] cellSize];
    
    switch (self.direction) {
        case CCScrollViewDirectionHorizontal:
            index = offset.x/cellSize.width;
            break;
        default:
            index = offset.y/cellSize.height;
            break;
    }
    
    index = MAX(0, index);
    index = MIN(((NSInteger)[dataSource_ numberOfCellsInTableView:self])-1, index);
    return ((NSUInteger)index);
}
- (CCTableViewCell *)_cellWithIndex:(NSUInteger)cellIndex {
    CCTableViewCell   *cell;
    NSPredicate       *pred;
    NSAutoreleasePool *pool;
    NSArray           *array;
    
    pool  = [NSAutoreleasePool new];
    pred  = [NSPredicate predicateWithFormat:@"idx == %i", cellIndex];
    array = [cellsUsed_ filteredArrayUsingPredicate:pred];
    cell  = nil;
    
    if (array && [array count] > 0) {
        if ([array count] > 1) {
            CCLOG(@"%s: %s: duplicate cells at index, %i", __FILE__, __FUNCTION__, cellIndex);
        }
        cell = [array objectAtIndex:0];
    }
    [pool drain];
    return cell;
}
- (void)_moveCellOutOfSight:(CCTableViewCell *)cell {
    [cellsFreed_ addObject:cell];
    [cellsUsed_ removeObject:cell];
    [self.container_ removeChild:cell.node cleanup:YES];
    cell.idx       = NSNotFound;
    cell.node      = nil;
}
- (void)_evictCell {
    if ([cellsFreed_ count] > 0) {
        return;
    }
    NSUInteger        startIdx, endIdx;
    CGSize            cellSize;
    NSArray           *clippedCells;
    CGPoint           offset;
    NSPredicate       *pred;
    NSAutoreleasePool *pool;
    
    pool     = [NSAutoreleasePool new];
    offset   = [self contentOffset];
    offset   = ccp(-offset.x, -offset.y);
    cellSize = [[dataSource_ cellClassForTable:self] cellSize];
    startIdx = [self _indexFromOffset:offset];
    
    switch (self.direction) {
        case CCScrollViewDirectionHorizontal:
            offset.x += self.viewSize.width;
            offset.y =  self.viewSize.height;
            break;
        default:
            offset.x =  self.viewSize.width;
            offset.y += self.viewSize.height;
            break;
    }
    endIdx = [self _indexFromOffset:offset];
    
    pred         = [NSPredicate predicateWithFormat:@"idx < %i",startIdx];
    clippedCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    for (CCTableViewCell *cell in clippedCells) {
        [self _moveCellOutOfSight:cell];
    }
    
    pred         = [NSPredicate predicateWithFormat:@"idx > %i", endIdx];
    clippedCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    for (CCTableViewCell *cell in clippedCells) {
        [self _moveCellOutOfSight:cell];
    }
    [pool drain];
}
- (void)_setIndex:(NSUInteger)index forCell:(CCTableViewCell *)cell {
    CGPoint    offset;
    CGSize     cellSize;
    CCNode     *item;
    //CCAssert(cell != nil, @"CCTableView: _setIndex:forCell: cell is nil!");
    
    offset   = [self _offsetFromIndex:index];
    cellSize = [[dataSource_ cellClassForTable:self] cellSize];
    
    if (!CGSizeEqualToSize(cell.node.contentSize, cellSize)) {
        CCLOG(@"%s: %s: inconsistent cell size", __FILE__, __FUNCTION__);
    }
    
    item             = cell.node;
    item.anchorPoint = ccp(0.0f, 0.0f);
    item.position    = offset;
    cell.idx         = index;
}
#pragma mark -
#pragma mark scrollView
-(void)scrollViewDidScroll:(CCScrollView *)view {
    NSUInteger        startIdx, endIdx;
    CGSize            cellSize;
    NSArray           *clippedCells;
    CGPoint           offset;
    NSPredicate       *pred;
    NSAutoreleasePool *pool;
    
    pool     = [NSAutoreleasePool new];
    offset   = [self contentOffset];
    offset   = ccp(-offset.x, -offset.y);
    cellSize = [[dataSource_ cellClassForTable:self] cellSize];
    startIdx = [self _indexFromOffset:offset];
    
    switch (self.direction) {
        case CCScrollViewDirectionHorizontal:
            offset.x += self.viewSize.width;
            offset.y =  self.viewSize.height;
            break;
        default:
            offset.x =  self.viewSize.width;
            offset.y += self.viewSize.height;
            break;
    }
    endIdx = [self _indexFromOffset:offset];
    
    pred         = [NSPredicate predicateWithFormat:@"idx < %i",startIdx];
    clippedCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    for (CCTableViewCell *cell in clippedCells) {
        [self _moveCellOutOfSight:cell];
    }
    
    pred         = [NSPredicate predicateWithFormat:@"idx > %i", endIdx];
    clippedCells = [cellsUsed_ filteredArrayUsingPredicate:pred];
    
    for (CCTableViewCell *cell in clippedCells) {
        [self _moveCellOutOfSight:cell];
    }
    
    for (NSUInteger i=startIdx; i <= endIdx; i++) {
        if ([self _cellWithIndex:i]) {
            continue;
        }
        [self updateCellAtIndex:i];
    }
    NSLog(@"%s: %s: cells in use: %i", __FILE__, __FUNCTION__, [cellsUsed_ count]);
    NSLog(@"%s: %s: cells in free list: %i", __FILE__, __FUNCTION__, [cellsFreed_ count]);
    [pool drain];
}
#pragma mark -
#pragma mark Touch events
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.visible) {
        return;
    }
    if ([touches count] == 1 && !self.touchMoved_ &&
        !CGPointEqualToPoint(ccp(-1.0f, -1.0f), self.touchPoint_) &&
        isEnabled) {
        CGPoint           localPoint;
        NSUInteger        index;
        CCTableViewCell   *cell;
        
        localPoint = [self contentOffset];
        localPoint = ccpAdd(ccp(-localPoint.x, -localPoint.y), self.touchPoint_);
        index      = [self _indexFromOffset:localPoint];
        cell       = [self _cellWithIndex:index];
        
        //CCAssert(cell, @"CCTableView: no cell exists with that index");
        
        [tDelegate_ table:self cellTouched:cell];
    }
    [super ccTouchesEnded:touches withEvent:event];
}
#pragma mark -
#pragma mark dealloc

-(void)dealloc {
    [cellsUsed_  release];
    [cellsFreed_ release];
    [super dealloc];
}
@end
