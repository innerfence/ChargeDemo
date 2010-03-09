//
// ChargeDemoViewController.m
// Sample Code
//
// An example view controller for a simple sort of application which
// might make use of IFChargeRequest and IFChargeResponse for
// processing credit card charges using Inner Fence's Credit Card
// Terminal for iPhone.
//
// You may license this source code under the MIT License. See COPYING.
//
// Copyright (c) 2009 Inner Fence, LLC
//
#import "ChargeDemoViewController.h"

// The IFChargeRequest class is provided by Inner Fence, LLC under the
// MIT License. We recommend that you include the file directly in
// your iPhone project for calling into Credit Card Terminal.
#import "IFChargeRequest.h"

@implementation ChargeDemoViewController

// Here we set up an IFChargeRequest object and submit it in order
// to invoke Credit Card Terminal.
- (IBAction)chargeTapped:(id)sender
{
    // Create the IFChargeRequest using the default initializer.
    //
    // If we wanted to, we could provide a delegate using the
    // initWithDelegate initializer instead. In that case, the object
    // provided should handle the creditCardTerminalNotInstalled
    // selector. When no delegate is provided, a simple UI alert is
    // displayed in the case that the charge request cannot be
    // invoked.
    IFChargeRequest* chargeRequest = [[[IFChargeRequest alloc] init] autorelease];

    // 2-way Integration
    //
    // By supplying the returnURL parameter, we give Credit Card
    // Terminal a way to invoke us when the transaction is
    // complete. If you don't give a returnURL, Credit Card Terminal
    // will still launch and pre-fill the form values supplied, but
    // there will be no way for the user to return to the your
    // application.
    //
    // The simplest way to do this is just to set the property:
    // chargeRequest.returnURL = @"com-innerfence-ChargeDemo://chargeResponse";
    //
    // But since it's so common to include app-specific parameters in
    // the return URL, you can use the setReturnURL:withExtraParams:
    // method to provide a dictionary of app-specific parameters which
    // are automatically encoded into the query string of the
    // returnURL. Those parameters will be available in the
    // extraParams dictionary of the IFChargeResponse when the request
    // is completed.
    //
    // In this sample, we include an app-specific "record_id"
    // parameter set to the value 123. You may call extra parameters
    // anything you like, but to avoid collision with charge-related
    // parameters, the names may not beginw with "ifcc_".
    [chargeRequest setReturnURL:@"com-innerfence-ChargeDemo://chargeResponse"
                   withExtraParams:[NSDictionary dictionaryWithObjectsAndKeys:
                       @"123", @"record_id",
                       nil]];

    // Finally, we can supply customer and transaction data so that it
    // will be pre-filled for submission with the charge.
    chargeRequest.address        = @"123 Test St";
    chargeRequest.amount         = @"50.00";
    chargeRequest.currency       = @"USD";
    chargeRequest.city           = @"Nowhereville";
    chargeRequest.company        = @"Company Inc";
    chargeRequest.country        = @"US";
    chargeRequest.description    = @"Test transaction";
    chargeRequest.email          = @"john@example.com";
    chargeRequest.firstName      = @"John";
    chargeRequest.invoiceNumber  = @"321";
    chargeRequest.lastName       = @"Doe";
    chargeRequest.phone          = @"555-1212";
    chargeRequest.state          = @"HI";
    chargeRequest.zip            = @"98021";

    // The IFChargeRequest object will retain itself and any specified
    // delegate for the duration of the request/timeout period, so
    // there's no need to maintain a reference of our own.
    [chargeRequest submit];
}

@end
