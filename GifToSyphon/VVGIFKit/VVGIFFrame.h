//
//  VVGIFFrame.h
//  GifToSyphon
//
//  Created by David Lublin on 2/10/15.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VVBasics/VVBasics.h>
#import <CoreMedia/CoreMedia.h>





/*

	Basically just a wrapper for an NSBitmapImageRep & CMTimeRange
	A VVGIFPlayerItem will have an array of these

*/




@interface VVGIFFrame : NSObject	{
	
	NSBitmapImageRep	*imageRep;
	CMTimeRange			timeRange;
	
}


+ (VVGIFFrame *)createWithImageRep:(NSBitmapImageRep *)r forTimeRange:(CMTimeRange)tr;
- (id)initWithImageRep:(NSBitmapImageRep *)r forTimeRange:(CMTimeRange)tr;

- (void)setImageRep:(NSBitmapImageRep *)r;
- (NSBitmapImageRep *)imageRep;
- (CMTimeRange)timeRange;


@end
