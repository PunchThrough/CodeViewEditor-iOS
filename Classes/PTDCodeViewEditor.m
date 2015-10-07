//
//  PTDCodeViewEditor.m
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDCodeViewEditor.h"
#import "PTDRichTextEditorToolbar.h"
#import "PTDCodeViewEditorHelper.h"
#import "PTDCodeViewEditorParser.h"
#import "LineNumberLayoutManager.h"
#import "NSAttributedString+MyRichTextEditor.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
typedef void (^ParsingCompletion)(long seqNum, NSMutableArray *segments, NSRange range);

@interface PTDCodeViewEditor() <PTDRichTextEditorToolbarDataSource>
@property (nonatomic, weak) id <PTDCodeViewEditorEventsDelegate> eventsDelegate;
@property (nonatomic, strong) PTDCodeViewEditorHelper *helper;
@property (nonatomic, strong) PTDCodeViewEditorParser *parser;
@property (nonatomic, strong) NSMutableArray *segments;
@property (nonatomic) NSRange unhighlightedTextRange;
@property (nonatomic) NSInteger unsuccessfulHighlightAttempts;
@property (nonatomic, strong) NSMutableDictionary *textReplaceDic;
@property (nonatomic, strong) NSMutableDictionary *keywordsDic;
@property (nonatomic, strong) NSMutableDictionary *colorsDic;
@property (nonatomic, strong) NSMutableDictionary *textSkipDic;
@property (nonatomic, strong) NSMutableArray *lines;
@property (nonatomic, readwrite) long charTypedSeqNum;
@property (nonatomic, copy) ParsingCompletion parseCompletionHandler;
@property (nonatomic, strong) LineNumberLayoutManager *lm;
@property (nonatomic, readwrite) NSUInteger lineNumberGutterWidth;
@end

@implementation PTDCodeViewEditor

#pragma mark Init

- (id)initWithLineViewWidth:(int)lineNumberWidth textReplaceFile:(NSString*)textReplaceFile keywordsFile:(NSString*)keywordsFile textColorsFile:(NSString*)textColorsFile textSkipFile:(NSString*)textSkipFile {
    // block copied from https://github.com/alldritt/TextKit_LineNumbers/blob/master/TextKit_LineNumbers/LineNumberTextView.m
    if (lineNumberWidth>0) {
        NSTextStorage* ts = [[NSTextStorage alloc] init];
        self.lm = [[LineNumberLayoutManager alloc] init];
        NSTextContainer* tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        
        //  Wrap text to the text view's frame
        tc.widthTracksTextView = YES;

        self.lineNumberGutterWidth = lineNumberWidth;

        //  Exclude the line number gutter from the display area available for text display.
        tc.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, self.lineNumberGutterWidth+4, CGFLOAT_MAX)]];
        
        [self.lm addTextContainer:tc];
        [ts addLayoutManager:self.lm];
        
        if ((self = [super initWithFrame:CGRectZero textContainer:tc])) {
            self.contentMode = UIViewContentModeRedraw; // cause drawRect: to be called on frame resizing and divice rotation
            [self commonInitialization];
        }
    }
    else {
        self = [super initWithFrame:CGRectZero];
    }
    
    NSArray *textJson = nil;
    NSString *filePath = nil;
    if (textReplaceFile) {
        filePath = [[NSBundle mainBundle] pathForResource:textReplaceFile ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSError *error;
        textJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            NSLog(@"JSONObjectWithData error: %@", error);
            NSAssert(NO, @"");
        }
    }
    
    self.textReplaceDic = [@{} mutableCopy];
    for (NSDictionary *dic  in textJson) {
        self.textReplaceDic[dic[@"text"]] = dic;
    }
    
    if (keywordsFile) {
        filePath = [[NSBundle mainBundle] pathForResource:keywordsFile ofType:@"txt"];
        self.keywordsDic = [self.helper keywordsForPath:filePath];
    }
    if (textColorsFile) {
        filePath = [[NSBundle mainBundle] pathForResource:textColorsFile ofType:@"json"];
        self.colorsDic = [self.helper colorsForPath:filePath];
    }
    if (textSkipFile) {
        filePath = [[NSBundle mainBundle] pathForResource:textSkipFile ofType:@"json"];
        self.textSkipDic = [self.helper textSkipForPath:filePath];
    }

    self.alwaysBounceVertical = YES;
    
    return self;
}

- (void)setEditorEventsDelegate:(id<PTDCodeViewEditorEventsDelegate>)eventsDelegate
{
    [self setEventsDelegate:eventsDelegate];
}

#pragma mark Override RichTextEditor

