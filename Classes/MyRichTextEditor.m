//
//  MyRichTextEditor.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditor.h"
#import "MyRichTextEditor.h"
#import "MyRichTextEditorToolbar.h"
#import "MyRichTextEditorHelper.h"
#import "MyRichTextEditorParser.h"
#import "LineNumberLayoutManager.h"
#import "NSAttributedString+MyRichTextEditor.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
typedef void (^ParsingCompletion)(long seqNum, NSMutableArray *segments, NSRange range);

@interface MyRichTextEditor() <MyRichTextEditorToolbarDataSource>
@property (nonatomic, strong) MyRichTextEditorHelper *helper;
@property (nonatomic, strong) MyRichTextEditorParser *parser;
@property (nonatomic, strong) NSMutableArray *segments;
@property (nonatomic, strong) NSMutableDictionary *textReplaceDic;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) NSMutableDictionary *colorsDic;
@property (nonatomic, strong) NSMutableDictionary *textSkipDic;
@property (nonatomic, strong) NSMutableArray *lines;
@property (nonatomic, readwrite) NSUInteger lineNumberGutterWidth;
@property (nonatomic, readwrite) long charTypedSeqNum;
@property (nonatomic, copy) ParsingCompletion parseCompletionHandler;
@end

@implementation MyRichTextEditor

- (id)initWithLineNumbers:(BOOL)lineNumbers textReplaceFile:(NSString*)textReplaceFile keywordsFile:(NSString*)keywordsFile textColorsFile:(NSString*)textColorsFile textSkipFile:(NSString*)textSkipFile {
    // block copied from https://github.com/alldritt/TextKit_LineNumbers/blob/master/TextKit_LineNumbers/LineNumberTextView.m
    if (lineNumbers) {
        NSTextStorage* ts = [[NSTextStorage alloc] init];
        LineNumberLayoutManager* lm = [[LineNumberLayoutManager alloc] init];
        NSTextContainer* tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        
        //  Wrap text to the text view's frame
        tc.widthTracksTextView = YES;
        
        //  Exclude the line number gutter from the display area available for text display.
        tc.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 40.0, CGFLOAT_MAX)]];
        
        [lm addTextContainer:tc];
        [ts addLayoutManager:lm];

        self.lineNumberGutterWidth = 40;
        
        if ((self = [super initWithFrame:CGRectZero textContainer:tc])) {
            self.contentMode = UIViewContentModeRedraw; // cause drawRect: to be called on frame resizing and divice rotation
            [self commonInitialization];
        }
    }
    else {
        self = [super initWithFrame:CGRectZero];
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:textReplaceFile ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSArray *textJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"JSONObjectWithData error: %@", error);
        NSAssert(NO, @"");
    }
    
    self.textReplaceDic = [@{} mutableCopy];
    for (NSDictionary *dic  in textJson) {
        self.textReplaceDic[dic[@"text"]] = dic;
    }
    
    filePath = [[NSBundle mainBundle] pathForResource:keywordsFile ofType:@"txt"];
    self.keywordsDic = [self.helper keywordsForPath:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:textColorsFile ofType:@"json"];
    self.colorsDic = [self.helper colorsForPath:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:textSkipFile ofType:@"json"];
    self.textSkipDic = [self.helper textSkipForPath:filePath];

    return self;
}

