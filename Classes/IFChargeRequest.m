//
// IFChargeRequest.m
// Inner Fence Credit Card Terminal for iPhone
// API 1.0.0
//
// You may license this source code under the MIT License, reproduced
// below.
//
// Copyright (c) 2009 Inner Fence, LLC
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
#import "IFChargeRequest.h"

#include <stdlib.h>

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#ifdef IF_INTERNAL

#import "IFURLUtils.h"

#else

// CFURLCreateStringByAddingPercentEscapes by default leaves legal
// URL characters alone, which is not what we want. So we'll specify
// that all the reserved chars *should* be encoded. This is the same
// as the 'reserved' BNF production from RFC 3986.
#define URI_RESERVED_CHARS @":/?#[]@!$&'()*+,;="

static NSString* IFEncodeURIComponent( NSString* s )
{
    CFStringRef encodedValue =
        CFURLCreateStringByAddingPercentEscapes(
            kCFAllocatorDefault,
            (CFStringRef)s,
            NULL,
            (CFStringRef)URI_RESERVED_CHARS,
            kCFStringEncodingUTF8
        );

    return [NSMakeCollectable( encodedValue ) autorelease];
}

#endif

#define IF_CHARGE_REQUEST_FIELD_LIST \
    @"returnAppName", \
    @"returnURL", \
    @"address", \
    @"amount", \
    @"city", \
    @"company", \
    @"country", \
    @"currency", \
    @"description", \
    @"email", \
    @"firstName", \
    @"invoiceNumber", \
    @"lastName", \
    @"phone", \
    @"state", \
    @"zip", \
    nil


static NSArray* _fieldList;

// Base64 isn't provided in Cocoa Touch, and I don't want to depend on
// an external Base64 library, so instead of base64 encoding a random
// value, I'll instead choose (web safe) base64-characters at random.
static const NSUInteger kNonceLength = 27; // same size as base64-encoded SHA1 seems good
static const long kNonceAlphabetMask = 0x3f;
static char _nonceAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

@interface IFChargeRequest ()

- (NSString*)createAndStoreNonce;

@end

@implementation IFChargeRequest

@synthesize delegate       = _delegate;
@synthesize returnAppName  = _returnAppName;
@synthesize returnURL      = _returnURL;
@synthesize address        = _address;
@synthesize amount         = _amount;
@synthesize city           = _city;
@synthesize company        = _company;
@synthesize country        = _country;
@synthesize currency       = _currency;
@synthesize description    = _description;
@synthesize email          = _email;
@synthesize firstName      = _firstName;
@synthesize invoiceNumber  = _invoiceNumber;
@synthesize lastName       = _lastName;
@synthesize phone          = _phone;
@synthesize state          = _state;
@synthesize zip            = _zip;

+ (void)initialize
{
    _fieldList = [[NSArray alloc] initWithObjects:IF_CHARGE_REQUEST_FIELD_LIST];
}

+ (NSArray*)knownFields
{
    return _fieldList;
}

