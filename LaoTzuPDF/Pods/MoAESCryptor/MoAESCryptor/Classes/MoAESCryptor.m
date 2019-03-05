//
//  MoAESCryptor.m
//  MoAESCryptor
//
//  Created by mozhe on 2019/3/4.
//

#import "MoAESCryptor.h"

//#import <CommonCrypto/CommonCryptor.h>

@interface MoAESCryptorSetting()
    
    @end

@implementation MoAESCryptorSetting
    
- (instancetype)initWithType:(MoAESCryptorType)type
                     padding:(MoAESCryptorPadding)dataPadding
                  keyPadding:(MoAESCryptorKeyPadding)keyPadding
                   operation:(MoAESCryptorOperation)encryptOrDencrypt {
    if (self = [super init]){
        self.type = type;
        self.dataPadding = dataPadding;
        self.keyPadding  = keyPadding;
        self.operation   = encryptOrDencrypt;
    }
    return self;
}
    - (void)createKey:(NSString *)key
                round:(NSUInteger)round
            algorithm:(u_int32_t)algorithm{};
    
    @end


/*************  MoAESCryptor    **********/

@interface MoAESCryptor()
    
    @end

@implementation MoAESCryptor
    
+ (void)ecbCipher:(NSData *)dataIn
              key:(NSData *)symmetricKey
         settings:(MoAESCryptorSetting *)setting
       completion:(MoAESCryptorCompletion)callback {
    
    //检查dataIn
    if (dataIn == nil || dataIn.length == 0){
        callback(nil, MoAESCryptorErrorDataIn);
        return;
    }
    
    MoAESCryptorType type = setting.type;
    MoAESCryptorKeyPadding keyPadding = setting.keyPadding;
    
    MoAESCryptorKeySize keySize;
    //检查Key
    switch (type) {
        case MoAESCryptorType128:
        keySize = MoAESCryptorKeySize128;
        break;
        case MoAESCryptorType192:
        keySize = MoAESCryptorKeySize192;
        break;
        case MoAESCryptorType256:
        keySize = MoAESCryptorKeySize256;
        break;
        default:
        break;
    }
    NSData *newKey = [self appendKeyDataWithKeySize:keySize key:symmetricKey keyPadding:keyPadding completion:^(NSData * _Nullable dataOut, MoAESCryptorError error) {
        if (error != MoAESCryptorErrorNone) {
            callback(nil, error);
            return;
        }
    }];
    
    CCOperation op;
    NSData *newData;
    
    switch (setting.operation) {
        case MoAESCryptorOperationEncrypt:
        op = (CCOperation)(kCCEncrypt);
        break;
        case MoAESCryptorOperationDecrypt:
        op = (CCOperation)(kCCDecrypt);
        break;
        default:
        break;
    }
    // 加密添加，解密移除， current not removed the data appendded, it's work
    newData = [self dealWithDataIn:dataIn padding:setting.dataPadding operation:op];
    
    [self executeCipher:newData
                    key:newKey
                   type:type
                context:op
             completion:^(NSData * _Nullable dataOut, MoAESCryptorError error) {
                 callback(dataOut, error);
             }];
    
}
    
+ (void)ecbCipher:(NSData *)dataIn
              key:(NSData *)symmetricKey
             type:(MoAESCryptorType)aes256
          padding:(MoAESCryptorPadding)dataPadding
       keyPadding:(MoAESCryptorKeyPadding)keyDataPadding
        operation:(MoAESCryptorOperation)encryptOrDecrypt
       completion:(MoAESCryptorCompletion)callback {
    
}
    
    
    
+ (void)doCipher:(NSData *)dataIn
             key:(NSData *)symmetricKey
       operation:(MoAESCryptorOperation)encryptOrDecrypt
      completion:(MoAESCryptorCompletion)callback {
    
    //校验dataIn
    if (dataIn == nil || dataIn.length == 0) {
        callback(nil,MoAESCryptorErrorDataIn);
        return;
    }
    
    
    //校验Key length
    NSArray<NSNumber *> *keyLengths = @[
                                        @(MoAESCryptorKeySize128),
                                        @(MoAESCryptorKeySize192),
                                        @(MoAESCryptorType256)
                                        ];
    NSNumber *inputKey = @(symmetricKey.length);
    if (![keyLengths containsObject:inputKey]) {
        callback(nil,MoAESCryptorErrorKeyLength);
        return;
    }
    CCOperation op = (CCOperation)kCCEncrypt;
    switch (encryptOrDecrypt) {
        case MoAESCryptorOperationEncrypt:
        op = (CCOperation)kCCEncrypt;
        break;
        case MoAESCryptorOperationDecrypt:
        op = (CCOperation)kCCDecrypt;
        break;
        
        default:
        break;
    }
    
}
    
#pragma mark - Private Methods
    
    // 处理 key
    
    /**
     处理加密密码
     
     @param keySize AES KeySize 16bytes 24 bytes 32bytes
     @param symmetricKey 对称key Data
     @param keyPadding key Data 拼接规则
     @param callback 回调
     @return 新的 key data
     */
