//
//  MoAESKeyGenerater.h
//  MoAESCryptor_Example
//
//  Created by mozhe on 2019/3/5.
//  Copyright © 2019 fremaksim. All rights reserved.
//  Inspired by BBAES at https://github.com/benoitsan/BBAES

#import <Foundation/Foundation.h>
#import "MoAESCryptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MoAESKeyGenerater : NSObject

/**
 Stretchs the key to a given size.
 The returned value is a hash value of the password. The hash function is MD5 for a 128 bits key and SHA256 for a 256 bits key.
 This method doesn't work for 192 bits key sizes.
 */
+ (NSData *)keyByHashingPassword:(NSString *)password
                         keySize:(MoAESCryptorType)keySize;


@end

NS_ASSUME_NONNULL_END
