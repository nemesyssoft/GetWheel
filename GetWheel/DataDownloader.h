//
//  DataDownloader.h
//  GetWheel
//
//  Created by Laurent Daudelin on 12/11/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataDownloader : NSObject <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

- (void)downloadDataWithCompletionHandler:(void (^ __nonnull)(NSArray *results))completion;

@end

NS_ASSUME_NONNULL_END
