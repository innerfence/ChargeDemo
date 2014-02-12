OVERVIEW
========

The ChargeDemo source code demonstrates how to implement 2-way
integration for accepting credit card payments using Credit Card
Terminal for iPhone.

ChargeDemo supplies a single charge button. When it's tapped, a URL
request is made to Credit Card Terminal in order to accept a credit
card payment. When the user is done with Credit Card Terminal,
ChargeDemo will be launched via its URL handler for
`com-innerfence-ChargeDemo://`.

Protocol details are provided below in the case that you cannot or do
not wish to use our Objective-C classes.

Please visit our [Developer API
page](http://www.innerfence.com/apps/credit-card-terminal/developer-api)
to see how the user experience flow will be like.

INTEGRATION CHECKLIST
=====================

* Add the IFChargeRequest.h, IFChargeRequest.m, IFChargeResponse.h,
  and IFChargeResponse.m files to your Xcode project.

* Make sure your application is registered to handle a URL scheme in
  your Info.plist. For example:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.innerfence.ChargeDemo</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com-innerfence-ChargeDemo</string>
    </array>
  </dict>
</array>
```

* Request payment by creating an IFChargeRequest object, setting its
  properties, and calling its submit method. Be sure to set the
  returnURL property. Consider using setReturnURL:withExtraParams: to
  automatically include extra parameters in the query string. For
  example:

```objc
IFChargeRequest* chargeRequest =
    [[[IFChargeRequest alloc] init] autorelease];

// Include my record_id so it comes back with the response
[chargeRequest
    setReturnURL:@"com-innerfence-ChargeDemo://chargeResponse"
    withExtraParams:[NSDictionary dictionaryWithObjectsAndKeys:
        @"123", @"record_id",
        nil
    ]
];

chargeRequest.amount        = @"50.00";
chargeRequest.description   = @"Test transaction";
chargeRequest.invoiceNumber = @"321";

// Include a tax rate if you want Credit Card terminal to calculate
// sales tax. If you pass in @"default", we'll use the default sales
// tax preset by the user. If you leave it as nil, we’ll hide the
// sales tax option from the user.
chargeRequest.taxRate = @"8.5";

[chargeRequest submit];
```

* Handle charge responses in your app delegate’s
  application:handleOpenURL: by creating an IFChargeResponse object
  using initWithURL:. Use the responseCode property to determine if
  the transaction was successful. For example:

```objc
- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    IFChargeResponse* chargeResponse =
        [[[IFChargeResponse alloc] initWithURL:url] autorelease];

    // My record_id from the request is available in the extraParams
    // dictionary.
    NSString* recordId = [chargeResponse.extraParams objectForKey:@"record_id"];

    // Since this value is from the URL, I need to validate it.
    if ( !IsValidRecordId( recordId ) )
    {
        // handle error
    }

    if ( chargeResponse.responseCode == kIFChargeResponseCodeApproved )
    {
        // Transaction succeeded, check out these properties:
        //  * chargeResponse.transactionId
        //  * chargeResponse.amount (includes tax and tip)
        //  * chargeResponse.taxAmount
        //  * chargeResponse.taxRate
        //  * chargeResponse.tipAmount
        //  * chargeResponse.cardType
        //  * chargeResponse.redactedCardNumber
    }
    else
    {
        // Transaction failed.
    }
}
```

PROTOCOL REQUEST
================

The Charge request is simply a set of query string parameters which
are appended to a Base URL. Be sure to properly encode the query
string parameters.

Base URL: `com-innerfence-ccterminal://charge/1.0.0/`

