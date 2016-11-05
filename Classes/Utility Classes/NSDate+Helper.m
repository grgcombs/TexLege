//
//  NSDate+Helper.m
//  Codebook
//
//  Created by Billy Gray on 2/26/09.
//  Copyright 2009 Zetetic LLC. All rights reserved.
//

#import "NSDate+Helper.h"

@implementation TexLegeDateHelper
@synthesize formatter = t_formatter, calendar = t_calendar, modFormatter = t_modFormatter;

+ (TexLegeDateHelper*)sharedTexLegeDateHelper
{
	static dispatch_once_t pred;
	static TexLegeDateHelper *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype)init {
	if ((self=[super init])) {
		t_formatter = nil;
		t_modFormatter = nil;
		t_calendar = nil;

	}
	return self;
}


- (NSDateFormatter *)modFormatter {
	if (!t_modFormatter)
		t_modFormatter = [[NSDateFormatter alloc] init];
	return t_modFormatter;
}

- (NSDateFormatter *)formatter {
	if (!t_formatter)
		t_formatter = [[NSDateFormatter alloc] init];
	return t_formatter;
}

- (NSCalendar *)calendar {
	if (!t_calendar)
		t_calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	return t_calendar;
}

@end

@implementation NSDate (Helper)

- (BOOL) equalsDefaultDate {
	NSDateFormatter *formatter = [TexLegeDateHelper sharedTexLegeDateHelper].formatter;
	BOOL equals = [self isEqualToDate:formatter.defaultDate];
	return equals;
}

// This is lengthy, for the sake of getting a known weekday string (Sunday, Monday, Tuesday ...) no matter where this NSDate is located.
- (NSString *)localWeekdayString {
	NSCalendar *gregorian = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDateFormatter *weekdayFormatter = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	weekdayFormatter.calendar = gregorian;
	weekdayFormatter.locale = usLocale;
	weekdayFormatter.dateFormat = @"EEEE";
	NSString *weekday = [weekdayFormatter stringFromDate:self];
	if (usLocale) usLocale = nil;
	
	return weekday;
}

/*
 * This guy can be a little unreliable and produce unexpected results,
 * you're better off using daysAgoAgainstMidnight
 */
- (NSUInteger)daysAgo {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDateComponents *components = [calendar components:(NSCalendarUnitDay)
											   fromDate:self
												 toDate:[NSDate date]
												options:0];
	return components.day;
}

- (NSUInteger)daysAgoAgainstMidnight {
	// get a midnight version of ourself:
	NSDateFormatter *mdf = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	mdf.dateFormat = @"yyyy-MM-dd";
	NSDate *midnight = [mdf dateFromString:[mdf stringFromDate:self]];
	
	return (int)midnight.timeIntervalSinceNow / (60*60*24) *-1;
}

- (NSString *)stringDaysAgo {
	return [self stringDaysAgoAgainstMidnight:YES];
}

- (NSString *)stringDaysAgoAgainstMidnight:(BOOL)flag {
	NSUInteger daysAgo = (flag) ? [self daysAgoAgainstMidnight] : [self daysAgo];
	NSString *text = nil;
	switch (daysAgo) {
		case 0:
			text = @"Today";
			break;
		case 1:
			text = @"Yesterday";
			break;
		default:
			text = [NSString stringWithFormat:@"%lu days ago", (unsigned long)daysAgo];
	}
	return text;
}

- (NSUInteger)weekday {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDateComponents *weekdayComponents = [calendar components:(NSCalendarUnitWeekday) fromDate:self];
	return weekdayComponents.weekday;
}

- (NSUInteger)year {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDateComponents *yearComponents = [calendar components:(NSCalendarUnitYear) fromDate:self];
	return yearComponents.year;
}

+ (NSDate *)dateFromString:(NSString *)string {
	return [NSDate dateFromString:string withFormat:[NSDate dbFormatString]];
}

+ (NSDate *)dateFromString:(NSString *)string withFormat:(NSString *)format {
	NSDateFormatter *inputFormatter = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	inputFormatter.dateFormat = format;
	NSDate *date = [inputFormatter dateFromString:string];
	return date;
}

+ (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format {
	return [date stringWithFormat:format];
}

+ (NSString *)stringFromDate:(NSDate *)date {
	return [date string];
}

+ (NSString *)stringForDisplayFromDate:(NSDate *)date prefixed:(BOOL)prefixed {
	/* 
	 * if the date is in today, display 12-hour time with meridian,
	 * if it is within the last 7 days, display weekday name (Friday)
	 * if within the calendar year, display as Jan 23
	 * else display as Nov 11, 2008
	 */
	
	NSDate *today = [NSDate date];
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDateComponents *offsetComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
													 fromDate:today];
	
	NSDate *midnight = [calendar dateFromComponents:offsetComponents];
	
	NSDateFormatter *displayFormatter = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	NSString *displayString = nil;
	
	// comparing against midnight
	if ([date compare:midnight] == NSOrderedDescending) {
		if (prefixed) {
			displayFormatter.dateFormat = @"'at' h:mm a"; // at 11:30 am
		} else {
			displayFormatter.dateFormat = @"h:mm a"; // 11:30 am
		}
	} else {
		// check if date is within last 7 days
		NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
		componentsToSubtract.day = -7;
		NSDate *lastweek = [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
		if ([date compare:lastweek] == NSOrderedDescending) {
			displayFormatter.dateFormat = @"EEEE"; // Tuesday
		} else {
			// check if same calendar year
			NSInteger thisYear = offsetComponents.year;
			
			NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
														   fromDate:date];
			NSInteger thatYear = dateComponents.year;			
			if (thatYear >= thisYear) {
				displayFormatter.dateFormat = @"MMM d";
			} else {
				displayFormatter.dateFormat = @"MMM d, yyyy";
			}
		}
		if (prefixed) {
			NSString *dateFormat = displayFormatter.dateFormat;
			NSString *prefix = @"'on' ";
			displayFormatter.dateFormat = [prefix stringByAppendingString:dateFormat];
		}
	}
	
	// use display formatter to return formatted date string
	displayString = [displayFormatter stringFromDate:date];
	return displayString;
}

