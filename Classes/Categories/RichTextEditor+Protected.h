//
//  RichTextEditor+Protected.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/15/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

@interface RichTextEditor(Protected) <RichTextEditorToolbarDelegate, RichTextEditorToolbarDataSource>
- (CGRect)currentScreenBoundsDependOnOrientation;
- (void)setText:(NSString *)text;
- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range;
- (void)removeAttributeForKey:(NSString *)key atRange:(NSRange)range;
@property (nonatomic, strong) RichTextEditorToolbar *toolBar;
@end