+ (NSData *)appendKeyDataWithKeySize:(MoAESCryptorKeySize)keySize
                                 key:(NSData *)symmetricKey
                          keyPadding:(MoAESCryptorKeyPadding)keyPadding
                          completion:(MoAESCryptorCompletion)callback {
    
    NSMutableData *keyData = [NSMutableData dataWithData:symmetricKey];
    
    if (symmetricKey.length != keySize) {
        if (keyPadding == MoAESCryptorKeyPaddingNone) {
            callback(nil,MoAESCryptorErrorKeyLength);
            return symmetricKey;
        }else if (symmetricKey.length < keySize) {
            if (keyPadding == MoAESCryptorKeyPaddingZero) {
                int appendCount = (int)(keySize - symmetricKey.length);
                NSMutableData *appendData = [NSMutableData dataWithLength:appendCount];
                [keyData appendData:appendData];
            }else{
                callback(nil,MoAESCryptorErrorKeyLength);
                return keyData;
            }
        }else { // ToDo
            callback(nil,MoAESCryptorErrorKeyLength);
            return keyData;
        }
    }
    callback(nil,MoAESCryptorErrorNone);
    return keyData;
}
    
    // 处理 data in
+ (NSData *)dealWithDataIn:(NSData *)dataIn
                   padding:(MoAESCryptorPadding)dataPadding
                 operation:(MoAESCryptorOperation)operation {
    
    int toAppendCount = 0;
    NSMutableData *data = [NSMutableData dataWithData:dataIn];
    toAppendCount = kCCBlockSizeAES128 - (dataIn.length % kCCBlockSizeAES128);
    // zero padding rule (eg. data + (padding 0000) + 04占位，（ % 余数2),  解密移除)
    //    switch (operation) {
    //        case MoAESCryptorOperationEncrypt:
    //        toAppendCount = kCCBlockSizeAES128 - (dataIn.length % kCCBlockSizeAES128);
    //        break;
    //
    //        case MoAESCryptorOperationDecrypt:
    //        if (dataPadding == MoAESCryptorPaddingZero) {
    //
    //        }
    //        break;
    //
    //        default:
    //        break;
    //    }
    //
    
    
    if (toAppendCount < kCCBlockSizeAES128) {
        
        if (dataPadding == MoAESCryptorPaddingZero) {
            NSMutableData *appendding = [NSMutableData dataWithLength:toAppendCount];
            [data appendData:appendding];
        }else if (dataPadding == MoAESCryptorPaddingPKCS7) {
            
            //             NSMutableData *appendding = [NSMutableData dataWithLength:toAppendCount];
            NSMutableData *appendding = [NSMutableData dataWithCapacity:toAppendCount];
            for (int i = 0; i < toAppendCount; i++) {
                int appendingNumber = toAppendCount;
                
                //                [appendding replaceBytesInRange:NSMakeRange(i, 1) withBytes:&appendingNumber];
                [appendding appendBytes:&appendingNumber length:1];
            }
            NSLog(@"pkcs7 appenddingData: %@",appendding);
            [data appendData:appendding];
        }else {
            
        }
    }
    return data;
}
    
    
+ (void)executeCipher:(NSData *)dataIn
                  key:(NSData *)symmetricKey
                 type:(MoAESCryptorType)aes256or192or128
              context:(CCOperation)encryptOrDecrypt // kCCEncrypt or kCCDecrypt
           completion:(MoAESCryptorCompletion)callback
    {
        CCCryptorStatus ccStatus   = kCCSuccess;
        size_t          cryptBytes = 0;    // Number of bytes moved to buffer.
        NSMutableData  *dataOut    = [NSMutableData dataWithLength:dataIn.length + kCCBlockSizeAES128];
        
        ccStatus = CCCrypt( encryptOrDecrypt,
                           kCCAlgorithmAES128,
                           kCCOptionECBMode,
                           symmetricKey.bytes,
                           aes256or192or128,
                           0,
                           dataIn.bytes, dataIn.length,
                           dataOut.mutableBytes, dataOut.length,
                           &cryptBytes);
        
        if (ccStatus != kCCSuccess) {
            NSLog(@"CCCrypt status: %d", ccStatus);
            if (encryptOrDecrypt == ((CCOperation)kCCEncrypt)) {
                callback(nil,MoAESCryptorErrorEncrypt);
                
            }else {
                callback(nil,MoAESCryptorErrorDecrypt);
            }
            return;
        }
        
        dataOut.length = cryptBytes;
        callback(dataOut,MoAESCryptorErrorNone);
        //    return dataOut;
    }
    
    
+ (NSData *)doCipher:(NSData *)dataIn
                 key:(NSData *)symmetricKey
             context:(CCOperation)encryptOrDecrypt // kCCEncrypt or kCCDecrypt
    {
        CCCryptorStatus ccStatus   = kCCSuccess;
        size_t          cryptBytes = 0;    // Number of bytes moved to buffer.
        NSMutableData  *dataOut    = [NSMutableData dataWithLength:dataIn.length + kCCBlockSizeAES128];
        
        ccStatus = CCCrypt( encryptOrDecrypt,
                           kCCAlgorithmAES128,
                           kCCOptionECBMode,
                           symmetricKey.bytes,
                           kCCKeySizeAES256,
                           0,
                           dataIn.bytes, dataIn.length,
                           dataOut.mutableBytes, dataOut.length,
                           &cryptBytes);
        
        if (ccStatus != kCCSuccess) {
            NSLog(@"CCCrypt status: %d", ccStatus);
        }
        
        dataOut.length = cryptBytes;
        
        //test
        //    NSMutableData *mData = [NSMutableData dataWithLength:4];
        //    NSLog(@"mData: = %@",mData);
        
        return dataOut;
    }
    
    
    @end
