//
//  PFStoreWindowController.h
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	PFCreditCardPaymentMethod,
	PFWebStorePaymentMethod
};

@class PFOrder;
@class PFAddress;
@class PFBackgroundView;

@interface PFStoreWindowController : NSWindowController {
	IBOutlet PFBackgroundView *headerView;
	IBOutlet PFBackgroundView *mainContentView;

	IBOutlet NSTextField *headerTitleField;
	IBOutlet NSTextField *headerStepsField;
	IBOutlet NSButton *primaryButton;
	IBOutlet NSButton *secondaryButton;
	IBOutlet NSButton *tertiaryButton;
	IBOutlet NSImageView *lockImageView;
	IBOutlet NSProgressIndicator *progressSpinner;

	// STUFF FOR PRICING VIEW
	IBOutlet NSView *pricingView;
	IBOutlet NSCollectionView *productCollectionView;
	IBOutlet NSTextField *orderTotalField;
	IBOutlet NSProgressIndicator *productFetchProgressSpinner;

	// STUFF FOR BILLING VIEW
	IBOutlet NSView *billingView;
	IBOutlet NSView *addressSelectionContainerView;

	// Labels
	IBOutlet NSTextField *nameLabel;
	IBOutlet NSTextField *emailLabel;
	IBOutlet NSTextField *creditCardNumberLabel;
	IBOutlet NSTextField *creditCardSecurityCodeLabel;
	IBOutlet NSTextField *creditCardExpirationLabel;
    IBOutlet NSTextField *thankYouLabel;

	// Input Fields
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *emailField;
	IBOutlet NSTextField *creditCardNumberField;
	IBOutlet NSTextField *creditCardExpirationMonthField;
	IBOutlet NSTextField *creditCardExpirationYearField;

    NSString* stripePublishableKey;
    
	PFAddress *customAddress;

	// STUFF FOR THANK YOU VIEW
	IBOutlet NSView *thankYouView;

	// OTHER STUFF
	id delegate;

	NSURL *storeURL;
	NSURL *productsPlistURL;
	PFOrder *order;
	NSInteger paymentMethod;
	BOOL cancelButtonQuits;
	BOOL validateFieldsImmediately;
}

+ (id)sharedController;

- (id)delegate;
- (void)setDelegate:(id)object;

// Accessors
- (PFOrder *)order;
- (NSURL *)storeURL;
- (void)setStoreURL:(NSURL *)URL;
- (NSURL *)productsPlistURL;
- (void)setProductsPlistURL:(NSURL *)value;
- (void)setWebStoreSupportsPayPal:(BOOL)flag1 googleCheckout:(BOOL)flag2;
- (void)setCancelButtonQuits:(BOOL)flag;
- (void)setStripePublishableKey:(NSString*) argStripePublishableKey;

// Actions
- (IBAction)showPricing:(id)sender;
- (IBAction)showBillingInformation:(id)sender;
- (IBAction)showThankYou:(id)sender;

- (IBAction)selectPaymentMethod:(id)sender;
- (IBAction)updatedOrderLineItems:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)openWebStore:(id)sender;
- (IBAction)showRegistrationWindow:(id)sender;

// Private
- (void)p_setEnabled:(BOOL)enabled toAllControlsInView:(NSView *)view;
- (void)p_setContentView:(NSView *)view;
- (void)p_setHeaderTitle:(NSString *)title;
- (BOOL)p_validateOrder;

@end
