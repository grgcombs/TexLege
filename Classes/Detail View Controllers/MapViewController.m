//
//  MapViewController.m
//  Created by Gregory Combs on 8/16/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "MapViewController.h"
#import "TexLegeTheme.h"
#import "UtilityMethods.h"
#import "LegislatorDetailViewController.h"
#import "DistrictOfficeObj+MapKit.h"
#import "DistrictMapObj+MapKit.h"
#import "DistrictMapDataSource.h"

#import "UserPinAnnotation.h"
#import "UserPinAnnotationView.h"

#import "TexLegeAppDelegate.h"
#import "TexLegeCoreDataUtils.h"

#import "LocalyticsSession.h"
#import "UIColor-Expanded.h"

#import "TexLegeMapPins.h"
#import "SLToastManager+TexLege.h"

#import "DistrictPinAnnotationView.h"
#import <CoreLocation/CoreLocation.h>

@interface MapViewController()
@property (nonatomic,assign,getter=isLocationServicesDenied) BOOL locationServicesDenied;
@property (nonatomic,assign) BOOL wantsUserLocation;
@property (nonatomic,strong) CLGeocoder *clGeocoder;
@property (nonatomic,strong) CLRegion *texasAreaRegion;
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

static MKCoordinateSpan kStandardZoomSpan = {2.f, 2.f};

@implementation MapViewController
@synthesize dataObject = _dataObject;

#pragma mark -
#pragma mark Initialization and Memory Management

- (NSString *)nibName
{
	if ([UtilityMethods isIPadDevice])
		return @"MapViewController~ipad";
	else
		return @"MapViewController~iphone";
}

- (void)dealloc
{
    if (self.clGeocoder) {
        [self.clGeocoder cancelGeocode];
    }
	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

- (void)didReceiveMemoryWarning
{
	[self clearOverlaysExceptRecent];

	[super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
		
	_colorIndex = 0;

    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _locationManager.distanceFilter = 3000;
    _locationManager.delegate = self;

    _clGeocoder = [[CLGeocoder alloc] init];

	(self.view).backgroundColor = [TexLegeTheme backgroundLight];
	self.mapView.showsUserLocation = NO;
    self.mapView.showsBuildings = YES;
	
	// Set up the map's region to frame the state of Texas.
	// Zoom = 6
	self.mapView.region = self.texasRegion;
	
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	self.toolbar.tintColor = [TexLegeTheme navbar];
	self.searchBar.tintColor = [TexLegeTheme navbar];
	if ([UtilityMethods isIPadDevice])
    {
		self.navigationItem.titleView = self.toolbar; 
	}
	else
    {
		self.hidesBottomBarWhenPushed = YES;
		self.navigationItem.titleView = self.searchBar;
	}
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	longPressRecognizer.delegate = self;
	[self.mapView addGestureRecognizer:longPressRecognizer];

    id<MKAnnotation> annotation = self.detailAnnotation;
    if (annotation)
    {
        [self setDetailAnnotation:annotation]; // now that the view is loaded, apply annotation and animate stuff
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidUnload
{
    if (self.clGeocoder)
    {
        [self.clGeocoder cancelGeocode];
        self.clGeocoder = nil;
    }

	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
	
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = self.splitViewController.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:animated];
    }
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (svc.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = svc.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.mapView removeOverlays:self.mapView.overlays];	// frees up memory
	
	[super viewDidDisappear:animated];
}

- (void)setDetailAnnotation:(id<MKAnnotation>)detailAnnotation
{
    _detailAnnotation = detailAnnotation;

    if (!self.isViewLoaded)
        return;

    MKMapView *mapView = self.mapView;
    if (!mapView)
        return;

    [self clearAnnotationsAndOverlays];

    [mapView addAnnotation:detailAnnotation];
    [self moveMapToAnnotation:detailAnnotation];

    DistrictMapObj *map = SLValueIfClass(DistrictMapObj, detailAnnotation);
    if (!map)
        return;

    MKPolygon *polygon = map.polygon;
    if (polygon)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [mapView addOverlay:polygon];
        });
    }
}

