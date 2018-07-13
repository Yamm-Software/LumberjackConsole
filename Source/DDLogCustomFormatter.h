//
//  DDLogCustomFormatter.h
//  Alamofire
//
//  Created by Roger Mabillard on 2018-05-28.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface DDLogCustomFormatter : NSObject <DDLogFormatter> {
    int loggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

- (id)initShort;


@end
