//
//  PTDCodeViewEditor.h
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "RichTextEditor.h"

@interface RichTextEditor(Protected) <RichTextEditorToolbarDelegate, RichTextEditorToolbarDataSource>
- (CGRect)currentScreenBoundsDependOnOrientation;
- (void)setText:(NSString *)text;
- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range;
- (void)removeAttributeForKey:(NSString *)key atRange:(NSRange)range;
@property (nonatomic, strong) RichTextEditorToolbar *toolBar;
@end

@interface PTDCodeViewEditor : RichTextEditor <UITextViewDelegate>

/**
 *  Initializes the RichTextEditor
 *
 *  @param lineNumbers turns on or off line numbers
 *  @param textReplaceFile the file that contains text entry substitions , ie ( for ()
 *  @param keywordsFile the file that contains keywords for syntax highlights
 *  @param textColorsFile the file that maps keywords to colors for syntax hightlights
 *  @param textSkipFile the file that contains keystrokes that skip the next char, ie with (cursor), typing ) goes to ()cursor
 *
 *  @return an instance of the PTDRichTextEditor
 */
- (id)initWithLineNumbers:(BOOL)lineNumbers textReplaceFile:(NSString*)textReplaceFile keywordsFile:(NSString*)keywordsFile textColorsFile:(NSString*)textColorsFile textSkipFile:(NSString*)textSkipFile;

/**
 *  loads the UITextView with text
 *
 *  @param text the text to load the file with
 */
- (void)loadWithText:(NSString *)text;

/**
 *  color for comments
 */
@property (nonatomic, strong) UIColor *commentColor;

/**
 *  color for strings
 */
@property (nonatomic, strong) UIColor *stringColor;

/**
 *  color for invalid strings
 */
@property (nonatomic, strong) UIColor *invalidStringColor;

/**
 *  indentation string
 */
@property (nonatomic, strong) NSString *indentation;

/**
 *  turning on or off syntax highlights
 */
@property (nonatomic, readwrite) BOOL syntaxHighlightOn;

/**
 *  after a parse, the bg thread waits a delay before applying the parsed values for syntax highlights.
 *  delay is necessary since updating the main thread is a heavy op. this approach waits for a user pause to
 *  do the update
 */
@property (nonatomic, readwrite) NSTimeInterval parseDelay;

/**
 *  width of the line numbers view
 */
@property (nonatomic, readwrite) NSUInteger lineNumberGutterWidth;

@end