- (void)commonInitialization
{
    self.borderColor = [UIColor lightGrayColor];
    self.borderWidth = 1.0;
    
	self.toolBar = [[PTDRichTextEditorToolbar alloc] initWithFrame:CGRectMake(0, 0, [self currentScreenBoundsDependOnOrientation].size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)
                                                         delegate:self
                                                       dataSource:self];
    
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.spellCheckingType = UITextSpellCheckingTypeNo;
    
    self.helper = [[PTDCodeViewEditorHelper alloc] init];
    self.parser = [[PTDCodeViewEditorParser alloc] init];
    self.delegate = self;
    
    self.segments = [@[] mutableCopy];
    self.lines = [@[] mutableCopy];
    self.unhighlightedTextRange = NSMakeRange(0, 0);

    [self observeKeyboard];

    // default values
    self.indentation = @"    ";
    self.syntaxHighlightOn = YES;
    self.parseDelay = .5;

    // callback called when parsing complete. if there have not been changes to the text since the parse, as determined
    // by the seqNum, then the application of the segments for syntax highlighting is allowed to occur
    __weak PTDCodeViewEditor *weakSelf = self;
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
                weakSelf.unhighlightedTextRange = NSUnionRange(weakSelf.unhighlightedTextRange, range);
                weakSelf.unsuccessfulHighlightAttempts++;

                NSLog(@"results thrown away");
            }
        });
    };
}

// we're not doing this so override and throw away the method call

- (void)updateToolbarState {
}


#pragma mark UITextViewDelegate

