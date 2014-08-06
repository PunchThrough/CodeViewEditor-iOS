//
//  NSAttributedString+MyRichTextEditor.h
//  RichTextEditor
//
//  Created by Matthew Chung on 8/1/14.
//  Copyright (c) 2014 Aryan Ghassemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (MyRichTextEditor)
- (void)applySegments:(NSArray*)segments colorsDic:colorsDic;
@end
