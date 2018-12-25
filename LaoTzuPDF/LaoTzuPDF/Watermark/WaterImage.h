//
//  WaterImage.h
//  LaoTzuPDF
//
//  Created by mozhe on 2018/12/25.
//  Copyright © 2018 mozhe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WaterImage : NSObject

//+ (UIImage *)getWaterMarkImage: (UIImage *)originalImage andTitle: (NSString *)title andMarkFont: (UIFont *)markFont andMarkColor: (UIColor *)markColor;

+ (UIImage *)getWaterMarkImage: (UIImage *)originalImage angle:(CGFloat)angle;

@end

NS_ASSUME_NONNULL_END
