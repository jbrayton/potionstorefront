//
//  PFOrder.m
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "PFOrder.h"
#import "PFAddress.h"
#import "PotionStorefront.h"

#import <JSONKit/JSONKit.h>

#import "NSInvocationAdditions.h"

@implementation PFOrder

@synthesize lineItems;
@synthesize currencyCode;

- (id)init {
	// Load JSONKit if necessary
	if (NSClassFromString(@"JSONDecoder") == nil &&
		![[NSDictionary dictionary] respondsToSelector:@selector(JSONString)]) {
		NSString *frameworkPath = [[[NSBundle bundleForClass:[self class]] bundlePath]
								   stringByAppendingPathComponent:@"Versions/A/Frameworks/JSONKit.framework"];
		[[NSBundle bundleWithPath:frameworkPath] load];
	}

	billingAddress = [[PFAddress alloc] init];
	[billingAddress fillUsingAddressBook];

	// Default to USD for now
	[self setCurrencyCode:@"USD"];

	return self;
}

- (void)dealloc {
	 billingAddress = nil;

	 creditCardNumber = nil;
	 creditCardSecurityCode = nil;
	 creditCardExpirationMonth = nil;
	 creditCardExpirationYear = nil;

	 submitURL = nil;

}

- (NSDictionary *)dictionaryRepresentationForPotionStore {
	PFAddress *a = [self billingAddress];
	NSString *creditCard = [self creditCardTypeString];
	NSAssert(creditCard != nil, @"credit card type should not be unknown at this point");

	NSMutableDictionary *orderDict = [NSMutableDictionary dictionary];

	@try {
		// This should give no trouble by the time we're here since everything
		// should be validated already. Putting it inside @try just in case though.
		[orderDict setObject:[a firstName]	forKey:@"first_name"];
		[orderDict setObject:[a lastName]	forKey:@"last_name"];
		[orderDict setObject:[self licenseeName] forKey:@"licensee_name"];
		[orderDict setObject:[a email]		forKey:@"email"];
		[orderDict setObject:creditCard		forKey:@"payment_type"];
		[orderDict setObject:[self cleanedCreditCardNumber]			forKey:@"cc_number"];
		[orderDict setObject:[self creditCardSecurityCode]		forKey:@"cc_code"];
		[orderDict setObject:[[self creditCardExpirationMonth] stringValue]	forKey:@"cc_month"];
		[orderDict setObject:[[self creditCardExpirationYear] stringValue] forKey:@"cc_year"];

		NSMutableDictionary *itemsDict = [NSMutableDictionary dictionaryWithCapacity:[lineItems count]];
		for (PFProduct *item in lineItems) {
			// Items dictionary uses the product_id as the key and the quantity as the value
			// I KNOW this is ugly but it's a carry over from when I first wrote Potion Store.
			[itemsDict setObject:[NSNumber numberWithInteger:1] forKey:[[item identifierNumber] stringValue]];
		}

		[orderDict setObject:itemsDict forKey:@"items"];
	}
	@catch (NSException *e) {
		NSLog(@"Got exception while building order dictionary: %@", e);
	}

	return orderDict;
}

// Helper error constructor used in submitInBackground
static NSError *ErrorWithObject(id object) {
	NSString *message = nil;
	if ([object isKindOfClass:[NSError class]]) {
		message = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), [(NSError *)object localizedDescription]];
	}
	else if ([object isKindOfClass:[NSException class]]) {
		return ErrorWithObject([NSString stringWithFormat:NSLocalizedString(@"Exception: %@", nil), [object description]]);
	}
	else {
		message = [object description];
	}

	return [NSError errorWithDomain:@"PotionStorefrontErrorDomain"
							   code:0
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									 NSLocalizedString(@"Could not process order", nil), NSLocalizedDescriptionKey,
									 message, NSLocalizedRecoverySuggestionErrorKey,
									 nil]];
}

static NSError *ErrorWithJSONResponse(NSString *string) {
	NSDictionary* dict = [string objectFromJSONString];
	if ([dict isKindOfClass:[NSDictionary class]] == NO) goto fail;
	@try {
		return dict[@"message"];
	}
	@catch (NSException * e) {
		NSLog(@"ERROR -- Got exception while trying to parse JSON error response: %@", e);
		return ErrorWithObject(e);
	}
fail:
	return ErrorWithObject(@"Could not process order due to an unexpected error. Please try again later.");
}

