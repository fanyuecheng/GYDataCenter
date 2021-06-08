//
//  FMDatabaseQueue+Async.h
//  GYDataCenter
//
//  Created by 佘泽坡 on 6/25/16.
//  Copyright © 2016 佘泽坡. All rights reserved.
//

#import <FMDB/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMDatabaseQueue (Async)

/// 获取私有属性 _queue
- (dispatch_queue_t)getQueue;
/// 获取私有属性 _db
- (FMDatabase *)getDatabase;

- (void)setShouldCacheStatements:(BOOL)value;

- (void)setDatabaseQueueSpecific;

- (void)syncInDatabase:(void (^)(FMDatabase *db))block;

- (void)asyncInDatabase:(void (^)(FMDatabase *db))block;

@end

NS_ASSUME_NONNULL_END