- (void)commonInitialization
{
    self.borderColor = [UIColor lightGrayColor];
    self.borderWidth = 1.0;
    
	self.toolBar = [[MyRichTextEditorToolbar alloc] initWithFrame:CGRectMake(0, 0, [self currentScreenBoundsDependOnOrientation].size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)
                                                         delegate:self
                                                       dataSource:self];
    
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
    
    self.helper = [[MyRichTextEditorHelper alloc] init];
    self.parser = [[MyRichTextEditorParser alloc] init];
    self.delegate = self;
    
    self.segments = [@[] mutableCopy];
    self.lines = [@[] mutableCopy];
    
    [self observeKeyboard];
    
    // default values
    self.indentation = @"    ";
    self.syntaxHighlightOn = YES;
    self.parseDelay = 1;
    
    __weak MyRichTextEditor *weakSelf = self;
    self.parseCompletionHandler = ^(long seqNum, NSMutableArray *segments, NSRange range) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, weakSelf.parseDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (seqNum == weakSelf.charTypedSeqNum) {
                weakSelf.segments = segments;
                NSRange r = weakSelf.selectedRange;
                // scroll fix from http://stackoverflow.com/questions/16716525/replace-uitextviews-text-with-attributed-string
                if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                    weakSelf.scrollEnabled = NO;
                }
                
                NSMutableAttributedString *attrString = [weakSelf.attributedText mutableCopy];
                [attrString applySegments:segments colorsDic:weakSelf.colorsDic];
                
                [weakSelf setAttributedText:attrString];
                weakSelf.selectedRange = r;
                
                if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                    weakSelf.scrollEnabled = YES;
                }
            }
            else {
                NSLog(@"results thrown away");
            }
        });
    };
}

// override RichTextEditor since we're using the Toolbar differently

- (void)updateToolbarState {
}


#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    self.charTypedSeqNum++;
    NSRange selectedRange = textView.selectedRange;
    NSMutableString *insertedText = [[NSMutableString alloc] init];
    // old range used to calculate how much text we need to process
    NSDictionary *prevSegment = [self.helper segmentForRange:range fromSegments:self.segments];
    NSRange prevSegmentRange = NSMakeRange([prevSegment[@"location"] integerValue], [prevSegment[@"length"] integerValue]);
    
    // backspace pressed
    if ([text isEqualToString:@""]) {
        [textView deleteBackward];
        if (selectedRange.location > 0) {
            selectedRange = NSMakeRange(selectedRange.location-1, 0);
        }
    }
    // newline entered
    else if ([text isEqualToString:@"\n"]) {
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSUInteger leftBrackers = [self.helper occurancesOfString:@[@"\\{"] text:beginningText addCaptureParen:YES].count;
        NSUInteger rightBrackers = [self.helper occurancesOfString:@[@"\\}"] text:beginningText addCaptureParen:YES].count;
        NSInteger indentationCt = leftBrackers - rightBrackers;
        if (indentationCt<0) {
            indentationCt = 0;
        }
        BOOL inBrackets = [self.helper text:textView.text range:range leftNeighbor:@"{" rightNeighbor:@"}"];
        textView.selectedRange = range;
        
        [insertedText appendString:@"\n"];
        for (int i=0; i<indentationCt; i++) {
            [insertedText appendString:self.indentation];
        }
        
        if (inBrackets) {
            [insertedText appendString:@"\n"];
            for (int i=0; i<indentationCt-1; i++) {
                [insertedText appendString:self.indentation];
            }
            NSRange range = textView.selectedRange;
            selectedRange.location = range.location + insertedText.length - self.indentation.length*(indentationCt-1)-1;
        }
        else {
            selectedRange.location = range.location + insertedText.length;
        }
    }
    // anything else entered
    else {
        selectedRange = NSMakeRange(selectedRange.location+text.length, 0);

        // when single char typed, check for replace { for {} , ...
        if (text.length == 1) {
            NSDictionary *dic = [self.textReplaceDic objectForKey:text];
            if (dic) {
                [insertedText appendString:dic[@"value"]];
                selectedRange.location = range.location + [dic[@"offset"] intValue];
            }
            else {
                NSString *nextChar = self.text.length>range.location ? [self.text substringWithRange:NSMakeRange(range.location, 1)] : nil;
                if (nextChar && [text isEqualToString:nextChar] && [self.textSkipDic objectForKey:nextChar]) {
                    NSDictionary *skipDic = self.textSkipDic[nextChar];
                    selectedRange = range;
                    selectedRange.location += [skipDic[@"offset"] intValue];
                }
                else {
                    [insertedText appendString:text];
                }
            }
        }
        else {
            [insertedText appendString:text];
        }
    }
    if (insertedText.length>0) {
        [textView insertText:insertedText];
     }

    if (self.syntaxHighlightOn) {
        [self parseAndHighlight:range selectedRange:selectedRange prevSegmentRange:prevSegmentRange];
    }
    
    textView.selectedRange = selectedRange;

    return NO;
}

