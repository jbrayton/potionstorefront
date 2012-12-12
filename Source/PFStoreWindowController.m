//
//  PFStoreWindowController.m
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "PFStoreWindowController.h"
#import "PotionStorefront.h"
#import "PFBackgroundView.h"
#import "PFCollectionRow.h"

@implementation PFStoreWindowController

static PFStoreWindowController *gController = nil;

+ (id)sharedController {
	if (gController == nil) {
		gController = [[PFStoreWindowController alloc] init];
		[gController window]; // Load the whole nib immediately
	}

	return gController;
}

- (id)init {
	self = [super initWithWindowNibName:@"Store"];
	if (self) {
		order = [[PFOrder alloc] initWithStripePublishableKey:stripePublishableKey];
	}
	return self;
}


- (void)awakeFromNib {
	[[self window] setDelegate:(id)self];

    NSString* appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Purchase %@", @""), appName]];
	
    [headerTitleField setTextColor:[NSColor colorWithCalibratedRed:201/255.0 green:220/255.0 blue:255/255.0 alpha:1.0]];
	[headerStepsField setTextColor:[NSColor colorWithCalibratedRed:201/255.0 green:220/255.0 blue:255/255.0 alpha:1.0]];

	// Default kerning on Helvetica Neue UltraLight is too small
	NSMutableAttributedString *as = [[headerTitleField attributedStringValue] mutableCopy];
	[as addAttribute:NSKernAttributeName value:[NSNumber numberWithFloat:1.2] range:NSMakeRange(0, [as length])];
	[headerTitleField setAttributedStringValue:as];

	[mainContentView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];

	[headerView setGradient:
	 [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:25/255.0 green:36/255.0 blue:43/255.0 alpha:1.0]
									endingColor:[NSColor colorWithCalibratedRed:25/255.0 green:31/255.0 blue:38/255.0 alpha:1.0]]];

}

