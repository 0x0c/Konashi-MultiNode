//
//  MasterViewController.m
//  MultiNode
//
//  Created by Akira Matsuda on 2014/06/15.
//  Copyright (c) 2014年 Akira Matsuda. All rights reserved.
//

#import "MasterViewController.h"
#import "Konashi.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
	NSMutableArray *_konashi;
}
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_konashi = [NSMutableArray new];
	[self reload];
	UIRefreshControl *r = [[UIRefreshControl alloc] init];
	[r addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
	self.refreshControl = r;
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(blink) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	}
	
	CBPeripheral *p = _objects[indexPath.row];
	cell.textLabel.text = p.name;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	__weak UITableView *t = tableView;
	__weak UITableViewCell *c = [tableView cellForRowAtIndexPath:indexPath];
	Konashi *konashi = [Konashi createKonashiWithConnectedHandler:^(Konashi *k) {
		NSLog(@"connected:%@", [k description]);
	} disconnectedHandler:^(Konashi *k) {
		NSLog(@"disconnected:%@", [k description]);
	} readyHandler:^(Konashi *k) {
		NSLog(@"ready:%@", [k description]);
		[k pinMode:KonashiS1 mode:KonashiPinModeInput];
		[k pinMode:KonashiLED2 mode:KonashiPinModeOutput];
		[k pinMode:KonashiLED3 mode:KonashiPinModeOutput];
		[k pinMode:KonashiLED4 mode:KonashiPinModeOutput];
		[k pinMode:KonashiLED5 mode:KonashiPinModeOutput];
		c.accessoryType = UITableViewCellAccessoryCheckmark;
		[t deselectRowAtIndexPath:indexPath animated:YES];
	}];
	CBPeripheral *p = _objects[indexPath.row];
	[konashi connectWithName:p.name];
	[_konashi addObject:konashi];
}

BOOL state;
- (void)blink
{
	if (state) {
		[_konashi enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			Konashi *k = (Konashi *)obj;
			[k digitalWrite:KonashiLED3 value:KonashiLevelLow];
		}];
	}
	else {
		[_konashi enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			Konashi *k = (Konashi *)obj;
			[k digitalWrite:KonashiLED3 value:KonashiLevelHigh];
		}];
	}
	state = !state;
}

- (void)reload
{
	[self.refreshControl beginRefreshing];
	[_konashi enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Konashi *k = (Konashi *)obj;
		[k disconnect];
	}];
	[_konashi removeAllObjects];
	[self.tableView reloadData];
	
	[Konashi findAny:^(NSArray *array) {
		NSLog(@"%@", [array description]);
	} timeoutBlock:^(NSArray *array) {
		_objects = [array copy];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
			[self.refreshControl endRefreshing];
		});
	} timeoutInterval:3];
}

@end
