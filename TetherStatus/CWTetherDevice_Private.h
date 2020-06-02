//
//  CWTetherDevice_Private.h
//  TetherInfo
//
//  Created by Mark Knowles on 16/5/20.
//  Copyright © 2020 Mark Knowles. All rights reserved.
//

#ifndef CWTetherDevice_Private_h
#define CWTetherDevice_Private_h

#import <Foundation/NSObject.h>
#import <Foundation/Foundation.h>

@interface CWTetherDevice : NSObject <NSCopying, NSSecureCoding>

@property (copy) NSNumber *batteryLife;
@property unsigned long long deviceGroup;
@property (copy) NSString *deviceIdentifier;
@property (copy) NSString *deviceName;
@property unsigned long long networkType;
@property (copy) NSNumber *signalStrength;

@end

#endif /* CWTetherDevice_Private_h */
