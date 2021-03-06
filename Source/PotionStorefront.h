//
//  PotionStorefront.h
//  PotionStorefront
//
//  Created by Andy Kim on 7/26/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PFOrder.h"
#import "PFAddress.h"
#import "PFProduct.h"

#define DEBUG_POTION_STORE_FRONT 0

@interface PotionStorefront : NSObject {
}

+ (PotionStorefront *)sharedStorefront;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (void) setApiUrlRoot:(NSString*) value;
- (void) setProductId:(NSString*) value;
- (void) setWebStoreUrl:(NSString*) value;

- (void)setCancelButtonQuits:(BOOL)flag;

- (void)beginSheetModalForWindow:(NSWindow *)window;

- (void)runModal;
- (void)showWindow;
- (void)closeWindow;
@end



@interface NSObject (PotionStorefrontDelegate)
// Required
- (void)orderDidFinishCharging:(PFOrder *)order;

// Optional -- If you implement this you get the "Unlock with License Key..." button
- (void)showRegistrationWindow:(id)sender;
@end
