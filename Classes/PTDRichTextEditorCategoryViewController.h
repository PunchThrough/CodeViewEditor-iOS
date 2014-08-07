//
//  PTDRichTextEditorCategoryViewController.h
//  RichTextEdtor
//
//  Created by Matthew Chung on 7/17/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//
//  Allows for drilling through categories 

#import <UIKit/UIKit.h>
#import "PTDRichTextEditorMacroPicker.h"

@interface PTDRichTextEditorCategoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithJson:(NSDictionary*)json;
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong, readonly) NSArray *json;
@end
