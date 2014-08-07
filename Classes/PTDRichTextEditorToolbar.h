//
//  PTDRichTextEditorToolbar.h
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Extends the toolbar
//

#import "RichTextEditorToolbar.h"
#import "RichTextEditorToolbar+Protected.h"
#import "PTDRichTextEditorMacroPicker.h"

@protocol PTDRichTextEditorToolbarDataSource <RichTextEditorToolbarDataSource>
- (void)insertText:(NSString *)text cursorOffset:(NSUInteger)cursorOffset;
- (void)didDismissKeyboard;
@end

@interface PTDRichTextEditorToolbar : RichTextEditorToolbar <UIInputViewAudioFeedback>
@property (nonatomic, weak) id <PTDRichTextEditorToolbarDataSource> dataSource;

@end


