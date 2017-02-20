//
//  TexLegeLibrary.m
//  Created by Gregory Combs on 2/4/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeLibrary.h"
#import "UtilityMethods.h"
#import "StateMetaLoader.h"

NSString *stringInitial(NSString *inString, BOOL parens)
{
	if (IsEmpty(inString))
		return nil;
	NSString * initial = [inString substringToIndex:1];
	if ([inString isEqualToString:NSLocalizedStringFromTable(@"All", @"DataTableUI", @"As in all chambers")] 
		|| [inString isEqualToString:NSLocalizedStringFromTable(@"Both", @"DataTableUI", @"As in both chambers")])
    {
		initial = inString;
	}
	if (parens)
		initial = [NSString stringWithFormat:@"(%@)", initial];
	return initial;
}

NSString *abbreviateString(NSString *inString)
{
	if (IsEmpty(inString))
		return nil;
	
	NSString *outString = NSLocalizedStringFromTable(inString, @"Abbreviations", nil);
	if (IsEmpty(outString)) {
		outString = inString;
	}
	return outString;
}

NSString *stringForChamber(TXLChamberType chamber, TLStringReturnType type)
{
    struct StateMetadataKeys keys = StateMetadataKeys;
	NSDictionary *stateMeta = [[StateMetaLoader instance] stateMetadata];
    NSDictionary *chambers = (stateMeta != nil) ? stateMeta[keys.chambers.metaLookup] : nil;
    NSDictionary *chamberInfo = nil;
    NSString *chamberName = nil;
    NSString *title = nil;
    struct StateMetadataChamberDetailKeys chamberKeys;

    if (chamber == SENATE || chamber == HOUSE)
    {
        chamberKeys = (chamber == SENATE) ? keys.chambers.upper : keys.chambers.lower;
        chamberInfo = (chambers != nil) ? chambers[chamberKeys.metaLookup] : nil;
        chamberName = chamberInfo[chamberKeys.name];
        title = chamberInfo[chamberKeys.title];

        if (!IsEmpty(stateMeta) && !IsEmpty(chamberName))
        {
            // Just shortens it to the first word (at least that's how we set it up in the file)
            chamberName = abbreviateString(chamberName);
        }
    }

	if (!chamberName)
    {
		switch (chamber) {
			case HOUSE:
				chamberName = NSLocalizedStringFromTable(@"House", @"DataTableUI", nil);
				break;
			case SENATE:
				chamberName = NSLocalizedStringFromTable(@"Senate", @"DataTableUI", nil);
				break;
			case JOINT:
				chamberName = NSLocalizedStringFromTable(@"Joint", @"DataTableUI", nil);
				break;
			case BOTH_CHAMBERS:
                chamberName = NSLocalizedStringFromTable(@"All", @"DataTableUI", nil);
				break;
            case EXECUTIVE:
                chamberName = NSLocalizedStringFromTable(@"Executive", @"DataTableUI", nil);
		}
	}

	if (type == TLReturnFull)
		return chamberName;
	
	if (type == TLReturnInitial)
		return stringInitial(chamberName, YES);
	
	if (type == TLReturnAbbrev || type == TLReturnTitle )
    {
		if (IsEmpty(title)) {
			switch (chamber) {
				case SENATE:
					title = NSLocalizedStringFromTable(@"Senator", @"DataTableUI", @"");
					break;
				case HOUSE:
					title = NSLocalizedStringFromTable(@"Representative", @"DataTableUI", @"");
					break;
                case EXECUTIVE:
                    title = NSLocalizedStringFromTable(@"Governor", @"DataTableUI", nil);
                    break;
                case BOTH_CHAMBERS:
                case JOINT:
                    // We need to know when this condition triggers --- so we can fix it, it's dumb.
                    title = NSLocalizedStringFromTable(@"Member", @"DataTableUI", nil);
                    break;
			}
		}
		
		if (type == TLReturnAbbrev && NO == IsEmpty(title))
			title = abbreviateString(title);			
		
		return title;
	}			

	if (type == TLReturnOpenStates)
    {
		switch (chamber) {
			case SENATE:
				chamberName = @"upper";
				break;
			case HOUSE:
				chamberName = @"lower";
				break;
			case JOINT:
				chamberName = @"joint";
				break;
			case EXECUTIVE:
				chamberName = @"executive";
				break;
			case BOTH_CHAMBERS:
			default:
				chamberName = @"";
				break;
		}
	}
	return chamberName;
}

TXLChamberType chamberFromOpenStatesString(NSString *chamberString)
{
    TXLChamberType chamber = BOTH_CHAMBERS;
	
	if (NO == IsEmpty(chamberString)) {
		if ([chamberString caseInsensitiveCompare:@"upper"] == NSOrderedSame)
			chamber = SENATE;
		else if ([chamberString caseInsensitiveCompare:@"lower"] == NSOrderedSame)
			chamber = HOUSE;
		else if ([chamberString caseInsensitiveCompare:@"joint"] == NSOrderedSame)
			chamber = JOINT;
		else if ([chamberString caseInsensitiveCompare:@"executive"] == NSOrderedSame)
			chamber = EXECUTIVE;
	}
	
	return chamber;
}


NSString *stringForParty(TXLPartyType party, TLStringReturnType type)
{
	NSString *partyString = nil;
	
	switch (party) {
		case DEMOCRAT:
			partyString = NSLocalizedStringFromTable(@"Democrat", @"DataTableUI", nil);
			break;
		case REPUBLICAN:
			partyString = NSLocalizedStringFromTable(@"Republican", @"DataTableUI", nil);
			break;
		default:
			partyString = NSLocalizedStringFromTable(@"Independent", @"DataTableUI", nil);
			break;
	}		
	
	if (type == TLReturnFull)
		return partyString;
	
	if (type == TLReturnInitial)
		partyString = stringInitial(partyString, NO);

	if (type == TLReturnAbbrev)
		partyString = abbreviateString(partyString);
	
	if (type == TLReturnAbbrevPlural)
		partyString = abbreviateString([partyString stringByAppendingString:@"s"]);
	
	return partyString;
}

NSString *billTypeStringFromBillID(NSString *billID)
{
	NSArray *words = [billID componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (!IsEmpty(words))
		return words[0];
    return nil;
}

NSString * watchIDForBill(NSDictionary *aBill)
{
	if (aBill && aBill[@"session"] && aBill[@"bill_id"])
		return [NSString stringWithFormat:@"%@:%@", aBill[@"session"],aBill[@"bill_id"]]; 
    return @"";
}