- (void)clearAnnotationsAndOverlays
{
	[self.mapView removeOverlays:self.mapView.overlays];
	[self.mapView removeAnnotations:self.mapView.annotations];
}

- (void)clearAnnotationsAndOverlaysExcept:(id)keep
{
	NSMutableArray *annotes = [[NSMutableArray alloc] initWithCapacity:(self.mapView.annotations).count];
	for (id object in self.mapView.annotations)
    {
		if (![object isEqual:keep])
			[annotes addObject:object];
	}
	if (annotes && annotes.count)
    {
		[self.mapView removeOverlays:self.mapView.overlays];
		[self.mapView removeAnnotations:annotes];
	}
}

- (void)clearOverlaysExceptRecent
{
	NSMutableArray *toRemove = [[NSMutableArray alloc] initWithArray:self.mapView.overlays];
    if (toRemove.count>2)
    {
        [toRemove removeLastObject];
        [toRemove removeLastObject];
        [self.mapView removeOverlays:toRemove];
	}
}

- (void)resetMapViewWithAnimation:(BOOL)animated
{
	[self clearAnnotationsAndOverlays];
    [self.mapView setRegion:self.texasRegion animated:animated];
}

- (void)animateToState
{    
    [self.mapView setRegion:self.texasRegion animated:YES];
}

- (void)animateToAnnotation:(id<MKAnnotation>)annotation
{
	if (!annotation)
		return;
	
    MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, kStandardZoomSpan);
    [self.mapView setRegion:region animated:YES];	
}

- (void)moveMapToAnnotation:(id<MKAnnotation>)annotation
{
    __weak typeof(self) wSelf = self;
	if (![self region:self.mapView.region isEqualTo:self.texasRegion])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wSelf) sSelf = wSelf;
            if (!sSelf || !sSelf.isViewLoaded || sSelf.view.isHidden)
                return;
            [sSelf animateToState];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wSelf) sSelf = wSelf;
            if (!sSelf || !annotation || !sSelf.isViewLoaded || sSelf.view.isHidden)
                return;
            [sSelf animateToAnnotation:annotation];
        });
	}
	else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wSelf) sSelf = wSelf;
            if (!sSelf || !annotation || !sSelf.isViewLoaded || sSelf.view.isHidden)
                return;
            [sSelf animateToAnnotation:annotation];
        });
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    MKMapView *mapView = SLValueIfClass(MKMapView, gestureRecognizer.view);
    if (mapView)
        return YES;
    return NO;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)longPressRecognizer
{
    if (longPressRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    MKMapView *mapView = self.mapView;
    CGPoint touchPoint = [longPressRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchCoord = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    
    [self clearAnnotationsAndOverlays];
    
    [mapView setCenterCoordinate:touchCoord animated:YES];
    
    [self geocodeAddressWithCoordinate:touchCoord];
}

- (MKCoordinateRegion)texasRegion
{
	// Set up the map's region to frame the state of Texas.
	// Zoom = 6	
	static CLLocationCoordinate2D texasCenter = {31.709476f, -99.997559f};
	static MKCoordinateSpan texasSpan = {10.f, 10.f};
	const MKCoordinateRegion txreg = MKCoordinateRegionMake(texasCenter, texasSpan);
	return txreg;
}

- (BOOL)region:(MKCoordinateRegion)region1 isEqualTo:(MKCoordinateRegion)region2
{
	MKMapPoint coord1 = MKMapPointForCoordinate(region1.center);
	MKMapPoint coord2 = MKMapPointForCoordinate(region2.center);
	BOOL coordsEqual = MKMapPointEqualToPoint(coord1, coord2);
	
	BOOL spanEqual = region1.span.latitudeDelta == region2.span.latitudeDelta; // let's just only do one, okay?
	return (coordsEqual && spanEqual);
}

#pragma mark -
#pragma DistrictMapSearchOperationDelegate

- (void)searchDistrictMapsForCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	NSArray *list = [TexLegeCoreDataUtils allDistrictMapIDsWithBoundingBoxesContaining:aCoordinate];
	
	DistrictMapSearchOperation *op = [[DistrictMapSearchOperation alloc] initWithDelegate:self 
																			   coordinate:aCoordinate 
																				searchDistricts:list];
	if (op)
    {
		if (!self.genericOperationQueue)
			self.genericOperationQueue = [[NSOperationQueue alloc] init];
		[self.genericOperationQueue addOperation:op];
	}
}

- (void)districtMapSearchOperationDidFinishSuccessfully:(DistrictMapSearchOperation *)op
{
    //debug_NSLog(@"Found some search results in %d districts", [op.foundDistricts count]);

    @autoreleasepool {

        NSMutableArray *districts = [[NSMutableArray alloc] init];

        for (NSNumber *districtID in op.foundIDs)
        {
            DistrictMapObj *district = [DistrictMapObj objectWithPrimaryKeyValue:districtID];
            if (!district)
                continue;
            [districts addObject:district];
        }

        if (!districts.count)
            return;

        [self.mapView addAnnotations:districts];

        __weak typeof(self) wself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wself) sself = wself;
            if (!sself || !sself.isViewLoaded)
                return;
            MKMapView *mapView = sself.mapView;
            if (!mapView)
                return;
            [mapView setCenterCoordinate:op.searchCoordinate animated:YES];

            NSMutableArray *polygons = [[NSMutableArray alloc] init];
            for (DistrictMapObj *district in districts)
            {
                MKPolygon *polygon = district.polygon;
                if (!polygon)
                    continue;
                [polygons addObject:polygon];
                [district.managedObjectContext refreshObject:district mergeChanges:NO];	// re-fault it to free memory
            }

            if (polygons.count)
                [mapView addOverlays:polygons];
        });


        if (self.genericOperationQueue)
            [self.genericOperationQueue cancelAllOperations];
        self.genericOperationQueue = nil;
    }
}

