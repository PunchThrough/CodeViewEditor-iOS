//
//  MyRichTextEditor.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditor.h"
#import "RichTextEditor+Protected.h"

@interface MyRichTextEditor : RichTextEditor <UITextViewDelegate>
- (id)initWithLineNumbers:(BOOL)lineNumbers textReplaceFile:(NSString*)textReplaceFile keywordsFile:(NSString*)keywordsFile textColorsFile:(NSString*)textColorsFile textSkipFile:(NSString*)textSkipFile;
- (void)loadWithText:(NSString *)text;
@property (nonatomic, strong) UIColor *commentColor;
@property (nonatomic, strong) UIColor *stringColor;
@property (nonatomic, strong) UIColor *invalidStringColor;
@property (nonatomic, strong) NSString *indentation;
@property (nonatomic, readwrite) BOOL syntaxHighlightOn;
@property (nonatomic, readwrite) NSTimeInterval parseDelay;
@end
