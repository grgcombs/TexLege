//
//  MapMiniDetailViewController.m
//  Created by Gregory Combs on 8/16/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "MapMiniDetailViewController.h"
#import "TexLegeTheme.h"
#import "UtilityMethods.h"
#import "DistrictOfficeObj.h"
#import "DistrictMapObj+MapKit.h"

#import "TexLegeAppDelegate.h"
#import "TexLegeCoreDataUtils.h"

#import "LocalyticsSession.h"
#import "UIColor-Expanded.h"

#import "TexLegeMapPins.h"
#import "DistrictPinAnnotationView.h"

@interface MapMiniDetailViewController (Private)
- (void) animateToState;
- (void) animateToAnnotation:(id<MKAnnotation>)annotation;
- (void) clearOverlaysExceptRecent;
- (void) resetMapViewWithAnimation:(BOOL)animated;
- (BOOL) region:(MKCoordinateRegion)region1 isEqualTo:(MKCoordinateRegion)region2;

@end

static MKCoordinateSpan kStandardZoomSpan = {2.f, 2.f};

@implementation MapMiniDetailViewController

- (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"MapMiniDetailViewController~ipad";
	else
		return @"MapMiniDetailViewController~iphone";
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
	if (![UtilityMethods isIPadDevice])
		self.hidesBottomBarWhenPushed = YES;
	
	self.view.backgroundColor = [TexLegeTheme backgroundLight];
	self.mapView.showsUserLocation = NO;
    self.mapView.delegate = self;
	
	// Set up the map's region to frame the state of Texas.
	// Zoom = 6
	self.mapView.region = self.texasRegion;
	
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	//self.navigationItem.title = @"District Location";

    if (self.districtOverlay)
    {
        [self.mapView addOverlay:self.districtOverlay];
    }
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
	self.mapView.showsUserLocation = NO;
		
	//if (![self isEqual:[self.navigationController.viewControllers objectAtIndex:0]])
	[self.mapView removeOverlays:self.mapView.overlays];
	
	[super viewDidDisappear:animated];
}

- (void)clearAnnotationsAndOverlays
{
    if (!self.isViewLoaded)
        return;
    MKMapView *mapView = self.mapView;
	mapView.showsUserLocation = NO;
	[mapView removeOverlays:mapView.overlays];
	[mapView removeAnnotations:mapView.annotations];
}


- (void)clearOverlaysExceptRecent
{
    if (!self.isViewLoaded)
        return;
    MKMapView *mapView = self.mapView;
	mapView.showsUserLocation = NO;
	
    NSArray *overlays = mapView.overlays;
    if (overlays.count <= 1)
        return;
	NSMutableArray *toRemove = [overlays mutableCopy];
    [toRemove removeLastObject];
    [mapView removeOverlays:toRemove];
}

- (void)resetMapViewWithAnimation:(BOOL)animated {
	[self clearAnnotationsAndOverlays];
	if (animated)
		[self.mapView setRegion:self.texasRegion animated:YES];
	else
		[self.mapView setRegion:self.texasRegion animated:NO];
	
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

- (void)addDistrictOverlay:(id<MKOverlay>)overlay
{
    self.districtOverlay = overlay;
    if (!self.isViewLoaded || !self.mapView)
    {
        return;
    }
    __weak MapMiniDetailViewController *bself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [bself.mapView addOverlay:overlay];
    });
}

- (MKCoordinateRegion) texasRegion
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
#pragma mark Action Sheet

- (IBAction) annotationActionSheet:(id)sender {
	UIActionSheet *popupQuery = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Button to cancel something")
								 destructiveButtonTitle:nil
								 otherButtonTitles:NSLocalizedStringFromTable(@"Open in Google Maps", @"AppAlerts", @"Button to open google maps"), 
								 nil];
	
	
	popupQuery.actionSheetStyle = UIActionSheetStyleAutomatic;
	
	UIView *aView = sender;
	if (aView && [aView isKindOfClass:[UIView class]])
    {
        CGRect fromRect = [self.mapView convertRect:aView.bounds fromView:aView];
        [popupQuery showFromRect:fromRect inView:self.mapView animated:YES];
    }
	else
		[popupQuery showInView:self.mapView];
}

//- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	if (buttonIndex == 0) {
		// if you want driving directions, daddr is the destination, saddr is the origin
		// @"http://maps.google.com/maps?daddr=San+Francisco,+CA&saddr=cupertino"
		// [NSString stringWithFormat: @"http://maps.google.com/maps?q=%f,%f", loc.latitude, loc.longitude];
		
		NSString *urlString =  [NSString stringWithFormat:@"%@/maps?q=%f,%f",
								[UtilityMethods texLegeStringWithKeyPath:@"ExternalURLs.googleMapsWeb"],
							self.annotationActionCoord.latitude, self.annotationActionCoord.longitude];	
		
		NSURL *url = [UtilityMethods safeWebUrlFromString:urlString];
		[UtilityMethods openURLWithTrepidation:url];
	}
}

- (void)mapView:(MKMapView *)theMapView annotationView:(MKAnnotationView *)annotationView 
									calloutAccessoryControlTapped:(UIControl *)control {
	id <MKAnnotation> annotation = annotationView.annotation;
	if ([annotation isKindOfClass:[DistrictOfficeObj class]])
    {
		self.annotationActionCoord = annotation.coordinate;
		[self annotationActionSheet:control];		
	}		
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[DistrictOfficeObj class]] || [annotation isKindOfClass:[DistrictMapObj class]]) 
    {
        static NSString* districtAnnotationID = @"districtObjectAnnotationID";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:districtAnnotationID];
        if (!pinView)
        {
            DistrictPinAnnotationView* customPinView = [[DistrictPinAnnotationView alloc]
												   initWithAnnotation:annotation reuseIdentifier:districtAnnotationID];			
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
            if ([pinView isKindOfClass:[DistrictPinAnnotationView class]])
            {
                [(DistrictPinAnnotationView *)pinView resetPinColorWithAnnotation:annotation];
            }
			
			pinView.rightCalloutAccessoryView = nil;
        }		

        return pinView;
    }
	
	return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	NSArray *colors = [[UIColor randomColor] triadicColors];
	UIColor *myColor = [colors[_colorIndex] colorByDarkeningTo:0.50f];
	_colorIndex++;
	if (_colorIndex > 1)
		_colorIndex = 0;
	
	if ([overlay isKindOfClass:[MKPolygon class]])
    {		
		myColor = [TexLegeTheme texasOrange];

		NSString *ovTitle = overlay.title;
		if (ovTitle && [ovTitle hasSubstring:stringForChamber(HOUSE, TLReturnFull) caseInsensitive:NO]) {
			if (self.mapView.mapType > MKMapTypeStandard)
				myColor = [UIColor cyanColor];
			else
				myColor = [TexLegeTheme texasGreen];
		}

		MKPolygonRenderer *aView = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay];
		aView.fillColor = [/*[UIColor cyanColor]*/myColor colorWithAlphaComponent:0.2];
        aView.strokeColor = [myColor colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
		self.districtView = aView;

        return aView;
    }
	
	else if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer*    aView = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
				
        aView.strokeColor = myColor;// colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
        return aView;
    }
	
    return [[MKOverlayRenderer alloc] init]; // we have to return something
}



- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView {
	
	id<MKAnnotation> annotation = aView.annotation;
	if (!annotation)
		return;
	
	if (!aView.selected)
		return;
	
	[self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
	
	if ([annotation isKindOfClass:[DistrictMapObj class]]) {
		MKCoordinateRegion region;
		region = [(DistrictMapObj *)annotation region];
		
		NSMutableArray *toRemove = [[NSMutableArray alloc] initWithArray:self.mapView.overlays];
		BOOL foundOne = NO;
		
		for (id<MKOverlay>item in self.mapView.overlays) {
			if ([item.title isEqualToString:annotation.title]) {	// we clicked on an existing overlay
				if (self.districtView && [item.title isEqualToString:(self.districtView.polygon).title]) { // it's the senate
					foundOne = YES;
					[toRemove removeObject:item];
					break;
				}
			}
		}
		
		//[self.mapView removeOverlays:self.mapView.overlays];
		if (toRemove && toRemove.count)
        {
            [self.mapView removeOverlays:toRemove];
        }

		
		if (!foundOne) {
			MKPolygon *mapPoly = [(DistrictMapObj*)annotation polygon];
            [self addDistrictOverlay:mapPoly];
		}
		[self.mapView setRegion:region animated:TRUE];
	}			
}


#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
	return YES;
}

@end
