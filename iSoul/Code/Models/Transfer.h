//
//  Transfer.h
//  iSoul
//
//  Created by Richard on 12/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Transfer :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * placeInQueue;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) NSNumber * rate;
@property (nonatomic, retain) NSString * error;
@property (nonatomic, retain) NSNumber * isUpload;
@property (nonatomic, retain) User * user;

@end



