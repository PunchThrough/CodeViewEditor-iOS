//
//  PTDNavViewController.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/17/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Allows for drilling through categories in menu

#import <UIKit/UIKit.h>
#import "PTDRichTextEditorMacroPicker.h"

@interface PTDNavViewController : UINavigationController <PTDRichTextEditorMacroPicker>
@property (nonatomic, weak) id<PTDRichTextEditorMacroPickerViewControllerDelegate> pickerDelegate;
@end