static void PFUnbindEverythingInViewTree(NSView *view) {
	if (view == nil) return; // just in case

	for (NSView *subview in view.subviews) {
		PFUnbindEverythingInViewTree(subview);
	}

	NSMutableArray *objectsToRemoveBindingsFrom = [NSMutableArray arrayWithObject:view];

	if ([view respondsToSelector:@selector(cell)]) {
		NSCell *cell = [(NSControl *)view cell];
		if (cell)
			[objectsToRemoveBindingsFrom addObject:cell];
	}
	if ([view respondsToSelector:@selector(cells)]) {
		NSArray *cells = [(id)view cells];
		if (cells)
			[objectsToRemoveBindingsFrom addObjectsFromArray:cells];
	}

	for (id obj in objectsToRemoveBindingsFrom) {
		if ([obj respondsToSelector:@selector(exposedBindings)]) {
			for (NSString *binding in [obj exposedBindings]) {
				NSDictionary *info = [obj infoForBinding:binding];
				if (info) {
					[obj unbind:binding];
				}
			}
		}
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	if ([NSApp modalWindow] == [self window]) {
		[NSApp stopModal];
	}
	else {
		[NSApp endSheet:[self window] returnCode:NSCancelButton];
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)showPricing:(id)sender {
	// Don't validate email and credit card number right away when going from billing information to pricing
	validateFieldsImmediately = NO;

	[self p_setHeaderTitle:NSLocalizedString(@"Purchase", nil)];
	[headerStepsField setStringValue:NSLocalizedString(@"Step 1 of 2", nil)];

	[primaryButton setTitle:NSLocalizedString(@"Next", nil)];
	[primaryButton setAction:@selector(showBillingInformation:)];

	[secondaryButton setTitle:cancelButtonQuits ? NSLocalizedString(@"Quit", nil) : NSLocalizedString(@"Cancel", nil)];
	[secondaryButton setAction:@selector(cancel:)];

	if ([[self delegate] respondsToSelector:@selector(showRegistrationWindow:)]) {
		[tertiaryButton setTitle:NSLocalizedString(@"Unlock with Registration Code...", nil)];
		[tertiaryButton setAction:@selector(showRegistrationWindow:)];
		[tertiaryButton setTarget:self];
		[tertiaryButton setHidden:NO];
	}
	else {
		[tertiaryButton setHidden:YES];
	}

	[lockImageView setHidden:YES];

	[self p_setContentView:pricingView];
}

- (IBAction)showBillingInformation:(id)sender {
	if (paymentMethod != PFCreditCardPaymentMethod) {
		// TODO: build URL to preset quantity at the web store
		[self openWebStore:nil];
		[self close];
		return;
	}

	// We want to validate fields right when the editor tries to commit the editing for some fields
	validateFieldsImmediately = YES;

	if ([order totalPriceCents] == 0) {
		[orderTotalField setTextColor:[[NSColor redColor] shadowWithLevel:0.15]];
		NSBeep();
		return;
	}

	[self p_setHeaderTitle:NSLocalizedString(@"Billing Information", nil)];
	[headerStepsField setStringValue:NSLocalizedString(@"Step 2 of 2", nil)];

	[primaryButton setTitle:NSLocalizedString(@"Purchase", nil)];
	[primaryButton setAction:@selector(purchase:)];

	[secondaryButton setTitle:NSLocalizedString(@"Go Back", nil)];
	[secondaryButton setAction:@selector(showPricing:)];

	[tertiaryButton setHidden:YES];

	[lockImageView setHidden:NO];

	[self p_setContentView:billingView];

	// If name is blank, put focus there
	if ([[firstNameField stringValue] length] == 0)
		[[self window] makeFirstResponder:firstNameField];
	// otherwise, if address is blank, put focus there
	// otherwise, if email is blank, put focus there
	else if ([[emailField stringValue] length] == 0)
		[[self window] makeFirstResponder:emailField];
	// otherwise put focus in credit card number field
	else
		[[self window] makeFirstResponder:creditCardNumberField];
}

- (IBAction)showThankYou:(id)sender {
	[self p_setHeaderTitle:NSLocalizedString(@"Thank You", nil)];
	[headerStepsField setStringValue:@""];

	[primaryButton setTitle:NSLocalizedString(@"Done", nil)];
	[primaryButton setAction:@selector(close)];

	[secondaryButton setHidden:YES];

	[lockImageView setHidden:YES];

    NSString* appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    [thankYouLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Thank you! %@ is now fully functional and all trial limitations have been removed. Your purchase receipt and registration code will arrive shortly by email.", @""), appName]];

	[self p_setContentView:thankYouView];
}

- (IBAction)selectPaymentMethod:(id)sender {
    paymentMethod = PFCreditCardPaymentMethod;
}

- (IBAction)updatedOrderLineItems:(id)sender {
	// Reset to regular text color in case the error color got set
	[orderTotalField setTextColor:[NSColor controlTextColor]];
}

- (IBAction)purchase:(id)sender {
	if ([self p_validateOrder]) {
		// Make the editing field commit
		[[self window] makeFirstResponder:nil];

		[self p_setEnabled:NO toAllControlsInView:[[self window] contentView]];

		[progressSpinner startAnimation:self];

		[order setDelegate:self];
		[order setSubmitURL:[NSURL URLWithString:[[storeURL absoluteString] stringByAppendingPathComponent:@"order.json"]]];
		[order submitInBackground];
	}
	else {
		NSBeep();
	}
}

- (IBAction)cancel:(id)sender {
	if (cancelButtonQuits)
		exit(0);
	else
		[self close];
}

- (IBAction)selectCountry:(id)sender {
	[self controlTextDidChange:nil];
}

- (IBAction)openWebStore:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:storeURL];
}

- (IBAction)showRegistrationWindow:(id)sender {
	if ([[self delegate] respondsToSelector:@selector(showRegistrationWindow:)]) {
		[self close];
		[[self delegate] showRegistrationWindow:sender];
	}
}

#pragma mark -
#pragma mark Delegate

- (void)fetchedProducts:(NSArray *)products {
	[productFetchProgressSpinner stopAnimation:self];
	[productFetchProgressSpinner removeFromSuperview];
    // Default to USD for now
    [products setValue:@"USD" forKey:@"currencyCode"];
    [order setLineItems:[products filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"checked = YES"]]];
    [productCollectionView setContent:products];
    [orderTotalField setHidden:NO];
    [primaryButton setEnabled:YES];
}

- (void) failedToFetchProductsWithError:(NSError*) error {
	[productFetchProgressSpinner stopAnimation:self];
	[productFetchProgressSpinner removeFromSuperview];
    [[self window] presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:NULL];
}

- (void)orderDidFinishSubmitting:(NSDictionary *)info {
    PFOrder* anOrder = info[@"order"];
    NSError* error = info[@"error"];
    [progressSpinner stopAnimation:self];

	if (error == nil) {
		[self p_setEnabled:YES toAllControlsInView:[[self window] contentView]];

		// Wipe the credit card information before notifying the delegate
		[anOrder setCreditCardNumber:nil];
		[anOrder setCreditCardSecurityCode:nil];
		[anOrder setCreditCardExpirationMonth:nil];
		[anOrder setCreditCardExpirationYear:nil];

		if ([[self delegate] respondsToSelector:@selector(orderDidFinishCharging:)]) {
			[[self delegate] orderDidFinishCharging:anOrder];
		}

		[self showThankYou:self];
	}
	else {
		[[self window] presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentOrderSubmitError:) contextInfo:NULL];
	}
}

- (void)didPresentOrderSubmitError:(BOOL)didRecover {
	[self p_setEnabled:YES toAllControlsInView:[[self window] contentView]];

	// Trigger a key value observer update so that the credit card buttons get their
	// enable state set correctly again
	[order willChangeValueForKey:@"creditCardNumber"];
	[order didChangeValueForKey:@"creditCardNumber"];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	if ([aNotification object] == creditCardNumberField) return;
	if ([aNotification object] == creditCardExpirationMonthField) return;
	if ([aNotification object] == creditCardExpirationYearField) return;
	if ([aNotification object] == emailField) return;

	// Should get here iff address is edited

	// Only add the custom address item once
	if (customAddress == nil) {

		customAddress = [[order billingAddress] copy];
		[order setBillingAddress:customAddress];
	}
	else {
		customAddress = [[order billingAddress] copy];
		[order setBillingAddress:customAddress];
		// Select the custom address in the pop up
	}
}

