//
//  MyRichTextEditorToolbar.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import "MyRichTextEditorToolbar.h"
#import "MyRichTextEditorToggleButton.h"
#import "MyRichTextEditorCategoryViewController.h"
#import "MyNavViewController.h"

@interface MyRichTextEditorToolbar() <MyRichTextEditorMacroPickerViewControllerDelegate>
@property (nonatomic, strong) MyNavViewController *navVC;
@property (nonatomic, strong) NSArray *menuJson;
@property (nonatomic, strong) NSMutableArray *btnArray;
@end

@implementation MyRichTextEditorToolbar

- (void)initializeButtons
{
    NSString *filePathName;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        filePathName = @"menu~ipad";
    }
    else {
        filePathName = @"menu~iphone";
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filePathName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        filePath = [[NSBundle mainBundle] pathForResource:@"menu" ofType:@"json"];
        data = [NSData dataWithContentsOfFile:filePath];
    }
    NSError *error;
    self.menuJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
        NSLog(@"JSONObjectWithData error: %@", error);

    self.btnArray = [@[] mutableCopy];
    
    for (NSDictionary *dic in self.menuJson) {
        MyRichTextEditorToggleButton *btn = [self buttonWithJson:dic];
        [self.btnArray addObject:btn];
    }
}

- (MyRichTextEditorToggleButton *)buttonWithJson:(NSDictionary*)json
{
    NSString * text = json[@"text"];
    NSNumber* width = json[@"width"];
    SEL selector = @selector(btnSelected:);

	MyRichTextEditorToggleButton *button = [[MyRichTextEditorToggleButton alloc] initWithFrame:CGRectZero json:json];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	[button setFrame:CGRectMake(0, 0, [width intValue], 0)];
	[button.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
	[button.titleLabel setTextColor:[UIColor blackColor]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:text forState:UIControlStateNormal];
	
	return button;
}

- (void)populateToolbar
{
    [super populateToolbar];
    
	CGRect visibleRect;
	visibleRect.origin = self.contentOffset;
	visibleRect.size = self.bounds.size;
	
    UIView *lastAddedView = self.subviews.lastObject;

    for (RichTextEditorToggleButton *btn in self.btnArray) {
		UIView *separatorView = [self separatorView];
		[self addView:btn afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:btn withSpacing:YES];
		lastAddedView = btn;
    }

	[self scrollRectToVisible:visibleRect animated:NO];
}

- (void)btnSelected:(id)sender {
    MyRichTextEditorToggleButton *btn = (MyRichTextEditorToggleButton*)sender;
    NSDictionary *json  = btn.json;
    if ([json[@"type"] isEqualToString:@"text"]) {
        [[UIDevice currentDevice] playInputClick];
        [self.dataSource insertText:json[@"value"] cursorOffset:[json[@"offset"] intValue]];
    }
    else if ([json[@"type"] isEqualToString:@"category"]) {
        if (!self.navVC) {
            MyRichTextEditorCategoryViewController *macroPicker = [[MyRichTextEditorCategoryViewController alloc] initWithJson:json[@"children"]];
            self.navVC = [[MyNavViewController alloc] initWithRootViewController:macroPicker];
            self.navVC.pickerDelegate = self;
        }
        
        self.navVC.pickerDelegate = self;
        [self presentViewController:self.navVC fromView:sender];
    }
    else if ([json[@"type"] isEqualToString:@"selector"]) {
        if ([json[@"value"] isEqualToString:@"dismissKeyboard"]) {
            [self.dataSource didDismissKeyboard];
        }
    }
}

#pragma mark - RichTextEditorFontSizePickerViewControllerDelegate & RichTextEditorFontSizePickerViewControllerDataSource Methods -

- (void)richTextEditorMacroPickerViewControllerDidSelectText:(NSDictionary *)json
{
    [[UIDevice currentDevice] playInputClick];
    [self.dataSource insertText:json[@"value"] cursorOffset:[json[@"offset"] intValue]];
	[self dismissViewController];
}

- (void)richTextEditorMacroPickerViewControllerDidSelectClose
{
	[self dismissViewController];
}

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

- (void)redraw
{
}


@end
