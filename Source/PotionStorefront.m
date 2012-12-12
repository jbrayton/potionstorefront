//
//  PotionStorefront.m
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "PotionStorefront.h"
#import "PFStoreWindowController.h"

@implementation PotionStorefront

static PotionStorefront *gStorefront = nil;

+ (PotionStorefront *)sharedStorefront {
	if (gStorefront == nil) {
		gStorefront = [[PotionStorefront alloc] init];
	}
	return gStorefront;
}

- (id)delegate {
	return [[PFStoreWindowController sharedController] delegate];
}

- (void)setDelegate:(id)delegate {
	[[PFStoreWindowController sharedController] setDelegate:delegate];
}

- (NSURL *)potionStoreURL {
	return [[PFStoreWindowController sharedController] storeURL];
}

- (void)setPotionStoreURL:(NSURL *)URL {
	[[PFStoreWindowController sharedController] setStoreURL:URL];
}

- (NSURL *)productsPlistURL {
	return [[PFStoreWindowController sharedController] productsPlistURL];
}

- (void)setProductsPlistURL:(NSURL *)URL {
	[[PFStoreWindowController sharedController] setProductsPlistURL:URL];
}

- (void) setStripePublishableKey:(NSString*) argStripePublishableKey {
	[[PFStoreWindowController sharedController] setStripePublishableKey:argStripePublishableKey];
}

- (void)setWebStoreSupportsPayPal:(BOOL)flag1 googleCheckout:(BOOL)flag2 {
	[[PFStoreWindowController sharedController] setWebStoreSupportsPayPal:flag1 googleCheckout:flag2];
}

- (void)setCancelButtonQuits:(BOOL)flag {
	[[PFStoreWindowController sharedController] setCancelButtonQuits:flag];
}

- (void)beginSheetModalForWindow:(NSWindow *)window {
	NSWindow *storeWindow = [[PFStoreWindowController sharedController] window];

	// Don't open twice
	if ([storeWindow isVisible]) {
		[storeWindow makeKeyAndOrderFront:self];
		return;
	}

	// Call the showPricing: action here because by now the delegate should be set
	[[PFStoreWindowController sharedController] showPricing:nil];

	[NSApp beginSheet:storeWindow
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];

	// Clear the first responder. By default it's getting set to the web store button, and that looks quite fugly
	[storeWindow makeFirstResponder:nil];
}

- (void)runModal {
	NSWindow *storeWindow = [[PFStoreWindowController sharedController] window];

	// Don't open twice
	if ([storeWindow isVisible]) {
		[storeWindow makeKeyAndOrderFront:self];
		return;
	}

	// Call the showPricing: action here because by now the delegate should be set
	[[PFStoreWindowController sharedController] showPricing:nil];

	// Center and open the window first
	[storeWindow center];
	[storeWindow makeKeyAndOrderFront:self];

	// Clear the first responder. By default it's getting set to the web store button, and that looks quite fugly
	[storeWindow makeFirstResponder:nil];

	// Begin modal session
	[NSApp runModalForWindow:storeWindow];
}

- (void)showWindow {
	NSWindow *storeWindow = [[PFStoreWindowController sharedController] window];
    
	// Don't open twice
	if ([storeWindow isVisible]) {
		[storeWindow makeKeyAndOrderFront:self];
		return;
	}
    
	// Call the showPricing: action here because by now the delegate should be set
	[[PFStoreWindowController sharedController] showPricing:nil];
    
	// Center and open the window first
	[storeWindow center];
	[storeWindow makeKeyAndOrderFront:self];
    
	// Clear the first responder. By default it's getting set to the web store button, and that looks quite fugly
	[storeWindow makeFirstResponder:nil];
}

- (void)closeWindow {
    PFStoreWindowController* controller = [PFStoreWindowController sharedController];
    [controller close];
}

@end
