//
//  RichTextEditorMacroPicker.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MyRichTextEditorMacroPickerViewControllerDelegate <NSObject>
- (void)richTextEditorMacroPickerViewControllerDidSelectText:(NSDictionary*)json;
- (void)richTextEditorMacroPickerViewControllerDidSelectClose;
@end


@protocol MyRichTextEditorMacroPicker <NSObject>

@property (nonatomic, weak) id<MyRichTextEditorMacroPickerViewControllerDelegate> delegate;

@end

