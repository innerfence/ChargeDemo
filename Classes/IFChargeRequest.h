// -*- objc -*-
//
// IFChargeRequest.h
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
@interface IFChargeRequest : NSObject
{
@protected
    NSObject* _delegate;

    NSString* _returnAppName;
    NSString* _returnURL;

    NSString* _address;
    NSString* _amount;
    NSString* _city;
    NSString* _company;
    NSString* _country;
    NSString* _currency;
    NSString* _description;
    NSString* _email;
    NSString* _firstName;
    NSString* _invoiceNumber;
    NSString* _lastName;
    NSString* _phone;
    NSString* _state;
    NSString* _zip;
}

// delegate - Will receive the
// creditCardTerminalNotInstalled calback if the invocation fails.
@property (assign) NSObject* delegate;

//
// Return Parameters - these properties are used to request that
// Credit Card Terminal return to the calling app when the trasaction
// is complete. The returnURL must be specified in order for the user
// to have the option of returning.
//

// returnAppName - Credit card terminal will inform the user that the
// charge request comes from the app named by this parameter. By
// default, the CFBundleDisplayName is used.
@property (copy) NSString* returnAppName;

// returnURL - Credit card terminal will invoke this URL
// when the transaction is complete. Should be a URL that is
// registered to be handled by this app.
@property (copy) NSString* returnURL;

// setReturnURL - this setter is a helper that will take the extra
// parameters passed in the dictionary and encode and include them in
// the returnURL. The parameters from this dictionary will be
// available as the extraParams property on IFChargeResponse when you
// handle the callback URL.
//
// NOTE - The extraParams dictionary must contain only NSString* keys
// and values.
- (void)setReturnURL:(NSString*)url withExtraParams:(NSDictionary*)extraParams;

//
// Charge Parameters - these properties are used to pre-populate the
// form fields of Credit Card Terminal
//

// address - The customer's billing address.
// Up to 60 characters (no symbols).
@property (copy) NSString* address;

// amount - The amount of the transaction.
// Up to 15 digits with a decimal point.
@property (copy) NSString* amount;

// city - The city of the customer's billing address.
// Up to 40 characters (no symbols).
@property (copy) NSString* city;

// company - The company associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* company;

// country - The country code of the customer's billing address. (E.g. US for USA)
// Up to 60 characters (no symbols).
@property (copy) NSString* country;

// currency - The currency code of the amount. (E.g. USD for US Dollars)
// 3 characters.
@property (copy) NSString* currency;

// description - The transaction description.
// Up to 255 characters (no symbols).
@property (copy) NSString* description;

// email - The customer's email address.
// Up to 255 characters.
@property (copy) NSString* email;

// firstName - The first name associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* firstName;

// invoiceNumber - The merchant-assigned invoice number.
// Up to 20 characters (no symbols).
@property (copy) NSString* invoiceNumber;

// lastName - The last name associated with the customer's billing address.
// Up to 50 characters (no symbols).
@property (copy) NSString* lastName;

// phone - The phone number associated with the customer's billing address.
// Up to 25 digits (no letters).
@property (copy) NSString* phone;

// state - The state of the customer's billing address.
// Up to 40 characters (no symbols) or a valid 2-char state code.
@property (copy) NSString* state;

// zip - The ZIP code of the customer's billing address.
// Up to 20 characters (no symbols).
@property (copy) NSString* zip;

+ (NSArray*)knownFields;

// init - designated initializer
- init;

// initWithDelegate: - Specifies the optional delegate when creating
// the object.
- initWithDelegate:(NSObject*)delegate;

// requestURL - Retrieves the URL for the request. If you have special
// requirements around invoking the URL, you can use this instead of
// submit.
- (NSURL*)requestURL;

#if TARGET_OS_IPHONE

// submit - Invokes the URL for this request. If Credit Card Terminal
// is installed, your app will terminate and Credit Card Terminal will
// run. If not, either creditCardTerminalNotInstalled will be sent to
// the delegate or a default UIAlert will be displayed.
- (void)submit;

#endif

@end

@interface NSObject (IFChargeRequestDelegate)

// Implement this on your delegate object in order to perform a custom
// action instead of displaying the default UIAlert if Credit Card
// Terminal cannot be launched.
- (void)creditCardTerminalNotInstalled;

@end

#define IF_CHARGE_API_VERSION  @"1.0.0"
#define IF_CHARGE_API_BASE_URI @"com-innerfence-ccterminal://charge/" IF_CHARGE_API_VERSION @"/"

#define IF_CHARGE_NONCE_KEY @"ifcc_request_nonce"

// These macros define the default message used for the UIAlert when
// Credit Card Terminal is not installed. Override these strings in
// your string table for other languages.
#define IF_CHARGE_NOT_INSTALLED_BUTTON  ( NSLocalizedString( @"OK", nil ) )
#define IF_CHARGE_NOT_INSTALLED_MESSAGE ( NSLocalizedString( \
    @"Install Credit Card Terminal to enable this functionality.", nil \
) )
#define IF_CHARGE_NOT_INSTALLED_TITLE   ( NSLocalizedString( @"Unable to Charge", nil ) )
