//
//  RichTextEditorFontSizePickerViewController.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//
// https://github.com/aryaxt/iOS-Rich-Text-Editor
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MyRichTextEditorCategoryViewController.h"
#import "MyNavViewController.h"

@interface MyRichTextEditorCategoryViewController()
@property (nonatomic, strong) NSArray *json;
@property (nonatomic, strong) MyRichTextEditorCategoryViewController *macroPicker;
@end

@implementation MyRichTextEditorCategoryViewController

- (id)initWithJson:(NSArray*)json
{
    self = [super init];
    if (self) {
        self.json = json;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
			
    self.tableview.frame = self.view.bounds;
	[self.view addSubview:self.tableview];


#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    
    self.preferredContentSize = CGSizeMake(140, 400);
#else
    
	self.contentSizeForViewInPopover = CGSizeMake(240, 400);
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

#pragma mark - UITableView Delegate & Datasrouce -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.json.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MacroCell";
	
	NSDictionary *dic = self.json[indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	
	cell.textLabel.text = dic[@"text"];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dic = self.json[indexPath.row];
    if ([dic[@"type"] isEqualToString:@"category"]) {
        self.macroPicker = [[MyRichTextEditorCategoryViewController alloc] initWithJson:dic[@"children"]];
        [self.navigationController pushViewController:self.macroPicker animated:YES];
    }
    else {
        MyNavViewController *myNav = (MyNavViewController *)self.navigationController;
        [myNav.pickerDelegate richTextEditorMacroPickerViewControllerDidSelectText:dic];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)cancel:(id)sender
{
    MyNavViewController *myNav = (MyNavViewController *)self.navigationController;
    [myNav.pickerDelegate richTextEditorMacroPickerViewControllerDidSelectClose];
}

#pragma mark - Setter & Getter -

- (UITableView *)tableview
{
	if (!_tableview)
	{
		_tableview = [[UITableView alloc] initWithFrame:self.view.bounds];
		_tableview.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tableview.delegate = self;
		_tableview.dataSource = self;
	}
	
	return _tableview;
}

@end
