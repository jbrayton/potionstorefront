//
//  PFOrder.h
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PFAddress;

typedef enum {
	PFUnknownType,
	PFVisaType,
	PFMasterCardType,
	PFAmexType,
	PFDiscoverType,
    PFDinersClubType,
    PFJcbCardType
} PFCreditCardType;

@interface PFOrder : NSObject {
	id delegate;
    
    NSString* apiUrlRoot;

	NSArray *lineItems;
	NSString *currencyCode;
	PFAddress *billingAddress;

	NSString *creditCardNumber;
	NSString *creditCardSecurityCode;
	NSNumber *creditCardExpirationMonth;
	NSNumber *creditCardExpirationYear;

	NSURL *submitURL;
}

- (id) initWithApiUrlRoot:(NSString*) argApiUrlRoot;

- (void)submitInBackground;

- (NSString *)cleanedCreditCardNumber;
- (PFCreditCardType)creditCardType;
- (NSString *)creditCardTypeString;
- (void) setApiUrlRoot:(NSString*) value;

// Simple accessors

@property (copy) NSArray *lineItems;
@property (copy) NSString *currencyCode;

+ (NSString *)currencySymbolForCode:(NSString *)code;

- (id)delegate;
- (void)setDelegate:(id)object;

- (NSString *)totalAmountString;
- (NSInteger) totalPriceCents;

- (NSURL *)submitURL;
- (void)setSubmitURL:(NSURL *)value;

- (PFAddress *)billingAddress;
- (void)setBillingAddress:(PFAddress *)value;

- (NSString *)creditCardNumber;
- (void)setCreditCardNumber:(NSString *)value;

- (NSString *)creditCardSecurityCode;
- (void)setCreditCardSecurityCode:(NSString *)value;

- (NSNumber *)creditCardExpirationMonth;
- (void)setCreditCardExpirationMonth:(id)value;

- (NSNumber *)creditCardExpirationYear;
- (void)setCreditCardExpirationYear:(id)value;

// Validation
- (BOOL)validateCreditCardExpiration:(NSError **)outError;

// Private
- (NSString *)p_cleanCreditCardNumber:(NSString *)value;
- (void)p_prepareForSubmission;
@end


@interface NSObject (PFOrderDelegate)
- (void)orderDidFinishSubmitting:(NSDictionary *)info;
@end