- (void)districtMapSearchOperationDidFail:(DistrictMapSearchOperation *)op 
							 errorMessage:(NSString *)errorMessage 
								   option:(DistrictMapSearchOperationFailOption)failOption
{
	if (failOption == DistrictMapSearchOperationFailOptionLog)
    {
		NSLog(@"%@", errorMessage);
	}
	
	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
}

#pragma mark -
#pragma mark Control Element Actions

- (IBAction)changeMapType:(id)sender
{
	NSInteger index = self.mapTypeControl.selectedSegmentIndex;
	self.mapView.mapType = index;
}

- (void)showLocateUserButton
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	UIBarButtonItem *locateItem = [[UIBarButtonItem alloc] 
								   initWithImage:[UIImage imageNamed:@"locationarrow.png"]
									style:UIBarButtonItemStylePlain
									target:self
									action:@selector(locateUser:)];

	locateItem.tag = 999;
    if (self.isLocationServicesDenied)
        locateItem.enabled = NO;
	
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.toolbar.items];

    __block NSUInteger buttonIndex = NSNotFound;
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        UIBarButtonItem *item = obj;
        if (item.tag == 999 || item.tag == 998)
        {
            *stop = YES;
            buttonIndex = idx;
        }
    }];

    if (buttonIndex != NSNotFound)
        [items removeObjectAtIndex:buttonIndex];
    else
        buttonIndex = 0;
	[items insertObject:locateItem atIndex:buttonIndex];

	self.userLocationButton = locateItem;
	[self.toolbar setItems:items animated:YES];
}

- (void)showLocateActivityButton
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	[activityIndicator startAnimating];
	UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	activityItem.tag = 998;
    if (self.isLocationServicesDenied)
        activityItem.enabled = NO;

	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.toolbar.items];

    __block NSUInteger buttonIndex = NSNotFound;
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIBarButtonItem *item = obj;
        if (item.tag == 999 || item.tag == 998)
        {
            *stop = YES;
            buttonIndex = idx;
        }
    }];

    if (buttonIndex != NSNotFound)
        [items removeObjectAtIndex:buttonIndex];
    else
        buttonIndex = 0;
    [items insertObject:activityItem atIndex:buttonIndex];

	[self.toolbar setItems:items animated:YES];
}

