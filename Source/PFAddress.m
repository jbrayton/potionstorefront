//
//  PFAddress.m
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "PFAddress.h"

@implementation PFAddress

- (id)copyWithZone:(NSZone *)zone {
	PFAddress *copy = [[PFAddress alloc] init];
	copy->name = [name copy];
	copy->email = [email copy];
	return copy;
}



- (void)fillUsingAddressBook {
    [self setName:@""];
    NSString* fullName = NSFullUserName();
    if (fullName) {
        [self setName:fullName];
    }
    NSString* emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"GHEmailAddress"];
    if (emailAddress) {
        [self setEmail:emailAddress];
    }
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"GHEmailAddress"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id)
object
                         change:(NSDictionary *) change context:(void *) context
{
    //was one of the selectedView buttons pressed?
    if([keyPath isEqual:@"GHEmailAddress"]) {
        NSString* emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"GHEmailAddress"];
        if (emailAddress) {
            [self setEmail:emailAddress];
        }
    }
}

- (void) dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"GHEmailAddress"];
}

#pragma mark -
#pragma mark Accessors

- (NSString *)name { return name; }
- (void)setName:(NSString *)value { if (name != value) {  name = [value copy]; } }

- (NSString *)email { return email; }
- (void)setEmail:(NSString *)value { if (email != value) {  email = [value copy]; } }

#pragma mark -
#pragma mark Validation

- (BOOL)validateName:(id *)value error:(NSError **)outError {
	if (outError) *outError = nil;
	return [[*value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0;
}

- (BOOL)validateEmail:(id *)value error:(NSError **)outError {
	// Very basic validation of an email address
	// Passes validation when value is a string, at least 5 letters long, and has a '@' and a '.'
	if (outError) *outError = nil;
	if ([*value isKindOfClass:[NSString class]] == NO) return NO;
	NSString *string = [*value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	BOOL isEmail = (([string length] >= 5) &&
					([string rangeOfString:@"@"].location != NSNotFound) &&
					([string rangeOfString:@"."].location != NSNotFound));
	if (isEmail) {
		return YES;
	}
	else {
		if (outError)
			*outError = [NSError errorWithDomain:@"PotionStorefrontErrorDomain"	code:0 // whatever, it's never used anyway
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												  NSLocalizedString(@"Invalid email address", nil),
												  NSLocalizedDescriptionKey,
												  NSLocalizedString(@"Please make sure you typed in your email address correctly.", nil),
												  NSLocalizedRecoverySuggestionErrorKey,
												  nil]];
		return NO;
	}
}

@end
