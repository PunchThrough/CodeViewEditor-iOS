//
//  NSAttributedString+MyRichTextEditor.m
//  RichTextEditor
//
//  Created by Matthew Chung on 8/1/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "NSAttributedString+MyRichTextEditor.h"

@implementation NSMutableAttributedString (MyRichTextEditor)

- (void)applySegments:(NSArray*)segments colorsDic:colorsDic  {
    for (NSDictionary *segment in segments) {
        [self applySegment:segment colors:colorsDic];
    }
}

- (void)applySegment:(NSDictionary*)segment colors:(NSDictionary*)colors {
    if (segment) {
        NSRange range = NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue]);
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

            
//            NSMutableArray *arr = [@[] mutableCopy];
//            if (segment[@"keywords"]) {
//                [arr addObjectsFromArray:segment[@"keywords"]];
//            }
//            if (segment[@"numbers"]) {
//                [arr addObjectsFromArray:segment[@"numbers"]];
//            }
//
//            // remove attributes on non-keywords and non-numbers
//            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
//            NSArray *subsegments=[arr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
//
//            for (int i=0;i<subsegments.count;i++) {
//                NSString *text = [self.string substringWithRange:NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue])];
//                NSDictionary *subsegment = subsegments[i];
//                if (i == 0) {
//                    if ([subsegment[@"location"] integerValue] > 0) {
//                        int length = [subsegment[@"location"] intValue];
//                        NSRange r = NSMakeRange(range.location, length);
//                        [self checkRemoveAttribute:NSForegroundColorAttributeName range:r];
//                    }
//                }
//                if (i == subsegments.count-1) {
//                    if ([subsegment[@"location"] integerValue]+[subsegment[@"length"] integerValue] < (text.length)) {
//                        NSUInteger location = [subsegment[@"location"] integerValue] + [subsegment[@"length"] integerValue];
//                        NSUInteger length = (text.length)-location;
//                        NSRange r = NSMakeRange(range.location+location, length);
//                        [self checkRemoveAttribute:NSForegroundColorAttributeName range:r];
//                    }
//                    // case where code (firstSegment) /* comment segment (secondSegment) */ EOF
//                    if (i>0) {
//                        NSDictionary *secondSegment = subsegment;
//                        NSDictionary *firstSegment = subsegments[i-1];
//                        NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
//                        NSUInteger length = [secondSegment[@"location"] integerValue] - location;
//                        NSRange r = NSMakeRange(range.location+location, length);
//                        [self checkRemoveAttribute:NSForegroundColorAttributeName range:r];
//                    }
//                }
//                
//                // case where BOF /* first comment */ code and comments /* last comment */ EOF
//                if (i > 0 && i < subsegments.count-1) {
//                    NSDictionary *secondSegment = subsegment;
//                    NSDictionary *firstSegment = subsegments[i-1];
//                    NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
//                    NSUInteger length = [secondSegment[@"location"] integerValue] - location;
//                    NSRange r = NSMakeRange(range.location+location, length);
//                    [self checkRemoveAttribute:NSForegroundColorAttributeName range:r];
//                }
//                
//                if (subsegment[@"type"] && colors[subsegment[@"type"]]) {
//                    NSRange r = NSMakeRange([subsegment[@"location"] integerValue]+range.location, [subsegment[@"length"] integerValue]);
//                    [self applyAttributes:colors[subsegment[@"type"]] forKey:NSForegroundColorAttributeName atRange:r];
//                }
//            }
        }
    }
}

- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range {
	if (range.length > 0) {
//        NSRange r1;
//        NSDictionary *attr = [self attributesAtIndex:range.location effectiveRange:&r1];
//        if (!attr || !attr[key] || ![attr[key] isEqual:attribute] || range.length != r1.length) {
            [self addAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] range:range];
//        }
    }
}

//- (void)checkRemoveAttribute:(NSString *)name range:(NSRange)range {
//    NSRange r1;
//    NSDictionary *attr = [self attributesAtIndex:range.location effectiveRange:&r1];
//    if (attr && attr[name]) {
//        [self removeAttribute:name range:range];
//    }
//}

@end
