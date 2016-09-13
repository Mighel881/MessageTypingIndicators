#import <substrate.h>
#import <objc/runtime.h>
#import <Preferences/PSSpecifier.h>

extern NSString *const PSDefaultsKey;
extern NSString *const PSKeyNameKey;
extern NSString *const PSTableCellKey;
extern NSString *const PSDefaultValueKey;
extern NSString *const PSFooterTextGroupKey;
NSString *const tweakKey = @"TypingIndicators";
NSString *const tweakPrefPath = @"/var/mobile/Library/Preferences/com.apple.imessage.plist";

%group iMessage

%hook CKConversation 

- (BOOL)_chatSupportsTypingIndicators
{
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:tweakPrefPath] ?: [NSDictionary dictionary];
	return [prefDict[tweakKey] boolValue];
}

%end

%end

%group Prefs

static char tweakSpecifierKey;

@interface PSViewController : UIViewController
@end

@interface PSListController : PSViewController
@end

@interface CNFRegListController : PSListController
@end

@interface CKSettingsMessagesController : CNFRegListController
@property (retain, nonatomic, getter=_specifier, setter=_set_specifier:) PSSpecifier *tweakSpecifier;
@end

%hook CKSettingsMessagesController

%new(v@:@)
- (void)_set_specifier:(id)object
{
    objc_setAssociatedObject(self, &tweakSpecifierKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new(@@:)
- (id)_specifier
{
    return objc_getAssociatedObject(self, &tweakSpecifierKey);
}

%new
- (id)getValue:(PSSpecifier *)specifier
{
	NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:tweakPrefPath] ?: [NSDictionary dictionary];
	id value = prefDict[tweakKey];
	return value != nil ? value : @NO;
}

%new
- (void)setValue:(id)value specifier:(PSSpecifier *)specifier
{
	NSMutableDictionary *prefDict = [[NSDictionary dictionaryWithContentsOfFile:tweakPrefPath] mutableCopy] ?: [NSMutableDictionary dictionary];
	[prefDict setObject:value forKey:tweakKey];
	[prefDict writeToFile:tweakPrefPath atomically:YES];
}

- (NSMutableArray *)specifiers
{
	NSMutableArray *specifiers = %orig();
	PSSpecifier *tweakSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Typing Indicator" target:self set:@selector(setValue:specifier:) get:@selector(getValue:) detail:nil cell:[PSTableCell cellTypeFromString:@"PSSwitchCell"] edit:nil];
	[tweakSpecifier setProperty:@"com.apple.Preferences" forKey:PSDefaultsKey];
	[tweakSpecifier setProperty:tweakKey forKey:PSKeyNameKey];
	[tweakSpecifier setProperty:@NO forKey:PSDefaultValueKey];
	[specifiers insertObject:tweakSpecifier atIndex:2];
	PSSpecifier *footerSpecifier = [PSSpecifier emptyGroupSpecifier];
	[footerSpecifier setProperty:@"Allow others to be notified you are typing in iMessages." forKey:PSFooterTextGroupKey];
	[specifiers insertObject:footerSpecifier atIndex:2];
	self.tweakSpecifier = tweakSpecifier;
	return specifiers;
}

%end

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL isPrefApp = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"];
	if (isPrefApp) {
		dlopen("/System/Library/PreferenceBundles/SMSPreferences.bundle/SMSPreferences", RTLD_LAZY);
		%init(Prefs);
	} else {
		%init(iMessage);
	}
	[pool drain];
}