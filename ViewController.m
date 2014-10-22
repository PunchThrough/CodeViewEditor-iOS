//
//  ViewController.m
//  RichTextEdtor
//
//  Created by Matthew Chung on 7/17/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<PTDCodeViewEditorEventsDelegate>
@property (strong, nonatomic) PTDCodeViewEditor *codeTextEditor;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged) name:UIContentSizeCategoryDidChangeNotification object:nil];

    self.codeTextEditor = [[PTDCodeViewEditor alloc] initWithLineViewWidth:25 textReplaceFile:@"textReplace" keywordsFile:@"keywords" textColorsFile:@"textColors" textSkipFile:@"textSkip"];
    self.codeTextEditor.translatesAutoresizingMaskIntoConstraints = NO;
    self.codeTextEditor.separatorViewColor = [UIColor colorWithRed:0 green:125.0/255.0 blue:1 alpha:1];

    NSError *error;
    [self.codeTextEditor setToolbarButtonsFromJsonResourceWithName:@"custom-menu" error:&error];
    if (error) {
        @throw error;
    }
    
    [self.codeTextEditor setEditorEventsDelegate:self];
    [self.view addSubview:self.codeTextEditor];
    
    NSDictionary *views = @{@"myRichTextEditor":self.codeTextEditor};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myRichTextEditor]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[myRichTextEditor]|" options:0 metrics:nil views:views]];
    
    [self preferredContentSizeChanged];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"examplesketch" ofType:@"ino"];
    NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSStringEncodingConversionAllowLossy error:nil];
    [self.codeTextEditor loadWithText:myText];    
}

- (void)preferredContentSizeChanged {
    self.codeTextEditor.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)openedKeyboardForEditor:(PTDCodeViewEditor *)editor
{
    NSLog(@"Opened keyboard for editor: %@", editor);
}

- (void)dismissedKeyboardForEditor:(PTDCodeViewEditor *)editor
{
    NSLog(@"Dismissed keyboard for editor: %@", editor);
}

@end
