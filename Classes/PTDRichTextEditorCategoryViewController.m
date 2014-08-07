//
//  PTDRichTextEditorCategoryViewController.m
//  RichTextEdtor
//
//  Created by Matthew Chung on 7/17/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDRichTextEditorCategoryViewController.h"
#import "PTDNavViewController.h"

@interface PTDRichTextEditorCategoryViewController()
@property (nonatomic, strong) NSArray *json;
@property (nonatomic, strong) PTDRichTextEditorCategoryViewController *macroPicker;
@end

@implementation PTDRichTextEditorCategoryViewController

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
    
    self.preferredContentSize = CGSizeMake(240, 400);
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
        self.macroPicker = [[PTDRichTextEditorCategoryViewController alloc] initWithJson:dic[@"children"]];
        [self.navigationController pushViewController:self.macroPicker animated:YES];
    }
    else {
        PTDNavViewController *myNav = (PTDNavViewController *)self.navigationController;
        [myNav.pickerDelegate richTextEditorMacroPickerViewControllerDidSelectText:dic];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)cancel:(id)sender
{
    PTDNavViewController *myNav = (PTDNavViewController *)self.navigationController;
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
