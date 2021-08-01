//
//  SOApiRequestClient.m
//  SpringOvertrue
//
//  Created by Sharker on 2021/7/28.
//

#import "SOApiRequestClient.h"
#import "SOApiRequestConfig.h"
#import "SONetworkMacro.h"
#import "SOApiError.h"
#import <AFNetworking/AFNetworking.h>
#import "SOApiRoute.h"

@implementation SOApiRequestClient

+ (NSURLSessionDataTask *)so_makeRequest:(void (^)(SOApiRequestConfig * _Nonnull))configBlock requestType:(SORequestType)type completion:(void (^)(id _Nullable, SOApiError * _Nullable))completion {
    SOApiRequestConfig *config = [[SOApiRequestConfig alloc] init];
    [SOApiRequestClient setRequestConfigWith:config configBlock:configBlock];
    
    if (config.url.length == 0 && config.route.length == 0) {
        // url error
        SOApiError *apiError = [SOApiError errorWithCode:kApiUrlError message:@"url错误" userHint:nil];
        [self handleRequesrError:apiError userHintType:config.hintType];
        !completion?:completion(nil, apiError);
        return nil;
    }
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (@available(iOS 11.0, *)) {
        sessionConfig.waitsForConnectivity = config.waitsForConnectivity; // 等待网络可用
    } else {
        // Fallback on earlier versions
    }
    if (config.timeoutIntervalForResource) {
        sessionConfig.timeoutIntervalForResource = config.timeoutIntervalForResource;
    }
    
    AFURLSessionManager *sessionManager =  [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfig];
    // 设置contentTypes
    [(AFJSONResponseSerializer *)sessionManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/css", @"text/plain", nil]];
    [(AFJSONResponseSerializer *)sessionManager.responseSerializer setRemovesKeysWithNullValues:YES];
    
    NSString *url = config.url?:[SOApiRoute urlWithRoute:config.route];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:[SOApiRequestClient requestMethodMappingWithReqType:type] URLString:url parameters:config.params?:@{} error:nil];
    if (config.timeoutInterval) {
        request.timeoutInterval = config.timeoutInterval.integerValue;
    } else {
        request.timeoutInterval = 15; // 默认超时请求设置为15s
    }
    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            SOApiError *apiError = [SOApiError errorWithCode:[@(error.code) stringValue] message:error.description userHint:nil];
            [self handleRequesrError:apiError userHintType:config.hintType];
            !completion?:completion(nil, apiError);
            return;
        }
        
        NSError *dataAnalysisError;
        SOApiError *apiError = [[SOApiError alloc] initWithDictionary:responseObject error:&dataAnalysisError];
        if (dataAnalysisError) {
            apiError = [SOApiError errorWithCode:kApiDataFormat message:@"数据格式错误" userHint:nil];
            [self handleRequesrError:apiError userHintType:config.hintType];
            !completion?:completion(nil, apiError);
            return;
        }
        
        id responseData = responseObject[@"data"];
        !completion?:completion(responseData, nil);
    }];
    
    [dataTask resume];
    return dataTask;
}


+ (NSString *)requestMethodMappingWithReqType:(SORequestType)type {
    switch (type) {
        case SORequestUnknowType:
            return @"Unknow";
        case SORequestUnGetType:
            return @"GET";
        case SORequestUnPutType:
            return @"PUT";
        case SORequestUnPostType:
            return @"POST";
        case SORequestUnDeleteType:
            return @"DELETE";
        default:
            return @"ERROR";
    }
    return @"ERROR";
}

+ (void)setRequestConfigWith:(SOApiRequestConfig *)config
                 configBlock:(void (^)(SOApiRequestConfig * _Nonnull))configBlock {
    NSDictionary *oldDic = [NSDictionary dictionaryWithDictionary:config.params];
    if (configBlock) {
        configBlock(config);
    }
    NSMutableDictionary *newConfigParams = [NSMutableDictionary dictionaryWithDictionary:config.params];
    [newConfigParams enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *objStr = [NSString stringWithFormat:@"%@", obj];
        if (![objStr length]) {
            [newConfigParams removeObjectForKey:key];
        }
    }];
    NSDictionary *newDic = [NSDictionary dictionaryWithDictionary:newConfigParams];
    NSMutableDictionary *changeDic = [NSMutableDictionary dictionaryWithDictionary:[SOApiRequestClient compareChangeWithOldDic:oldDic newDic:newDic ignoreKeys:@[@"nonce"]]];
    __unused NSString *sign = [SOApiRequestClient signWithParams:changeDic];
//    config.params[@"sign"] = sign;
}

+ (void)handleRequesrError:(SOApiError *)error userHintType:(SOApiErrorHintType)hintType {
    
}

/// 判断新增的参数
+ (NSDictionary *)compareChangeWithOldDic:(NSDictionary *)old newDic:(NSDictionary *)new ignoreKeys:(NSArray *)ignoreKeys {
    return @{};
}

/// md5签名
+ (NSString *)signWithParams:(NSDictionary *)params {
    return  @"";
}

@end
