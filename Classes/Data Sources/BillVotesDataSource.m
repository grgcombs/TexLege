//
//  LegislatorsDataSource.m
//  TexLege
//
//  Created by Gregory S. Combs on 3/31/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//

#import "BillVotesDataSource.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"
#import "LegislatorDetailViewController.h"

@interface BillVotesDataSource (Private)
- (void) loadVotesAndVoters;
@end

@implementation BillVotesDataSource

@synthesize billVotes = billVotes_, voters = voters_, voteID, viewController;

- (Class)dataClass {
	return nil;
}

- (NSManagedObjectContext *)managedObjectContext {
	return nil;
}

- (id)initWithBillVotes:(NSMutableDictionary *)newVotes {
	if (self = [super init]) {
		voters_ = nil;
		if (newVotes) {
			billVotes_ = [newVotes retain];
			voteID = [[newVotes objectForKey:@"vote_id"] retain];
			[self loadVotesAndVoters];
		}
	}
	return self;
}

- (void)dealloc {	
	self.voteID = nil;
	self.voters = nil;	
	self.billVotes = nil;	
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

// legislator name is displayed in a plain style tableview

- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
};


// return the legislator at the index in the sorted by symbol array
- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath {
	if (!IsEmpty(voters_) && [voters_ count] > indexPath.row)
		return [voters_ objectAtIndex:indexPath.row];
	return nil;	
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject {
	if (!IsEmpty(voters_))
		return [NSIndexPath indexPathForRow:[voters_ indexOfObject:dataObject] inSection:0];
	return nil;
}

- (void)resetCoreData:(NSNotification *)notification {
	[self loadVotesAndVoters];
}

#pragma mark - UITableViewDataSource methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	// deselect the new row using animation
	[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];	
	
	NSDictionary *voter = [self dataObjectForIndexPath:newIndexPath];

	LegislatorObj *legislator = [LegislatorObj objectWithPrimaryKeyValue:[voter objectForKey:@"legislatorID"]];
	if (legislator) {
		LegislatorDetailViewController *legVC = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
		legVC.legislator = legislator;	
		if (self.viewController)
			[self.viewController.navigationController pushViewController:legVC animated:YES];
		[legVC release];
	}	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dataObj = [self dataObjectForIndexPath:indexPath];

	NSString *leg_cell_ID = @"StandardVotingCell";		

	TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:leg_cell_ID];
	
	if (cell == nil) {
		cell = [[[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:leg_cell_ID] autorelease];
		cell.accessoryView = [[[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 30.f, 30.f)] autorelease];
		cell.detailTextLabel.font = [TexLegeTheme boldFifteen];
		cell.textLabel.font =		[TexLegeTheme boldTwelve];
	}
	NSInteger voteCode = [[dataObj objectForKey:@"vote"] integerValue];
	UIImageView *imageView = (UIImageView *)cell.accessoryView;
	
	switch (voteCode) {
		case BillVotesTypeYea:
			imageView.image = [UIImage imageNamed:@"ball_green"];
			break;
		case BillVotesTypeNay:
			imageView.image = [UIImage imageNamed:@"ball_red"];
			break;
		case BillVotesTypePNV:
		default:
			imageView.image = [UIImage imageNamed:@"ball_yellow"];
			break;
	}
	cell.textLabel.text = [dataObj objectForKey:@"subtitle"];
	cell.detailTextLabel.text = [dataObj objectForKey:@"name"];
	cell.imageView.image = [UIImage imageNamed:[dataObj objectForKey:@"photo"]];

	cell.backgroundColor = (indexPath.row % 2 == 0) ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	return cell;	
}

#pragma mark -
#pragma mark Indexing / Sections


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return 1; 
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	if (!IsEmpty(voters_)) {
		return [voters_ count];
	}
	return 0;	
}

#pragma mark -
#pragma mark Data Methods

- (void) loadVotesAndVoters {
	if (!billVotes_)
		return;
	
	if (voters_)
		[voters_ release];
	voters_ = [[NSMutableArray alloc] init];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSInteger chamber = chamberForString([billVotes_ objectForKey:@"chamber"]);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.legtype == %d", chamber];
	
	NSArray *allMembers = [LegislatorObj objectsWithPredicate:predicate];
	NSDictionary *memberLookup = [allMembers indexKeyedDictionaryWithKey:@"openstatesID"];
	
	NSArray *voteTypes = [NSArray arrayWithObjects:@"other", @"no", @"yes", nil];

	NSInteger codeIndex = BillVotesTypePNV;
	for (NSString *type in voteTypes) {
		NSString *countString = [type stringByAppendingString:@"_count"];
		NSString *votesString = [type stringByAppendingString:@"_votes"];
		NSNumber *voteCode = [NSNumber numberWithInteger:codeIndex];
		
		if ([billVotes_ objectForKey:countString] && [[billVotes_ objectForKey:countString] integerValue]) {
			for (NSMutableDictionary *voter in [billVotes_ objectForKey:votesString]) {
				LegislatorObj *member = [memberLookup objectForKey:[voter objectForKey:@"leg_id"]];
				if (member) {
					NSMutableDictionary *voter = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
												  [member shortNameForButtons], @"name",
												  [member fullNameLastFirst], @"nameReverse",
												  member.lastnameInitial, @"initial",
												  member.legislatorID, @"legislatorID",
												  voteCode, @"vote",
												  [member labelSubText], @"subtitle",
												  member.photo_name, @"photo",
												  nil];
					[voters_ addObject:voter];
					[voter release];
				}
			}
		}
		codeIndex++;
	}
	
	[voters_ sortUsingDescriptors:[NSArray arrayWithObject:
								   [NSSortDescriptor sortDescriptorWithKey:@"nameReverse" ascending:YES]]];
	
	[pool drain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BILLVOTES_LOADED" object:self];
	
}

- (NSFetchedResultsController *)fetchedResultsController {
    return nil;		// in case someone wants this from our [super]
}    

@end