#pragma mark Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	return NO;
}

#pragma mark -
#pragma mark Accessors

- (PFOrder *)order { return order; }

- (id)delegate { return delegate; }
- (void)setDelegate:(id)object { delegate = object; }

- (NSURL *)storeURL { return storeURL; }
- (void)setStoreURL:(NSURL *)value {
	if (storeURL != value) {
		 storeURL = [value copy];
		if ([[storeURL scheme] isEqualToString:@"https"] == NO) {
			// Don't show lock if it's not really secure
			[lockImageView removeFromSuperview];
			lockImageView = nil;
		}
	}
}

- (NSURL *)productsPlistURL { return productsPlistURL; }
- (void)setProductsPlistURL:(NSURL *)value {
	if (productsPlistURL != value) {
		productsPlistURL = [value copy];

		// Grab products from server if we haven't yet
		if ([[productCollectionView content] count] == 0) {
			[productFetchProgressSpinner startAnimation:self];
			[PFProduct beginFetchingProductsFromURL:productsPlistURL delegate:self];
		}
	}
}

- (void)setWebStoreSupportsPayPal:(BOOL)paypal googleCheckout:(BOOL)gc {
}

- (void)setCancelButtonQuits:(BOOL)flag {
	cancelButtonQuits = flag;
}

- (void)setStripePublishableKey:(NSString*) argStripePublishableKey {
    stripePublishableKey = argStripePublishableKey;
    [order setStripePublishableKey:argStripePublishableKey];
}

#pragma mark -
#pragma mark Private

- (void)p_setEnabled:(BOOL)enabled toAllControlsInView:(NSView *)view {
	NSEnumerator *e = [[view subviews] objectEnumerator];
	NSView *subview = nil;
	while ((subview = [e nextObject])) {
		[self p_setEnabled:enabled toAllControlsInView:subview];
	}

	if ([view respondsToSelector:@selector(setEnabled:)]) {
		[(NSControl *)view setEnabled:enabled];
	}
}

- (void)p_setContentView:(NSView *)view {
	CGFloat diff = NSHeight([mainContentView frame]) - NSHeight([view frame]);
	NSRect wframe = [[self window] frame];
	wframe.origin.y += diff;
	wframe.size.height -= diff;
	[[mainContentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[[self window] setFrame:wframe display:YES animate:YES];
	[view setFrame:[mainContentView bounds]];
	[mainContentView addSubview:view positioned:NSWindowBelow relativeTo:nil];

	// This is necessary even when window is set to auto-recalculate key view loop
	[[self window] recalculateKeyViewLoop];
}

- (void)p_setHeaderTitle:(NSString *)title {
	NSMutableAttributedString *as = [[headerTitleField attributedStringValue] mutableCopy];
	[as replaceCharactersInRange:NSMakeRange(0, [as length]) withString:title];
	[headerTitleField setAttributedStringValue:as];
}

- (BOOL)p_validateOrder {
	BOOL success = YES;

	NSColor *good = [NSColor controlTextColor];
	NSColor *bad = [[NSColor redColor] shadowWithLevel:0.15];

	[firstNameLabel setTextColor:good];
	[lastNameLabel setTextColor:good];
	[emailLabel setTextColor:good];
	[creditCardNumberLabel setTextColor:good];
	[creditCardSecurityCodeLabel setTextColor:good];
	[creditCardExpirationLabel setTextColor:good];

	id value = nil;
	NSError *error = nil;
	PFAddress *billingAddress = [order billingAddress];

	if (!(value = [billingAddress firstName]) || ![billingAddress validateValue:&value forKey:@"firstName" error:nil]) {
		[firstNameLabel setTextColor:bad];
		success = NO;
	}

	if (!(value = [billingAddress lastName]) || ![billingAddress validateValue:&value forKey:@"lastName" error:nil]) {
		[lastNameLabel setTextColor:bad];
		success = NO;
	}

	if (!(value = [billingAddress email]) || ![billingAddress validateValue:&value forKey:@"email" error:&error]) {
		[emailLabel setTextColor:bad];
		success = NO;
	}

	if (!(value = [order creditCardNumber]) || ![order validateValue:&value forKey:@"creditCardNumber" error:nil]) {
		[creditCardNumberLabel setTextColor:bad];
		success = NO;
	}

	if (!(value = [order creditCardSecurityCode]) || ![order validateValue:&value forKey:@"creditCardSecurityCode" error:nil]) {
		[creditCardSecurityCodeLabel setTextColor:bad];
		success = NO;
	}

	if (![order validateCreditCardExpiration:&error]) {
		[creditCardExpirationLabel setTextColor:bad];
		success = NO;
	}

	if (error) {
		[[self window] presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:NULL];
	}

	return success;
}

@end
