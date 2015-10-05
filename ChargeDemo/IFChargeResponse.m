//
// IFChargeResponse.m
// Inner Fence Credit Card Terminal for iPhone
// API 1.0.0
//
// You may license this source code under the MIT License, reproduced
// below.
//
// Copyright (c) 2015 Inner Fence Holdings, Inc.
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
#import "IFChargeResponse.h"

#import "IFChargeRequest.h"

#ifdef IF_INTERNAL

#import "GTMRegex.h"   // for [NSString -gtm_matchesPattern:]
#import "IFURLUtils.h"

static __inline__ BOOL IFMatchesPattern( NSString* s, NSString* p )
{
    return [s gtm_matchesPattern:p];
}

#else

#import <regex.h>

static BOOL IFMatchesPattern( NSString* nsString, NSString* nsPattern )
{
    const char* string  = [nsString  cStringUsingEncoding:NSUTF8StringEncoding];
    const char* pattern = [nsPattern cStringUsingEncoding:NSUTF8StringEncoding];

    BOOL matches = NO;
    BOOL compiled = NO;
    int re_error;
    regex_t re;

    re_error = regcomp(
        &re,
        pattern,
        REG_EXTENDED
        | REG_NOSUB    // match only, no captures
    );
    if ( re_error )
    {
        NSLog( @"regcomp error %d", re_error );
        goto Cleanup;
    }
    compiled = YES;

    re_error = regexec(
        &re,
        string,
        0, NULL, // no captures
        0        // no flags
    );
    if ( re_error )
    {
        if ( REG_NOMATCH == re_error )
        {
            NSLog( @"string '%s' does not match pattern '%s'", string, pattern );
        }
        else
        {
            NSLog( @"regexec error %d", re_error );
        }
        goto Cleanup;
    }

    // No error, regex matched, input is valid
    matches = YES;

Cleanup:
    if ( compiled )
    {
        regfree( &re );
    }

    return matches;
}