// handles all char input and parsing of that input for syntax highlights

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // this is used to see if there have been changes since the parse
    self.charTypedSeqNum++;

    NSRange selectedRange = textView.selectedRange;
    NSMutableString *insertedText = [[NSMutableString alloc] init];

    // prevSegmentRange is the segment before adding the text the range falls under
    // this is later used to compare with the segment the range falls under after the text is added
    // then the union of the two is what is redrawn via the attr strings
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
        // determines indentation based on count on ({ count) - (} count) up to the cursor
        NSString *beginningText = [textView.text substringToIndex:range.location];
        NSUInteger leftBrackers = [self.helper occurancesOfString:@[@"\\{"] text:beginningText addCaptureParen:YES].count;
        NSUInteger rightBrackers = [self.helper occurancesOfString:@[@"\\}"] text:beginningText addCaptureParen:YES].count;
        NSInteger indentationCt = leftBrackers - rightBrackers;
        if (indentationCt<0) {
            indentationCt = 0;
        }
        // determines if newline entered like {\n} and if so, adds indentation
        // then sets cursor to last space on the entered newline
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
    // other stuff entered
    else {
        // default selected range for this case is at the end of the text
        selectedRange = NSMakeRange(selectedRange.location+text.length, 0);

        if (text.length == 1) {
            // char replacing, ie when single char typed, check for insertion values. ie { for {} , ( for (), [ for []
            NSDictionary *dic = [self.textReplaceDic objectForKey:text];
            if (dic) {
                //checking to see if the next character is whitespace before inserting anything.
                NSString *nextChar = self.text.length>range.location ? [self.text substringWithRange:NSMakeRange(range.location, 1)] : nil;
                if ( nextChar ) {
                    nextChar = [nextChar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if ( [nextChar isEqualToString:@""] ) {
                        [insertedText appendString:dic[@"value"]];
                        selectedRange.location = range.location + [dic[@"offset"] intValue];
                    } else {
                        [insertedText appendString:text];
                    }
                } else {
                    [insertedText appendString:dic[@"value"]];
                    selectedRange.location = range.location + [dic[@"offset"] intValue];
                }
            }
            // char skipping, ie typing } when {cursor} yields {}cursor
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

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ( [self.eventsDelegate respondsToSelector:@selector(shouldBeginEditingForEditor:)] ) {
        return [self.eventsDelegate shouldBeginEditingForEditor:self];
    } else {
        return YES;
    }
}

#pragma mark UITextViewTextDidChangeNotification

// inspired by http://www.think-in-g.net/ghawk/blog/2012/09/practicing-auto-layout-an-example-of-keyboard-sensitive-layout/

// The callback for frame-changing of keyboard
- (void)keyboardDidShow:(NSNotification *)notification {
    
    if ( !self.isFirstResponder ) {
        return;
    }
    
    if ([[self eventsDelegate] respondsToSelector:@selector(openedKeyboardForEditor:)]) {
        [[self eventsDelegate] openedKeyboardForEditor:self];
    }
    
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
 
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    BOOL isOS8OrLater = [[[UIDevice currentDevice] systemVersion] hasPrefix:@"8"];
    CGFloat height;
    
    if ( isOS8OrLater ) {
        height = keyboardFrame.size.height;
    } else {
        height = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    }
    
    self.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if ( !self.isFirstResponder ) {
        return;
    }
    [self closeKeyboardAndToolbar];
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark MyRichTextEditorToolbarDataSource

// when text inserted from a menu

- (void)insertText:(NSString *)text cursorOffset:(NSUInteger)cursorOffset
{
    [self textView:self shouldChangeTextInRange:self.selectedRange replacementText:text];
}

- (void)didDismissKeyboard
{
    if ([[self eventsDelegate] respondsToSelector:@selector(dismissedKeyboardForEditor:)]) {
        [[self eventsDelegate] dismissedKeyboardForEditor:self];
    }
    [self resignFirstResponder];
}

- (void)closeKeyboardAndToolbar
{
    [self didDismissKeyboard];
}

// used to initialize a file with text

- (void)loadWithText:(NSString *)text
{
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        // newline at end of file causes UITextView to hang
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    self.text = text;
    
    // performs a parse on the whole file then builds the segments and assigns the colors
    [self.parser parseText:self.text segment:self.segments keywords:self.keywordsDic];
    self.segments = [[self.segments sortedArrayUsingDescriptors:@[self.helper.sortDesc]] mutableCopy];

    NSMutableAttributedString *attrString = [self.attributedText mutableCopy];
    [attrString applySegments:self.segments colorsDic:self.colorsDic];
    [self setAttributedText:attrString];
}

// parses the file and builds the ABT

- (void)parseAndHighlight:(NSRange)range selectedRange:(NSRange)selectedRange prevSegmentRange:(NSRange)prevSegmentRange {
    __weak PTDCodeViewEditor *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // saves the seq number for later comparison
        long backgroundCharTypedSeqNum = weakSelf.charTypedSeqNum;
        NSMutableArray *segmentsCopy = weakSelf.segments ? [weakSelf.segments mutableCopy] : [NSMutableArray new];
        NSString *textCopy = [weakSelf.text copy];
        NSRange unhighlightedTextRange = weakSelf.unhighlightedTextRange;

        // parses the entire file
        [weakSelf.parser parseText:textCopy segment:segmentsCopy keywords:weakSelf.keywordsDic];
        segmentsCopy = [[segmentsCopy sortedArrayUsingDescriptors:@[weakSelf.helper.sortDesc]] mutableCopy];

        // see comment at top of shouldChangeTextInRange
        NSDictionary *newSegment = [weakSelf.helper segmentForRange:range fromSegments:segmentsCopy];
        NSRange newRange = NSMakeRange([newSegment[@"location"] integerValue], [newSegment[@"length"] integerValue]);
        
        NSRange rangeUnion = NSMakeRange(0, 0);

        if (prevSegmentRange.length>0 || prevSegmentRange.location>0) {
            rangeUnion = prevSegmentRange;
        }
        if (newRange.length>0 || newRange.location>0) {
            rangeUnion = (rangeUnion.length>0 || rangeUnion.location>0) ? NSUnionRange(rangeUnion, newRange) : newRange;
        }
        if (selectedRange.length>0 || selectedRange.location>0) {
            rangeUnion = (rangeUnion.length>0 || rangeUnion.location>0) ? NSUnionRange(rangeUnion, selectedRange) : selectedRange;
        }

        if (unhighlightedTextRange.length>0 || unhighlightedTextRange.location>0) {
            rangeUnion = NSUnionRange(rangeUnion, unhighlightedTextRange);
             weakSelf.unsuccessfulHighlightAttempts--;
            if (!weakSelf.unsuccessfulHighlightAttempts) {
                weakSelf.unhighlightedTextRange = NSMakeRange(0, 0);
            }
        }

        segmentsCopy = [weakSelf.helper segmentsForRange:rangeUnion fromSegments:segmentsCopy];
        weakSelf.parseCompletionHandler(backgroundCharTypedSeqNum, segmentsCopy, rangeUnion);
    });
}

// block copied from https://github.com/alldritt/TextKit_LineNumbers/blob/master/TextKit_LineNumbers/LineNumberTextView.m

- (void)drawRect:(CGRect)rect {
    
    if (self.lineNumberGutterWidth == 0) {
        [super drawRect:rect];
    }
    else {
        if (self.lineNumberGutterWidth != self.lm.lineNumberGutterWidth) {
            self.lm.lineNumberGutterWidth = self.lineNumberGutterWidth;
        }
        
        //  Drag the line number gutter background.  The line numbers them selves are drawn by LineNumberLayoutManager.
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect bounds = self.bounds;
        
        CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
        CGContextFillRect(context, CGRectMake(bounds.origin.x, bounds.origin.y, self.lineNumberGutterWidth, bounds.size.height));
        
        CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGContextStrokeRect(context, CGRectMake(bounds.origin.x + self.lineNumberGutterWidth, bounds.origin.y, 0.5, CGRectGetHeight(bounds)));
        
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

- (void)setSeparatorViewColor:(UIColor *)separatorViewColor {
    self.toolBar.separaterViewColor = separatorViewColor;
}

- (void)setToolbarButtonsFromJsonResourceWithName:(NSString *)resourceName error:(NSError **)error
{
    [self.toolBar initializeCustomButtonsFromJsonResourceWithName:resourceName error:error];
}

@end
