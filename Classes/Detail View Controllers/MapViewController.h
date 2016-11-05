//
//  MapViewController.h
//  Created by Gregory Combs on 8/16/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

@import CoreLocation;
@import MapKit;
@import UIKit;

#import "UserPinAnnotation.h"
#import "DistrictMapSearchOperation.h"
#import "TXLDetailProtocol.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,
                                                 UISearchBarDelegate,
                                                 UIPopoverControllerDelegate,
                                                 UISplitViewControllerDelegate,
                                                 UIActionSheetDelegate,
                                                 UIGestureRecognizerDelegate,
                                                 DistrictMapSearchOperationDelegate,
                                                 CLLocationManagerDelegate,
                                                 UserPinAnnotationDelegate,
                                                 TXLDetailProtocol>

@property (nonatomic,strong) IBOutlet MKMapView *mapView;
@property (nonatomic,strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic,strong) IBOutlet UISegmentedControl *mapTypeControl;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *mapTypeControlButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *userLocationButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *districtOfficesButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *searchBarButton;
@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic,readonly) MKCoordinateRegion texasRegion;
@property (nonatomic,strong) UserPinAnnotation *searchLocation;
@property (nonatomic,strong) MKPolygonRenderer *senateDistrictView, *houseDistrictView;
@property (nonatomic,strong) NSOperationQueue *genericOperationQueue;
@property (nonatomic,assign) NSInteger colorIndex;

#if 0 // can't get custom objects while using propertiesToFetch: anymore
- (IBAction) showAllDistricts:(id)sender;
#endif

//- (IBAction) showAllDistrictOffices:(id)sender;
- (IBAction) changeMapType:(id)sender;
- (IBAction) locateUser:(id)sender;
- (void)clearAnnotationsAndOverlays;
- (void)resetMapViewWithAnimation:(BOOL)animated;
- (void)moveMapToAnnotation:(id<MKAnnotation>)annotation;
- (void)searchDistrictMapsForCoordinate:(CLLocationCoordinate2D)aCoordinate;
- (void)annotationCoordinateChanged:(id)sender;

@end
