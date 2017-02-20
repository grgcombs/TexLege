//
//  TexLegeMapPins.m
//  Created by Gregory Combs on 9/7/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeMapPins.h"
#import <MapKit/MapKit.h>

UIColor * pinTintColorForColorIndex(TexLegePinAnnotationColor pinColorIndex)
{
    UIColor *tintColor = nil;
    
    switch (pinColorIndex) {
        case TexLegePinAnnotationColorRed:
        tintColor = [MKPinAnnotationView redPinColor];
        break;
        
        case TexLegePinAnnotationColorPurple:
        tintColor = [MKPinAnnotationView purplePinColor];
        break;
        
        case TexLegePinAnnotationColorBlue:
        tintColor = [UIColor blueColor];
        break;
        
        case TexLegePinAnnotationColorGreen:
        default:
        tintColor = [MKPinAnnotationView greenPinColor];
        break;
    }
    return tintColor;
}
