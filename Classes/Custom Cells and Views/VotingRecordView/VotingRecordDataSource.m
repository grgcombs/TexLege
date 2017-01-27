//
//  VotingRecordDataSource.m
//  Created by Gregory Combs on 3/25/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "VotingRecordDataSource.h"
#import "NSDate+Helper.h"
#import "TexLegeTheme.h"
#import "PartisanIndexStats.h"
#import "LegislatorObj.h"

@interface VotingRecordDataSource()
@property (nonatomic,copy) NSDictionary *chartData;
@property (nonatomic,copy) NSString *legislatorName;
@property (nonatomic,copy) NSNumber *legType;
@end

@implementation VotingRecordDataSource

- (instancetype)init {
    self = [super init];
    if (self)
    {
	}
	return self;
}

- (void)setLegislator:(LegislatorObj *)legislator
{
    if (!legislator)
    {
        _chartData = nil;
        _legislatorName = nil;
        _legType = nil;
        return;
    }
    _legislatorName = legislator.lastname;
    _legType = legislator.legtype;
    _chartData = [[PartisanIndexStats sharedPartisanIndexStats] partisanshipDataForLegislator:legislator];
}

// stupid to go here, but I'm too tired to put this someplace proper
- (void)prepareVotingRecordView:(S7GraphView *)aView
{
	if (!aView)
		return;
	
	aView.dataSource = self;
	aView.delegate = self;
	
	aView.backgroundColor = [TexLegeTheme backgroundLight];
    
    aView.drawAxisX = YES;
    aView.drawAxisY = YES;
    aView.drawGridX = NO;
    aView.drawGridY = YES;
    
    aView.xValuesColor = [TexLegeTheme textDark];	// The values on the bottom of the chart (years)
    aView.yValuesColor = [TexLegeTheme textDark];	// The values on the left side of the chart (scores)
    
    aView.gridXColor = [UIColor darkGrayColor];
    aView.gridYColor = [UIColor darkGrayColor];
	
	aView.info = NSLocalizedStringFromTable(@"Historical Voting Comparison", @"DataTableUI", @"Title for the partisanship chart");
	aView.infoColor = [TexLegeTheme textDark];
    aView.drawInfo = YES;
	
	aView.highlightColor = [UIColor colorWithRed:0.6f green:0.745f blue:0.353f alpha:.3f]; // accent + transp
	
	aView.xUnit = NSLocalizedStringFromTable(@"Year", @"DataTableUI", @"The year for a given legislative session");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.maximumFractionDigits = 1;
    
    aView.yValuesFormatter = numberFormatter;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"''yy";
    aView.xValuesFormatter = dateFormatter;
    
    
    aView.yUnit = NSLocalizedStringFromTable(@"Partisanship", @"DataTableUI", @"The data value axis for the partisanship chart, like 'dollars', or 'car sales'");
}

#pragma mark protocol S7GraphViewDataSource

- (NSDictionary *)graphViewMinAndMaxY:(S7GraphView *)graphView {
	
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];
    NSNumber *legType = self.legType;
    if (!indexStats || !legType)
        return nil;
    
	CGFloat sliderMin = [indexStats minPartisanIndexUsingChamber:(legType).integerValue];
	CGFloat sliderMax = [indexStats maxPartisanIndexUsingChamber:(legType).integerValue];

	if (sliderMax > (-sliderMin))
		sliderMin = (-sliderMax);
	else
		sliderMax = (-sliderMin);
	
	return @{@"minY": @(sliderMin),
			@"maxY": @(sliderMax)};
}

- (NSUInteger)graphViewMaximumNumberOfXaxisValues:(S7GraphView *)graphView {
	if (_chartData)
		return [_chartData[@"member"] count];
    return 0;
}

- (NSUInteger)graphViewNumberOfPlots:(S7GraphView *)graphView {
    /* Return the number of plots you are going to have in the view. 1+ */
    return 3;
}

- (UIColor *)graphView:(S7GraphView *)graphView colorForPlot:(NSUInteger)plotIndex {
	if (plotIndex == 0)
		return [TexLegeTheme texasRed];
	else if (plotIndex == 2)
		return [TexLegeTheme texasBlue];
	else
		return [TexLegeTheme texasGreen];
}


- (NSArray *)graphViewXValues:(S7GraphView *)graphView {
    /* An array of objects that will be further formatted to be displayed on the X-axis.
     The number of elements should be equal to the number of points you have for every plot. */
	
	return self.chartData[@"time"];
}

- (NSArray *)graphView:(S7GraphView *)graphView yValuesForPlot:(NSUInteger)plotIndex {
    /* Return the values for a specific graph. Each plot is meant to have equal number of points.
     And this amount should be equal to the amount of elements you return from graphViewXValues: method. */
	
	// Returning the following object in an array will treat it like missing data
	// [NSNumber numberWithFloat:CGFLOAT_MAX]
	
    NSDictionary *chartData = self.chartData;
    NSArray *items = nil;

    switch (plotIndex) {
        case 0:
			items = chartData[@"repub"];
            break;
		case 2:
			items =	chartData[@"democ"];
            break;
        case 1:
        default:
			items =	chartData[@"member"];
            break;
    }
    return items;
}

- (BOOL)graphView:(S7GraphView *)graphView shouldFillPlot:(NSUInteger)plotIndex {
    return NO;
}

- (void)graphView:(S7GraphView *)graphView indexOfTappedXaxis:(NSInteger)indexOfTappedXaxis {
/*
 NSNumber *repub = [[chartData objectForKey:@"repub"] objectAtIndex:indexOfTappedXaxis];
	NSNumber *democ = [[chartData objectForKey:@"democ"] objectAtIndex:indexOfTappedXaxis];
	NSNumber *member = [[chartData objectForKey:@"member"] objectAtIndex:indexOfTappedXaxis];
	NSDate *time = [[chartData objectForKey:@"time"] objectAtIndex:indexOfTappedXaxis];
	
	if ([member floatValue] == CGFLOAT_MIN)
		return;
	
	LegislatorObj *legislator = [LegislatorObj objectWithPrimaryKeyValue:self.legislatorID];

	CGFloat diff1 = (CGFloat)([member floatValue] - [repub floatValue]);
	CGFloat diff2 = (CGFloat)([member floatValue] - [democ floatValue]);
	NSString *string = [NSString stringWithFormat:@"For %@:\n%@ is %01.2f pts from %@\n%@ is %01.2f pts from %@",
						[time stringWithFormat:@"yyyy"],
						[legislator legProperName], diff1, @"repubs",
						[legislator legProperName], diff2, @"dems"];
	
    debug_NSLog(@"%@",string);
 */
}

- (NSString *)graphView:(S7GraphView *)graphView nameForPlot:(NSInteger)plotIndex {
    NSString *name = nil;

    switch (plotIndex) {
        case 0:
			name = 	stringForParty(REPUBLICAN, TLReturnAbbrevPlural);
            break;
		case 2:
			name = 	stringForParty(DEMOCRAT, TLReturnAbbrevPlural);
            break;
        case 1:
        default:
			name = self.legislatorName;
            break;
    }
    return name;
}

@end