- (IBAction)locateUser:(id)sender
{
	[self clearAnnotationsAndOverlays];
	[self showLocateActivityButton];				// this gets changed in viewForAnnotation once we receive the location

    self.wantsUserLocation = YES;
	if ([self determineOrRequestLocationAuthorization])
    {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark -
#pragma mark MapKit

- (void)setLocationServicesDenied:(BOOL)locationServicesDenied
{
    _locationServicesDenied = locationServicesDenied;
    if (_locationServicesDenied &&
        self.userLocationButton)
    {
        self.userLocationButton.enabled = NO;
    }
}

- (BOOL)determineOrRequestLocationAuthorization
{
    BOOL locationEnabled = NO;

    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusNotDetermined:
        {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                [self.locationManager requestWhenInUseAuthorization];
            else
                [CLLocationManager locationServicesEnabled];
            break;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            self.locationServicesDenied = YES;
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            self.locationServicesDenied = NO;
            locationEnabled = YES;
            break;
        }
    }

    return locationEnabled;
}

- (void)showLegislatorDetails:(LegislatorObj *)legislator
{
	if (!legislator)
		return;
	
	LegislatorDetailViewController *legVC = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
	legVC.legislator = legislator;
	[self.navigationController pushViewController:legVC animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
	[self clearAnnotationsAndOverlays];
	[self geocodeCoordinateWithSearchAddress:theSearchBar.text];
}

- (CLRegion *)getCircularTexasRegion
{
    CLRegion *texasRegion = self.texasAreaRegion;
    if (!texasRegion)
    {
        texasRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(31.391533, -99.170633) radius:700000 identifier:@"Area of Texas"];
        _texasAreaRegion = texasRegion;
    }
    return texasRegion;
}

- (BOOL)geocodeCoordinateWithSearchAddress:(NSString *)address
{
    if (!address.length || self.clGeocoder.isGeocoding)
        return NO;

	[self showLocateActivityButton];

    CLRegion *circularTexas = [self getCircularTexasRegion];

    __weak typeof(self) bself = self;
    [self.clGeocoder geocodeAddressString:address inRegion:circularTexas completionHandler:^(NSArray *placemarks, NSError *error) {
        __strong typeof(bself) sself = bself;
        if (!sself)
            return;
        if (error || !placemarks.count)
        {
            [sself showLocateUserButton];
            NSLog(@"Geocoder error - unable to geocode location: (%@)", error);
            return;
        }
        [sself geocoderDidFindPlacemark:placemarks[0]];
    }];

    return YES;
}

- (BOOL)geocodeAddressWithCoordinate:(CLLocationCoordinate2D)newCoord
{
    if (!CLLocationCoordinate2DIsValid(newCoord) || self.clGeocoder.isGeocoding)
        return NO;

	[self showLocateActivityButton];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude];
    __weak typeof(self) bself = self;
    [self.clGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        __strong typeof(bself) sself = bself;
        if (!sself)
            return;
        if (error || !placemarks.count)
        {
            CLLocation *localLocation = [[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude];
            [sself showLocateUserButton];
            NSLog(@"Geocoder error - unable to geocode location: %@ (%@)", localLocation, error);
            return;
        }
        [sself geocoderDidFindPlacemark:placemarks[0]];
    }];

    return YES;
}

