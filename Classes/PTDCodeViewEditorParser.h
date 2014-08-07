//
//  PTDCodeViewEditorParser.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/25/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  parses and builds ABT

#import <Foundation/Foundation.h>

@interface PTDCodeViewEditorParser : NSObject
- (void)parseText:(NSString*)text segment:(NSMutableArray*)segments keywords:(NSDictionary*)keywords;
@end
