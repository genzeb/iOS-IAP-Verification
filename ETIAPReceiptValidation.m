//
//  ETIAPReceiptValidation.m
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

#import "ETIAPReceiptValidation.h"
#import "NSData+PMBase64.h"

@interface NSDictionary (ETIAPReceipt) <ETIAPReceipt>
@end

@implementation NSDictionary (ETIAPReceipt)
- (NSInteger)status
{
    return self[@"status"] ? [self[@"status"] integerValue] : -1; // prevent 0, i.e. success, from returning if missing
}

- (NSDictionary *)receipt
{
    return self[@"receipt"];
}

- (NSDate *)expirationDate
{
    return [NSDate dateWithTimeIntervalSince1970:[self[@"expires_date"] doubleValue]/1000.0];
}

- (NSDate *)originalPurchaseDate
{
    return [NSDate dateWithTimeIntervalSince1970:[self[@"original_purchase_date_ms"] doubleValue]/1000.0];
}

- (NSDate *)purchaseDate
{
    return [NSDate dateWithTimeIntervalSince1970:[self[@"purchase_date_ms"] doubleValue]/1000.0];
}

- (NSString *)originalTransactionId
{
    return self[@"original_transaction_id"];
}

- (NSString *)productId
{
    return self[@"product_id"];
}

- (NSString *)transactionId
{
    return self[@"transaction_id"];
}

- (NSDictionary *)latestReceipt
{
    return self[@"latest_receipt"];
}

- (NSDictionary *)latestExpiredReceiptInfo
{
    return self[@"latest_expired_receipt_info"];
}
- (NSDictionary *)latestReceiptInfo
{
    return self[@"latest_receipt_info"];
}
@end

static const NSInteger kETIAPReceiptProductionError = 21007;
//This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
static const NSInteger kETIAPReceiptSandboxError = 21008;
//This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.

@implementation ETIAPReceiptValidation

+ (void) startIAPReceiptValidationWithtData:(NSData *)receiptData
                          productIdentifier:(NSString *)productIdentifier
                          iTunesIAPPassword:(NSString *)password
                                 completion:(ETIAPReceiptValidationCompletionBlock)completion
{
    [self startIAPReceiptValidationWithtData:receiptData
                           productIdentifier:productIdentifier
                                     sandbox:NO
                           iTunesIAPPassword:password
                                  completion:completion];
}

+ (void) startIAPReceiptValidationWithtData:(NSData *)receiptData
                          productIdentifier:(NSString *)productIdentifier
                          iTunesIAPPassword:(NSString *)password
                                    sandbox:(BOOL)sandbox
                                 completion:(ETIAPReceiptValidationCompletionBlock)completion
{
    if (receiptData == nil) {
        BLOCK_SAFE_RUN(completion, nil, receiptData, productIdentifier, [NSError errorWithDomain:@"receipt data missing" code:ETIAPReceiptValiationRequestErrorCodeNoDataError userInfo:nil]);
        return;
    }
    
    NSString *receiptString = nil;
    
    if (IS_IOS7_OR_LATER()) {
        receiptString = [receiptData base64EncodedStringWithOptions:0];
    } else {
        receiptString = [receiptData base64EncodedString];
    }
    
    if (receiptData == nil) {
        BLOCK_SAFE_RUN(completion, nil, receiptData, productIdentifier, [NSError errorWithDomain:@"invalid receipt data" code:ETIAPReceiptValiationRequestErrorCodeInvalidDataError userInfo:nil]);
        return;
    }
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:@{
                                                                    @"receipt-data":receiptString,
                                                                    @"password":password
                                                                    }
                                                          options:0
                                                            error:nil];
    
    if (requestData == nil) {
        BLOCK_SAFE_RUN(completion, nil, receiptData, productIdentifier, [NSError errorWithDomain:@"" code:ETIAPReceiptValiationRequestErrorCodeUnknownError userInfo:nil]);
        return;
    }
    
    NSURL *storeURL = [NSURL URLWithString:sandbox ? @"https://sandbox.itunes.apple.com/verifyReceipt" : @"https://buy.itunes.apple.com/verifyReceipt"];
    
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    [NSURLConnection sendAsynchronousRequest:storeRequest queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   BLOCK_SAFE_RUN(completion, nil, receiptData, productIdentifier, [NSError errorWithDomain:[NSString stringWithFormat:@"connection error: %@", connectionError.description] code:ETIAPReceiptValiationRequestErrorCodeConnectionError userInfo:nil]);
                               } else {
                                   NSError *error;
                                   NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                   if (!jsonResponse) {
                                       BLOCK_SAFE_RUN(completion, nil, receiptData, productIdentifier, [NSError errorWithDomain:@"iTunes responded with empty data" code:ETIAPReceiptValiationRequestErrorCodeAppleError userInfo:nil]);
                                   }
                                   
                                   if (jsonResponse.status == kETIAPReceiptProductionError) {
                                       [self startIAPReceiptValidationWithtData:receiptData
                                                              productIdentifier:productIdentifier
                                                                        sandbox:YES
                                                              iTunesIAPPassword:password
                                                                     completion:completion];
                                   } else {
                                       if (jsonResponse.status == kETIAPReceiptSandboxError) {
                                           // We have a problem if we are sending prod receipt to sandbox!! -- this is not
                                           // possible to enter anyway since we are always validating with prod first, per Apple recommendation
                                       }
                                       
                                       BLOCK_SAFE_RUN(completion, jsonResponse, receiptData, productIdentifier, nil);
                                   }
                               }
                           }];
}

@end
