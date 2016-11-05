//
//  XMLReader.m
//
//  Created by Troy Brant.
//  http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/
//

#import "XMLReader.h"

NSString *const kXMLReaderTextNodeKey = @"text";

@interface XMLReader()

- (NSMutableDictionary *)objectWithData:(NSData *)data;

@property (nonatomic,copy) NSMutableArray *dictionaryStack;
@property (nonatomic,copy) NSMutableString *textInProgress;
@property (nonatomic,copy) NSError *parseError;

@end


@implementation XMLReader

#pragma mark -
#pragma mark Public methods

+ (NSMutableDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)error
{
    XMLReader *reader = [[XMLReader alloc] init];
    NSMutableDictionary *rootDictionary = [reader objectWithData:data];
    if (error && reader.parseError)
        *error = reader.parseError;
    return rootDictionary;
}

+ (NSMutableDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
}

#pragma mark -
#pragma mark Parsing


- (NSMutableDictionary *)objectWithData:(NSData *)data
{
    self.dictionaryStack = nil;
    self.textInProgress = nil;

    _dictionaryStack = [[NSMutableArray alloc] init];
    _textInProgress = [[NSMutableString alloc] init];
    
    // Initialize the stack with a fresh dictionary
    [_dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    BOOL success = [parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
    {
        NSMutableDictionary *resultDict = self.dictionaryStack[0];
        return resultDict;
    }
    
    return nil;
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = self.dictionaryStack.lastObject;

    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = parentDict[elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray arrayWithObject:existingValue];

            // Replace the child dictionary with an array of children dictionaries
            parentDict[elementName] = array;
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        parentDict[elementName] = childDict;
    }
    
    // Update the stack
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = self.dictionaryStack.lastObject;
    
    // Set the text property
    if (self.textInProgress.length > 0)
    {
        dictInProgress[kXMLReaderTextNodeKey] = self.textInProgress;

        // Reset the text

        self.textInProgress = [NSMutableString string];
    }
    
    // Pop the current dict
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Build the text value
    [self.textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    if (parseError)
        self.parseError = parseError;
}

@end
