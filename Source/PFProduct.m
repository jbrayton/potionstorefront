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
	[self setQuantity:1];
	return self;
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
    
    NSURLSession* session = [NSURLSession sharedSession];
    
    NSURL* url = argInfo[@"url"];
    PFStoreWindowController* windowController = argInfo[@"wc"];

    NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if ((response) && ([(NSHTTPURLResponse*) response statusCode] == 200) && (data)) {
    
            NSDictionary* productInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray* products = @[[self productWithDictionary:productInfo]];
            if (products) {
                [windowController performSelectorOnMainThread:@selector(fetchedProducts:) withObject:products waitUntilDone:YES];
                return;
            }
            
            
        }
        [windowController performSelectorOnMainThread:@selector(failedToFetchProductsWithError:) withObject:error waitUntilDone:YES];
    }];
    [task resume];
    

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
	[p setIdentifier:[dictionary objectForKey:@"id"]];
	[p setName:[dictionary objectForKey:@"name"]];
	[p setByline:[dictionary objectForKey:@"tagline"]];
	[p setPriceCents:[[dictionary objectForKey:@"unitPriceUsCents"] intValue]];

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

	[p setChecked:YES];
	return p;
}

#pragma mark -
#pragma mark Accessors

- (NSArray *)children { return nil; }

- (NSString *)identifier { return identifier; }
- (void)setIdentifier:(NSString *)value { if (identifier != value) {  identifier = [value copy]; } }

- (NSInteger)priceCents { return priceCents; }
- (void)setPriceCents:(NSInteger)value { priceCents = value; }

+ (NSSet *)keyPathsForValuesAffectingPriceString {
	return [NSSet setWithObjects:@"price", @"currencyCode", nil];
}

- (NSString *)priceString {
    CGFloat priceFloat = (float) [self priceCents] / 100;
	return [NSString stringWithFormat:@"%@%.2lf", [PFOrder currencySymbolForCode:[self currencyCode]], priceFloat];
}

- (NSString *)name { return name; }
- (void)setName:(NSString *)value { if (name != value) {  name = [value copy]; } }

- (NSString *)byline { return byline; }
- (void)setByline:(NSString *)value { if (byline != value) {  byline = [value copy]; } }

- (NSImage *)iconImage { return iconImage; }
- (void)setIconImage:(NSImage *)value { if (iconImage != value) {  iconImage = value; } }

- (NSString *)licenseKey { return licenseKey; }
- (void)setLicenseKey:(NSString *)value { if (licenseKey != value) {  licenseKey = [value copy]; } }

- (NSInteger)quantity { return quantity; }
- (void)setQuantity:(NSInteger)value { quantity = value; }

- (NSString *)radioGroupName { return radioGroupName; }
- (void)setRadioGroupName:(NSString *)value { if (radioGroupName != value) {  radioGroupName = [value copy]; } }

@end
