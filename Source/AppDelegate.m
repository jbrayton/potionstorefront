//
//  AppDelegate.m
//  RaisedEditor2
//
//  Created by Andy Kim on 1/29/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import "AppDelegate.h"

#import <PotionStorefront/PotionStorefront.h>

@implementation AppDelegate

- (IBAction)buy:(id)sender {
	[[PotionStorefront sharedStorefront] setDelegate:self];
    [[PotionStorefront sharedStorefront] setProductId:@"cloudpull"];
    [[PotionStorefront sharedStorefront] setApiUrlRoot:@"https://storeapi.goldenhillsoftware.com/v1"];
    [[PotionStorefront sharedStorefront] setWebStoreUrl:@"https://www.goldenhillsoftware.com/cloudpull/buy/"];
    [[PotionStorefront sharedStorefront] showWindow];
}

@end
