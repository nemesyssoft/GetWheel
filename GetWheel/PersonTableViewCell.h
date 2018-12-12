//
//  PersonTableViewCell.h
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PersonTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *pictureView;
@property (nonatomic, strong) IBOutlet UILabel *medalCountLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;

@end

NS_ASSUME_NONNULL_END
