//
//  PFGradientView.h
//  TheHitList
//
//  Created by Andy Kim on 6/9/08.
//  Copyright 2008 Potion Factory LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PFBackgroundView : NSView {
	NSImage *image;
	NSGradient *gradient;
	NSColor *backgroundColor;
	NSColor *minYBorderColor;
	NSColor *maxYBorderColor;
	BOOL rebuild;
}

@property (strong) NSGradient *gradient;
@property (strong) NSColor *backgroundColor;
@property (strong) NSColor *minYBorderColor;
@property (strong) NSColor *maxYBorderColor;

// Private
- (void)rebuildImage;

@end