- (void)geocoderDidFindPlacemark:(CLPlacemark *)placemark
{
	NSLog(@"Geocoder found placemark: %@ (was %@)", placemark, self.searchLocation);
	[self showLocateUserButton];

    UserPinAnnotation *userPin = self.searchLocation;
	if (userPin)
		[self.mapView removeAnnotation:userPin];

    UserPinAnnotation *annotation = [[UserPinAnnotation alloc] initWithPlacemark:placemark];
    if (annotation)
    {
        annotation.coordinateChangedDelegate = self;
	
        [self.mapView addAnnotation:annotation];
        [self searchDistrictMapsForCoordinate:annotation.coordinate];
        [self moveMapToAnnotation:annotation];
    }
	self.searchLocation = annotation;
	
	// is this necessary??? because we will have just created the related annotation view, so we don't need to redisplay it.
	[[NSNotificationCenter defaultCenter] postNotificationName:kUserPinAnnotationAddressChangeKey object:annotation];
			
	[self.searchBar resignFirstResponder];
}

- (void)annotationCoordinateChanged:(id)sender
{
    UserPinAnnotation *newPin = SLValueIfClass(UserPinAnnotation, sender);
    if (!newPin)
        return;
    UserPinAnnotation *oldPin = self.searchLocation;
	if (!oldPin || ![newPin isEqual:oldPin])
		self.searchLocation = newPin;
	[self clearAnnotationsAndOverlaysExcept:newPin];

    if ([self geocodeAddressWithCoordinate:newPin.coordinate])
        [self searchDistrictMapsForCoordinate:newPin.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	if (!self || !self.isViewLoaded || !self.mapView)
        return;

    NSString *title = NSLocalizedStringFromTable(@"Geolocation Error", @"AppAlerts", nil);
    NSString *message = [NSString stringWithFormat: NSLocalizedStringFromTable(@"Failed to determine your geographic location due to the following: %@", @"AppAlerts", nil), error.localizedDescription];
    [[SLToastManager txlSharedManager] addToastWithIdentifier:@"TXLGeocodeFailed"
                                                         type:SLToastTypeError
                                                        title:title
                                                     subtitle:message
                                                        image:nil
                                                     duration:3];
    [self showLocateUserButton];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!self || !self.isViewLoaded || !self.mapView)
        return;

    [self showLocateUserButton];
    if (!locations.count)
        return;

    CLLocation *foundLocation = locations.firstObject;

    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self searchDistrictMapsForCoordinate:foundLocation.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (!self)
        return;
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        self.locationServicesDenied = NO;
        if (self.wantsUserLocation)
            [self.locationManager startUpdatingLocation];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
	
	//if (oldState == MKAnnotationViewDragStateDragging)
	if (newState == MKAnnotationViewDragStateEnding)
	{
		if ([annotationView.annotation isEqual:self.searchLocation])
        {
			if (self.searchLocation.coordinateChangedDelegate)
            {
				self.searchLocation.coordinateChangedDelegate = nil;		// it'll handle it once, then we'll do it.
			}
			else
            {
				debug_NSLog(@"MapView:didChangeDrag - when does this condition happen???");
				[self annotationCoordinateChanged:self.searchLocation];	
			}
		}
	}
}


- (void)mapView:(MKMapView *)theMapView didAddAnnotationViews:(NSArray *)views
{
}

