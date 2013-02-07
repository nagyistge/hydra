//
//  ActivityDetailViewController.m
//  Hydra
//
//  Created by Pieter De Baets on 11/10/12.
//  Copyright (c) 2012 Zeus WPI. All rights reserved.
//

#import "ActivityDetailViewController.h"
#import "AssociationActivity.h"
#import "Association.h"
#import "NSDateFormatter+AppLocale.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "FacebookEvent.h"

#define kInfoSection 0
#define KActionSection 1
#define kFaceBookSection 2
#define kFaceBookButtonSection 3

#define kTitleRow 0
#define kAssociationRow 1
#define kDateRow 2
#define kLocationRow 3

#define ENABLE_FACEBOOK 0

@interface ActivityDetailViewController () <EKEventEditViewDelegate>

@property (nonatomic, strong) AssociationActivity *activity;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) id<ActivityListDelegate> listDelegate;

@end

@implementation ActivityDetailViewController

- (id)initWithActivity:(AssociationActivity *)activity delegate:(id<ActivityListDelegate>)delegate
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.activity = activity;
        self.listDelegate = delegate;

        [self reloadFields];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Detail";

#if ENABLE_FACEBOOK
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(reloadData) name:FacebookEventDidUpdateNotification
                 object:nil];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Fast navigation between activitities
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[
        [UIImage imageNamed:@"navigation-up"], [UIImage imageNamed:@"navigation-down"]]];
    [segmentedControl addTarget:self action:@selector(segmentTapped:)
               forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0, 0, 90, 30);
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [self enableSegments:segmentedControl];

    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.rightBarButtonItem = segmentBarItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    GAI_Track([@"Activity > " stringByAppendingString:self.activity.title]);
}

- (void)reloadFields
{
    static NSDateFormatter *dateStartFormatter = nil;
    static NSDateFormatter *dateEndFormatter = nil;
    if (!dateStartFormatter || !dateEndFormatter) {
        dateStartFormatter = [NSDateFormatter H_dateFormatterWithAppLocale];
        dateStartFormatter.dateFormat = @"EEE d MMMM H:mm";
        dateEndFormatter = [NSDateFormatter H_dateFormatterWithAppLocale];
        dateEndFormatter.dateFormat = @"H:mm";
    }

    NSMutableArray *fields = [[NSMutableArray alloc] init];
    fields[kTitleRow] = self.activity.title;
    fields[kAssociationRow] = self.activity.association.displayedFullName;

    if (self.activity.end) {
        fields[kDateRow] = [NSString stringWithFormat:@"%@ - %@",
                            [dateStartFormatter stringFromDate:self.activity.start],
                            [dateEndFormatter stringFromDate:self.activity.end]];
    }
    else {
        fields[kDateRow] = [dateStartFormatter stringFromDate:self.activity.start];
    }

    fields[kLocationRow] = self.activity.location ? self.activity.location : @"";

    self.fields = fields;
}

- (void)reloadData
{
    DLog(@"reloadData");
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case kInfoSection:
            return 4;
        case KActionSection:
            return 1;
        case kFaceBookSection:
            return 2;
        case (kFaceBookButtonSection + 1):
            return 1;
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // TODO: add test if facebook is availble
#if ENABLE_FACEBOOK
    return 4;
#else
    return 2;
#endif
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kInfoSection) {
        BOOL isTitleRow = indexPath.row == kTitleRow;

        UIFont *font = [UIFont systemFontOfSize:13.0f];
        if (isTitleRow) font = [UIFont boldSystemFontOfSize:20.0f];

        NSString *text = self.fields[indexPath.row];
        CGFloat width = tableView.frame.size.width - (isTitleRow ? 40.0f : 125.0f);
        CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                           lineBreakMode:NSLineBreakByWordWrapping];

        return MAX(40.0f, size.height + (isTitleRow ? 26.0f : 18.0f));
    }
    else {
        return 44.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kInfoSection) {
        if (indexPath.row == kTitleRow) {
            static NSString *CellIdentifier = @"ActivityDetailTitleCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:CellIdentifier];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:20.0f];
                cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                cell.textLabel.numberOfLines = 0;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.textLabel.text = self.fields[indexPath.row];
            return cell;
        }
        else {
            static NSString *CellIdentifier = @"ActivityDetailCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                              reuseIdentifier:CellIdentifier];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0f];
                cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:13.0f];
                cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
                cell.detailTextLabel.numberOfLines = 0;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            switch (indexPath.row) {
                case kAssociationRow:
                    cell.textLabel.text = @"Vereniging";
                    break;
                case kDateRow:
                    cell.textLabel.text = @"Datum";
                    break;
                case kLocationRow:
                    cell.textLabel.text = @"Locatie";
                    break;
            }
            cell.detailTextLabel.text = self.fields[indexPath.row];

            return cell;
        }
    }
    else if(indexPath.section == KActionSection){
        static NSString *CellIdentifier = @"ActivityDetailButtonCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"Toevoegen aan agenda";
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor detailLabelTextColor];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
        return cell;
    }