#pragma mark UITextViewTextDidChangeNotification

// inspired by http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/

// The callback for frame-changing of keyboard
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
 
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    
    self.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark MyRichTextEditorToolbarDataSource

- (void)insertText:(NSString *)text cursorOffset:(NSUInteger)cursorOffset
{
    [self textView:self shouldChangeTextInRange:self.selectedRange replacementText:text];
}

- (void)didDismissKeyboard
{
    [self resignFirstResponder];
}

- (void)loadWithText:(NSString *)text
{
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        // newline at end of file causes UITextView to hang
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    self.text = text;
    [self.parser parseText:self.text segment:self.segments keywords:self.keywordsDic];
    self.segments = [[self.segments sortedArrayUsingDescriptors:@[self.helper.sortDesc]] mutableCopy];

    NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
    [attrString applySegments:self.segments colorsDic:self.colorsDic];
    [self setAttributedText:attrString];
}

- (void)parseAndHighlight:(NSRange)range selectedRange:(NSRange)selectedRange prevSegmentRange:(NSRange)prevSegmentRange {
    __weak MyRichTextEditor *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        long backgroundCharTypedSeqNum = weakSelf.charTypedSeqNum;
        NSMutableArray *segmentsCopy = [weakSelf.segments mutableCopy];
        NSString *textCopy = [weakSelf.text copy];
        NSRange selectedRangeCopy = selectedRange;
        
        [weakSelf.parser parseText:textCopy segment:segmentsCopy keywords:weakSelf.keywordsDic];
        segmentsCopy = [[segmentsCopy sortedArrayUsingDescriptors:@[weakSelf.helper.sortDesc]] mutableCopy];
        
        NSDictionary *newSegment = [weakSelf.helper segmentForRange:range fromSegments:segmentsCopy];
        NSRange newRange = NSMakeRange([newSegment[@"location"] integerValue], [newSegment[@"length"] integerValue]);
        
        NSRange rangeUnion;
        if ((prevSegmentRange.length>0 || prevSegmentRange.location>0) && (newRange.length>0 || newRange.location>0)) {
            rangeUnion = NSUnionRange(prevSegmentRange, newRange);
        }
        else if (newRange.length>0 || newRange.location>0) {
            rangeUnion = newRange;
        }
        else if (prevSegmentRange.length>0 || prevSegmentRange.location>0) {
            rangeUnion = prevSegmentRange;
        }
        else {
            // should never get here
            NSAssert(NO, @"");
        }
        
        segmentsCopy = [weakSelf.helper segmentsForRange:rangeUnion fromSegments:segmentsCopy];
        
        weakSelf.parseCompletionHandler(backgroundCharTypedSeqNum, segmentsCopy, selectedRangeCopy);
    });
}

- (void)drawRect:(CGRect)rect {
    
    if (self.lineNumberGutterWidth == 0) {
        [super drawRect:rect];
    }
    else {
        //  Drag the line number gutter background.  The line numbers them selves are drawn by LineNumberLayoutManager.
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect bounds = self.bounds;
        
        CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
        CGContextFillRect(context, CGRectMake(bounds.origin.x, bounds.origin.y, self.lineNumberGutterWidth, bounds.size.height));
        
        CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGContextStrokeRect(context, CGRectMake(bounds.origin.x + 39.5, bounds.origin.y, 0.5, CGRectGetHeight(bounds)));
        
        [super drawRect:rect];
    }
}

// turns on syntax highlighting, if turned off, removes attributes

- (void)setSyntaxHighlightOn:(BOOL)syntaxHighlightOn {
    _syntaxHighlightOn = syntaxHighlightOn;
    if (!_syntaxHighlightOn) {
        NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
        [attrString removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, self.text.length)];
        [self setAttributedText:attrString];
    }
}

@end
