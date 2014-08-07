//
//  PTDCodeViewEditorHelper.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Helper class. see the .m for comments

#import "PTDCodeViewEditor.h"

@interface PTDCodeViewEditorHelper : NSObject 
- (NSMutableDictionary*)occurancesOfString:(NSArray*)strArray text:(NSString*)text addCaptureParen:(BOOL)addParen;
- (BOOL)text:(NSString*)text range:(NSRange)range leftNeighbor:(NSString*)left rightNeighbor:(NSString*)right;
- (NSDictionary*)segmentForRange:(NSRange)range fromSegments:(NSMutableArray*)segments;
- (NSMutableArray*)segmentsForRange:(NSRange)range fromSegments:(NSMutableArray*)segments;
- (BOOL)isNumber:(NSString*)text;
- (NSMutableDictionary*)keywordsForPath:(NSString*)filePath;
- (NSMutableDictionary*)colorsForPath:(NSString*)filePath;
- (NSMutableDictionary*)textSkipForPath:(NSString*)filePath;
@property (nonatomic, strong) NSSortDescriptor *sortDesc;
@end
