//
//  CodeViewEditorTests.m
//
//  Created by Aryan Gh on 5/4/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "CodeViewEditorTests.h"
#import "RichTextEditor.h"
#import "PTDCodeViewEditor.h"

@interface CodeViewEditorTests()
@end

@implementation CodeViewEditorTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSetupFiles {
    PTDCodeViewEditor *editor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:25 textReplaceFile:@"testTextReplace" keywordsFile:@"testKeywords" textColorsFile:@"testTextColors" textSkipFile:@"testTextSkip"];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"testSetupFiles" ofType:@"ino"];
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
    [editor loadWithText:myText];
    NSAttributedString *attrStr = editor.attributedText;
    [attrStr enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, attrStr.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        
        // keyword color test
        if (range.location == 0 && range.length == 4) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.4, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.4, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.4, @"");
        }
        else if (range.location == 5 && range.length == 8) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.5, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.5, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.5, @"");
        }
        else if (range.location == 14 && range.length == 7) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.1, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.1, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.1, @"");
        }
        else if (range.location == 22 && range.length == 4) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.2, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.2, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.2, @"");
        }
        else if (range.location == 27 && range.length == 4) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.3, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.3, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.3, @"");
        }
        
        // comment test
        else if ((range.location == 32 && range.length == 18)) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.6, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.6, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.6, @"");
        }
        
        // string test
        else if ((range.location == 51 && range.length == 6) || (range.location == 64 && range.length == 6)) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.7, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.7, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.7, @"");
        }
        
        // invalid string test
        else if ((range.location == 58 && range.length == 6)) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.8, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.8, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.8, @"");
        }
        
        // num test
        else if ((range.location == 71 && range.length == 4) || (range.location == 76 && range.length == 4) || (range.location == 81 && range.length == 4)) {
            UIColor *color = value;
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            [color getRed:&red green:&green blue:&blue alpha:NULL];
            XCTAssertEqual((int)(10*red+0.5), 10*0.9, @"");
            XCTAssertEqual((int)(10*green+0.5), 10*0.9, @"");
            XCTAssertEqual((int)(10*blue+0.5), 10*0.9, @"");
        }
    }];
}

- (void)testTextReplaceAndSkipAhead {
    PTDCodeViewEditor *editor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:25 textReplaceFile:@"testTextReplace" keywordsFile:@"testKeywords" textColorsFile:@"testTextColors" textSkipFile:@"testTextSkip"];
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"["];
    XCTAssertEqualObjects(editor.text, @"[]", @"");
    XCTAssertEqual(editor.selectedRange.location, 1, @"");
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@"]"];
    XCTAssertEqualObjects(editor.text, @"[]", @"");
    XCTAssertEqual(editor.selectedRange.location, 2, @"");
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"A"];
    XCTAssertEqualObjects(editor.text, @"[]ABCDEF", @"");
    XCTAssertEqual(editor.selectedRange.location, 8, @"");
}

- (void)testStrings {
    PTDCodeViewEditor *editor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:25 textReplaceFile:@"testTextReplace" keywordsFile:@"testKeywords" textColorsFile:@"testTextColors" textSkipFile:@"testTextSkip"];
    editor.parseDelay = 0.05;
    
    // non-terminated valid string
    // string now '
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"'"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    NSAttributedString *attrStr = editor.attributedText;
    NSRange r1;
    NSDictionary *attr = [attrStr attributesAtIndex:0 effectiveRange:&r1];
    UIColor *color = attr[NSForegroundColorAttributeName];
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    XCTAssertEqual((int)(10*red+0.5), 10*0.7, @"");
    XCTAssertEqual((int)(10*green+0.5), 10*0.7, @"");
    XCTAssertEqual((int)(10*blue+0.5), 10*0.7, @"");

    // valid string
    // string now 'abc'
    [editor textView:editor shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@"abc'"];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    attrStr = editor.attributedText;
    attr = [attrStr attributesAtIndex:1 effectiveRange:&r1];
    color = attr[NSForegroundColorAttributeName];
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    XCTAssertEqual((int)(10*red+0.5), 10*0.7, @"");
    XCTAssertEqual((int)(10*green+0.5), 10*0.7, @"");
    XCTAssertEqual((int)(10*blue+0.5), 10*0.7, @"");
    XCTAssertEqual(r1.length, 4, @"");
}

@end
