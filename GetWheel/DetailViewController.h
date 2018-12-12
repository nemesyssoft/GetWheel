//
//  DetailViewController.h
//  GetWheel
//
//  Created by Laurent Daudelin on 12/10/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person+CoreDataClass.h"

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Person *detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

