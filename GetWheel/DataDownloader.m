//
//  DataDownloader.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import "DataDownloader.h"

#define DEFAULT_URL @"https://api.stackexchange.com/2.2/users?site=stackoverflow"

static DataDownloader *sharedDataDownloader = nil;

@interface DataDownloader ()

@property (nonatomic, assign) NSInteger downloadRetry;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation DataDownloader


+ (id)sharedDataDownloader
{
    static dispatch_once_t dataDownloaderPredicate;
    dispatch_once(&dataDownloaderPredicate, ^{
        sharedDataDownloader = [[super allocWithZone:NULL] init];
        if (sharedDataDownloader != nil) {
            sharedDataDownloader.downloadQueue = [[NSOperationQueue alloc] init];
            sharedDataDownloader.downloadQueue.maxConcurrentOperationCount = 1;
        }
    });
    
    return sharedDataDownloader;
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

- (void)downloadPictureForUserID:(NSInteger)userID withPictureURL:(NSURL *)pictureURL completion:(void (^)(NSInteger userID))completion {
    [APP_DELEGATE startNetworkIndicatorForInstance:self];
    __block NSURL *picturePath = APP_DELEGATE.picturesDirectory;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 60.0f;
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                             delegate:self
                                                        delegateQueue:self.downloadQueue];
    NSURL *url = pictureURL;
    NSURLSessionDataTask *downloadTask = [urlSession dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                       if (error != nil) {
                                                           NELog(@"error %ld while trying to download picture at '%@': %@",
                                                                 (long)error.code,
                                                                 pictureURL,
                                                                 error.description);
                                                       }
                                                       else {
                                                           picturePath = [picturePath URLByAppendingPathComponent:[NSString stringWithFormat:@"%ld.jpg", (long)userID]];
                                                           NSError *error = nil;
                                                           if ( ! [data writeToURL:picturePath options:NSDataWritingAtomic error:&error]) {
                                                               NELog(@"error %ld while trying to save picture file at '%@': %@", (long)error.code, picturePath, error.description);
                                                           }
                                                           else {
                                                               completion(userID);
                                                           }
                                                       }
                                                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                           NELog(@"finished downloading picture at '%@'", pictureURL);
                                                           [APP_DELEGATE stopNetworkIndicatorForInstance:self];
                                                       }];
                                                   }];
    NELog(@"starting download of picture at '%@'", url);
    [downloadTask resume];
}

#pragma mark - NSURLSessionDelegate Methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    
}

@end
