//
//  MyRichTextEditorParser.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/25/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorParser.h"
#import "MyRichTextEditorHelper.h"

typedef enum {
	CommentStateSlashSlash = 1,
    CommentStateSlashStar,
    CommentStateStarSlash,
    CommentStateReturn,
    CommentStateSlashNone
} CommentState;

typedef enum {
	StringStateTick = 1,
    StringStateQuote,
    StringStateNone
} StringState;


@interface MyRichTextEditorParser()
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@end

@implementation MyRichTextEditorParser

- (id)init {
    self = [super init];
    if (self) {
        self.helper = [[MyRichTextEditorHelper alloc] init];
    }
    return self;
}

- (void)monkeyPatchText:(NSString*)text range:(NSRange)range segment:(NSMutableArray*)segments keywords:(NSDictionary*)keywords {
    [segments removeAllObjects];
    
    [self parseStringCommentsText:text segments:segments];
    NSMutableArray *otherSegments = [self otherSegmentsFromText:text segments:segments];
    NSMutableArray *lineSegments = [self lineSegmentsText:text otherSegments:otherSegments];
    NSMutableArray *tokenizedSegments = [self tokenizeFromText:text otherSegments:lineSegments keywords:keywords];
    
    [segments addObjectsFromArray:tokenizedSegments];
}


// parses the text into segments based on comment symbols

- (void)parseText:(NSString*)text segment:(NSMutableArray*)segments keywords:(NSDictionary*)keywords {
    [segments removeAllObjects];
    
    [self parseStringCommentsText:text segments:segments];
    NSMutableArray *otherSegments = [self otherSegmentsFromText:text segments:segments];
    NSMutableArray *lineSegments = [self lineSegmentsText:text otherSegments:otherSegments];
    NSMutableArray *tokenizedSegments = [self tokenizeFromText:text otherSegments:lineSegments keywords:keywords];

    [segments addObjectsFromArray:tokenizedSegments];
}

