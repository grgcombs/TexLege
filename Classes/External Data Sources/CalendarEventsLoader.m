//
//  CalendarEventsLoader.m
//  Created by Gregory Combs on 3/18/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CalendarEventsLoader.h"
#import "NSDate+Helper.h"
#import "UtilityMethods.h"
#import "TexLegeReachability.h"
#import "OpenLegislativeAPIs.h"

#import "LocalyticsSession.h"
#import "OpenLegislativeAPIs.h"
#import "LoadingCell.h"

#import "CalendarDetailViewController.h"
#import "StateMetaLoader.h"

/*
 Sorts an array of CalendarItems objects by date.
 */
NSComparisonResult sortByDate(id firstItem, id secondItem, void *context)
{
	NSComparisonResult comparison = NSOrderedSame;

	NSDate *firstDate = firstItem[kCalendarEventsLocalizedDateKey];
	NSDate *secondDate = secondItem[kCalendarEventsLocalizedDateKey];

	NSString *firstWhen = firstItem[kCalendarEventsWhenKey];
	NSString *secondWhen = secondItem[kCalendarEventsWhenKey];

	NSString *firstID = firstItem[kCalendarEventsIDKey];
	NSString *secondID = secondItem[kCalendarEventsIDKey];

	if (firstDate && secondDate)
		comparison = [firstDate compare:secondDate];
	else if (firstWhen && secondWhen)
		comparison = [firstWhen compare:secondWhen];
	else if (firstID && secondID)
		comparison = [firstID compare:secondID];

	return comparison;
}

@interface CalendarEventsLoader (Private)
- (NSMutableDictionary *)parseEvent:(NSDictionary *)inEvent;
@end

@implementation CalendarEventsLoader

@synthesize isFresh, loadingStatus;

+ (CalendarEventsLoader*)sharedCalendarEventsLoader
{
	static dispatch_once_t pred;
	static CalendarEventsLoader *foo = nil;

	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype)init {
	if ((self=[super init])) {
		isFresh = NO;
		_events = nil;
		updated = nil;
		loadingStatus = LOADING_IDLE;

		[[TexLegeReachability sharedTexLegeReachability] addObserver:self
														  forKeyPath:@"openstatesConnectionStatus"
															 options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
															 context:nil];

		[OpenLegislativeAPIs sharedOpenLegislativeAPIs];

        eventStore = [[EKEventStore alloc] init];
        [eventStore defaultCalendarForNewEvents];

        /*
         #warning danger
         NSDate *past = [NSDate dateFromString:@"December 1, 2009" withFormat:@"MMM d, yyyy"];
         NSDate *future = [NSDate dateFromString:@"December 1, 2011" withFormat:@"MMM d, yyyy"];
         NSPredicate *pred = [eventStore predicateForEventsWithStartDate:past endDate:future calendars:nil];
         NSArray *allEvents = [eventStore eventsMatchingPredicate:pred];
         for (EKEvent *event in allEvents) {
         NSError *error = nil;
         if (![eventStore removeEvent:event span:EKSpanThisEvent error:&error])
         NSLog(@"%@", [error localizedDescription]);
         }

         [[NSUserDefaults standardUserDefaults] synchronize];
         if (IsEmpty([[NSUserDefaults standardUserDefaults] objectForKey:kTLEventKitKey])) {
         [[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray array] forKey:kTLEventKitKey];
         [[NSUserDefaults standardUserDefaults] synchronize];
         }
         */

	}
	return self;
}

- (void)dealloc {
	[[TexLegeReachability sharedTexLegeReachability] removeObserver:self forKeyPath:@"openstatesConnectionStatus"];
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	nice_release(updated);
    nice_release(_events);
	nice_release(eventStore);
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (!IsEmpty(keyPath) && [keyPath isEqualToString:@"openstatesConnectionStatus"]) {
		/*
         if ([change valueForKey:NSKeyValueChangeKindKey] == NSKeyValueChangeSetting) {
         id newVal = [change valueForKey:NSKeyValueChangeNewKey];
         }*/
		if ([TexLegeReachability openstatesReachable])
			[self loadEvents:nil];
		else if (self.loadingStatus != LOADING_NO_NET) {
			self.loadingStatus = LOADING_NO_NET;
			[[NSNotificationCenter defaultCenter] postNotificationName:kCalendarEventsNotifyError object:nil];
		}
	}
}