- (id) initWithStripePublishableKey:(NSString*) argStripePublishableKey {
    if (![self init]) {
        return nil;
    }
    stripePublishableKey = argStripePublishableKey;
    return self;
}

- (void) setStripePublishableKey:(NSString*) argStripePublishableKey {
    stripePublishableKey = argStripePublishableKey;
}

- (void)submitInBackground {
	if ([NSThread currentThread] == [NSThread mainThread]) {
		[self p_prepareForSubmission];
		[NSThread detachNewThreadSelector:@selector(submitInBackground) toTarget:self withObject:nil];
		return;
	}

	@autoreleasepool {
		NSError *error = nil;
        NSHTTPURLResponse *response = nil;

		@try {
			if ([self submitURL] == nil) {
				NSLog(@"ERROR -- Cannot submit order without a URL");
				return;
			}
            
            NSString* cardNumber = [self creditCardNumber];
            cardNumber = [cardNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            cardNumber = [cardNumber stringByReplacingOccurrencesOfString:@"\t" withString:@""];
            cardNumber = [cardNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
            cardNumber = [cardNumber stringByReplacingOccurrencesOfString:@"_" withString:@""];
            NSString* cardNumberEncoded = [self stringByUrlEncoding:cardNumber];
            NSString* secCodeEncoded = [self stringByUrlEncoding:[self creditCardSecurityCode]];
            NSString* args = [NSString stringWithFormat:@"card[number]=%@&card[exp_month]=%@&card[exp_year]=%@&card[cvc]=%@", cardNumberEncoded, [self creditCardExpirationMonth], [self creditCardExpirationYear], secCodeEncoded];
            NSMutableURLRequest* submitTokenRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.stripe.com/v1/tokens"]];
            [submitTokenRequest setHTTPMethod:@"POST"];
            [submitTokenRequest setHTTPBody:[args dataUsingEncoding:NSUTF8StringEncoding]];
            [submitTokenRequest setHTTPShouldHandleCookies:NO];
            [submitTokenRequest addValue:[NSString stringWithFormat:@"Bearer %@", stripePublishableKey] forHTTPHeaderField:@"Authorization"];
            
            NSData* responseData = [NSURLConnection sendSynchronousRequest:submitTokenRequest returningResponse:&response error:&error];
			NSString *responseBody = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
			NSInteger statusCode = [response statusCode];
            
            NSString* token = nil;
            NSString* errorMessage = nil;
            @try {
                NSDictionary *responseOrder = [responseBody objectFromJSONString];
                if (statusCode == 200) {
                    token = responseOrder[@"id"];
                } else if (responseOrder) {
                    errorMessage = responseOrder[@"error"][@"message"];
                } else if (response) {
                    errorMessage = [NSString stringWithFormat:@"Unexpected response code (%ld) from credit card processor.", [response statusCode]];
                } else {
                    errorMessage = @"Unable to communicate with credit card processor.";
                }
            } @catch (NSException* e) {
                errorMessage = NSLocalizedString(@"Unable to process the response.", @"");
            }
            
            if ([errorMessage length]) {
                if ([errorMessage characterAtIndex:[errorMessage length]-1] != '.') {
                    errorMessage = [errorMessage stringByAppendingString:@"."];
                }
                errorMessage = [errorMessage stringByAppendingString:@" Your credit card was not charged."];
                NSError* error = ErrorWithObject(errorMessage);
                NSDictionary* info = @{ @"order": self, @"error": error } ;
                [delegate performSelectorOnMainThread:@selector(orderDidFinishSubmitting:) withObject:info waitUntilDone:YES];
                return;
            }
            
            
            NSString* tokenEncoded = [self stringByUrlEncoding:token];
            NSString* nameEncoded = [self stringByUrlEncoding:[NSString stringWithFormat:@"%@ %@", [[self billingAddress] firstName], [[self billingAddress] lastName]]];
            NSString* emailEncoded = [self stringByUrlEncoding:[[self billingAddress] email]];
            NSNumber* product = [[self lineItems][0] identifierNumber];
            NSInteger quantity = 1;
            NSInteger totalPriceCents = [self totalPriceCents];
            
            NSMutableURLRequest* registerRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://secure.goldenhillsoftware.com/noindex/store/processtransaction.php"]];
            args = [NSString stringWithFormat:@"token=%@&name=%@&email=%@&product=%@&quantity=%ld&totalPriceCents=%ld", tokenEncoded, nameEncoded, emailEncoded, product, quantity, totalPriceCents];
            //if (couponCode) {
            //    args = [args stringByAppendingFormat:@"&couponCode=%@", couponCodeEncoded];
            //}
            [registerRequest setHTTPMethod:@"POST"];
            [registerRequest setHTTPBody:[args dataUsingEncoding:NSUTF8StringEncoding]];
            [registerRequest setHTTPShouldHandleCookies:NO];

			responseData = [NSURLConnection sendSynchronousRequest:registerRequest returningResponse:&response error:&error];
			if (error != nil) {
				error = ErrorWithObject(error);
				goto done;
			}

			responseBody = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
			statusCode = [response statusCode];
            
            NSArray* regCodes = @[];
            BOOL success = NO;
            errorMessage = nil;
            @try {
                NSDictionary* responseObj = [responseBody objectFromJSONString];
                if (responseObj) {
                    errorMessage = responseObj[@"error"];
                    regCodes = responseObj[@"registrationCodes"];
                    success = [responseObj[@"success"] boolValue];
                } else {
                    errorMessage = NSLocalizedString(@"Unable to retrieve registration codes. Please email us at support@goldenhillsoftware.com.", @"");
                }
            } @catch (NSException* e) {
                errorMessage = NSLocalizedString(@"Unable to retrieve registration codes. Please email us at support@goldenhillsoftware.com.", @"");
            }

            

			if (success) {
				NSInteger licensedCount = 0;

				// Update license key from returned order
				for (PFProduct *myitem in lineItems) {
                    [myitem setLicenseKey:regCodes[0]];
                    licensedCount += [regCodes count];
				}

				if (licensedCount == 0)
					error = ErrorWithObject(NSLocalizedString(@"The order was charged, but a license key was not received. Please email us at support@goldenhillsoftware.com", nil));
			} else {
				error = ErrorWithObject(errorMessage);
			}
		} @catch (NSException *e) {
			NSLog(@"ERROR -- Exception while submitting order: %@", e);
			error = ErrorWithObject(e);
		}

done:
		if ([[self delegate] respondsToSelector:@selector(orderDidFinishSubmitting:)]) {
            NSMutableDictionary* info = [NSMutableDictionary dictionary];
            info[@"order"] = self;
            if(error) {
                info[@"error"] = error;
            }
            [delegate performSelectorOnMainThread:@selector(orderDidFinishSubmitting:) withObject:info waitUntilDone:YES];
		}

	}
}

- (NSString *)cleanedCreditCardNumber {
	return [self p_cleanCreditCardNumber:[self creditCardNumber]];
}

// Return the credit card type based on the credit card number
- (PFCreditCardType)creditCardType {
	NSString *ccnum = [self cleanedCreditCardNumber];

	if ([ccnum length] == 0) {
        return PFUnknownType;
    }

    if ([ccnum hasPrefix:@"2131"] || [ccnum hasPrefix:@"1800"]) {
        return PFJcbCardType;
    }
	if ([ccnum hasPrefix:@"3"]) {
		// Diners (Mastercard) (36) or Amex (34 or 37)
        if ([ccnum hasPrefix:@"36"] || [ccnum hasPrefix:@"38"] || [ccnum hasPrefix:@"300"] || [ccnum hasPrefix:@"301"] || [ccnum hasPrefix:@"302"] || [ccnum hasPrefix:@"303"] || [ccnum hasPrefix:@"304"] || [ccnum hasPrefix:@"305"]) {
            return PFDinersClubType;
        }
        if ([ccnum hasPrefix:@"34"] || [ccnum hasPrefix:@"37"]) {
            return PFAmexType;
        }
        if ([ccnum hasPrefix:@"35"]) {
            return PFJcbCardType;
        }
	}
	else if ([ccnum hasPrefix:@"4"]) {
		return PFVisaType;
	}
	else if ([ccnum hasPrefix:@"5"]) {
		return PFMasterCardType;
	}
	else if ([ccnum hasPrefix:@"6"]) {
		return PFDiscoverType;
	}

	return PFUnknownType;
}

- (NSString *)creditCardTypeString {
	switch ([self creditCardType]) {
		case PFVisaType:
			return @"Visa";
		case PFMasterCardType:
			return @"MasterCard";
		case PFAmexType:
			return @"Amex";
		case PFDiscoverType:
			return @"Discover";
		case PFDinersClubType:
			return @"Diners Club";
		case PFJcbCardType:
			return @"JCB";
		default:
			return nil;
	}
}

// These are used in binding enabled state of card type buttons
- (BOOL)isVisaCard { return [self creditCardType] == PFVisaType; }
- (BOOL)isMasterCard { return [self creditCardType] == PFMasterCardType; }
- (BOOL)isAmexCard { return [self creditCardType] == PFAmexType; }
- (BOOL)isDiscoverCard { return [self creditCardType] == PFDiscoverType; }
- (BOOL)isDinersCard { return [self creditCardType] == PFDinersClubType; }
- (BOOL)isJcbCard { return [self creditCardType] == PFJcbCardType; }

+ (NSSet *)keyPathsForValuesAffectingVisaCard { return [NSSet setWithObject:@"creditCardNumber"]; }
+ (NSSet *)keyPathsForValuesAffectingMasterCard { return [NSSet setWithObject:@"creditCardNumber"]; }
+ (NSSet *)keyPathsForValuesAffectingAmexCard { return [NSSet setWithObject:@"creditCardNumber"]; }
+ (NSSet *)keyPathsForValuesAffectingDiscoverCard { return [NSSet setWithObject:@"creditCardNumber"]; }
+ (NSSet *)keyPathsForValuesAffectingDinersCard { return [NSSet setWithObject:@"creditCardNumber"]; }
+ (NSSet *)keyPathsForValuesAffectingJcbCard { return [NSSet setWithObject:@"creditCardNumber"]; }

#pragma mark -
#pragma mark Accessors

- (id)delegate { return delegate; }
- (void)setDelegate:(id)object { delegate = object; }

+ (NSSet *)keyPathsForValuesAffectingCurrencySymbol {
	return [NSSet setWithObject:@"currencyCode"];
}

+ (NSString *)currencySymbolForCode:(NSString *)code {
	// Just a few of the most common currency symbols
	if ([code isEqualToString:@"USD"])
		return @"$";
	else if ([code isEqualToString:@"EUR"])
		return @"€";
	else if ([code isEqualToString:@"JPY"])
		return @"¥";
	else if ([code isEqualToString:@"GBP"])
		return @"£";
	else
		return @"$";
}

+ (NSSet *)keyPathsForValuesAffectingTotalPriceCents {
	return [NSSet setWithObject:@"lineItems"];
}

- (NSInteger)totalPriceCents {
	NSInteger totalCents = 0;
	for (PFProduct *product in lineItems) {
        totalCents += ([product priceCents] * [product quantity]);
	}

	return totalCents;
}

+ (NSSet *)keyPathsForValuesAffectingTotalAmountString {
	return [NSSet setWithObjects:@"currencyCode", @"lineItems", nil];
}

- (NSString *)totalAmountString {
    float totalAmount = (float) [self totalPriceCents] / 100;
	return [NSString stringWithFormat:@"%@%.2lf", [PFOrder currencySymbolForCode:[self currencyCode]], totalAmount];
}

- (NSURL *)submitURL { return submitURL; }
- (void)setSubmitURL:(NSURL *)value { if (submitURL != value) {  submitURL = [value copy]; } }

// Just return the name from the address
- (NSString *)licenseeName { return [NSString stringWithFormat:@"%@ %@", [[self billingAddress] firstName], [[self billingAddress] lastName]]; }

- (PFAddress *)billingAddress { return billingAddress; }
- (void)setBillingAddress:(PFAddress *)value { if (billingAddress != value) {  billingAddress = value; } }

- (NSString *)creditCardNumber { return creditCardNumber; }
- (void)setCreditCardNumber:(NSString *)value { if (creditCardNumber != value) {  creditCardNumber = [value copy]; } }

- (NSString *)creditCardSecurityCode { return creditCardSecurityCode; }
- (void)setCreditCardSecurityCode:(NSString *)value { if (creditCardSecurityCode != value) {  creditCardSecurityCode = [value copy]; } }

- (NSNumber *)creditCardExpirationMonth { return creditCardExpirationMonth; }
- (void)setCreditCardExpirationMonth:(id)value {
	if (creditCardExpirationMonth != value) {
		if ([value isKindOfClass:[NSNumber class]])
			creditCardExpirationMonth = [value copy];
		else if ([value isKindOfClass:[NSString class]])
			creditCardExpirationMonth = [NSNumber numberWithInteger:[value integerValue]];
		else
			creditCardExpirationMonth = value;
	}
}

- (NSNumber *)creditCardExpirationYear { return creditCardExpirationYear; }
- (void)setCreditCardExpirationYear:(id)value {
	if (creditCardExpirationYear != value) {
		if ([value isKindOfClass:[NSNumber class]])
			creditCardExpirationYear = [value copy];
		else if ([value isKindOfClass:[NSString class]])
			creditCardExpirationYear = [NSNumber numberWithInteger:[value integerValue]];
		else
			creditCardExpirationYear = value;
	}
}

#pragma mark -
#pragma mark Validation

- (BOOL)validateCreditCardNumber:(id *)value error:(NSError **)outError {
	// Do a Luhn algorithm check

	// 1. Double all the alternating numbers starting from the end.
	// 2. If their sum isn't divisible by 10, it's a bad card number

	NSString *ccnum = [self p_cleanCreditCardNumber:*value];

	// American Express is 15 digits and everything else is at least 16
	if ([ccnum length] < 13 || [ccnum length] > 16) goto fail;

	NSInteger sum = 0;
	BOOL alt = NO;

	for (NSInteger i = [ccnum length] - 1; i >= 0; i--) {
		NSInteger thedigit = [[ccnum substringWithRange:NSMakeRange(i, 1)] integerValue];
		if (alt) {
			thedigit = 2 * thedigit;
			if (thedigit > 9) {
				thedigit -= 9;
			}
		}
		sum += thedigit;
		alt = !alt;
	}
	if (sum % 10 == 0) {
		if (outError) *outError = nil;
		return YES;
	}

fail:
	if (outError)
		*outError = [NSError errorWithDomain:@"PotionStorefrontErrorDomain"	code:0 // whatever, it's never used anyway
									userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											  NSLocalizedString(@"Invalid credit card number", nil),
											  NSLocalizedDescriptionKey,
											  NSLocalizedString(@"Please make sure you typed in the credit card number correctly.", nil),
											  NSLocalizedRecoverySuggestionErrorKey,
											  nil]];
	return NO;
}

- (BOOL)validateCreditCardSecurityCode:(id *)value error:(NSError **)outError {
	if (outError) *outError = nil;
	return [[*value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] != 0;
}

- (BOOL)validateCreditCardExpiration:(NSError **)outError {
	NSInteger month = [[self creditCardExpirationMonth] integerValue];
	NSInteger year = [[self creditCardExpirationYear] integerValue];
	if (month < 1 || month > 12 || year <= 0 || year > 99) {
		if (outError) *outError = nil; // Don't specify error to not show an alert sheet for this simple error condition
		return NO;
	}

	// Validate expiration date
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setMonth:month];
	[comps setYear:year + 2000];
	[comps setDay:2];
	NSDate *expirationDate = [cal dateFromComponents:comps];

	comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
	[comps setDay:1];

	NSDate *firstDayOfCurrentMonth = [cal dateFromComponents:comps];

	if ([firstDayOfCurrentMonth compare:expirationDate] != NSOrderedAscending) {
		if (outError)
			*outError = [NSError errorWithDomain:@"PotionStorefrontErrorDomain" code:1 // whatever, it's never used anyway
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												  NSLocalizedString(@"Your credit card is expired", nil),
												  NSLocalizedDescriptionKey,
												  NSLocalizedString(@"Please make sure that your credit card is not expired and that you typed in the expiration date correctly.", nil),
												  NSLocalizedRecoverySuggestionErrorKey,
												  nil]];
		return NO;
	}
	else {
		return YES;
	}
}

#pragma mark -
#pragma mark Private

- (NSString *)p_cleanCreditCardNumber:(NSString *)value {
	NSCharacterSet *digitCharacterSet = [NSCharacterSet decimalDigitCharacterSet];

	// Construct credit card number string using only numbers
	NSMutableString *ccnum = [NSMutableString stringWithCapacity:32];
	for (NSUInteger i = 0; i < [value length]; i++) {
		if ([digitCharacterSet characterIsMember:[value characterAtIndex:i]]) {
			[ccnum appendString:[value substringWithRange:NSMakeRange(i, 1)]];
		}
	}

	return ccnum;
}

- (void)p_prepareForSubmission {
	// Trim all the string fields of the address
	NSArray *keys = [NSArray arrayWithObjects:
					 @"firstName", @"lastName", @"email",
					 nil];
	for (NSString *key in keys) {
		NSString *trimmed = [[[self billingAddress] valueForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[[self billingAddress] setValue:trimmed forKey:key];
	}
}

- (NSString*) stringByUrlEncoding:(NSString*) argInput {
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (__bridge CFStringRef)argInput,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8 );
}


@end
