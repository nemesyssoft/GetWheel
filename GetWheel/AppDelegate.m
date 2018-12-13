//
//  AppDelegate.m
//  GetWheel
//
//  Created by Laurent Daudelin on 12/10/18.
//  Copyright © 2018 Nemesys Software. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MasterViewController.h"

#define DELAY_TO_STOP_ACTIVITY_INDICATOR 3.0f

@interface AppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, strong) NSRecursiveLock *networkClientsLock;
@property (nonatomic, strong) NSMutableDictionary *networkIndicatorClients;
@property (nonatomic, assign) NSInteger networkIndicatorStack;
@property (nonatomic, strong) DataSource *dataSource;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

    UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
    MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
    controller.managedObjectContext = self.persistentContainer.viewContext;
    
    NSError *error = nil;
    self.picturesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSPicturesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error != nil) {
        NELog(@"error %ld while trying to get the URL for the pictures directory: %@", (long)error.code, error.localizedDescription);
    }
    DataSource *sharedDataSource = [DataSource sharedDataSource];
    sharedDataSource.managedObjectContext = self.persistentContainer.viewContext;
    if ([sharedDataSource personCount] == 0) {
        DataDownloader *dataDownloader = [DataDownloader sharedDataDownloader];
        [dataDownloader downloadDataWithCompletionHandler:^(NSArray * _Nonnull results) {
            NSArray *persons = results;
            [sharedDataSource savePersons:persons];
        }];
    }
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"GetWheel"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

#pragma mark - Service Methods

- (void)startNetworkIndicatorForInstance:(id)anInstance
{
    NSString *addressAsString = [NSString stringWithFormat:@"%p", anInstance];
    //    NELog(@"                 instance: %@ @ %@", [anInstance class], addressAsString);
    if (addressAsString == nil) {
        NELog(@"Received a nil addressAsString. Aborting");
        return;
    }
    NSNumber *numberOfInvocations = [self.networkIndicatorClients objectForKey:addressAsString];
    if (numberOfInvocations == nil) {
        numberOfInvocations = [NSNumber numberWithInteger:1];
        [self.networkClientsLock lock];
        [self.networkIndicatorClients setObject:numberOfInvocations forKey:addressAsString];
        [self.networkClientsLock unlock];
    }
    else {
        [self.networkClientsLock lock];
        [self.networkIndicatorClients setObject:[NSNumber numberWithLong:numberOfInvocations.integerValue + 1] forKey:addressAsString];
        [self.networkClientsLock unlock];
    }
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reallyStopNetworkIndicatorFromTimer:) object:nil];
    if ( ! [NSThread isMainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_networkIndicatorStack++;
            if (self->_networkIndicatorStack > 0 && ! [UIApplication sharedApplication].networkActivityIndicatorVisible)
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }];
    }
    else {
        _networkIndicatorStack++;
        if (_networkIndicatorStack > 0 && ! [UIApplication sharedApplication].networkActivityIndicatorVisible)
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

- (void)stopNetworkIndicatorForInstance:(id)anInstance
{
    NSString *addressAsString = [[NSString stringWithFormat:@"%p", anInstance] copy];
    [self.networkClientsLock lock];
    NSNumber *numberOfInvocations = [self.networkIndicatorClients objectForKey:addressAsString];
    [self.networkClientsLock unlock];
    if (numberOfInvocations == nil) {
        NELog(@"Instance of class '%@' @ %@ invoked stopNetworkIndicatorForInstance: without calling startNetworkIndicatorForInstance:", [anInstance class], addressAsString);
    }
    if (numberOfInvocations != nil) {
        if ([numberOfInvocations intValue] > 1) {
            [self.networkClientsLock lock];
            [self.networkIndicatorClients setObject:[NSNumber numberWithInt:[numberOfInvocations intValue] - 1] forKey:addressAsString];
            [self.networkClientsLock unlock];
        }
        else {
            [self.networkClientsLock lock];
            [self.networkIndicatorClients removeObjectForKey:addressAsString];
            [self.networkClientsLock unlock];
        }
    }
    if ( ! [NSThread isMainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_networkIndicatorStack--;
            if (self->_networkIndicatorStack < 0) {
                self->_networkIndicatorStack = 0;
            }
            if (self->_networkIndicatorStack == 0) {
                [self stopNetworkIndicatorOnMainThread];
            }
        }];
    }
    else {
        _networkIndicatorStack--;
        if (_networkIndicatorStack < 0) {
            _networkIndicatorStack = 0;
        }
        if (_networkIndicatorStack == 0) {
            [self stopNetworkIndicatorOnMainThread];
        }
    }
}

#pragma mark - Private Methods

- (void)reallyStopNetworkIndicatorFromTimer:(NSTimer *)aTimer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [aTimer invalidate];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

- (void)stopNetworkIndicatorOnMainThread
{
    // In case of very short start and stop, we don't want to have the indicator flickering so when we get a stop, we delay
    // the hiding by one second
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reallyStopNetworkIndicatorFromTimer:) object:NULL];
    //    NELog(@"About to perform reallyStopNetworkIndicatorFromTimer: in 3 seconds");
    [self performSelector:@selector(reallyStopNetworkIndicatorFromTimer:) withObject:NULL afterDelay:DELAY_TO_STOP_ACTIVITY_INDICATOR];
}

#pragma mark - Public Methods


@end
