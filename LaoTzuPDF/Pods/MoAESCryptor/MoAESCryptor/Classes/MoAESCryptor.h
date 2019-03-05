//
//  MoAESCryptor.h
//  MoAESCryptor
//
//  Created by mozhe on 2019/3/4.
//


#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    MoAESCryptorType128 = 16,
    MoAESCryptorType192 = 24,
    MoAESCryptorType256 = 32,
} MoAESCryptorType;

typedef enum : NSUInteger {
    MoAESCryptorKeySize128 = 16, //bytes
    MoAESCryptorKeySize192 = 24,
    MoAESCryptorKeySize256 = 32,
} MoAESCryptorKeySize;

typedef enum : NSUInteger {
    MoAESCryptorOperationEncrypt = 0, //加密
    MoAESCryptorOperationDecrypt,     //解密
} MoAESCryptorOperation;

typedef enum : NSUInteger {
    MoAESCryptorErrorKeyLength,
    MoAESCryptorErrorDataIn,
    MoAESCryptorErrorEncrypt,
    MoAESCryptorErrorDecrypt,
    MoAESCryptorErrorNone, //无错误... bad design
} MoAESCryptorError;

typedef enum : NSUInteger {
    MoAESCryptorPaddingZero,
    MoAESCryptorPaddingPKCS7,
} MoAESCryptorPadding;

typedef enum : NSUInteger {
    MoAESCryptorKeyPaddingZero,
    MoAESCryptorKeyPaddingNone,
} MoAESCryptorKeyPadding; // if key size large 16，24，32 bytes ... Bad design

typedef void(^MoAESCryptorCompletion)(NSData *_Nullable dataOut ,MoAESCryptorError error);


@interface MoAESCryptorSetting: NSObject
    
    @property(nonatomic, assign) MoAESCryptorType type;
    @property(nonatomic, assign) MoAESCryptorPadding dataPadding;
    @property(nonatomic, assign) MoAESCryptorKeyPadding keyPadding;
    @property(nonatomic, assign) MoAESCryptorOperation operation;
    
    
- (instancetype)initWithType:(MoAESCryptorType)type
                     padding:(MoAESCryptorPadding)dataPadding
                  keyPadding:(MoAESCryptorKeyPadding)keyPadding
                   operation:(MoAESCryptorOperation)encryptOrDencrypt;

#pragma mark - TODO
/**
 求导 可以

 @param key <#key description#>
 @param round <#round description#>
 @param algorithm <#algorithm description#>
 */
- (void)createKey:(NSString *)key
            round:(NSUInteger)round
        algorithm:(u_int32_t)algorithm;
    
    
    @end

/**
 The MoAESCryptor design for ECB, only support zeroPadding and PKCS7Padding ()
 */
@interface MoAESCryptor: NSObject
    
    // todo -
    // 1.0 key 求导成相应的size
    
    // features
    // 1. DataIn bytes padding.
    // 2. keySize padding, use padding zero.
    
    
    /**
     cipher with keysize check and data padding
     
     @param dataIn 处理数据
     @param symmetricKey 加密key
     @param setting 配置
     @param callback 回调
     */
+ (void)ecbCipher:(NSData *)dataIn
              key:(NSData *)symmetricKey
         settings:(MoAESCryptorSetting *)setting
       completion:(MoAESCryptorCompletion)callback;
    
    
    /**
     Encrypt or Decrypt with no checks
     
     @param dataIn input Data
     @param symmetricKey key Data
     @param encryptOrDecrypt encrypt or decrypt
     @return output data
     */
+ (NSData *)doCipher:(NSData *)dataIn
                 key:(NSData *)symmetricKey
             context:(CCOperation)encryptOrDecrypt;// kCCEncrypt or kCCDecrypt
    
    @end

NS_ASSUME_NONNULL_END
