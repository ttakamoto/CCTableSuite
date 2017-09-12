//
//  CCTableView.h
//  CCTable
//
//  http://www.opensource.org/licenses/mit-license.php
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

#import "CCScrollView.h"

@class CCTableViewCell, CCTableView;

/**
 * Sole purpose of this delegate is to single touch event in this version.
 */
@protocol CCTableViewDelegate
/**
 * Delegate to responde touch event
 *
 * @param table table contains the given cell
 * @param cell  cell that is touched
 */
-(void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell;

@end

/**
 * Data source that governs table backend data.
 */
@protocol CCTableViewDataSource
<
          NSObject
>
/**
 * Class to be used in the table. As seen, table supports homogeneous cell type. In addition,
 * all cells must have an equal, fixed size.
 *
 * @param table table to hold the instances of Class
 * @return class of the cell instances
 */
-(Class)cellClassForTable:(CCTableView *)table;
/**
 * a cell instance at a given index
 *
 * @param idx index to search for a cell
 * @return cell found at idx
 */
-(CCTableViewCell *)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx;
/**
 * Returns number of cells in a given table view.
 * 
 * @return number of cells
 */
-(NSUInteger)numberOfCellsInTableView:(CCTableView *)table;

@end


/**
 * UITableView counterpart for cocos2d for iphone.
 *
 * this is a very basic, minimal implementation to bring UITableView-like component into cocos2d world.
 * 
 */
@interface CCTableView 
:          CCScrollView
<
           CCScrollViewDelegate
>{
@private
    /**
     * Determines whether this view is enabled for user interaction
     */
    BOOL isEnabled;
    /**
     * cells that are currently in the table
     */
    NSMutableArray *cellsUsed_;
    /**
     * free list of cells
     */
    NSMutableArray *cellsFreed_;
    /**
     * weak link to the data source object
     */
    id<CCTableViewDataSource> dataSource_;
    /**
     * weak link to the delegate object
     */
    id<CCTableViewDelegate>   tDelegate_;
}
/**
 * Determines whether this view is enabled for user interaction.
 * It controlls all table cells too.
 */
@property (nonatomic, assign, setter=setIsEnabled:) BOOL isEnabled;
/**
 * data source
 */
@property (nonatomic, assign) id<CCTableViewDataSource> dataSource;
/**
 * delegate
 */
@property (nonatomic, assign) id<CCTableViewDelegate> tDelegate;
/**
 * An intialized table view object
 *
 * @param dataSource data source
 * @param size view size
 * @return table view
 */
+(id)tableViewWithDataSource:(id<CCTableViewDataSource>)dataSource size:(CGSize)size;
/**
 * Updates the content of the cell at a given index.
 *
 * @param idx index to find a cell
 */
-(void)updateCellAtIndex:(NSUInteger)idx;
/**
 * Inserts a new cell at a given index
 *
 * @param idx location to insert
 */
-(void)insertCellAtIndex:(NSUInteger)idx;
/**
 * Removes a cell at a given index
 *
 * @param idx index to find a cell
 */
-(void)removeCellAtIndex:(NSUInteger)idx;
/**
 * reloads data from data source.  the view will be refreshed.
 */
-(void)reloadData;
/**
 * Dequeues a free cell if available. nil if not.
 *
 * @return free cell
 */
-(CCTableViewCell *)dequeueCell;
@end
