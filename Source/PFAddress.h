//
//  PFAddress.h
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PFAddress : NSObject <NSCopying> {
	NSString *name;
	NSString *email;
}

- (void)fillUsingAddressBook;

#pragma mark Accessors

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)email;
- (void)setEmail:(NSString *)value;

@end
