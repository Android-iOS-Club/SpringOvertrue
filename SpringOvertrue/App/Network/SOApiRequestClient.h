//
//  SOApiRequestClient.h
//  SpringOvertrue
//
//  Created by Sharker on 2021/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SOApiRequestConfig;
@class SOApiError;
@interface SOApiRequestClient : NSObject

+ (NSURLSessionDataTask *)so_makeRequest:(void(^)(SOApiRequestConfig *config))configBlock
                              completion:(void(^)(id _Nullable responseObject, SOApiError *error))completion;
@end

NS_ASSUME_NONNULL_END