#if ENABLE_FACEBOOK
    else if (indexPath.section == kFaceBookSection) {
        static NSString *CellIdentifier = @"FacebookDetailButtonCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier];
            cell.textLabel.font = [UIFont systemFontOfSize:12];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
        switch (indexPath.row) {
            case 0:
                DLog(@"Attendees: %@", self.activity.facebookEvent.attendees);
                cell.detailTextLabel.text = @"Gasten";
                cell.textLabel.text = [NSString stringWithFormat:@"Er zijn %@ mensen die komen.", self.activity.facebookEvent.attendees];
                break;
            case 1:
                cell.detailTextLabel.text = @"Vrienden";
                DLog(@"Friends: %d", [self.activity.facebookEvent.friendsAttending count]);
                cell.textLabel.text = [NSString stringWithFormat:@"Er zijn %d vrienden die komen.", [self.activity.facebookEvent.friendsAttending count]];
                break;
        }
        return cell;
    }
    else {
        static NSString *CellIdentifier = @"FacebookButtonCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:CellIdentifier];
            cell.textLabel.text = self.activity.facebookEvent.userAttending ? @"Aanwezig" : @"Gaan";
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor detailLabelTextColor];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
       /* if (!cell) {
            UIButton *attendingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [attendingButton setFrame:CGRectMake(10, 150, 80, 40)];

            [attendingButton setTitle:@"Gaan?" forState:UIControlStateNormal];
            [attendingButton setTitle:@"Aanwezig" forState:UIControlStateDisabled];
            [attendingButton setEnabled:!self.activity.facebookEvent.userAttending];
            [attendingButton addTarget:self.activity.facebookEvent action:@selector(postUserAttendsEvent:) forControlEvents:UIControlEventTouchUpInside];
            [cell addSubview:attendingButton];
        }//*/
        return cell;
    }
#else
    return nil;
#endif
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 1 || (indexPath.section == kFaceBookButtonSection) ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == KActionSection){
    EKEventStore *store = [[EKEventStore alloc] init];
    if([store respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [self performSelectorOnMainThread:@selector(addEventToCalendarStore:)
                                       withObject:store waitUntilDone:NO];
            }
        }];
    }
    else {
        [self addEventToCalendarStore:store];
    }
    }else if(indexPath.section == kFaceBookButtonSection){
        [self.activity.facebookEvent postUserAttendsEvent];
    }
}

- (void)addEventToCalendarStore:(EKEventStore *)store
{
    EKEvent *event  = [EKEvent eventWithEventStore:store];
    event.title     = self.activity.title;
    event.location  = self.activity.location;
    event.startDate = self.activity.start;
    event.endDate   = self.activity.end;

    [event setCalendar:[store defaultCalendarForNewEvents]];

    EKEventEditViewController *eventViewController = [[EKEventEditViewController alloc] init];

    eventViewController.event = event;
    eventViewController.eventStore = store;
    eventViewController.editViewDelegate = self;
    [self.navigationController presentModalViewController:eventViewController animated:YES];
}

- (void)eventEditViewController:(EKEventEditViewController *)controller
          didCompleteWithAction:(EKEventEditViewAction)action
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Segmented control

- (void)enableSegments:(UISegmentedControl *)control
{
    AssociationActivity *prev = [self.listDelegate activityBefore:self.activity];
    [control setEnabled:(prev != nil) forSegmentAtIndex:0];
    AssociationActivity *next = [self.listDelegate activityAfter:self.activity];
    [control setEnabled:(next != nil) forSegmentAtIndex:1];
}

- (void)segmentTapped:(UISegmentedControl *)control
{
    if (control.selectedSegmentIndex == 0) {
        self.activity = [self.listDelegate activityBefore:self.activity];
    }
    else {
        self.activity = [self.listDelegate activityAfter:self.activity];
    }

    [self reloadFields];
    [self viewDidAppear:NO]; // Trigger analytics
    [self enableSegments:control];
    [self.tableView reloadData];
    [self.listDelegate didSelectActivity:self.activity];
}

@end
