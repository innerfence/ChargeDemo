//
// ChargeDemoAppDelegate+HandleURL.m
// Sample Code
//
// Demonstrates how to handle a URL from the application delegate and
// use IFChargeResponse to determine the outcome of the Credit Card
// Terminal charge request.
//
// You may license this source code under the MIT License. See COPYING.
//
// Copyright (c) 2009 Inner Fence, LLC
//
#import "ChargeDemoAppDelegate.h"

// The IFChargeResponse class is provided by Inner Fence, LLC under the
// MIT License. We recommend that you include the file directly in
// your iPhone project for calling into Credit Card Terminal.
#import "IFChargeResponse.h"

// This example uses <regex.h> to validate input. For a convenient
// Objective-C wrapper to <regex.h>, see GTMRegex from
// http://code.google.com/p/google-toolbox-for-mac/
#import <regex.h>

// kRecordIdPattern -- the regular expression for validating the
// recordId extra param that ChargeDemo passes with its charge request
// and expects to receive back with the response.
//
// See `man re_format` for documentation about regular expressions.
//
// Or, I find `man perlre` to be a better introduction, but beware the
// <regex.h> extended regex format doesn't have quite as many bells
// and whistles as perl REs.
static const char* kRecordIdPattern = "^[0-9]+$";

// IsValidRecordId -- matches kRecordIdPattern against nsRecordId
BOOL IsValidRecordId( NSString* nsRecordId )
{
    const char* recordId = [nsRecordId cStringUsingEncoding:NSUTF8StringEncoding];
    BOOL matches = NO;
    BOOL compiled = NO;
    int re_error;
    regex_t re;

    re_error = regcomp(
        &re,
        kRecordIdPattern,
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
        recordId,
        0, NULL, // no captures
        0        // no flags
    );
    if ( re_error )
    {
        if ( REG_NOMATCH == re_error )
        {
            NSLog( @"recordId does not match pattern %s", kRecordIdPattern );
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

void ReportError( NSString* message )
{
    [[[[UIAlertView alloc]
          initWithTitle:@"Error"
          message:message
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil
    ] autorelease] show];
}

@implementation ChargeDemoAppDelegate (HandleURL)

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    //
    // Often, you'll want to react to the incoming URL request in a
    // view controller. There are a couple of ways to do that.
    //
    // (1) Use proper MVC architecture
    //
    // This method would simply call into your model, which would
    // perform all the processing. Interested view controllers would
    // use KVO or other eventing mechanisms to express interest in the
    // URL event.
    //
    // (2) Just use a global event
    //
    // Raise the event here, and include the URL in the userInfo:
    //
    //    [[NSNotificationCenter defaultCenter]
    //        postNotificationName:@"ChargeDemoURLNotification"
    //        object:[UIApplication sharedApplication]
    //        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", nil]
    //    ];
    //
    // In the interested view controller, register for the event:
    //
    // - (void)viewDidLoad
    // {
    //    [[NSNotificationCenter defaultCenter]
    //        addObserver:self
    //        selector:@selector(handleChargeResponse:)
    //        name:@"ChargeDemoURLNotification"
    //        object:[UIApplication sharedApplication]];
    // }
    //
    // And put the code like what's below inside handleChargeResponse:
    //

    // This sample always uses com-innerfence-ChargeDemo://chargeResponse
    // as the base return URL.
    if ( ![[url host] isEqualToString:@"chargeResponse"] )
    {
        // In your app, this might mean that you should handle this as
        // a normal URL request instead of a charge response.
        ReportError( @"Unknown URL, abandoning the request!" );
        return NO;
    }

    // initWithURL will throw an exception if there's a problem with
    // the response URL parameters.
    IFChargeResponse* chargeResponse = nil;
    @try
    {
        chargeResponse = [[IFChargeResponse alloc] initWithURL:url];
    }
    @catch ( NSException* e )
    {
        ReportError( @"URL not valid charge response, abandoning the request!" );
        return NO;
    }
    @finally
    {
        [chargeResponse autorelease];
    }

    // Any extra params we included with the return URL can be
    // queried from the extraParams dictionary.
    NSString* recordId = [chargeResponse.extraParams objectForKey:@"record_id"];

    // The URL is a public attack vector for the app, so it's
    // important to validate any parameters.
    if ( !IsValidRecordId( recordId ) )
    {
        ReportError( @"Bad record id, abandoning the request!" );
        return NO;
    }

    NSString* title;
    NSString* message;

    // You may want to perform different actions based on the response
    // code. This example shows an alert with the response data when
    // the charge is approved.
    if ( chargeResponse.responseCode == kIFChargeResponseCodeApproved )
    {
        title = @"Charged!";
        message = [NSString stringWithFormat:@"Record: %@\n"
                                             @"Transaction ID: %@\n"
                                             @"Amount: %@ %@\n"
                                             @"Card Type: %@\n"
                                             @"Redacted Number: %@",
           recordId,
           chargeResponse.transactionId,
           chargeResponse.amount,
           chargeResponse.currency,
           chargeResponse.cardType,
           chargeResponse.redactedCardNumber
        ];
    }
    else // other response code values are documented in IFChargeResponse.h
    {
        title = @"Not Charged!";
        message = [NSString stringWithFormat:@"Record: %@", recordId];
    }

    // Generally you would do something app-specific here, like load
    // the record specified by recordId, record the success or
    // failure, etc. Since this sample doesn't actually do much, we'll
    // just pop an alert.
    UIAlertView* alert = [UIAlertView alloc];
    [[alert initWithTitle:title
            message:message
            delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil
    ] show];
    [alert release];

    return YES;
}

@end
