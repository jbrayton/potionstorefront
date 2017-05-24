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

@interface PFStoreWindowController : NSWindowController<NSTextViewDelegate> {
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
    IBOutlet NSTextView* webBasedLink;

	// STUFF FOR BILLING VIEW
	IBOutlet NSView *billingView;

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

	PFAddress *customAddress;

	// STUFF FOR THANK YOU VIEW
	IBOutlet NSView *thankYouView;

	// OTHER STUFF
	id delegate;

	PFOrder *order;
	NSInteger paymentMethod;
	BOOL cancelButtonQuits;
	BOOL validateFieldsImmediately;
}

@property NSString* productId;
@property NSString* apiUrlRoot;
@property NSString* webStoreUrl;

+ (id)sharedController;

- (id)delegate;
- (void)setDelegate:(id)object;

// Accessors
- (PFOrder *)order;
- (void)setCancelButtonQuits:(BOOL)flag;

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
