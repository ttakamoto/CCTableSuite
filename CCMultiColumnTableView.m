//
//  CCMultiColumnTableView.m
//  CCTable
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCMultiColumnTableView.h"
#import "CCTableViewCell.h"
#import "CGPointExtension.h"

@interface CCTableView ()

-(NSUInteger)_indexFromOffset:(CGPoint)offset;
-(CGPoint)_offsetFromIndex:(NSUInteger)index;
-(void)_updateContentSize;

@end

@implementation CCMultiColumnTableView
@synthesize colCount;

+(id)tableViewWithDataSource:(id<CCTableViewDataSource>)dataSource size:(CGSize)size {
    CCTableView *table;
    table = [[[CCMultiColumnTableView alloc] initWithViewSize:size] autorelease];
    table.dataSource = dataSource;
    [table _updateContentSize];
    return table;
}
-(id)initWithViewSize:(CGSize)size {
    if ((self = [super initWithViewSize:size])) {
        colCount = 1;
    }
    return self;
}
-(void)setColCount:(NSUInteger)cols {
    colCount = cols;
    if (self.direction == CCScrollViewDirectionBoth) {
        [self _updateContentSize];
    } else {
        NSLog(@"%s: %s: You cannot set this value. The value will ignored and overwritten.", __FILE__, __FUNCTION__);
    }
}
-(NSUInteger)_indexFromOffset:(CGPoint)offset {
    NSInteger  index;
    CGSize     cellSize;
    NSUInteger col, row;
    CGFloat    spaceWidth;
    
    cellSize = [[self.dataSource cellClassForTable:self] cellSize];
    
    switch (self.direction) {
        case CCScrollViewDirectionBoth:
            spaceWidth = self.contentSize.width / colCount;
            col        = (offset.x - (spaceWidth - cellSize.width)*0.5)/spaceWidth;
            row        = offset.y / cellSize.height;
            break;
        case CCScrollViewDirectionHorizontal:
            colCount   = self.viewSize.height / cellSize.height;
            spaceWidth = self.viewSize.height / colCount;
            col        = (offset.y - (spaceWidth - cellSize.height)*0.5)/spaceWidth;
            row        = offset.x / cellSize.width;
            break;
        default:
            colCount   = self.viewSize.width / cellSize.width;
            spaceWidth = self.viewSize.width / colCount;
            col        = (offset.x - (spaceWidth - cellSize.width)*0.5)/spaceWidth;
            row        = offset.y / cellSize.height;
            break;
    }
    index = col + row * colCount;
    index = MAX(0, index);
    index = MIN(((NSInteger)[self.dataSource numberOfCellsInTableView:self])-1, index);
    return ((NSUInteger)index);
}
-(CGPoint)_offsetFromIndex:(NSUInteger)index {
    CGPoint    offset;
    CGSize     cellSize;
    CGFloat    spaceWidth;
    NSUInteger col, row;
    
    //CCAssert(index != NSNotFound, @"CCTableView: _offsetFromIndex: invalid index");
    
    cellSize = [[self.dataSource cellClassForTable:self] cellSize];
    switch (self.direction) {
        case CCScrollViewDirectionBoth:
            row        = index / colCount;
            col        = index % colCount;
            spaceWidth = self.contentSize.width / colCount;
            offset     = ccp(col * spaceWidth + (spaceWidth - cellSize.width) * 0.5,
                             row * cellSize.height);
            break;
        case CCScrollViewDirectionHorizontal:
            colCount   = self.viewSize.height / cellSize.height;
            row        = index / colCount;
            col        = index % colCount;
            spaceWidth = self.viewSize.height / colCount;
            offset     = ccp(row * cellSize.height,
                             col * spaceWidth + (spaceWidth - cellSize.width) * 0.5);
            break;
        default:
            colCount   = self.viewSize.width / cellSize.width;
            row        = index / colCount;
            col        = index % colCount;
            spaceWidth = self.viewSize.width / colCount;
            offset     = ccp(col * spaceWidth + (spaceWidth - cellSize.width) * 0.5,
                             row * cellSize.height);
            break;
    }
    
    return offset;
}
-(void)_updateContentSize {
    CGSize     size, cellSize;
    NSUInteger cellCount, rows;
    
    cellSize  = [[self.dataSource cellClassForTable:self] cellSize];
    cellCount = [self.dataSource numberOfCellsInTableView:self];
    switch (self.direction) {
        case CCScrollViewDirectionBoth:
            rows     = ceilf(cellCount/((CGFloat)colCount));
            size     = CGSizeMake(cellSize.width * colCount, rows * cellSize.height);
            break;
        case CCScrollViewDirectionHorizontal:
            colCount = self.viewSize.height / cellSize.height;
            rows     = ceilf(cellCount/((CGFloat)colCount));
            size     = CGSizeMake(rows * cellSize.width, colCount * cellSize.height);
            break;
        default:
            colCount = self.viewSize.width / cellSize.width;
            rows     = ceilf(cellCount/((CGFloat)colCount));
            size     = CGSizeMake(cellSize.width * colCount, rows * cellSize.height);
            break;
    }
    [self setContentSize:size];
}
@end
