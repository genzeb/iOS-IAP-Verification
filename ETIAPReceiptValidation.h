//
//  ETIAPReceiptValidation.h
//
//  Created by Ephraim Tekle on 5/14/14.
//  Copyright (c) 2013 Ephraim Tekle. All rights reserved.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2013 Ephraim Tekle
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

@protocol ETIAPReceipt <NSObject>
- (NSInteger)status; // returns -1 if missing
- (NSDictionary *)receipt;
- (NSDate *)expirationDate;
- (NSDate *)originalPurchaseDate;
- (NSDate *)purchaseDate;
- (NSString *)originalTransactionId;
- (NSString *)productId;
- (NSString *)transactionId;
- (NSDictionary *)latestReceipt;
- (NSDictionary *)latestExpiredReceiptInfo;
- (NSDictionary *)latestReceiptInfo;
@end

static const NSInteger kETIAPReceiptSuccess = 0;
// Success -- receipt is valid (for app purchases and for non-renwables, this does not neccessarily mean the purchase hasn't expired -- it just means the receipt is a valid receipt)
static const NSInteger kETIAPReceiptInvalidRequest = 21000;
//The App Store could not read the JSON object you provided.
static const NSInteger kETIAPReceiptInvalidReceiptData = 21002;
//The data in the receipt-data property was malformed or missing.
static const NSInteger kETIAPReceiptAuthError = 21003;
//The receipt could not be authenticated.
static const NSInteger kETIAPReceiptAccountError = 21004;
//The shared secret you provided does not match the shared secret on file for your account. Note: only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.
static const NSInteger kETIAPReceiptServiceUnavailable = 21005;
//The receipt server is not currently available.
static const NSInteger kETIAPReceiptSubscriptionExpired = 21006;
//This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Note: only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.

typedef enum {
    ETIAPReceiptValiationRequestErrorCodeNoDataError = 0,
    ETIAPReceiptValiationRequestErrorCodeInvalidDataError,
    ETIAPReceiptValiationRequestErrorCodeConnectionError,
    ETIAPReceiptValiationRequestErrorCodeAppleError,
    ETIAPReceiptValiationRequestErrorCodeUnknownError
} ETIAPReceiptValiationRequestErrorCode;


typedef void (^ETIAPReceiptValidationCompletionBlock)(id<ETIAPReceipt> receipt, NSData *receiptData, NSString *productIdentifier, NSError *error);

@interface ETIAPReceiptValidation : NSObject

+ (void) startIAPReceiptValidationWithtData:(NSData *)receiptData
                          productIdentifier:(NSString *)productIdentifier
                          iTunesIAPPassword:(NSString *)password
                                 completion:(ETIAPReceiptValidationCompletionBlock)completion;
@end
