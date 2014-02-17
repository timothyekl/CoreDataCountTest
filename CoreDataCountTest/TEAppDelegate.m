//
//  TEAppDelegate.m
//  CoreDataCountTest
//
//  Created by Tim Ekl on 2/17/14.
//  Copyright (c) 2014 Tim Ekl. All rights reserved.
//

#import "TEAppDelegate.h"

#import <CoreData/CoreData.h>

@implementation TEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    NSDictionary *storeURLsByType = @{ NSInMemoryStoreType : [NSNull null],
                                       NSSQLiteStoreType : [[self _documentURL] URLByAppendingPathComponent:@"store.sqlite"],
                                       NSBinaryStoreType : [[self _documentURL] URLByAppendingPathComponent:@"store.binary"] };
    
    [storeURLsByType enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSURL *storeURL = (obj == [NSNull null] ? nil : obj);
        
        @try {
            NSLog(@"=== BEGIN %@ ===", key);
            [self _testFetchByRelationshipCountForStoreType:key atURL:storeURL];
        } @catch(NSException *exception) {
            NSLog(@"Failed to complete test: raised exception %@", [exception name]);
            NSLog(@"Reason: %@", [exception reason]);
            NSLog(@"Trace: %@", [exception callStackSymbols]);
        } @finally {
            if (storeURL != nil) {
                NSError *error = nil;
                BOOL success = [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
                if (!success) {
                    NSLog(@"Removing store failed; future tests will likely fail as well. %@", [error localizedDescription]);
                    NSLog(@"You may want to delete this app or reset your Simulator before trying again.");
                }
            }
            
            NSLog(@"=== END %@ ===", key);
        }
    }];
    
    return YES;
}

- (void)_testFetchByRelationshipCountForStoreType:(NSString *)storeType atURL:(NSURL *)storeURL;
{
    // Model
    NSEntityDescription *parentDesc = [[NSEntityDescription alloc] init];
    parentDesc.name = @"Parent";

    NSEntityDescription *childDesc = [[NSEntityDescription alloc] init];
    childDesc.name = @"Child";
    
    NSRelationshipDescription *childrenRelationship = [[NSRelationshipDescription alloc] init];
    childrenRelationship.destinationEntity = childDesc;
    childrenRelationship.name = @"children";
    childrenRelationship.optional = YES;
    childrenRelationship.minCount = 0;
    childrenRelationship.maxCount = 1000;
    
    NSRelationshipDescription *parentRelationship = [[NSRelationshipDescription alloc] init];
    parentRelationship.destinationEntity = parentDesc;
    parentRelationship.name = @"parent";
    parentRelationship.optional = NO;
    parentRelationship.minCount = 1;
    parentRelationship.maxCount = 1;
    
    parentRelationship.inverseRelationship = childrenRelationship;
    childrenRelationship.inverseRelationship = parentRelationship;
    
    [parentDesc setProperties:@[ childrenRelationship ]];
    [childDesc setProperties:@[ parentRelationship ]];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] init];
    [mom setEntities:@[ parentDesc, childDesc ]];
    NSAssert(mom != nil, @"Expected model");
    
    // Store & coordinator
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    NSError *storeError = nil;
    NSPersistentStore *store = [psc addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:nil error:&storeError];
    NSAssert(store != nil, @"Expected store");
    
    // Context
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    moc.persistentStoreCoordinator = psc;
    
    // Create objects
    NSManagedObject *parentA = [NSEntityDescription insertNewObjectForEntityForName:@"Parent" inManagedObjectContext:moc];
    NSManagedObject *parentB = [NSEntityDescription insertNewObjectForEntityForName:@"Parent" inManagedObjectContext:moc];
    
    NSManagedObject *childA = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:moc];
    NSManagedObject *childB = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:moc];
    NSManagedObject *childC = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:moc];
    
    [parentA setValue:[NSSet setWithObjects:childA, childB, nil] forKeyPath:@"children"];
    [parentB setValue:[NSSet setWithObject:childC] forKeyPath:@"children"];
    
    NSError *saveError = nil;
    BOOL saveSuccess = [moc save:&saveError];
    NSAssert(saveSuccess, @"Expected to save (error: %@)", [saveError localizedDescription]);
    
    // Request parents, sorting by child count
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Parent"];
    [request setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"children.@count" ascending:NO] ]];
    
    NSError *fetchError = nil;
    NSArray *parents = [moc executeFetchRequest:request error:&fetchError];
    NSAssert(parents != nil, @"Expected to fetch parents");
    for (NSManagedObject *parent in parents) {
        NSLog(@"found parent %@ with %tu children (%@)",
              [[[parent objectID] URIRepresentation] lastPathComponent],
              [[parent valueForKey:@"children"] count],
              [[[parent valueForKeyPath:@"children.objectID.URIRepresentation.lastPathComponent"] allObjects] componentsJoinedByString:@","]);
    }
}

- (NSURL *)_documentURL;
{
    NSArray *candidates = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSAssert([candidates count] > 0, @"Expected at least one document directory");
    return candidates[0];
}

@end
