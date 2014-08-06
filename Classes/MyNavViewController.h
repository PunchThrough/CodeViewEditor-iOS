//
//  MyNavViewController.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/17/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyRichTextEditorMacroPicker.h"

@interface MyNavViewController : UINavigationController <MyRichTextEditorMacroPicker>
@property (nonatomic, weak) id<MyRichTextEditorMacroPickerViewControllerDelegate> pickerDelegate;
@end
