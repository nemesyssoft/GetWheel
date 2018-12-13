//
//  DetailViewController.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/10/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.nameLabel.text = self.detailItem.name;
        NSString *photoFilename = [NSString stringWithFormat:@"%ld.jpg", (long)self.detailItem.user_id];
        NSURL *photoPath = [APP_DELEGATE.picturesDirectory URLByAppendingPathComponent:photoFilename];
        NSData *imageData = [NSData dataWithContentsOfURL:photoPath];
        UIImage *photoImage = [UIImage imageWithData:imageData];
        self.pictureView.image = photoImage;
        self.reputationLabel.text = [NSString stringWithFormat:@"%lld", self.detailItem.reputation];
        self.goldCountLabel.text = [NSString stringWithFormat:@"%hd", self.detailItem.goldMedals];
        self.silverCountLabel.text = [NSString stringWithFormat:@"%hd", self.detailItem.silverMedals];
        self.bronzeCountLabel.text = [NSString stringWithFormat:@"%hd", self.detailItem.bronzeMedals];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}


#pragma mark - Managing the detail item

- (void)setDetailItem:(Person *)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}


@end
