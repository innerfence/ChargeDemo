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
// Copyright (c) 2015 Inner Fence Holdings, Inc.
//
#import "AppDelegate.h"

// The IFChargeResponse class is provided by Inner Fence under the
// MIT License. We recommend that you include the file directly in
// your iPhone project for calling into Credit Card Terminal.
#import "IFChargeResponse.h"

// kRecordIdPattern -- the regular expression for validating the
// recordId extra param that ChargeDemo passes with its charge request
// and expects to receive back with the response.
static NSString* const kRecordIdPattern = @"^[0-9]+$";

// IsValidRecordId -- matches kRecordIdPattern against nsRecordId
BOOL IsValidRecordId( NSString* nsRecordId )
{
    return NSNotFound != [nsRecordId rangeOfString:kRecordIdPattern options:NSRegularExpressionSearch].location;
}

void ReportError( NSString* message )
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [[[UIAlertView alloc]
          initWithTitle:@"Error"
          message:message
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil
    ] show];
#pragma clang diagnostic pop
}

@implementation AppDelegate (HandleURL)

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

    return YES;
}

@end
