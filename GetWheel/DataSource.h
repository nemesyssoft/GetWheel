//
//  DataSource.h
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataSource : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (id)sharedDataSource;
- (NSInteger)personCount;
- (void)savePersons:(NSArray *)persons;

@end

NS_ASSUME_NONNULL_END
