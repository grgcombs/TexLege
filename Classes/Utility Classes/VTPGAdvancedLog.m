//
//  VTPGAdvancedLog.m
//  TexLege
//
//  Found at Vincent Gable's Blog
//  http://vgable.com/blog/2010/08/19/the-most-useful-objective-c-code-ive-ever-written/
//

/*
 USAGE:
 Stop using logs like this:
 NSLog(@"actionURL = %@", actionURL))
 
 And start using logs like this:
 
 LOG_EXPR(self.window.screen);
 >>> self.window.screen = <UIScreen: 0x6d20780; bounds = {{0, 0}, {320, 480}}; mode = <UIScreenMode: 0x6d20c50; size = 320.000000 x 480.000000>>
 
 LOG_EXPR(self.tabBarController.viewControllers);
 >>> self.tabBarController.viewControllers = (
 “<UINavigationController: 0xcd02e00>”,
 “<SavingsViewController: 0xcd05c40>”,
 “<SettingsViewController: 0xcd05e90>”
 )
 
 **** It even works on scalars and structs ****
 
 LOG_EXPR(self.window.windowLevel);
 >>> self.window.windowLevel = 0.000000
 
 LOG_EXPR(self.window.frame.size);
 >>> self.window.frame.size = {320, 480}
 
 */

#import "VTPGAdvancedLog.h"

static BOOL TypeCodeIsCharArray(const char *typeCode){
	size_t lastCharOffset = strlen(typeCode) - 1;
	size_t secondToLastCharOffset = lastCharOffset - 1 ;
	
	BOOL isCharArray = typeCode[0] == '[' &&
	typeCode[secondToLastCharOffset] == 'c' && typeCode[lastCharOffset] == ']';
	for(int i = 1; i < secondToLastCharOffset; i++)
		isCharArray = isCharArray && isdigit(typeCode[i]);
	return isCharArray;
}

//since BOOL is #defined as a signed char, we treat the value as
//a BOOL if it is exactly YES or NO, and a char otherwise.
static NSString* VTPGStringFromBoolOrCharValue(BOOL boolOrCharvalue) {
	if(boolOrCharvalue == YES)
		return @"YES";
	if(boolOrCharvalue == NO)
		return @"NO";
	return [NSString stringWithFormat:@"'%c'", boolOrCharvalue];
}

static NSString *VTPGStringFromFourCharCodeOrUnsignedInt32(FourCharCode fourcc) {
	return [NSString stringWithFormat:@"%u ('%u%u%u%u')",
			(unsigned int)fourcc,
			(unsigned int)((fourcc >> 24) & 0xFF),
			(unsigned int)((fourcc >> 16) & 0xFF),
			(unsigned int)((fourcc >> 8) & 0xFF),
			(unsigned int)(fourcc & 0xFF)];
}

static NSString *StringFromNSDecimalWithCurrentLocal(NSDecimal dcm) {
	return NSDecimalString(&dcm, [NSLocale currentLocale]);						   
}

NSString * VTPG_DDToStringFromTypeAndValue(const char * typeCode, void * value) {
#define IF_TYPE_MATCHES_INTERPRET_WITH(typeToMatch,func) \
if (strcmp(typeCode, @encode(typeToMatch)) == 0) \
return (func)(*(typeToMatch*)value)
	
#if	TARGET_OS_IPHONE
	IF_TYPE_MATCHES_INTERPRET_WITH(CGPoint,NSStringFromCGPoint);
	IF_TYPE_MATCHES_INTERPRET_WITH(CGSize,NSStringFromCGSize);
	IF_TYPE_MATCHES_INTERPRET_WITH(CGRect,NSStringFromCGRect);
#else
	IF_TYPE_MATCHES_INTERPRET_WITH(NSPoint,NSStringFromPoint);
	IF_TYPE_MATCHES_INTERPRET_WITH(NSSize,NSStringFromSize);
	IF_TYPE_MATCHES_INTERPRET_WITH(NSRect,NSStringFromRect);
#endif
	IF_TYPE_MATCHES_INTERPRET_WITH(NSRange,NSStringFromRange);
	IF_TYPE_MATCHES_INTERPRET_WITH(Class,NSStringFromClass);
	IF_TYPE_MATCHES_INTERPRET_WITH(SEL,NSStringFromSelector);
	IF_TYPE_MATCHES_INTERPRET_WITH(BOOL,VTPGStringFromBoolOrCharValue);
	IF_TYPE_MATCHES_INTERPRET_WITH(NSDecimal,StringFromNSDecimalWithCurrentLocal);
	
#define IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(typeToMatch,formatString) \
if (strcmp(typeCode, @encode(typeToMatch)) == 0) \
return [NSString stringWithFormat:(formatString), (*(typeToMatch*)value)]
	
	
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(CFStringRef,@"%@"); //CFStringRef is toll-free bridged to NSString*
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(CFArrayRef,@"%@"); //CFArrayRef is toll-free bridged to NSArray*
	IF_TYPE_MATCHES_INTERPRET_WITH(FourCharCode, VTPGStringFromFourCharCodeOrUnsignedInt32);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(long long,@"%lld");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(unsigned long long,@"%llu");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(float,@"%f");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(double,@"%f");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(id,@"%@");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(short,@"%hi");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(unsigned short,@"%hu");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(int,@"%i");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(unsigned, @"%u");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(long,@"%ld");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(long double,@"%Lf"); //WARNING on older versions of OS X, @encode(long double) == @encode(double)
	
	//C-strings
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(char*, @"%s");
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(const char*, @"%s");
	if(TypeCodeIsCharArray(typeCode))
		return [NSString stringWithFormat:@"%s", (char*)value];
	
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(void*,@"(void*)%p");
	
	//This is a hack to print out CLLocationCoordinate2D, without needing to #import <CoreLocation/CoreLocation.h>
	//A CLLocationCoordinate2D is a struct made up of 2 doubles.
	//We detect it by hard-coding the result of @encode(CLLocationCoordinate2D).
	//We get at the fields by treating it like an array of doubles, which it is identical to in memory.
	if(strcmp(typeCode, "{?=dd}")==0)//@encode(CLLocationCoordinate2D)
		return [NSString stringWithFormat:@"{latitude=%g,longitude=%g}",((double*)value)[0],((double*)value)[1]];
	
	//we don't know how to convert this typecode into an NSString
	return nil;
}
