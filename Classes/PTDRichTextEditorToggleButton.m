//
//  MyRichTextEditorToggleButton.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDRichTextEditorToggleButton.h"

@interface PTDRichTextEditorToggleButton()
@property (nonatomic, strong) NSDictionary *json;
@end

@implementation PTDRichTextEditorToggleButton

- (id)initWithFrame:(CGRect)frame json:(NSDictionary*)json
{
    self = [super initWithFrame:frame];
    if (self) {
        self.json = json;
    }
    return self;
}

@end
