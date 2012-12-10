//
//  PFAddress.h
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PFAddress : NSObject <NSCopying> {
	NSString *firstName;
	NSString *lastName;
	NSString *email;
}

- (void)fillUsingAddressBook;

#pragma mark Accessors

- (NSString *)firstName;
- (void)setFirstName:(NSString *)value;

- (NSString *)lastName;
- (void)setLastName:(NSString *)value;

- (NSString *)email;
- (void)setEmail:(NSString *)value;

@end