- (void)loadEvents:(id)sender {
	if ([TexLegeReachability openstatesReachable]) {
		StateMetaLoader *meta = [StateMetaLoader sharedStateMeta];

		if (IsEmpty(meta.selectedState))
			return;

		//	http://openstates.sunlightlabs.com/api/v1/events/?state=tx&apikey=xxxxxxxxxxxxxxxx

		self.loadingStatus = LOADING_ACTIVE;
		NSDictionary *queryParams = @{@"state": meta.selectedState,
									 @"apikey": SUNLIGHT_APIKEY};
		[[OpenLegislativeAPIs sharedOpenLegislativeAPIs].osApiClient get:@"/events" queryParams:queryParams delegate:self];
	}
	else if (self.loadingStatus != LOADING_NO_NET) {
		self.loadingStatus = LOADING_NO_NET;
		[[NSNotificationCenter defaultCenter] postNotificationName:kCalendarEventsNotifyError object:nil];
	}
}

- (NSArray*)events {
	if (self.loadingStatus > LOADING_NO_NET || !_events || !isFresh || !updated || ([[NSDate date] timeIntervalSinceDate:updated] > 1800)) {	// if we're over a half-hour old, let's refresh
		isFresh = NO;
//		debug_NSLog(@"CalendarEventsLoader is stale, need to refresh");

		[self loadEvents:nil];
	}
	return _events;
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if (error && request) {
		debug_NSLog(@"Error loading events from %@: %@", [request description], [error localizedDescription]);
	}

	isFresh = NO;

	nice_release(_events);

	// We had trouble loading the events online, so pull up the cache from the one in the documents folder, if possible
	NSString *thePath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kCalendarEventsCacheFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:thePath]) {
		debug_NSLog(@"EventsLoader: using cached events in the documents folder.");
		_events = [[NSMutableArray arrayWithContentsOfFile:thePath] retain];
	}
	if (!_events) {
		_events = [[NSMutableArray array] retain];
    }

	if (self.loadingStatus != LOADING_NO_NET) {
		self.loadingStatus = LOADING_NO_NET;
		[[NSNotificationCenter defaultCenter] postNotificationName:kCalendarEventsNotifyError object:nil];
	}
}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
	if ([request isGET] && [response isOK]) {
		// Success! Let's take a look at the data
		self.loadingStatus = LOADING_IDLE;

        nice_release(_events);

        NSError *error = nil;
        NSArray *allEvents = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

		if (IsEmpty(allEvents))
			return;

		allEvents = [allEvents findAllWhereKeyPath:kCalendarEventsTypeKey equals:kCalendarEventsTypeCommitteeValue];
		if (allEvents) {
			_events = [[NSMutableArray alloc] init];
			for (NSDictionary *event in allEvents) {
				NSString *when = event[kCalendarEventsWhenKey];
				NSInteger daysAgo = [[NSDate dateFromTimestampString:when] daysAgo];
				if (daysAgo < 5) {
					NSMutableDictionary *newEvent = [self parseEvent:event];
					NSArray *tempKeys = newEvent.allKeys;
					for (NSString *key in tempKeys) {
						id value = newEvent[key];
						if ([[NSNull null] isEqual:value]) {
							[newEvent removeObjectForKey:key];
						}
					}
					[_events addObject:newEvent];
				}

			}
			[_events sortUsingFunction:sortByDate context:nil];

			NSString *thePath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kCalendarEventsCacheFile];
			if (![_events writeToFile:thePath atomically:YES]) {
				NSLog(@"CalendarEventsLoader: Error writing event cache to file: %@", thePath);
			}

			isFresh = YES;
            nice_release(updated);
			updated = [[NSDate date] retain];

			[[NSNotificationCenter defaultCenter] postNotificationName:kCalendarEventsNotifyLoaded object:nil];
			debug_NSLog(@"EventsLoader network download successful, archiving for others.");
		}
		else {
			[self request:request didFailLoadWithError:nil];
			return;
		}
	}
}

