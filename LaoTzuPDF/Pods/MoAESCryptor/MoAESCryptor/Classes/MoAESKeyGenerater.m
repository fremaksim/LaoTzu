//
//  MoAESKeyGenerater.m
//  MoAESCryptor_Example
//
//  Created by mozhe on 2019/3/5.
//  Copyright © 2019 fremaksim. All rights reserved.
//  Inspired by BBAES at https://github.com/benoitsan/BBAES

#import "MoAESKeyGenerater.h"
//#import <CommonCrypto/CommonKeyDerivation.h>
#if !__has_feature(objc_arc)
#error BBAES must be built with ARC.
// You can turn on ARC for only BBAES files by adding -fobjc-arc to the build phase for each of its files.
#endif

static NSData *digest(NSData *data, unsigned char *(*cc_digest)(const void *, CC_LONG, unsigned char *), CC_LONG digestLength)
{
    unsigned char md[digestLength];
    memset(md, 0, sizeof(md));
    cc_digest([data bytes], (CC_LONG)[data length], md);
    //CC_MD5(<#const void *data#>, <#CC_LONG len#>, <#unsigned char *md#>)
    //CC_SHA256(<#const void *data#>, <#CC_LONG len#>, <#unsigned char *md#>)
    return [NSData dataWithBytes:md length:sizeof(md)];
}

//static NSData * SHA1Hash(NSData* data) {
//    return digest(data, CC_SHA1, CC_SHA1_DIGEST_LENGTH);
//}

static NSData *MD5Hash(NSData *data)
{
    return digest(data, CC_MD5, CC_MD5_DIGEST_LENGTH);
}

static NSData *SHA256Hash(NSData *data)
{
    return digest(data, CC_SHA256, CC_SHA256_DIGEST_LENGTH);
}


@implementation MoAESKeyGenerater

+ (NSData *)keyByHashingPassword:(NSString *)string keySize:(MoAESCryptorType)keySize
{
    NSParameterAssert(string);
    
    NSData *retData = nil;
    if (keySize == MoAESCryptorType128) {
        retData = MD5Hash([string dataUsingEncoding:NSUTF8StringEncoding]); // MD5 produces a 128 bits hash value
    }
    if (keySize == MoAESCryptorType256) {
        retData = SHA256Hash([string dataUsingEncoding:NSUTF8StringEncoding]); // SHA256 produces a 256 bits hash value
    } else {
        [NSException exceptionWithName:NSInternalInconsistencyException reason:@"The key size must be `MoAESCryptorType128` or `MoAESCryptorType256`." userInfo:nil];
    }
    return retData;
}

@end