- (void)parseStringCommentsText:(NSString*)text segments:(NSMutableArray*)segments {
    NSMutableDictionary *symbolsDic = [self.helper occurancesOfString:@[@"\\/\\/",@"\\/\\*",@"\\*\\/",@"\n",@"(.?)\"",@"(.?)'"] text:text addCaptureParen:YES];
    
    for (NSNumber *num in [symbolsDic copy]) {
        NSString *val = symbolsDic[num];
        if (val.length==2 && ([val hasSuffix:@"\'"] || [val hasSuffix:@"\""])) {
            [symbolsDic removeObjectForKey:num];
            if ([val isEqualToString:@"\\\""]) {
                [symbolsDic removeObjectForKey:num];
            }
            else {
                symbolsDic[@([num intValue]+1)] = [val substringFromIndex:1];
            }
        }
    }
    
    NSArray *symbolKeys = [[symbolsDic allKeys] sortedArrayUsingSelector: @selector(compare:)];
    CommentState commentState = CommentStateSlashNone;
    StringState stringState = StringStateNone;
    NSNumber *prevKey;
    NSNumber *key;
    
    // comment ruleset
    for (int j=0; j<symbolKeys.count; j++) {
        key = symbolKeys[j];
        NSString *symbol = symbolsDic[key];
        if ([symbol isEqualToString:@"/*"]) {
            if (stringState == StringStateTick || stringState == StringStateQuote) {
                // do nothing
            }
            else if (commentState != CommentStateSlashSlash && commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashStar;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"*/"]) {
            if (commentState == CommentStateSlashStar) {
                // found /* */
                [segments addObject: @{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"*/".length)}];
                commentState = CommentStateSlashNone;
            }
        }
        else if ([symbol isEqualToString:@"//"]) {
            if (stringState == StringStateTick || stringState == StringStateQuote) {
                // do nothing
            }
            else if (commentState != CommentStateSlashStar) {
                commentState = CommentStateSlashSlash;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"'"]) {
            if (stringState == StringStateQuote) {
                continue;
            }
            else if (stringState == StringStateTick) {
                [segments addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\'".length)}];
                stringState = StringStateNone;
            }
            else if (commentState == CommentStateSlashSlash || commentState == CommentStateSlashStar) {
                // do nothing
            }
            else {
                stringState = StringStateTick;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\""]) {
            if (stringState == StringStateTick) {
                continue;
            }
            else if (stringState == StringStateQuote) {
                // quote found
                [segments addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)}];
                stringState = StringStateNone;
            }
            else if (commentState == CommentStateSlashSlash || commentState == CommentStateSlashStar) {
                // do nothing
            }
            else {
                stringState = StringStateQuote;
                prevKey = key;
            }
        }
        else if ([symbol isEqualToString:@"\n"]) {
            if (commentState == CommentStateSlashSlash) {
                [segments addObject:@{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\n".length)}];
                commentState = CommentStateSlashNone;
            }
            else if (stringState == StringStateQuote || stringState == StringStateTick) {
                [segments addObject:@{@"type":@"invalid-string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue]+@"\"".length)}];
                stringState = StringStateNone;
            }
        }
    }
    
    if (commentState == CommentStateSlashStar) {
        key = @(text.length);
        [segments addObject:@{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
    }
    else if (commentState == CommentStateSlashSlash) {
        key = @(text.length);
        [segments addObject:@{@"type":@"comment", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
    }
    if (stringState == StringStateTick) {
        key = @(text.length);
        [segments addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
    }
    else if (stringState == StringStateQuote) {
        key = @(text.length);
        [segments addObject:@{@"type":@"string", @"location":prevKey, @"length":@([key integerValue]-[prevKey integerValue])}];
    }
}

- (NSMutableArray*)otherSegmentsFromText:(NSString*)text segments:(NSMutableArray*)segments {
    NSMutableArray *otherSegments = [@[] mutableCopy];
    NSArray *sortedSegments = [segments sortedArrayUsingDescriptors:@[self.helper.sortDesc]];
    for (int i=0;i<sortedSegments.count;i++) {
        // case where BOF code /* comment
        if (i == 0) {
            NSDictionary *segment = sortedSegments[i];
            if ([segment[@"location"] integerValue] > 0) {
                int length = [segment[@"location"] intValue];
                if (length>0) {
                    [otherSegments addObject:@{@"type":@"code", @"location":@(0), @"length":@(length)}];
                }
                else {
                    continue;
                }
            }
        }
        if (i == sortedSegments.count-1) {
            NSDictionary *segment = sortedSegments[i];
            // case where /* comment segment */ otherSegment EOF
            if ([segment[@"location"] integerValue]+[segment[@"length"] integerValue] < (text.length)) {
                NSUInteger location = [segment[@"location"] integerValue] + [segment[@"length"] integerValue];
                NSUInteger length = (text.length)-location;
                if (length==0) {
                    continue;
                }
                else {
                    [otherSegments addObject:@{@"type":@"code", @"location":@(location), @"length":@(length)}];
                }
            }
            // case where code (firstSegment) /* comment segment (secondSegment) */ EOF
            if (i>0) {
                NSDictionary *secondSegment = sortedSegments[i];
                NSDictionary *firstSegment = sortedSegments[i-1];
                NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
                NSUInteger length = [secondSegment[@"location"] integerValue] - location;
                if (length==0) {
                    continue;
                }
                else {
                    [otherSegments addObject:@{@"type":@"code", @"location":@(location), @"length":@(length)}];
                }
            }
        }
        
        // case where BOF /* first comment */ code and comments /* last comment */ EOF
        if (i > 0 && i < sortedSegments.count-1) {
            NSDictionary *secondSegment = sortedSegments[i];
            NSDictionary *firstSegment = sortedSegments[i-1];
            NSUInteger location = [firstSegment[@"location"] integerValue] + [firstSegment[@"length"] integerValue];
            NSUInteger length = [secondSegment[@"location"] integerValue] - location;
            if (length==0) {
                continue;
            }
            else {
                [otherSegments addObject:@{@"type":@"code", @"location":@(location), @"length":@(length)}];
            }
        }
    }
    
    if (sortedSegments.count == 0) {
        [otherSegments addObject:@{@"type":@"code", @"location":@(0), @"length":@(text.length)}];
    }
    
    return otherSegments;
}

- (NSMutableArray *)lineSegmentsText:(NSString*)text otherSegments:(NSMutableArray*)otherSegments {
//    NSMutableArray *lineSegments = [@{} mutableCopy];
//    NSArray *sortedSegments = [otherSegments sortedArrayUsingDescriptors:@[self.helper.sortDesc]];
//    for (int j=0;j<sortedSegments.count;j++) {
//        NSDictionary *segment = sortedSegments[j];
//        NSString *segmentText = [text substringWithRange:NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue])];
//        NSMutableDictionary *dic = [self.helper occurancesOfString:@[@"\n"] text:segmentText addCaptureParen:YES];
//        if (!dic) {
//            continue;
//        }
//        NSArray *lines = [[dic allValues] sortedArrayUsingSelector:@selector(compare:)];
//        for (int i=1; i<lines.count-1; i++) {
//            
//        }
//        
//        
//        if (dic && dic.count>1) {
//            for (NSNumber *key in dic) {
//                NSString *val = dic[key];
//                if (val.length==0) {
//                    continue;
//                }
//            }
//        }
//    }
    return otherSegments;
}

- (NSMutableArray*)tokenizeFromText:(NSString*)text otherSegments:(NSMutableArray*)segments keywords:(NSDictionary*)keywords {
    NSMutableArray *sortedSegments = [[segments sortedArrayUsingDescriptors:@[self.helper.sortDesc]] mutableCopy];
    for (int j=0;j<sortedSegments.count;j++) {
        NSDictionary *segment = sortedSegments[j];
        NSString *segmentText = [text substringWithRange:NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue])];
        NSMutableDictionary *dic = [self.helper occurancesOfString:@[@"\\b((\\w)*)\\b"] text:segmentText addCaptureParen:NO];
        if (dic && dic.count>0) {
            for (NSNumber *key in dic) {
                NSString *val = dic[key];
                if (val.length==0) {
                    continue;
                }
                if (keywords[val]) {
                    if (![segment isKindOfClass:[NSMutableDictionary class]]) {
                        sortedSegments[j] = [segment mutableCopy];
                        segment = sortedSegments[j];
                    }
                    if (![segment[@"keywords"] isKindOfClass:[NSMutableArray class]]) {
                        ((NSMutableDictionary*)segment)[@"keywords"] = [@[] mutableCopy];
                    }
                    [((NSMutableDictionary*)segment)[@"keywords"] addObject:@{@"type":keywords[val], @"location":key, @"length":@(val.length)}];
                }
                else if ([self.helper isNumber:val]) {
                    if (![segment isKindOfClass:[NSMutableDictionary class]]) {
                        sortedSegments[j] = [segment mutableCopy];
                        segment = sortedSegments[j];
                    }
                    if (![segment[@"numbers"] isKindOfClass:[NSMutableArray class]]) {
                        ((NSMutableDictionary*)segment)[@"numbers"] = [@[] mutableCopy];
                    }
                    [((NSMutableDictionary*)segment)[@"numbers"] addObject:@{@"type":@"number", @"location":key, @"length":@(val.length)}];
                }
            }
        }
    }
    return sortedSegments;
}

@end