- (NSMutableDictionary *)parseEvent:(NSDictionary *)inEvent {
	NSMutableDictionary *loadedEvent = [NSMutableDictionary dictionaryWithDictionary:inEvent];


	if ([[NSNull null] isEqual:loadedEvent[kCalendarEventsEndKey]])
		[loadedEvent removeObjectForKey:kCalendarEventsEndKey];
	if ([[NSNull null] isEqual:loadedEvent[kCalendarEventsNotesKey]])
		loadedEvent[kCalendarEventsNotesKey] = @"";


	NSString *when = loadedEvent[kCalendarEventsWhenKey];
	NSDate *utcDate = [NSDate dateFromTimestampString:when];
	NSDate *localDate = [NSDate dateFromDate:utcDate fromTimeZone:@"UTC"];

	// Set the date and time, and pre-format our strings
	if (localDate) {
		loadedEvent[kCalendarEventsLocalizedDateKey] = localDate;

		NSString *dateString = [localDate stringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
		if (dateString)
			loadedEvent[kCalendarEventsLocalizedDateStringKey] = dateString;

		NSString *timeString = [localDate stringWithDateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
		if (timeString) {
			loadedEvent[kCalendarEventsLocalizedTimeStringKey] = timeString;
		}
	}

	NSArray *participants = loadedEvent[kCalendarEventsParticipantsKey];
	if (participants) {
		NSDictionary *participant = [participants findWhereKeyPath:kCalendarEventsParticipantTypeKey equals:@"committee"];
		if (participant) {
			loadedEvent[kCalendarEventsCommitteeNameKey] = participant[kCalendarEventsParticipantNameKey];

			NSString * chamberString = participant[kCalendarEventsTypeChamberValue];
			if (!IsEmpty(chamberString))
				loadedEvent[kCalendarEventsTypeChamberValue] = @(chamberFromOpenStatesString(chamberString));
		}
	}

	BOOL canceled = ([loadedEvent[kCalendarEventsStatusKey] isEqualToString:kCalendarEventsCanceledKey]);
	loadedEvent[kCalendarEventsCanceledKey] = @(canceled);

    NSURL *announcementURL = [self announcementURLForEvent:loadedEvent];
    if (announcementURL) {
        loadedEvent[kCalendarEventsAnnouncementURLKey] = announcementURL;
    }
	return loadedEvent;
}

- (NSArray *)commiteeeMeetingsForChamber:(NSInteger)chamber {
	if (IsEmpty(self.events))
		return nil;

	if (chamber == BOTH_CHAMBERS)
		return _events;
	else
		return [_events findAllWhereKeyPath:kCalendarEventsTypeChamberValue equals:@(chamber)];
}


#pragma mark -
#pragma mark EventKit
- (void)addAllEventsToiCal:(id)sender {
    //#warning see about asking what calendar they want to put these in

	if (![UtilityMethods supportsEventKit] || !eventStore) {
		debug_NSLog(@"EventKit not available on this device");
		return;
	}

	NSLog(@"CalendarEventsLoader == ADDING ALL MEETINGS TO ICAL == (MESSY)");
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"iCAL_ALL_MEETINGS"];

    __block CalendarEventsLoader *bself = self;
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!bself || !granted)
                return;
            NSArray *meetings = [bself commiteeeMeetingsForChamber:BOTH_CHAMBERS];
            for (NSDictionary *meeting in meetings) {
                [bself addEventToiCal:meeting delegate:nil];
            }
        }];
    }];
}

- (NSURL *)announcementURLForEvent:(NSDictionary *)eventDict {
    NSString *urlString = eventDict[kCalendarEventsAnnouncementURLKey];
    if (NO == IsEmpty(urlString)) {
        return [NSURL URLWithString:urlString];
    }
    NSArray *urls = [eventDict valueForKeyPath:kCalendarEventsSourceURLKeyPath];
    if (IsEmpty(urls)) {
        return nil;
    }
    if (![urls isKindOfClass:[NSArray class]]) {
        return nil;
    }
    urlString = urls[0];
    return [NSURL URLWithString:urlString];
}

