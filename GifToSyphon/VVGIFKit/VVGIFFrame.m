//
//  VVGIFFrame.m
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import "VVGIFFrame.h"

@implementation VVGIFFrame


+ (VVGIFFrame *)createWithImageRep:(NSBitmapImageRep *)r forTimeRange:(CMTimeRange)tr	{
	VVGIFFrame *returnMe = [[VVGIFFrame alloc] initWithImageRep:r forTimeRange:tr];
	if (returnMe != nil)
		[returnMe autorelease];
	return returnMe;
}

- (id)initWithImageRep:(NSBitmapImageRep *)r forTimeRange:(CMTimeRange)tr	{
	if (self = [super init])	{
		timeRange = tr;
		[self setImageRep: r];
		return self;
	}
	[self release];
	return nil;
}

- (void)dealloc	{
	VVRELEASE(imageRep);
	[super dealloc];
}

- (void)setImageRep:(NSBitmapImageRep *)r	{
	VVRELEASE(imageRep);
	if (r != nil)	{
		imageRep = [r copy];
	}
}

- (NSBitmapImageRep *)imageRep	{
	return imageRep;
}

- (CMTimeRange)timeRange	{
	return timeRange;
}


@end
