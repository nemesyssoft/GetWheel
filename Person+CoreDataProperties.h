//
//  Person+CoreDataProperties.h
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//
//

#import "Person+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Person (CoreDataProperties)

+ (NSFetchRequest<Person *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *gravatarURL;
@property (nonatomic) int16_t bronzeMedals;
@property (nonatomic) int16_t silverMedals;
@property (nonatomic) int16_t goldMedals;
@property (nonatomic) int64_t user_id;
@property (nonatomic) int64_t reputation;

@end

NS_ASSUME_NONNULL_END