+ (NSString *)stringForDisplayFromDate:(NSDate *)date {
	return [self stringForDisplayFromDate:date prefixed:NO];
}

- (NSString *)stringWithFormat:(NSString *)format {
	NSDateFormatter *outputFormatter = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	outputFormatter.dateFormat = format;
	NSString *timestamp_str = [outputFormatter stringFromDate:self];
	return timestamp_str;
}

- (NSString *)string {
	return [self stringWithFormat:[NSDate dbFormatString]];
}

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle {
	NSDateFormatter *outputFormatter = [TexLegeDateHelper sharedTexLegeDateHelper].modFormatter;
	outputFormatter.dateStyle = dateStyle;
	outputFormatter.timeStyle = timeStyle;
	NSString *outputString = [outputFormatter stringFromDate:self];
	return outputString;
}

- (NSDate *)beginningOfWeek {
	// largely borrowed from "Date and Time Programming Guide for Cocoa"
	// we'll use the default calendar and hope for the best
	
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	NSDate *beginningOfWeek = nil;
	BOOL ok = [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek
						   interval:NULL forDate:self];
	if (ok) {
		return beginningOfWeek;
	} 
	
	// couldn't calc via range, so try to grab Sunday, assuming gregorian style
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:self];
	
	/*
	 Create a date components to represent the number of days to subtract from the current date.
	 The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today's Sunday, subtract 0 days.)
	 */
	NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
	componentsToSubtract.day = 0 - (weekdayComponents.weekday - 1);
	beginningOfWeek = nil;
	beginningOfWeek = [calendar dateByAddingComponents:componentsToSubtract toDate:self options:0];
	
	//normalize to midnight, extract the year, month, and day components and create a new date from those components.
	NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
											   fromDate:beginningOfWeek];
	return [calendar dateFromComponents:components];
}

- (NSDate *)beginningOfDay {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	// Get the weekday component of the current date
	NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
											   fromDate:self];
	return [calendar dateFromComponents:components];
}

- (NSDate *)endOfWeek {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:self];
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of week for a particular date, add (7 - weekday) days
	componentsToAdd.day = (7 - weekdayComponents.weekday);
	NSDate *endOfWeek = [calendar dateByAddingComponents:componentsToAdd toDate:self options:0];
	
	return endOfWeek;
}

- (NSDate *)dateByAddingDays:(NSInteger)days {
	NSCalendar *calendar = [TexLegeDateHelper sharedTexLegeDateHelper].calendar;
	// Get the weekday component of the current date
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the week offset for a particular date, subtract 7 days
	componentsToAdd.day = days;
	NSDate *timeFrom = [calendar dateByAddingComponents:componentsToAdd toDate:self options:0];
	
	return timeFrom;
}


+ (NSString *)dateFormatString {
	return @"yyyy-MM-dd";
}

+ (NSString *)timeFormatString {
	return @"HH:mm:ss";
}

+ (NSString *)timestampFormatString {
	return @"yyyy-MM-dd HH:mm:ss";
}

// preserving for compatibility
+ (NSString *)dbFormatString {	
	return [NSDate timestampFormatString];
}

#pragma mark -
#pragma mark Comparison

- (BOOL) isEarlierThanDate:(NSDate *)laterDate {
	return ([self compare:laterDate] != NSOrderedDescending); // sooner is before later
}

#pragma mark -
#pragma mark Timestamp

- (NSString *)timestampString {
	NSString *stampString = [self stringWithFormat:[NSDate timestampFormatString]];
	return stampString;
}

+ (NSDate *)dateFromTimestampString:(NSString *)timestamp {
	NSDate *aDate = [NSDate dateFromString:timestamp withFormat:[NSDate timestampFormatString]];
	return aDate;
}

#pragma mark -
#pragma mark Time Zone Conversion

+ (NSDate *)dateFromDate:(NSDate *)sourceDate fromTimeZone:(NSString *)tzAbbrev {
	// The date in your source timezone (eg. EST)	
																	// @"EST", @"CST", @"UTC", @"GMT"
	NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:tzAbbrev];
	NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
	
	NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
	NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
	NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
	
	return [sourceDate dateByAddingTimeInterval:interval];	
}

@end
