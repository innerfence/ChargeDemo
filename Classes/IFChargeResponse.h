// -*- objc -*-
//
// IFChargeResponse.h
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
#define IF_CHARGE_RESPONSE_FIELD_PREFIX @"ifcc_"

typedef enum {
    // Approved - The card was approved and charged.
    kIFChargeResponseCodeApproved,

    // Cancelled - The user pressed the "Done" button in Credit Card
    // Terminal before performing a transaction.
    kIFChargeResponseCodeCancelled,

    // Declined - The card was declined. This is a very specific
    // response indicating that the card is not authorized for the
    // requested charge. Other issues such as expired card, improper
    // AVS, etc, all yield the "Error" code.
    kIFChargeResponseCodeDeclined,

    // Error - The user attempted to process the transaction, but the
    // card was not charged. This could be anything from a network
    // error to an expired card. The specific error was presented to
    // the user in Credit Card Terminal, and they chose to return to
    // your program rather than edit and retry the transaction.
    kIFChargeResponseCodeError
} IFChargeResponseCode;

@interface IFChargeResponse : NSObject
{
@private
    NSString*            _baseURL;
    NSString*            _amount;
    NSString*            _cardType;
    NSString*            _currency;
    NSDictionary*        _extraParams;
    NSString*            _redactedCardNumber;
    IFChargeResponseCode _responseCode;
    NSString*            _responseType;
}

// amount - The amount that was charged to the card. This is a string,
// which is a currency value to two decimal places like @"50.00". This
// property will only be set if responseCode is Accepted.
@property (nonatomic,readonly,copy)   NSString*            amount;

// cardType - The type of card that was charged. This will be
// something like "Visa", "MasterCard", "American Express", or
// "Discover". This property will only be set if responseCode is
// Accepted. In the case that the card type is unknown, this property
// will be nil.
@property (nonatomic,readonly,copy)   NSString*            cardType;

// currency - The ISO 4217 currency code for the transaction
// amount. For example, "USD" for US Dollars. This property will be
// set when amount is set.
@property (nonatomic,readonly,copy)   NSString*            currency;

// extraParams - This dictionary contains any unrecognized query
// parameters that were part of the URL. This should be the same as
// the dictionary you passed to setReturnURL:WithExtraPrams: when
// creating the IFChargeRequest. If there are no extra parameters,
// this property will be an empty dictionary.
//
// WARNING - The URL is an attack vector to your iPhone app, just like
// if it were a web app; you must be wary of SQL injection and similar
// malicious data attacks. As such, you will need to validate any
// parameters from the extraParams fields that you will be using. For
// example, if you expect a numeric value, you should ensure the field
// is comprised of digits.
@property (nonatomic,readonly,retain) NSDictionary*        extraParams;

// redactedCardNumber - This string is the credit card number with all
// but the last four digits replaced by 'X'. This property will only
// be set if responseCode is Accepted.
@property (nonatomic,readonly,copy)   NSString*            redactedCardNumber;

// responseCode - One of the IFChargeResponseCode enum values.
@property (nonatomic,readonly,assign) IFChargeResponseCode responseCode;

// initWithURL - Pass the URL that you receive in
// application:handleOpenURL: and the resulting object will have the
// properties set. Any fields that aren't part of the usual response
// will be exposed in the extraParams dictionary for your convenience.
//
// Throws an exception if the input is not a valid charge response URL.
- initWithURL:(NSURL*)url;

+ (NSArray*)knownFields;
+ (NSDictionary*)responseCodeMapping;

@end
