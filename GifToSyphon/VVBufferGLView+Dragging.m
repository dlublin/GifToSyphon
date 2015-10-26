//
//  VVBufferGLView+Dragging.m
//  GifToSyphon
//
//  Created by Daniel Ellis on 26/10/2015.
//  Copyright (c) 2015 VIDVOX. All rights reserved.
//

#import "VVBufferGLView+Dragging.h"
#import <objc/runtime.h>


NSString const *key = @"Gif.To.Syphon";

@implementation VVBufferGLView(Dragging)

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        [self.dragDelegate fileWasDraggedWithPath:[files firstObject]];
        
    }
    return YES;
}

-(id)dragDelegate
{
    return objc_getAssociatedObject(self, &key);
}

-(void)setDragDelegate:(id<DraggingDelegate>)dragDelegate
{
    objc_setAssociatedObject(self, &key, dragDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
