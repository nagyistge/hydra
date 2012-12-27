//
//  RestoMapViewController.m
//  Hydra
//
//  Created by Feliciaan De Palmenaer on 27/12/12.
//  Copyright (c) 2012 Zeus WPI. All rights reserved.
//

#import "RestoMapViewController.h"
#import "RestoMapPoint.h"

@implementation RestoMapViewController

- (NSArray*)generateRestoList
{
    RestoMapPoint *astrid = [[RestoMapPoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(51.026952, 3.712086) andTitle:@"Resto Astrid"];

    RestoMapPoint *brug = [[RestoMapPoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(51.045613, 3.727147) andTitle:@"Resto De Brug"];
    
    RestoMapPoint *coupure = [[RestoMapPoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(51.053252, 3.707671) andTitle:@"Resto Coupure"];
    
    return [[NSArray alloc] initWithObjects:astrid, brug, coupure, nil];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Create Location Manager
        locationManager = [[CLLocationManager alloc] init];
        
        // delegate to self
        [locationManager setDelegate:self];
        
        // set accuracy of location manager
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        
        // start updating location
        [locationManager startUpdatingLocation];
        
        
        // add restos to map
        restos = [self generateRestoList];
        [self addRestosToMap];
        
    }
    return self;
}


#pragma mark Setting up the view & viewcontroller

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [[self navigationItem] setTitle:@"Resto Map"];
    
    // show location on map
    [worldView setShowsUserLocation:YES];

    // Check for updates
   /* NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(locationsUpdated:)
                   name:RestoStoreDidReceiveLocationNotification
                 object:nil];//*/

   
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark Buttons
- (IBAction)toggleTableView:(id)sender
{
    if ([tableView isHidden]){
        // is hidden, show table
        [tableView setHidden:NO];
        CGRect mapFrame = [worldView frame];
        CGRect tableFrame = [tableView frame];
        
        CGRect newMapFrame = CGRectMake(mapFrame.origin.x, mapFrame.origin.y, mapFrame.size.width, mapFrame.size.height-tableFrame.size.height);
        [worldView setFrame:newMapFrame];
        
    }else {
        // is shown, hide table
        CGRect mapFrame = [worldView frame];
        CGRect tableFrame = [tableView frame];
        
        CGRect newMapFrame = CGRectMake(mapFrame.origin.x, mapFrame.origin.y, mapFrame.size.width, mapFrame.size.height+tableFrame.size.height);
        [worldView setFrame:newMapFrame];
        [tableView setHidden:YES];
    }
}

- (IBAction)routeToClosestResto:(id)sender
{
    // TODO implement route to closest resto
}

# pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [restos count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RestoMapPoint *resto = (RestoMapPoint*)restos[indexPath.row];
    
    static NSString *cellIdentifier = @"RestoMapTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [[NSString alloc] initWithString:[resto title]];
    CLLocation *temp = [[CLLocation alloc] initWithCoordinate:[resto coordinate] altitude:0 horizontalAccuracy:kCLLocationAccuracyBest verticalAccuracy:kCLLocationAccuracyBest timestamp:[NSDate date]];
    CLLocationDistance dis = [currentLocation distanceFromLocation:temp];
    NSString *afstand;
    if (dis < 3000){
        afstand = [[NSString alloc]initWithFormat:@"%4f m", dis];
    }else
        afstand = [[NSString alloc]initWithFormat:@"%4f km", dis/1000];
    NSLog(@"afstand: %f", dis);
    cell.detailTextLabel.text = afstand;
    return cell;
}




# pragma mark Location Settings

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    NSLog(@"%@", newLocation);
    
    // How many seconds ago was this new location created?
    NSTimeInterval t = [[newLocation timestamp] timeIntervalSinceNow];
    
    // CLLocationManagers will return the last found location of the
    // device first, you don't want that data in this case.
    // If this location was made more than 3 minutes ago, ignore it.
    if (t < -180) {
        // This is cached data, you don't want it, keep looking
        return;
    }

    if (currentLocation != newLocation){
        currentLocation = newLocation;
    }
    
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError *)error{
    NSLog(@"Could not find location: %@", error);
}

#pragma mark Map settings
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D loc = [userLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [worldView setRegion:region animated:YES];
}

- (void)addRestosToMap
{
    for (RestoMapPoint* resto in restos) {
        [worldView addAnnotation:resto];
    }
}

#pragma mark Extra functions


- (void)findLocation
{
    [locationManager startUpdatingLocation];
    [activityIndicator startAnimating];
//    [locationTitleTextField setHidden:YES];
}

- (void)foundLocation:(CLLocation *)loc
{
    CLLocationCoordinate2D coord = [loc coordinate];
    
    RestoMapPoint* mp = [[RestoMapPoint alloc] init];
    
    // add mapPoint to worldView
    [worldView addAnnotation:mp];
    
    // Zoom the region to this location
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000);
    [worldView setRegion:region animated:YES];
    
    // Reset the UI
//    [locationTitleTextField setText:@""];
    [activityIndicator stopAnimating];
//    [locationTitleTextField setHidden:NO];
    [locationManager stopUpdatingLocation];
    
}

@end