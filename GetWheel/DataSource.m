//
//  DataSource.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import "DataSource.h"
#import "Person+CoreDataClass.h"

static DataSource *sharedDataSource = nil;

@implementation DataSource

+ (id)sharedDataSource
{
    static dispatch_once_t dataSourcePredicate;
    dispatch_once(&dataSourcePredicate, ^{
        sharedDataSource = [[super allocWithZone:NULL] init];
    });
    
    return sharedDataSource;
}

- (NSInteger)personCount {
    NSInteger countToReturn = 0;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    NSError *error = nil;
    countToReturn = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        NELog(@"error %ld while trying to fetch the count of persons: %@", (long)error.code, error.description);
    }
    
    return countToReturn;
}

- (void)savePersons:(NSArray *)persons {
    Person *newPerson = nil;
    NSEntityDescription *personEntity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    for (NSDictionary *aPersonAsDictionary in persons) {
        newPerson = [[Person alloc] initWithEntity:personEntity insertIntoManagedObjectContext:self.managedObjectContext];
        newPerson.name = aPersonAsDictionary[@"display_name"];
        newPerson.reputation = [aPersonAsDictionary[@"reputation"] integerValue];
        newPerson.gravatarURL = aPersonAsDictionary[@"profile_image"];
        NSDictionary *badgeCounts = aPersonAsDictionary[@"badge_counts"];
        newPerson.bronzeMedals = [badgeCounts[@"bronze"] integerValue];
        newPerson.silverMedals = [badgeCounts[@"silver"] integerValue];
        newPerson.goldMedals = [badgeCounts[@"gold"] integerValue];
        newPerson.user_id = [aPersonAsDictionary[@"user_id"] integerValue];
    }
    
    if ([self.managedObjectContext hasChanges]) {
        NSError *error = nil;
        if ( ! [self.managedObjectContext save:&error]) {
            NELog(@"error %ld while trying to save persons: %@", (long)error.code, error.description);
        }
    }
}

@end