// Designated constructor
- init
{
    if ( ( self = [super init] ) )
    {
        self.returnAppName = [[NSBundle mainBundle]
            objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    }
    return self;
}

- initWithDelegate:(NSObject*)delegate
{
    if ( ( self = [self init] ) )
    {
        self.delegate = delegate;
    }
    return self;
}

- (NSString*)createAndStoreNonce
{
    NSMutableString* nonceString = [[[NSMutableString alloc] initWithCapacity:kNonceLength] autorelease];
    for ( NSUInteger i = 0; i < kNonceLength; i++ )
    {
        [nonceString appendFormat:@"%c", _nonceAlphabet[ ( arc4random() & kNonceAlphabetMask ) ]];
    }

    [[NSUserDefaults standardUserDefaults] setObject:nonceString forKey:IF_CHARGE_NONCE_KEY];

    return nonceString;
}

// If there's a delegate, invoke -creditCardTerminalNotInstalled on it;
// otherwise, display a default dialog.
- (void)creditCardTerminalNotInstalled
{
    [self autorelease];
    [_delegate autorelease];

    if ( _delegate )
    {
        [_delegate creditCardTerminalNotInstalled];
    }
#if TARGET_OS_IPHONE
    else
    {
        [[[[UIAlertView alloc]
            initWithTitle:IF_CHARGE_NOT_INSTALLED_TITLE
            message:IF_CHARGE_NOT_INSTALLED_MESSAGE
            delegate:nil
            cancelButtonTitle:IF_CHARGE_NOT_INSTALLED_BUTTON
            otherButtonTitles:nil
        ] autorelease] show];
    }
#endif
}

// Create the appropriate request URL based on the current property
// values.
- (NSURL*)requestURL
{
    NSMutableString* urlString = [[NSMutableString alloc] initWithString:IF_CHARGE_API_BASE_URI];
    BOOL first = YES;

    // First build up the query params
    for ( NSString* field in _fieldList )
    {
        NSString* value = [self valueForKey:field];
        if ( [value length] )
        {
            [urlString appendFormat:@"%@%@=%@",
                       first ? @"?" : @"&",
                       field,
                       IFEncodeURIComponent( value )];
            first = NO;
        }
    }

    // Convert to NSURL
    NSURL* url = [NSURL URLWithString:urlString];
    [urlString release];
    return url;
}

- (void)setReturnURL:(NSString*)url withExtraParams:(NSDictionary*)extraParams
{
    BOOL hasQuery = 0 != [[[NSURL URLWithString:url] query] length];

    NSMutableString* urlString = [[NSMutableString alloc] initWithString:url];
    BOOL first = YES;

    // TODO - actually, to prevent tampering, etc, we should probably
    // just shove this dictionary into NSUserDefaults instead of
    // including it on the URL.

    for ( NSObject* keyObject in [extraParams allKeys] )
    {
        NSObject* valueObject = [extraParams objectForKey:keyObject];

        if ( ![keyObject isKindOfClass:[NSString class]] ||
             ![valueObject isKindOfClass:[NSString class]] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"extraParams dictionary keys and values must all be strings"];
        }

        NSString* field = (NSString*)keyObject;
        NSString* value = (NSString*)valueObject;
        if ( [value length] )
        {
            [urlString appendFormat:@"%@%@=%@",
                       ( first && !hasQuery ) ? @"?" : @"&",
                       field,
                       IFEncodeURIComponent( value )];
            first = NO;
        }
    }

    self.returnURL = urlString;
    [urlString release];
}

#if TARGET_OS_IPHONE

// Submit the charge request. The current application will terminate
// and Credit Card Terminal will launch with the specified fields
// pre-filled.
- (void)submit
{
    // Create a nonce
    if ( [_returnURL length] )
    {
        self.returnURL = [_returnURL stringByAppendingFormat:@"%@%@=%@",
            [[[NSURL URLWithString:_returnURL] query] length] ? @"&" : @"?",
            IF_CHARGE_NONCE_KEY,
            IFEncodeURIComponent( [self createAndStoreNonce] )
        ];
    }

    // Submit the URL
    NSURL* url = [self requestURL];

    UIApplication* app = [UIApplication sharedApplication];

    // On newer OSes, we can query and know for sure if Credit Card
    // Terminal is installed.
    BOOL assuredSuccess = NO;
    if ( [app respondsToSelector:@selector(canOpenURL:)] )
    {
        assuredSuccess = [app canOpenURL:url];
        if ( !assuredSuccess )
        {
            // Assured failure -- early out.
            [self creditCardTerminalNotInstalled];
            return;
        }
    }

    [[UIApplication sharedApplication] openURL:url];

    if ( !assuredSuccess )
    {
        // On older OSes, if the openURL succeeds, this app will
        // terminate. We register here to receive a callback in 1
        // second, which will only happen if we don't terminate,
        // meaning the openURL failed.
        [self retain];
        [_delegate retain];
        [self performSelector:@selector(creditCardTerminalNotInstalled)
              withObject:nil
              afterDelay:1];
    }
}

#endif

- (void)dealloc
{
    _delegate = nil;

    [_returnAppName release];
    [_returnURL release];

    [_address release];
    [_amount release];
    [_city release];
    [_company release];
    [_country release];
    [_currency release];
    [_description release];
    [_email release];
    [_firstName release];
    [_invoiceNumber release];
    [_lastName release];
    [_phone release];
    [_state release];
    [_zip release];

    [super dealloc];
}

@end
