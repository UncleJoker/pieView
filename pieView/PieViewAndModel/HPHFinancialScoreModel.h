//
//  HPHFinancialScoreModel.h
//  dpw
//
//  Created by 林 on 2018/10/30.
//  Copyright © 2018年 qzpay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPHFinancialPieModel : NSObject
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy) NSString *total_name;
@property (nonatomic, copy) NSString *income_amount;
@property (nonatomic, copy) NSString *out_amount;
@property (nonatomic, copy) NSString *rate;
@end

@interface HPHFinancialScoreModel : NSObject
@property (nonatomic, copy) NSString *score;
@property (nonatomic, copy) NSArray  *outcome;
@property (nonatomic, copy) NSString *score_status;
@property (nonatomic, copy) NSArray  *income;

@end