* `returnAppName` - your app's name, displayed to give the user context
* `returnURL` - your app's URL handler, see PROTOCOL RESPONSE
* `returnImmediately` - if set to 1,  the `returnURL` will be called with the result immediately instead of waiting for the end user to tap through the “Approved” screen
* `fm` - if set to 1, the FileMaker-compatible response format will be used
* `amount` - amount of the transaction (e.g. `10.99`, `1.00`, `0.90`)
* `amountFixed` - if set to 1, the amount (subtotal) will be unchangable. If tips or sales tax is enabled, the final amount can still differ
* `taxRate` - sales tax rate to apply to amount (e.g. `8`, `8.5`, `8.25`, `8.125`)
* `currency` - currecy code of amount (e.g. `USD`)
* `email` - customer's email address for receipt
* `firstName` - billing first name
* `lastName` - billing lastName
* `company` - billing company name
* `address` - billing street address
* `city` - billing city
* `state` - billing state or province (e.g. `TX`, `ON`)
* `zip` - billing zip or postal code
* `phone` - billing phone number
* `country` - billing country code (e.g. `US`)
* `invoiceNumber` - merchant-assigned invoice number
* `description` - description of goods or services

Here is a simple example. Please note the correct encoding of parameters:

```
com-innerfence-ccterminal://charge/1.0.0/?amount=10.99&email=john%40example.com&returnURL=com-your-app%3A%2F%2Faction%2F
```

PROTOCOL RESPONSE
=================

When the request includes a `returnURL`, the results of the charge
will be returned via the URL by including additional query string
parameters. These parameters all begin with ifcc_ to avoid conflict
with any query parameters your app may already recognize.

* `ifcc_responseType` - `approved`, `cancelled`, `declined`, or `error`
* `ifcc_transactionId` - transaction id (e.g. `100001`)
* `ifcc_amount` - amount charged (e.g. `10.99`)
* `ifcc_currency` - currency of amount (e.g. `USD`)
* `ifcc_taxAmount` - tax portion from amount (e.g. `0.93`)
* `ifcc_taxRate` - tax rate applied to original amount (e.g. `8.5`)
* `ifcc_tipAmount` - tip portion from amount (e.g. `1.50`)
* `ifcc_redactedCardNumber` - redacted card number (e.g. `XXXXXXXXXXXX1111`)
* `ifcc_cardType` - card type: `Visa`, `MasterCard`, `Amex`, `Discover`, `Maestro`, `Solo`, or `Unknown`

Here is a simple example:

```
com-your-app://action/?ifcc_responseType=approved&ifcc_transactionId=100001&ifcc_amount=10.99&ifcc_currency=USD&ifcc_redactedCardNumber=XXXXXXXXXXXX1111&ifcc_cardType=Visa&ifcc_taxAmount=0.93&ifcc_taxRate=8.5&ifcc_tipAmount=1.50
```

When the `fm=1` parameter is included in the original request, the
response is modified by including a dollar-sign ($) before each query
value so that they can be accessed by FileMaker Go scripts. For instance,
instead of `ifcc_responseType=success`, `$ifcc_responseType=success`.

FILE MANIFEST
=============

* README.markdown

This file.

* COPYING

A copy of the MIT License, under which you may reuse any of the source
code in this sample.

* Classes/IFChargeRequest.h
* Classes/IFChargeRequest.m
* Classes/IFChargeResponse.h
* Classes/IFChargeResponse.m

The IFChargeRequest and IFChargeResponse classes. Copy these files
into your own XCode project. There are no external dependencies other
than libc, Foundation, and UIKit.

* ChargeDemoViewController.xib
* Classes/ChargeDemoViewController.h
* Classes/ChargeDemoViewController.m

A very simple view controller that provides a single Charge
button. When the button is tapped, an IFChargeRequest object is
created and submitted.

* Info.plist

Registers the com-innerfence-ChargeDemo:// URL scheme.

* Classes/ChargeDemoAppDelegate+HandleURL.m

Handles the URL request, using IFChargeResponse to process the result
of the charge request.

* ChargeDemo_Prefix.pch
* Classes/ChargeDemoAppDelegate.h
* Classes/ChargeDemoAppDelegate.m
* main.m
* MainWindow.xib

These files are all stock as generated by XCode.

* ChargeDemo.xcodeproj/

An XCode project for building this sample.
