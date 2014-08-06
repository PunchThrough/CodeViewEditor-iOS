//
//  MyRichTextEditorToggleButton.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/16/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "RichTextEditorToggleButton.h"

@interface MyRichTextEditorToggleButton : RichTextEditorToggleButton
- (id)initWithFrame:(CGRect)frame json:(NSDictionary*)json;
@property (nonatomic, strong, readonly) NSDictionary *json;
@end
