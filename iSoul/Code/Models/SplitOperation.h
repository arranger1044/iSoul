//
//  SplitOperation.h
//  iSoul
//
//  Created by Richard on 12/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SplitOperation : NSOperation {
	BOOL shouldSort;
	NSArray *files;
    NSString *tickets;
}

- (id)initWithFiles:(NSArray *)fileList tickets:(NSString *)tickets shouldSort:(BOOL)yesOrNo;

@end