- (void)mapView:(MKMapView *)theMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	id <MKAnnotation,LegislatorAnnotation> annotation = (id<MKAnnotation,LegislatorAnnotation>)view.annotation;
	
    if ([annotation conformsToProtocol:@protocol(LegislatorAnnotation)])
    {
        LegislatorObj *legislator = [annotation legislator];
        if (legislator)
            [self showLegislatorDetails:legislator];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (SLValueIfClass(MKUserLocation, annotation))
        return nil;
    MKAnnotationView *pinView = nil;
    DistrictOfficeObj *office = SLValueIfClass(DistrictOfficeObj, annotation);
    DistrictMapObj *map = SLValueIfClass(DistrictMapObj, annotation);
    if (office || map)
    {
        NSString * const reuseIdentifier = @"districtObjectAnnotationID";
        pinView = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
        if (pinView)
        {
            pinView.annotation = annotation;
            DistrictPinAnnotationView *districtPin = SLValueIfClass(DistrictPinAnnotationView, pinView);
            if (districtPin)
                [districtPin resetPinColorWithAnnotation:annotation];
        }
        else
            pinView = [[DistrictPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        return pinView;
    }
	
    UserPinAnnotation *userPin = SLValueIfClass(UserPinAnnotation, annotation);
    if (!annotation)
        return nil;
    
    NSString * const reuseIdentifier = @"customAnnotationIdentifier";
    pinView = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
    if (pinView)
        pinView.annotation = userPin;
    else
        pinView = [[UserPinAnnotationView alloc] initWithAnnotation:userPin reuseIdentifier:reuseIdentifier];
    return pinView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
	NSArray *colors = [[UIColor randomColor] triadicColors];
	UIColor *myColor = [colors[self.colorIndex] colorByDarkeningTo:0.50f];
	self.colorIndex++;
	if (self.colorIndex > 1)
		self.colorIndex = 0;
	
	if ([overlay isKindOfClass:[MKPolygon class]])
    {		
		BOOL senate = NO;
		
		NSString *ovTitle = overlay.title;
		if (ovTitle && [ovTitle hasSubstring:stringForChamber(HOUSE, TLReturnFull) caseInsensitive:NO]) {
			if (self.mapView.mapType > MKMapTypeStandard)
				myColor = [UIColor cyanColor];
			else
				myColor = [TexLegeTheme texasGreen];
			senate = NO;
		}
		else if (ovTitle && [ovTitle hasSubstring:stringForChamber(SENATE, TLReturnFull) caseInsensitive:NO]) {
			myColor = [TexLegeTheme texasOrange];
			senate = YES;
		}

		MKPolygonRenderer *aView = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay];
		if (senate) {
			self.senateDistrictView = aView;
		}
		else {
			self.houseDistrictView = aView;
		}

		aView.fillColor = [myColor colorWithAlphaComponent:0.2];
        aView.strokeColor = [myColor colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
        return aView;
    }
	
	else if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer* aView = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
				
        aView.strokeColor = myColor;// colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
        return aView;
    }
	
    return [[MKOverlayRenderer alloc] init]; // we have to return something
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView
{
	id<MKAnnotation> annotation = aView.annotation;
	if (!annotation)
		return;
	
	if (!aView.isSelected)
		return;
	
	[mapView setCenterCoordinate:annotation.coordinate animated:YES];
	
    UserPinAnnotation *userPin = SLValueIfClass(UserPinAnnotation, annotation);
	if (userPin)
    {
		self.searchLocation = userPin;
        return;
    }

    DistrictMapObj *map = SLValueIfClass(DistrictMapObj, annotation);
	if (!map)
        return;
    NSString *districtTitle = SLTypeStringOrNil(map.title);
    NSString *houseMapTitle = SLTypeStringOrNil(self.houseDistrictView.polygon.title);
    NSString *senateMapTitle = SLTypeStringOrNil(self.senateDistrictView.polygon.title);
    MKCoordinateRegion region = [map region];
    NSArray *overlays = mapView.overlays;
    NSMutableArray *toRemove = [[NSMutableArray alloc] initWithArray:overlays];
    BOOL foundOne = NO;
    for (id<MKOverlay>item in overlays)
    {
        NSString *itemTitle = item.title;
        if (itemTitle && [itemTitle isEqualToString:districtTitle])
        {
            if ([itemTitle isEqualToString:senateMapTitle] ||
                [itemTitle isEqualToString:houseMapTitle])
            {
                [toRemove removeObject:item];
                foundOne = YES;
                break;
            }
        }
    }
    
    if (toRemove.count)
        [mapView removeOverlays:toRemove];
    
    if (!foundOne)
    {
        MKPolygon *mapPoly = [map polygon];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!mapView)
                return;
            [mapView addOverlay:mapPoly];
        });
        
        [map.managedObjectContext refreshObject:map mergeChanges:NO];
    }
    [mapView setRegion:region animated:YES];
}

#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
	return YES;
}

@end