- (void)addEventToiCal:(NSDictionary *)eventDict delegate:(id)delegate {
	if (!eventDict || !eventStore)
		return;

    __block CalendarEventsLoader *bself = self;
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            if (!bself || !granted)
                return;
            NSString *chamberString = stringForChamber([eventDict[kCalendarEventsTypeChamberValue] integerValue], TLReturnFull);
            NSString *committee = eventDict[kCalendarEventsCommitteeNameKey];
            NSDate *meetingDate = eventDict[kCalendarEventsLocalizedDateKey];
            NSString *chamberCommitteeString = [NSString stringWithFormat:@"%@ %@", chamberString, committee];

            EKEvent *event  = nil;

            [[NSUserDefaults standardUserDefaults] synchronize];
            NSMutableArray *eventIDs = [[[NSUserDefaults standardUserDefaults] objectForKey:kTLEventKitKey] mutableCopy];
            NSMutableDictionary *eventEntry = [eventIDs findWhereKeyPath:kTLEventKitTLIDKey equals:eventDict[kCalendarEventsIDKey]];
            if (eventEntry) {
                id eventIdentifier = eventEntry[kTLEventKitEKIDKey];
                if (eventIdentifier)
                    event = [eventStore eventWithIdentifier:eventIdentifier];
            }
            if (!event && meetingDate) {
                NSPredicate *pred = [eventStore predicateForEventsWithStartDate:meetingDate endDate:meetingDate calendars:nil];
                NSArray *allEvents = [eventStore eventsMatchingPredicate:pred];
                for (EKEvent *foundevent in allEvents) {
                    //NSError *error = nil;
                    if ([foundevent.title isEqualToString:chamberCommitteeString]) {
                        NSLog(@"found event %@", foundevent.title);
                        event = foundevent; //[eventStore removeEvent:foundevent span:EKSpanThisEvent error:&error];
                    }
                }
            }
            if (!event)
                // we didn't find an event, so lets create
                event = [EKEvent eventWithEventStore:eventStore];

            event.title     = chamberCommitteeString;
            if ([eventDict[kCalendarEventsCanceledKey] boolValue] == YES)
                event.title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ (CANCELED)", @"DataTableUI", @"the event was cancelled"),
                               event.title];

            event.location = eventDict[kCalendarEventsLocationKey];

            event.notes = NSLocalizedStringFromTable(@"[TexLege] Length of this meeting is only an estimate.", @"DataTableUI", @"inserted into iOS calendar events");
            if (NO == IsEmpty(eventDict[kCalendarEventsAgendaKey]))
                event.notes = eventDict[kCalendarEventsAgendaKey];
            else if (NO == IsEmpty(eventDict[kCalendarEventsNotesKey]))
                event.notes = eventDict[kCalendarEventsNotesKey];
            else {
                NSURL *url = [self announcementURLForEvent:eventDict];
                if (url && [TexLegeReachability canReachHostWithURL:url alert:NO]) {
                    NSError *error = nil;
                    NSString *urlcontents = [NSString stringWithContentsOfURL:url encoding:NSWindowsCP1252StringEncoding error:&error];
                    if (!error && urlcontents && urlcontents.length) {
                        NSString *flattened = [[urlcontents flattenHTML] stringByReplacingOccurrencesOfString:@"Schedule Display" withString:@""];
                        flattened = [flattened stringByReplacingOccurrencesOfString:@"\r\n\r\n" withString:@"\r\n"];
                        event.notes = flattened;
                    }
                }
            }

            if (!meetingDate || [eventDict[kCalendarEventsAllDayKey] boolValue]) {
                debug_NSLog(@"Calendar Detail ... don't know the complete event time/date");
                event.allDay = YES;
                if (eventDict[kCalendarEventsLocalizedDateKey]) {
                    event.startDate = eventDict[kCalendarEventsLocalizedDateKey];
                    event.endDate = eventDict[kCalendarEventsLocalizedDateKey];
                }
                event.location = eventDict[kCalendarEventsDescriptionKey];
            }
            else {
                event.startDate = meetingDate;
                event.endDate   = [NSDate dateWithTimeInterval:3600 sinceDate:event.startDate];
            }
            event.calendar = eventStore.defaultCalendarForNewEvents;

            NSError *err = nil;
            [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
            if (err)
                NSLog(@"CalendarEventsLoader: error saving event %@: %@", event.description, err.localizedDescription);

            if (eventEntry)
                [eventIDs removeObject:eventEntry];

            eventEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          event.eventIdentifier, kTLEventKitEKIDKey,
                          eventDict[kCalendarEventsIDKey], kTLEventKitTLIDKey,
                          //eventStore.eventStoreIdentifier, kTLEventKitStoreKey,
                          nil];
            [eventIDs addObject:eventEntry];

            [[NSUserDefaults standardUserDefaults] setObject:eventIDs forKey:kTLEventKitKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if (delegate && [delegate respondsToSelector:@selector(presentEventEditorForEvent:)]) {
                [delegate performSelector:@selector(presentEventEditorForEvent:) withObject:event];
            }
            nice_release(eventIDs);
        }];
    }];
}

@end
