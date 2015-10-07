//
//  PTDRichTextEditorToolbar.m
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Extends the toolbar driven off a config file.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PTDRichTextEditorToolbar.h"
#import "PTDRichTextEditorToggleButton.h"
#import "PTDRichTextEditorCategoryViewController.h"
#import "PTDNavViewController.h"

@interface PTDRichTextEditorToolbar() <PTDRichTextEditorMacroPickerViewControllerDelegate>
@property (nonatomic, strong) PTDNavViewController *navVC;
@property (nonatomic, strong) NSArray *menuJson;
@property (nonatomic, strong) NSMutableArray *btnArray;
@end

#define SEPARATOR_VIEW 1001

@implementation PTDRichTextEditorToolbar

// Indicate that we actually intend to override RichTextEditorToolbarDataSource as PTD* without re-synthesizing dataSource
// http://stackoverflow.com/a/29667762/254187
@dynamic dataSource;

/**
 *  Initializes toolbar buttons with the default iPhone and iPad menus, declared in menu~iphone.json and menu~ipad.json.
 *
 *  Don't rename this method! It's overriding the RichTextEditorToolbar method of the same name.
 */
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
    NSArray *menuJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
        NSLog(@"JSONObjectWithData error: %@", error);
    else
        [self setButtonArrayFromJson:menuJson];
}

- (void)initializeCustomButtonsFromJsonResourceWithName:(NSString *)resourceName error:(NSError **)error
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"No data returned for filePath: %@", filePath]};
        *error = [NSError errorWithDomain:@"com.ptd.CodeTextEditor" code:-100 userInfo:userInfo];
        return;
    }

    NSArray *menuJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:error];
    NSError *checkableError = *error;  // We have to do this to dereference the error properly. Testing for nil on `error` always returns not-nil.
    if (checkableError) {
        return;
    }
    [self setButtonArrayFromJson:menuJson];
}

/**
 *  Sets toolbar buttons from a set of buttons.
 *  Buttons are loaded from JSON into an NSArray of PTDRichTextEditorToggleButtons, then passed in.
 */
- (void)setButtonArrayFromJson:(NSArray *)menuJson
{
    self.menuJson = menuJson;
    
    self.btnArray = [@[] mutableCopy];
    
    for (NSDictionary *dic in self.menuJson) {
        PTDRichTextEditorToggleButton *btn = [self buttonWithJson:dic];
        [self.btnArray addObject:btn];
    }
    
    [self populateToolbar];
}

- (PTDRichTextEditorToggleButton *)buttonWithJson:(NSDictionary*)json
{
    NSString * text = json[@"text"];
    NSString * image = json[@"image"];
    NSNumber* width = json[@"width"];
    SEL selector = @selector(btnSelected:);

	PTDRichTextEditorToggleButton *button = [[PTDRichTextEditorToggleButton alloc] initWithFrame:CGRectZero json:json];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	[button setFrame:CGRectMake(0, 0, [width intValue], 0)];
	[button.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
	[button.titleLabel setTextColor:[UIColor blackColor]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:text forState:UIControlStateNormal];
    if (image) {
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    }
	return button;
}

- (void)populateToolbar
{
    [super populateToolbar];
    
	CGRect visibleRect;
	visibleRect.origin = self.contentOffset;
	visibleRect.size = self.bounds.size;

    // removes previously added views to toolbar, mainly spaces
    for (UIView *v in [self.subviews copy]) {
        [v removeFromSuperview];
    }

    UIView *lastAddedView = self.subviews.lastObject;

    for (RichTextEditorToggleButton *btn in self.btnArray) {
		UIView *separatorView = [self separatorView];
		[self addView:btn afterView:lastAddedView withSpacing:YES];
		[self addView:separatorView afterView:btn withSpacing:YES];
		lastAddedView = btn;
    }

	[self scrollRectToVisible:visibleRect animated:NO];
}

- (UIView *)separatorView
{
    UIView *v = [super separatorView];
    v.tag = SEPARATOR_VIEW;
    return v;
}

- (void)btnSelected:(id)sender {
    PTDRichTextEditorToggleButton *btn = (PTDRichTextEditorToggleButton*)sender;
    NSDictionary *json  = btn.json;
    if ([json[@"type"] isEqualToString:@"text"]) {
        [[UIDevice currentDevice] playInputClick];
        [self.dataSource insertText:json[@"value"] cursorOffset:[json[@"offset"] intValue]];
    }
    else if ([json[@"type"] isEqualToString:@"category"]) {
        if (!self.navVC) {
            PTDRichTextEditorCategoryViewController *macroPicker = [[PTDRichTextEditorCategoryViewController alloc] initWithJson:json[@"children"]];
            self.navVC = [[PTDNavViewController alloc] initWithRootViewController:macroPicker];
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

- (void)setSeparaterViewColor:(UIColor *)separaterViewColor {
    for (UIView *v in self.subviews) {
        if (v.tag == SEPARATOR_VIEW) {
            v.backgroundColor = separaterViewColor;
        }
    }
}

@end
