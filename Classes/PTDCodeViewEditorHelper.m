//
//  PTDCodeViewEditorHelper.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDCodeViewEditorHelper.h"

@interface PTDCodeViewEditorHelper()
@end

@implementation PTDCodeViewEditorHelper

- (id)init {
    self = [super init];
    if (self) {
        self.sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
    }
    return self;
}

// returns a segment that is in the location of the passed in range

- (NSDictionary*)segmentForRange:(NSRange)range fromSegments:(NSMutableArray*)segments {
    NSUInteger min = NSUIntegerMax;
    NSMutableDictionary *foundSegment;
    for (NSMutableDictionary *segment in segments) {
        long location = [segment[@"location"] integerValue];
        long diff = labs(location - (int)range.location);
        if ((location <= range.location) && (diff <= min)) {
            min = diff;
            foundSegment = segment;
        }
    }
    // get the intersection of ranges between the range input and the range of the segment
    // we just found
    if (foundSegment) {
        NSUInteger location = [foundSegment[@"location"] integerValue];
        NSUInteger length = [foundSegment[@"length"] integerValue];
        // handles case where NSIntersectionRange returns false positive
        if (range.location == 0 && range.length == 0) {
            if (location == 0) {
                return foundSegment;
            }
        }
        else {
            NSRange intersectionRange = NSIntersectionRange(range, NSMakeRange(location, length));
            if (intersectionRange.length != 0 || intersectionRange.location != 0) {
                return foundSegment;
            }
        }
    }
    return nil;
}

// returns the segments that are within the range

- (NSMutableArray*)segmentsForRange:(NSRange)range fromSegments:(NSMutableArray*)segments {
    NSMutableArray *retArr = nil;
    for (NSDictionary *segment in segments) {
        NSRange segmentRange = NSMakeRange([segment[@"location"] integerValue], [segment[@"length"] integerValue]);
        NSRange intersectionRange = NSIntersectionRange(range, segmentRange);
        if (intersectionRange.length!= 0 || intersectionRange.location != 0) {
            if (!retArr) {
                retArr =  [@[] mutableCopy];
            }
            [retArr addObject:segment];
        }
    }
    return retArr;
}

// returns if the text is surrounded on the left and right

- (BOOL)text:(NSString*)text range:(NSRange)range leftNeighbor:(NSString*)left rightNeighbor:(NSString*)right  {
    if (text.length < range.location+range.length+1 || !range.location) {
        return NO;
    }
    
    NSString *l = [text substringWithRange:NSMakeRange(range.location-1, 1)];
    NSString *r = [text substringWithRange:NSMakeRange(range.location+range.length, 1)];
    if ([left isEqualToString:l] && [right isEqualToString:r]) {
        return YES;
    }
    return NO;
}

// returns a dic keyed by the location with a value of the string

static NSMutableDictionary *occuranceRegexDic;

- (NSMutableDictionary*)occurancesOfString:(NSArray*)strArray text:(NSString*)text addCaptureParen:(BOOL)addParen {
    NSError *error=NULL;
    NSMutableArray *temp = [@[] mutableCopy];
    for (NSString *str in strArray) {
        [temp addObject:str];
    }

    NSString *pattern;;
    if (addParen) {
        pattern = [NSString stringWithFormat:@"(%@)", [temp componentsJoinedByString:@"|"]];
    }
    else {
        pattern = [NSString stringWithFormat:@"%@", [temp componentsJoinedByString:@"|"]];
    }
    
    if (!occuranceRegexDic) {
        occuranceRegexDic = [@{} mutableCopy];
    }
    
    NSRegularExpression *regex = occuranceRegexDic[pattern];
    if (!regex) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (error) {
            NSLog(@"Couldn't create regex with given string and options %@", [error localizedDescription]);
        }
        occuranceRegexDic[pattern] = regex;
    }
    
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    NSMutableDictionary *retDic = [@{} mutableCopy];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        retDic[@(matchRange.location)] = [text substringWithRange:matchRange];
    }
    
    return retDic;
}

// utility to determine if the text is a number

static NSRegularExpression *numberRegex;

- (BOOL)isNumber:(NSString*)text {
    
    if (text == nil || text.length == 0) {
        return NO;
    }
    if (!numberRegex) {
        NSError *error=NULL;
        numberRegex = [NSRegularExpression regularExpressionWithPattern:@"\\d(x|b)?[0-9a-fA-F]*" options:0 error:&error];
        if (error) {
            NSLog(@"Couldn't create regex with given string and options %@", [error localizedDescription]);
        }
    }
    
    NSRange textRange = NSMakeRange(0, text.length);
    NSRange matchRange = [numberRegex rangeOfFirstMatchInString:text options:NSMatchingReportCompletion range:textRange];
    
    return (matchRange.location != NSNotFound && matchRange.length == textRange.length);
}

// returns a dic based on the arduino keywords file format

- (NSMutableDictionary*)keywordsForPath:(NSString*)filePath {
    NSError *error;
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:&error];
    if (error) {
        NSLog(@"Error getting contents of file: %@: %@", filePath, error);
    }
    NSArray *arr = [myText componentsSeparatedByString:@"\n"];
    NSMutableDictionary *keywordsDic = [@{} mutableCopy];
    for (NSString *line in arr) {
        if ([line hasPrefix:@"#"]) {
            continue;
        }
        
        // arduino file tends to have text \t text \t text but sometimes has an empty second text, so
        // in that case, we're checking the third one
        NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (words.count >= 2) {
            if (((NSString*)words[1]).length == 0 && words.count>=3) {
                keywordsDic[words[0]] = words[2];
            }
            else {
                keywordsDic[words[0]] = words[1];
            }
        }
    }
    return keywordsDic;
}

// returns a dic of colors mapping to a data type

- (NSMutableDictionary*)colorsForPath:(NSString*)filePath {
    NSMutableDictionary *colorsDic = [@{} mutableCopy];
    if (filePath) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) {
            NSLog(@"textColors file not found");
        }
        NSError *error;
        NSDictionary *textColors = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"JSONObjectWithData error: %@", error);
        NSArray *temp = textColors[@"comments"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"comment"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"invalid-string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"invalid-string"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"string"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"string"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"number"];
        if (temp && temp.count == 3) {
            float red = [temp[0] floatValue];
            float green = [temp[1] floatValue];
            float blue = [temp[2] floatValue];
            colorsDic[@"number"] = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        temp = textColors[@"keywords"];
        if (temp && [temp isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary*)temp;
            for (NSString *key in dic) {
                NSArray *val = dic[key];
                colorsDic[key] = [UIColor colorWithRed:[val[0] floatValue] green:[val[1] floatValue] blue:[val[2] floatValue] alpha:1];
            }
        }
    }
    return colorsDic;
}

// returns a dic of chars to skip

- (NSMutableDictionary*)textSkipForPath:(NSString*)filePath {
    NSMutableDictionary *textSkip;
    if (filePath) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) {
            NSLog(@"textSkip file not found");
        }
        NSError *error;
        textSkip = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"JSONObjectWithData error: %@", error);
    }
    return textSkip;
}

@end
