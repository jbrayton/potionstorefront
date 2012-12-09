//
//  PFProduct.m
//  PotionStorefront
//
//  Created by Andy Kim on 7/27/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "PFProduct.h"
#import "PotionStorefront.h"
#import "PFStoreWindowController.h"

#import "NSInvocationAdditions.h"

@implementation PFProduct

@synthesize currencyCode;
@synthesize checked;

- (id)init {
	[self setQuantity:[NSNumber numberWithInteger:1]];
	return self;
}

- (void)dealloc {
	 identifierNumber = nil;
	 price = nil;
	 name = nil;
	 byline = nil;
	 iconImage = nil;
	 licenseKey = nil;
	 quantity = nil;
	 radioGroupName = nil;

}

// Helper error constructor used in fetchedProductsFromURL:error:
static NSError *ErrorWithObject(id object) {
	NSString *message = nil;
	if ([object isKindOfClass:[NSError class]])
		message = [NSString stringWithFormat:NSLocalizedString(@"Please make sure that you're connected to the Internet. (Error: %@)", nil), [(NSError *)object localizedDescription]];
	else
		message = [object description];

	return [NSError errorWithDomain:@"PotionStorefrontErrorDomain"	code:2 // whatever, it's never used anyway
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									 NSLocalizedString(@"Could not get pricing information through the Internet", nil), NSLocalizedDescriptionKey,
									 message, NSLocalizedRecoverySuggestionErrorKey,
									 nil]];
}

+ (void) beginFetching:(NSDictionary*) argInfo {
    NSURL* url = argInfo[@"url"];
    PFStoreWindowController* windowController = argInfo[@"wc"];
    
	NSError *error = nil;
	NSMutableArray *products = nil;
    
	@try {
        NSArray *array = [NSArray arrayWithContentsOfURL:url];
        if (array == nil) {
            error = ErrorWithObject(@"Please make sure that you are connected to the Internet or try again later.");
        }
        else {
            NSMutableArray* tmpProducts = [NSMutableArray arrayWithCapacity:[array count]];
            for (NSDictionary *dict in array) {
                [tmpProducts addObject:[PFProduct productWithDictionary:dict]];
            }
            products = tmpProducts;
        }
	} @catch (NSException *e) {
		NSLog(@"ERROR -- Exception while getting products: %@", e);
		error = ErrorWithObject([NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), [e description]]);
	}
    
    if (products) {
        [windowController performSelectorOnMainThread:@selector(fetchedProducts:) withObject:products waitUntilDone:YES];
    } else {
        [windowController performSelectorOnMainThread:@selector(failedToFetchProductsWithError:) withObject:error waitUntilDone:YES];
    }
    
}

+ (void)beginFetchingProductsFromURL:(NSURL *)aURL delegate:(id)delegate {
    NSDictionary* info = @{ @"url": aURL, @"wc": delegate } ;
	if ([NSThread currentThread] == [NSThread mainThread]) {
		[self performSelectorInBackground:@selector(beginFetching:) withObject:info];
	} else {
		[self beginFetching:info];
    }
}

+ (PFProduct *)productWithDictionary:(NSDictionary *)dictionary {
	PFProduct *p = [[PFProduct alloc] init];
	[p setIdentifierNumber:[dictionary objectForKey:@"id"]];
	[p setName:[dictionary objectForKey:@"name"]];
	[p setByline:[dictionary objectForKey:@"byline"]];
	[p setPrice:[dictionary objectForKey:@"price"]];

	// Check for a image path first to see if we can load it from the bundle
	NSString *iconImagePath = [dictionary objectForKey:@"iconImagePath"];
	if (iconImagePath) {
		iconImagePath = [[NSBundle mainBundle] pathForResource:iconImagePath ofType:nil];
		if (iconImagePath) {
			[p setIconImage:[[NSImage alloc] initWithContentsOfFile:iconImagePath]];
		}
	}

	// Load from the net if you can't get the image through the path
	if ([p iconImage] == nil) {
		NSString *URLString = [dictionary objectForKey:@"iconImageURL"];
		if (URLString) {
			NSURL *iconImageURL = [NSURL URLWithString:URLString];
			if (iconImageURL)
				[p setIconImage:[[NSImage alloc] initWithContentsOfURL:iconImageURL]];
		}
	}

	// Use the default application icon if there's still no icon at this point
	if ([p iconImage] == nil) {
		[p setIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	}

	[p setRadioGroupName:[dictionary objectForKey:@"radioGroupName"]];

	[p setChecked:[[dictionary objectForKey:@"checked"] boolValue]];
	return p;
}

#pragma mark -
#pragma mark Accessors

- (NSArray *)children { return nil; }

- (NSNumber *)identifierNumber { return identifierNumber; }
- (void)setIdentifierNumber:(NSNumber *)value { if (identifierNumber != value) {  identifierNumber = [value copy]; } }

- (NSNumber *)price { return price; }
- (void)setPrice:(NSNumber *)value { if (price != value) {  price = [value copy]; } }

+ (NSSet *)keyPathsForValuesAffectingPriceString {
	return [NSSet setWithObjects:@"price", @"currencyCode", nil];
}

- (NSString *)priceString {
	return [NSString stringWithFormat:@"%@%.2lf", [PFOrder currencySymbolForCode:[self currencyCode]], [[self price] floatValue]];
}

- (NSString *)name { return name; }
- (void)setName:(NSString *)value { if (name != value) {  name = [value copy]; } }

- (NSString *)byline { return byline; }
- (void)setByline:(NSString *)value { if (byline != value) {  byline = [value copy]; } }

- (NSImage *)iconImage { return iconImage; }
- (void)setIconImage:(NSImage *)value { if (iconImage != value) {  iconImage = value; } }

- (NSString *)licenseKey { return licenseKey; }
- (void)setLicenseKey:(NSString *)value { if (licenseKey != value) {  licenseKey = [value copy]; } }

- (NSNumber *)quantity { return quantity; }
- (void)setQuantity:(NSNumber *)value { if (quantity != value) {  quantity = [value copy]; } }

- (NSString *)radioGroupName { return radioGroupName; }
- (void)setRadioGroupName:(NSString *)value { if (radioGroupName != value) {  radioGroupName = [value copy]; } }

@end