static NSMutableDictionary* IFParseQueryParameters( NSURL* url )
{
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
    NSString*     queryString = [url query];

    if ( [queryString length] )
    {
        NSArray* queryPairs = [queryString componentsSeparatedByString:@"&"];

        for ( NSString* queryPair in queryPairs )
        {
            NSArray* queryComps = [queryPair componentsSeparatedByString:@"="];
            if ( 2 != [queryComps count] )
            {
                // Only interested in field=value pairs
                continue;
            }

// Must support iOS8, so ignore iOS9 deprecation of stringByReplacingPercentEscapesUsingEncoding:
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            NSString* decodedField = [[queryComps objectAtIndex:0]
                stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* decodedValue = [[queryComps objectAtIndex:1]
                stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop

            [dict setObject:decodedValue forKey:decodedField];
        }
    }

    return dict;
}

#endif

#define IF_CHARGE_RESPONSE_FIELD_PATTERNS                     \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"amount",             \
    @"^[A-Z]{3}$",                     @"currency",           \
    @"^X*[0-9]{4}$",                   @"redactedCardNumber", \
    @"^[A-Za-z ]{0,20}$",              @"cardType",           \
    @"^[a-z]*$",                       @"responseType",       \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"taxAmount",          \
    @"^[0-9]{1,2}([.][0-9]{1,3})?$",   @"taxRate",            \
    @"^(0|[1-9][0-9]*)[.][0-9][0-9]$", @"tipAmount",          \
    @"^.{1,255}$",                     @"transactionId",      \
    nil

#define IF_NSINT( n )  ( [NSNumber numberWithInteger:(n)] )

#define IF_CHARGE_RESPONSE_CODE_MAPPING \
    IF_NSINT( kIFChargeResponseCodeApproved ),  @"approved",  \
    IF_NSINT( kIFChargeResponseCodeCancelled ), @"cancelled", \
    IF_NSINT( kIFChargeResponseCodeDeclined ),  @"declined",  \
    IF_NSINT( kIFChargeResponseCodeError ),     @"error",     \
    nil

static NSArray*      _fieldList;
static NSDictionary* _fieldPatterns;
static NSDictionary* _responseCodes;

@interface IFChargeResponse ()

@property (nonatomic,readwrite,copy)   NSString*     amount;
@property (nonatomic,readwrite,copy)   NSString*     cardType;
@property (nonatomic,readwrite,copy)   NSString*     currency;
@property (nonatomic,readwrite,retain) NSDictionary* extraParams;
@property (nonatomic,readwrite,copy)   NSString*     redactedCardNumber;
@property (nonatomic,readwrite,copy)   NSString*     responseType;

- (void) validateFields;

@end

@implementation IFChargeResponse

@synthesize amount             = _amount;
@synthesize cardType           = _cardType;
@synthesize currency           = _currency;
@synthesize extraParams        = _extraParams;
@synthesize redactedCardNumber = _redactedCardNumber;
@synthesize responseCode       = _responseCode;
@synthesize responseType       = _responseType;
@synthesize taxAmount          = _taxAmount;
@synthesize taxRate            = _taxRate;
@synthesize tipAmount          = _tipAmount;
@synthesize transactionId      = _transactionId;

+ (void)initialize
{
    _fieldPatterns = [[NSDictionary alloc]
                         initWithObjectsAndKeys:IF_CHARGE_RESPONSE_FIELD_PATTERNS];
    _fieldList     = [[[_fieldPatterns allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
    _responseCodes = [[NSDictionary alloc]
                         initWithObjectsAndKeys:IF_CHARGE_RESPONSE_CODE_MAPPING];
}

+ (NSArray*)knownFields
{
    return _fieldList;
}

+ (NSDictionary*)responseCodeMapping
{
    return _responseCodes;
}

- initWithURL:(NSURL*)url
{
    if ( ( self = [super init] ) )
    {
        if ( nil == url )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"URL must not be nil"];
        }

        NSMutableDictionary* queryFields = IFParseQueryParameters( url );

        for ( NSString* field in _fieldList )
        {
            NSString* queryName = [IF_CHARGE_RESPONSE_FIELD_PREFIX
                                      stringByAppendingString:field];
            NSString* value = [queryFields valueForKey:queryName];
            if ( [value length] )
            {
                [self setValue:value forKey:field];

                [queryFields removeObjectForKey:field];
            }
        }

        NSString* expectedNonce = [[NSUserDefaults standardUserDefaults]
                                      objectForKey:IF_CHARGE_NONCE_KEY];
        if ( 0 == [expectedNonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: No outstanding charge responses"];
        }

        NSString* nonce = [queryFields objectForKey:IF_CHARGE_NONCE_KEY];
        if ( 0 == [nonce length] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: Nonce missing from response"];
        }

        if ( ![expectedNonce isEqualToString:nonce] )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: Incorrect nonce received"];
        }

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:IF_CHARGE_NONCE_KEY];

        self.extraParams = queryFields;
        [self validateFields];
    }

    return self;
}

- (NSString*)currency
{
    if ( 0 == [_currency length] && 0 != [_amount length] )
    {
        return @"USD";
    }
    else
    {
        return _currency;
    }
}

- (void)validateFields
{
    for ( NSString* field in _fieldList )
    {
        NSString* pattern = [_fieldPatterns objectForKey:field];
        NSAssert1( nil != pattern, @"No regex for field %@", field );

        NSString* value = [self valueForKey:field];

        if ( nil != value && !IFMatchesPattern( value, pattern ) )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: field '%@' is not valid",
                         field];
        }
    }

    NSNumber* responseCode = [_responseCodes valueForKey:_responseType];
    if ( nil == responseCode )
    {
        [NSException raise:NSInvalidArgumentException
                     format:@"Bad URL Request: Unknown response type"];
    }
    _responseCode = [responseCode intValue];

    if ( kIFChargeResponseCodeApproved == _responseCode )
    {
        if ( nil == _amount )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: missing amount"];
        }
        if ( nil == _redactedCardNumber )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: missing redactedCardNumber"];
        }
    }
    else
    {
        if ( nil != _amount || nil != _cardType || nil != _currency || nil != _redactedCardNumber )
        {
            [NSException raise:NSInvalidArgumentException
                         format:@"Bad URL Request: failure should not contain transaction info"];
        }
    }
}

- (void)dealloc
{
    [_baseURL release];
    [_amount release];
    [_cardType release];
    [_currency release];
    [_extraParams release];
    [_redactedCardNumber release];
    [_responseType release];
    [_transactionId release];

    [super dealloc];
}

@end
