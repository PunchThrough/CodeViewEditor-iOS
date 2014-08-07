//
//  RichTextEditorMacroPicker.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Extension for RichTextEditorMacroPicker

#import <Foundation/Foundation.h>

@protocol PTDRichTextEditorMacroPickerViewControllerDelegate <NSObject>
- (void)richTextEditorMacroPickerViewControllerDidSelectText:(NSDictionary*)json;
- (void)richTextEditorMacroPickerViewControllerDidSelectClose;
@end


@protocol PTDRichTextEditorMacroPicker <NSObject>

@property (nonatomic, weak) id<PTDRichTextEditorMacroPickerViewControllerDelegate> delegate;

@end

