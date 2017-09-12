//
//  CCMultiColumnTableView.h
//  CCTable
//
//  http://www.opensource.org/licenses/mit-license.php
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCTableView.h"

/**
 * It adds multiple column support to CCTableView.
 * Use CCScrollViewDirectionBoth to set custom column count, colCount.
 * If a specific direction is set, table automatically find a proper value,
 * computing from viewSize and cellSize.
 */
@interface CCMultiColumnTableView 
:          CCTableView {
    /**
     * the maximum number of columns.
     */
    NSUInteger colCount;
}
/**
 * the maximum number of columns.
 */
@property (nonatomic, assign, setter=setColCount:) NSUInteger colCount;
@end
