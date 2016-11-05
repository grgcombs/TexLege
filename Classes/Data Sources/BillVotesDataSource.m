//
//  BillVotesDataSource.m
//  Created by Gregory S. Combs on 3/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillVotesDataSource.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"
#import "LegislatorDetailViewController.h"
#import "LegislatorObj+RestKit.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface BillVotesDataSource ()
- (void) loadVotesAndVoters;
@end

@implementation BillVotesViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.rowHeight = 73.0f;
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end

@implementation BillVotesDataSource

- (Class)dataClass
{
	return nil;
}

- (instancetype)initWithBillVotes:(NSDictionary *)newVotes
{
	if ((self = [super init]))
    {
		_voters = nil;
		if (newVotes)
        {
			_billVotes = [newVotes mutableCopy];
            id voteID = newVotes[@"vote_id"];
            if (voteID)
                _voteID = voteID;
			[self loadVotesAndVoters];
		}
	}
	return self;
}


#pragma mark -
#pragma mark UITableViewDataSource methods

// legislator name is displayed in a plain style tableview

- (UITableViewStyle)tableViewStyle
{
	return UITableViewStylePlain;
};


// return the legislator at the index in the sorted by symbol array
- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath
{
	if (!IsEmpty(self.voters) && _voters.count > indexPath.row)
		return _voters[indexPath.row];
	return nil;	
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
	if (!IsEmpty(self.voters))
		return [NSIndexPath indexPathForRow:[_voters indexOfObject:dataObject] inSection:0];
	return nil;
}

- (void)resetCoreData:(NSNotification *)notification
{
	[self loadVotesAndVoters];
}

#pragma mark - UITableViewDataSource methods
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{
	// deselect the new row using animation
	[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];	
	
	NSDictionary *voter = [self dataObjectForIndexPath:newIndexPath];
    if (!voter)
        return;

	LegislatorObj *legislator = [LegislatorObj objectWithPrimaryKeyValue:voter[@"legislatorID"]];
	if (!legislator)
        return;

    LegislatorDetailViewController *legVC = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
    legVC.legislator = legislator;
    UIViewController *controller = self.viewController;
    if (!controller)
        return;
    [controller.navigationController pushViewController:legVC animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *dataObj = [self dataObjectForIndexPath:indexPath];

	NSString *leg_cell_ID = @"StandardVotingCell";		

	TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:leg_cell_ID];
	
	if (cell == nil)
    {
		cell = [[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:leg_cell_ID];
		cell.accessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 50.f)];
		cell.detailTextLabel.font = [TexLegeTheme boldFifteen];
		cell.textLabel.font = [TexLegeTheme boldTwelve];
	}
	NSInteger voteCode = [dataObj[@"vote"] integerValue];
	UIImageView *imageView = (UIImageView *)cell.accessoryView;
	
	switch (voteCode)
    {
		case BillVotesTypeYea:
			imageView.image = [UIImage imageNamed:@"VoteYea"];
			break;
		case BillVotesTypeNay:
			imageView.image = [UIImage imageNamed:@"VoteNay"];
			break;
		case BillVotesTypePNV:
		default:
			imageView.image = [UIImage imageNamed:@"VotePNV"];
			break;
	}
    if (dataObj)
    {
        cell.textLabel.text = dataObj[@"subtitle"];
        cell.detailTextLabel.text = dataObj[@"name"];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:dataObj[@"photo_url"]] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    }

	cell.backgroundColor = (indexPath.row % 2 == 0) ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	return cell;	
}

#pragma mark -
#pragma mark Indexing / Sections


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return 1; 
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	if (!IsEmpty(self.voters))
    {
		return _voters.count;
	}
	return 0;	
}

#pragma mark -
#pragma mark Data Methods

- (void) loadVotesAndVoters
{
	if (!self.billVotes)
		return;

    self.voters = nil;
    NSMutableArray *voters = [@[] mutableCopy];
    self.voters = voters;
    voters = nil;

    @autoreleasepool {

        NSInteger chamber = chamberFromOpenStatesString(_billVotes[@"chamber"]);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.legtype == %d", chamber];

        NSArray *allMembers = [LegislatorObj objectsWithPredicate:predicate];
        NSDictionary *memberLookup = [allMembers indexKeyedDictionaryWithKey:@"openstatesID"];

        NSArray *voteTypes = @[@"other", @"no", @"yes"];

        NSInteger codeIndex = BillVotesTypePNV;
        for (NSString *type in voteTypes) {
            NSString *countString = [type stringByAppendingString:@"_count"];
            NSString *votesString = [type stringByAppendingString:@"_votes"];
            NSNumber *voteCode = @(codeIndex);

            if (_billVotes[countString] && [_billVotes[countString] integerValue])
            {
                for (NSMutableDictionary *voter in _billVotes[votesString])
                {
                    /* We sometimes (all the time?) have to hard code in the Speaker ... let's just hope
                     they don't get rid of Joe Straus any time soon. */
                    if ((!voter[@"leg_id"] || [voter[@"leg_id"] isEqual:[NSNull null]]) &&
                        ([voter[@"name"] hasSubstring:@"Speaker" caseInsensitive:NO]))
                        voter[@"leg_id"] = @"TXL000347";

                    LegislatorObj *member = memberLookup[voter[@"leg_id"]];
                    if (member)
                    {
                        NSMutableDictionary *voter = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                      [member shortNameForButtons], @"name",
                                                      [member fullNameLastFirst], @"nameReverse",
                                                      member.lastnameInitial, @"initial",
                                                      member.legislatorID, @"legislatorID",
                                                      voteCode, @"vote",
                                                      [member labelSubText], @"subtitle",
                                                      member.photo_url, @"photo_url",
                                                      nil];
                        [self.voters addObject:voter];
                    }
                }
            }
            codeIndex++;
        }
        
        [self.voters sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"nameReverse" ascending:YES]]];
    }

	[[NSNotificationCenter defaultCenter] postNotificationName:@"BILLVOTES_LOADED" object:self];
	
}

- (NSFetchedResultsController *)fetchedResultsController
{
    return nil;		// in case someone wants this from our [super]
}    

@end
