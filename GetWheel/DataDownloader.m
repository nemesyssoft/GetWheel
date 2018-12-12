//
//  DataDownloader.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import "DataDownloader.h"

#define DEFAULT_URL @"https://api.stackexchange.com/2.2/users?site=stackoverflow"

@interface DataDownloader ()

@property (nonatomic, assign) NSInteger downloadRetry;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation DataDownloader

- (instancetype)init {
    if (self = [super init]) {
        self.downloadQueue = [[NSOperationQueue alloc] init];
        self.downloadQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)downloadDataWithCompletionHandler:(void (^ __nonnull)(NSArray *results))completion {
    [APP_DELEGATE startNetworkIndicatorForInstance:self];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 25.0f;
    sessionConfiguration.HTTPAdditionalHeaders = @{@"key": @"4YnWUk)V2spLwvnNdQ238w(("};
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                             delegate:self
                                                        delegateQueue:self.downloadQueue];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", DEFAULT_URL]];
    NSURLSessionDataTask *downloadTask = [urlSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                       if (error != nil) {
                                                           NELog(@"error %ld while trying to download the data: %@", (long)error.code, error.description);
                                                           if (self.downloadRetry++ < 5) {
                                                               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                   [self performSelector:@selector(downloadDataWithCompletionHandler:) withObject:completion afterDelay:2.0f];
                                                               }];
                                                           }
                                                           else {
                                                               completion(@[]);
                                                           }
                                                       }
                                                       else {
                                                           NSError *parseError = nil;
                                                           NSDictionary *dataInDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                  options:0
                                                                                                                    error:&parseError];
                                                           if (parseError != nil) {
                                                               NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                               NELog(@"error %ld while trying to parse the downloaded data: %@", (long)error.code, error.description);
                                                               NELog(@"data:\n\n%@", dataAsString);
                                                               completion(@[]);
                                                           }
                                                           else {
                                                               NSArray *persons = [dataInDictionary objectForKey:@"items"];
                                                               completion(persons);
                                                               self.downloadRetry = 0;
                                                           }
                                                       }
                                                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                           [APP_DELEGATE stopNetworkIndicatorForInstance:self];
                                                       }];
                                                   }];
    [downloadTask resume];
}

#pragma mark - NSURLSessionDelegate Methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    
}

@end
