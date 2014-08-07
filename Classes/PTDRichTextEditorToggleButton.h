//
//  PTDRichTextEditorToggleButton.h
//  RichTextEditor
//
//  Created by Matthew Chung on 7/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "RichTextEditorToggleButton.h"

@interface PTDRichTextEditorToggleButton : RichTextEditorToggleButton
- (id)initWithFrame:(CGRect)frame json:(NSDictionary*)json;
@property (nonatomic, strong, readonly) NSDictionary *json;
@end
