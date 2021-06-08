//
//  FMDatabaseQueue+Async.m
//  GYDataCenter
//
//  Created by 佘泽坡 on 6/25/16.
//  Copyright © 2016 佘泽坡. All rights reserved.
//

#import "FMDatabaseQueue+Async.h"
#import <sqlite3.h>
#import <objc/runtime.h>

static const void * const kDatabaseQueueSpecificKey = &kDatabaseQueueSpecificKey;

@implementation FMDatabaseQueue (Async)

- (dispatch_queue_t)getQueue {
    Ivar ivar = class_getInstanceVariable([self class], "_queue");
    dispatch_queue_t queue = object_getIvar(self, ivar);
    return queue;
}

- (FMDatabase *)getDatabase {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"database");
    if ([self respondsToSelector:selector]) {
        return [self performSelector:selector];
    }
#pragma clang diagnostic pop
    return nil;
}

- (void)setShouldCacheStatements:(BOOL)value {
    FMDatabase *db = [self getDatabase];
    [db setShouldCacheStatements:value];
}

- (void)setDatabaseQueueSpecific {
    dispatch_queue_set_specific([self getQueue], kDatabaseQueueSpecificKey, (__bridge void *)self, NULL);
}

- (void)syncInDatabase:(void (^)(FMDatabase *db))block {
    FMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDatabaseQueueSpecificKey);
    
    FMDBRetain(self);
    
    dispatch_block_t task = ^() {
        
        FMDatabase *db = [self getDatabase];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue syncInDatabase:]");
            
#ifdef DEBUG
            NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
            for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                NSLog(@"query: '%@'", [rs query]);
            }
#endif
        }
    };
    
    if (currentSyncQueue == self) {
        task();
    } else {
        dispatch_sync([self getQueue], task);
    }
    
    FMDBRelease(self);
}

- (void)asyncInDatabase:(void (^)(FMDatabase *db))block {
    FMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDatabaseQueueSpecificKey);
    
    FMDBRetain(self);
    
    dispatch_block_t task = ^() {
        
        FMDatabase *db = [self getDatabase];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue asyncInDatabase:]");
            
#ifdef DEBUG
            NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
            for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                NSLog(@"query: '%@'", [rs query]);
            }
#endif
        }
    };
    
    if (currentSyncQueue == self) {
        task();
    } else {
        dispatch_async([self getQueue], task);
    }
    
    FMDBRelease(self);
}

@end
