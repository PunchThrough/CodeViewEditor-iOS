//
//  NSAttributedString+MyRichTextEditor.m
//  RichTextEditor
//
//  Created by Matthew Chung on 8/1/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "NSAttributedString+MyRichTextEditor.h"

@implementation NSMutableAttributedString (MyRichTextEditor)

- (void)applySegments:(NSArray*)segments colorsDic:colorsDic
{
    for (NSDictionary *segment in segments) {
        [self applySegment:segment colors:colorsDic];
    }
}

- (void)applySegment:(NSDictionary*)segment colors:(NSDictionary*)colors
{
    if (segment && colors) {
        NSRange range = NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue]);
        if ( range.location == NSNotFound ) {
            return;
        }
        if ([segment[@"type"] isEqualToString:@"comment"] ||
            [segment[@"type"] isEqualToString:@"string"]  ||
            [segment[@"type"] isEqualToString:@"invalid-string"]) {
            [self applyAttributes:colors[segment[@"type"]] forKey:NSForegroundColorAttributeName atRange:range];
        }
        else if ([segment[@"type"] isEqualToString:@"code"]) {
            [self removeAttribute:NSForegroundColorAttributeName range:range];
            if (segment[@"keywords"]) {
                for (NSDictionary *keyword in segment[@"keywords"]) {
                    if (keyword[@"type"] && colors[keyword[@"type"]]) {
                        NSRange r = NSMakeRange([keyword[@"location"] integerValue]+range.location, [keyword[@"length"] integerValue]);
                        [self applyAttributes:colors[keyword[@"type"]] forKey:NSForegroundColorAttributeName atRange:r];
                    }
                }
            }
            if (segment[@"numbers"]) {
                for (NSDictionary *keyword in segment[@"numbers"]) {
                    NSRange r = NSMakeRange([keyword[@"location"] integerValue]+range.location, [keyword[@"length"] integerValue]);
                    if (keyword[@"type"] && colors[keyword[@"type"]]) {
                        [self applyAttributes:colors[keyword[@"type"]] forKey:NSForegroundColorAttributeName atRange:r];
                    }
                }
            }
        }
    }
}

- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range
{
	if (range.length > 0) {
        [self addAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] range:range];
    }
}

@end
