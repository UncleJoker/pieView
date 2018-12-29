//
//  HPHFinancialScoreModel.m
//  dpw
//
//  Created by 林 on 2018/10/30.
//  Copyright © 2018年 qzpay. All rights reserved.
//

#import "HPHFinancialScoreModel.h"

@implementation HPHFinancialPieModel
+(NSDictionary *)replacedKeyFromPropertyName{
    return @{@"categoryId":@"id"};
}
@end

@implementation HPHFinancialScoreModel
+ (NSDictionary *)objectClassInArray {
    return @{@"outcome":[HPHFinancialPieModel class],@"income":[HPHFinancialPieModel class]};
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}
@end
