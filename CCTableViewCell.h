//
//  CCTableViewCell.h
//  CCTable
//
//  http://www.opensource.org/licenses/mit-license.php
//
//  Created by Sangwoo Im on 6/3/10.
//  Copyright 2010 Sangwoo Im. All rights reserved.
//

@class CCNode;

@interface CCTableViewCell: NSObject {
@private
    CCNode     *node;
    NSUInteger idx;
}
@property (nonatomic, retain) CCNode     *node;
@property (nonatomic, assign) NSUInteger idx;
/**
 * override this! otherwise, cells won't be aligned properly.
 */
+(CGSize)cellSize;
@end
