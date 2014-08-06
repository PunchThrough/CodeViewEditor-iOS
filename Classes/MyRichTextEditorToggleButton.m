//
//  MyRichTextEditorToggleButton.m
//  RichTextEditor
//
//  Created by Matthew Chung on 7/16/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import "MyRichTextEditorToggleButton.h"

@interface MyRichTextEditorToggleButton()
@property (nonatomic, strong) NSDictionary *json;
@end

@implementation MyRichTextEditorToggleButton

- (id)initWithFrame:(CGRect)frame json:(NSDictionary*)json
{
    self = [super initWithFrame:frame];
    if (self) {
        self.json = json;
    }
    return self;
}

@end
