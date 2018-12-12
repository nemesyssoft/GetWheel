//
//  Person+CoreDataProperties.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//
//

#import "Person+CoreDataProperties.h"

@implementation Person (CoreDataProperties)

+ (NSFetchRequest<Person *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Person"];
}

@dynamic name;
@dynamic gravatarURL;
@dynamic bronzeMedals;
@dynamic silverMedals;
@dynamic goldMedals;
@dynamic user_id;

@end
