//
//  ViewController.m
//  ReactiveCocoaTest1
//
//  Created by 程倩 on 16/5/12.
//  Copyright © 2016年 CQ. All rights reserved.
//对应技术博客地址：http://blog.csdn.net/u013232867

#import "ViewController.h"
#import "Header.h"
#import "NSObject+RACKVOWrapper.h"
#import "RACReturnSignal.h"
@interface ViewController ()
@property(nonatomic,strong)id<RACSubscriber> subscriber;
@property(nonatomic,strong)RACDisposable *disposable;
@property(nonatomic,strong)RACSubject *signal;
@property(nonatomic,strong)UIButton *button;
@property(nonatomic,strong)UILabel *label;
@property(nonatomic,strong)UITextField *textfield;
@property (weak, nonatomic) IBOutlet UITextField *textfield1;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

   
}

-(void)throttle
{
    RACSubject *signal = [RACSubject subject];
    
    _signal = signal;
    
    // 节流，在一定时间（1秒）内，不接收任何信号内容，过了这个时间（1秒）获取最后发送的信号内容发出。
    [[signal throttle:1] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    [signal sendNext:@"100"];
    [signal sendNext:@"1000"];
    //输出 2016-05-18 17:14:24.841 ReactiveCocoaTest1[6097:299606] 1000
}

-(void)replay
{
    //replay重放：当一个信号被多次订阅,反复播放内容
    //没有明白这个有何意义
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        
        return nil;
    }] replay];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第一个订阅者%@",x);
        
    }];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第二个订阅者%@",x);
        
    }];
}
-(void)retry
{
    //重试 ：只要失败，就会重新执行创建信号中的block,直到成功
    __block int i = 0;
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        if (i == 10) {
            [subscriber sendNext:@1];
        }else{
            NSLog(@"接收到错误");
            [subscriber sendError:nil];
        }
        i++;
        
        return nil;
        
    }] retry] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    } error:^(NSError *error) {
        
    }];
    /*
     输出：
     2016-05-18 17:07:27.494 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.522 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.523 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.523 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.523 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.524 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.524 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.525 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.525 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.525 ReactiveCocoaTest1[5695:293689] 接收到错误
     2016-05-18 17:07:27.525 ReactiveCocoaTest1[5695:293689] 1
     */
}

-(void)delay
{
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"100"];
        
        return nil;
    }] delay:2] subscribeNext:^(id x) {
        //调用[subscriber sendNext:@"100"] 2秒之后执行这个block
        NSLog(@"%@",x);
    }];
}
-(void)interval
{
    //每隔一秒钟就会发出信号
    [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

-(void)timeout{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"100"];
        return nil;
    }] timeout:1 onScheduler: [RACScheduler currentScheduler]];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    } error:^(NSError *error) {
        
        NSLog(@"1秒后会自动调用");
    }];
}

-(void)doNextdoCompleted
{
    RACSignal *signal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"100"];
        
        [subscriber sendCompleted];
        NSLog(@"发送完毕");
        return nil;
    }] doNext:^(id x) {
        // 执行[subscriber sendNext:@100];之前会调用这个Block
        NSLog(@"doNext%@",x);
    }] doCompleted:^{
        //执行[subscriber sendCompleted];之前调用这个block
        NSLog(@"doCompleted");;
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    /*
     输出：
     2016-05-18 15:42:53.720 ReactiveCocoaTest1[4966:252147] doNext100
     2016-05-18 15:42:53.720 ReactiveCocoaTest1[4966:252147] 100
     2016-05-18 15:42:53.720 ReactiveCocoaTest1[4966:252147] doCompleted
     2016-05-18 15:42:53.720 ReactiveCocoaTest1[4966:252147] 发送完毕
     */
}

-(void)skip
{
    self.textfield1.text = @"12";
    // 跳过第N个信号不接受
    [[self.textfield1.rac_textSignal skip:1] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}



-(void)takeUntil
{
    RACSubject *subject = [RACSubject subject];
    
    [[subject takeUntil:subject] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subject sendNext:@"111"];
    
    [subject sendCompleted];
}

-(void)takeLast
{
    RACSubject *subject = [RACSubject subject];
    //只取最后两次的信号
    [[subject takeLast:2] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subject sendNext:@"123456"];
    [subject sendNext:@"12346"];
    [subject sendNext:@"last1"];
    [subject sendNext:@"last2"];
    [subject sendCompleted];//订阅者必须调用完成
    //输出
    /*
     2016-05-18 15:04:36.700 ReactiveCocoaTest1[3220:219323] last1
     2016-05-18 15:04:36.701 ReactiveCocoaTest1[3220:219323] last2
     */
}
-(void)take
{
    RACSubject *subject = [RACSubject subject];
    //只取前两次的信号
    [[subject take:2] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subject sendNext:@"123456"];
    [subject sendNext:@"12346"];
    [subject sendNext:@"123456"];
    [subject sendNext:@"12346"];
}
-(void)distinctUntilChanged
{
    RACSubject *subject = [RACSubject subject];
    //当上一次的值和这次的值有明显变化的时候就会发出信号，否则会忽略掉
    //一般用来刷新UI界面，当数据有变化的时候才会刷新
    [[subject distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subject sendNext:@"123456"];
    [subject sendNext:@"12346"];
}
-(void)ignore
{
    // 内部调用filter过滤，忽略掉ignore的值
    [[self.textfield1.rac_textSignal ignore:@"123"] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}
-(void)filter
{
    //每次信号发出都会先执行过滤条件判断
    [[self.textfield1.rac_textSignal filter:^BOOL(NSString  *value) {
        // 当条件判断等于YES的时候才会调用订阅的block
        return  value.length>5;
    }] subscribeNext:^(id x) {
        self.loginBtn.enabled = YES;
    } ];
}

-(void)reduce
{
    //reduce:用于信号发出的内容是元组，把信号发出的元组聚合成一个值
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        
        return  nil;
        
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"2"];
        
        return nil;
    }];
    
    // NSArray是遵守这个NSFastEnumeration协议的
    //reduce中的block简介
    //reduceblcok中的参数，有多少信号组合reduceblcok中就有多少参数，每个参数就是之前信号发出的内容,参数顺序和数组中的 参数一一对应
    //reduceblcok的返回值：聚合信号之后的内容
    RACSignal *reducesignal =  [RACSignal combineLatest:@[signalB,signalA] reduce:^id(NSString *str1,NSString *str2){
        return [NSString stringWithFormat:@"%@ --  %@",str1,str2];
    }];
    [reducesignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}


-(void)combineLatestWith
{
    //   combineLatest:将多个信号合并起来，并且拿到各个信号的最新值，必须每个合并的signal最少有过一次sendNext才会触发合并信号
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        
        return  nil;
        
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"2"];
        
        return nil;
    }];
    
    [[signalA combineLatestWith:signalB] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}


-(void)zipWith
{
    // zipWith:把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时候，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        //发送完毕
        //        [subscriber sendCompleted];
        return  nil;
        
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"2"];
        
        return nil;
    }];
    
    //订阅中的数据和zip的顺序相关。
    RACSignal *zipWithsignal = [signalA zipWith:signalB];
    [zipWithsignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

-(void)merge{
    //    merge:把多个信号合并成为一个信号，任何一个信号有值的时候都会被调用
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"signalA发送完信号"];
       
        return  nil;
        
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"signalB发送完信号"];
        
        return nil;
    }];
    
    // 合并信号，任何一个信号发送数据都能在订阅中监听到
    RACSignal *mergesignal = [signalA merge:signalB];
    
    [mergesignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

-(void)then
{
    //then:用于连接两个信号，当第一个信号完成，才会连接then返回的信号
    //then:之前的信号会被忽略掉
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"signalA发送完信号"];
        //发送完毕
        [subscriber sendCompleted];
        return  nil;
        
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"signalB发送完信号"];
        
        return nil;
    }];
    
    RACSignal *thensignal = [signalA then:^RACSignal *{
        return signalB;
    }];
    
    [thensignal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}
-(void)concat
{
    //concat:按照一定顺序拼接信号，当多个信号发出的时候有顺序的接受信号
    //第一个信号发送完成，第二个信号才会被激活
        RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"signalA发送完信号"];
            //发送完毕
            [subscriber sendCompleted];
            return  nil;
    
        }];
    
        RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"signalB发送完信号"];
    
            return nil;
        }];
    
        [[signalA concat:signalB] subscribeNext:^(id x) {
            NSLog(@"%@",x);
        }];
    
    
    RACSubject *subjectA = [RACSubject subject];
    RACSubject *subjectB = [RACSubject subject];
    
    //把subjectA拼接到subjectB的时候只有subjectA发送完毕之后subjectB才会被激活
    // 只需要订阅拼接之后的信号，不在需要单独拼接subjectA或者subjectB,内部会自动订阅
    [[subjectA concat:subjectB] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subjectA sendNext:@"subjectA发送完信号"];
    // 第一个信号发送完成，第二个信号才会被激活
    [subjectA sendCompleted];
    [subjectB sendNext:@"subjectB发送完信号"];
}

-(void)flattenMap2{
    
    //  flattenMap  用于信号中的信号
    
    
    [[self.textfield.rac_textSignal flattenMap:^RACStream *(id value) {
        //这个block什么时候调用：原信号发送数据的时候就会调用这个block
        //block的作用：改变原信号的内容
        return [RACReturnSignal return:value];
    }] subscribeNext:^(id x) {
        // 订阅绑定信号，每当原信号发送内容，做完处理就会调用这个block
        NSLog(@"%@",x);
    }];
    
    
    // 创建信号
    // 信号中的信号
    RACSubject *signalofsignal = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    // 一
    //    [signalofsignal subscribeNext:^(RACSignal *x) {
    //        [x subscribeNext:^(id x) {
    //            NSLog(@"%@",x);
    //        }];
    //    }];
    
    // 二
    // 取到发送的最后的信号
    //    [signalofsignal.switchToLatest subscribeNext:^(id x) {
    //         NSLog(@"%@",x);
    //    }];
    
    //三用于信号中的信号 直接返回信号然后直接订阅
    [[signalofsignal flattenMap:^RACStream *(id value) {
        return value;
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [signalofsignal sendNext:signal];
    [signal sendNext:@100];
}

/**
 *  底层是flattenMap
 */
-(void)map{
    // 创建信号
    RACSubject *subject = [RACSubject subject];
    
    RACSignal *signal = [subject map:^id(id value) {
        value  = @([value floatValue] +1.0);
        return value;
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    [subject sendNext:@"999"];
}

/**
 *  底层依然是bind
 */
-(void)flattenMap
{
    
  //  flattenMap  用于信号中的信号
    // 创建信号
    RACSubject *subject = [RACSubject subject];
    
    // 绑定信号
    RACSignal *signal  = [subject flattenMap:^RACStream *(id value) {
        // value 就是原信号发送的内容
        // 返回信号用来包装修改内容的值
        return [RACReturnSignal return:value];
    }];
    
    // flattenMap返回的是什么信号，订阅的就是什么信号
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    // 原信号发送数据
    [subject sendNext:@100];
}


-(void)bind2
{
    // 方式一:在返回结果后，拼接。
    [_textfield.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"输出:%@",x);
    }];
    
    // 方式二:在返回结果前，拼接，使用RAC中bind方法做处理。
    // bind方法参数:需要传入一个返回值是RACStreamBindBlock的block参数
    // RACStreamBindBlock是一个block的类型，返回值是信号，参数（value,stop），因此参数的block返回值也是一个block。
    
    // RACStreamBindBlock:
    // 参数一(value):表示接收到信号的原始值，还没做处理
    // 参数二(*stop):用来控制绑定Block，如果*stop = yes,那么就会结束绑定。
    // 返回值：信号，做好处理，在通过这个信号返回出去，一般使用RACReturnSignal,需要手动导入头文件RACReturnSignal.h。
    
    // bind方法使用步骤:
    // 1.传入一个返回值RACStreamBindBlock的block。
    // 2.描述一个RACStreamBindBlock类型的bindBlock作为block的返回值。
    // 3.描述一个返回结果的信号，作为bindBlock的返回值。
    // 注意：在bindBlock中做信号结果的处理。
    
    // 底层实现:
    // 1.源信号调用bind,会重新创建一个绑定信号。
    // 2.当绑定信号被订阅，就会调用绑定信号中的didSubscribe，生成一个bindingBlock。
    // 3.当源信号有内容发出，就会把内容传递到bindingBlock处理，调用bindingBlock(value,stop)
    // 4.调用bindingBlock(value,stop)，会返回一个内容处理完成的信号（RACReturnSignal）。
    // 5.订阅RACReturnSignal，就会拿到绑定信号的订阅者，把处理完成的信号内容发送出来。
    
    // 注意:不同订阅者，保存不同的nextBlock，看源码的时候，一定要看清楚订阅者是哪个。
    // 这里需要手动导入#import <ReactiveCocoa/RACReturnSignal.h>，才能使用RACReturnSignal。
    
    [[_textfield.rac_textSignal bind:^RACStreamBindBlock{
        // 什么时候调用:
        // block作用:表示绑定了一个信号.
        return ^RACStream *(id value, BOOL *stop){
            // 什么时候调用block:当信号有新的值发出，就会来到这个block。
            // block作用:做返回值的处理
            // 做好处理，通过信号返回出去.
            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        };
    }] subscribeNext:^(id x) {
        NSLog(@"%@",x);
        
    }];
}
-(void)bind
{
    
    
    // 创建信号
    RACSubject *subject = [RACSubject subject];
    // 绑定信号，只有绑定的 信号被订阅就会被调用
    // bind 返回一个绑定信号
    RACSignal  *bindsignal =  [subject bind:^RACStreamBindBlock{
        
        
        return ^RACSignal *(id value, BOOL *stop){
            // block调用:只要原信号发送数据,就会调用block
            // block作用:处理原信号内容
            // value:原信号发送的内容
            
            NSLog(@"接收到原信号的内容%@",value);
            // 返回信号,不能传nil,返回空信号[RACSignal empty]
            value = @"程倩";
            return [RACReturnSignal return:value];
        };
        
    }];
    
    [bindsignal subscribeNext:^(id x) {
        NSLog(@"接收到绑定信号处理完的内容%@",x);
    }];
    
    // 原型号发送数据
    [subject sendNext:@"123"];
}
-(void)executing
{
    RACCommand *command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        NSLog(@"执行命令传入参数%@",input);
        
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            [subscriber sendNext:@"执行命令产生数据"];
            // 发送完成
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    
    // 监听任务是否执行完成
    [command.executing subscribeNext:^(id x) {
        if([x boolValue]==YES)
        {
            NSLog(@"当前任务正在执行");
        }else{
            NSLog(@"当前任务执行没有在执行");
        }
    }];
    
    [command execute:@0];
}

-(void)switchToLatest2
{
    // 创建信号中信号
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signalA = [RACSubject subject];
    RACSubject *signalB = [RACSubject subject];
    
    // switchToLatest:获取信号中信号发送的最新信号
    [signalOfSignals.switchToLatest subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    // 发送信号
    [signalOfSignals sendNext:signalB];
    
    [signalA sendNext:@1];
    [signalB sendNext:@"BB"];
    [signalA sendNext:@"11"];
}

-(void)switchToLatest
{
    // 创建命令
    RACCommand *command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        // 当前block执行命令的时候调用
        // input 执行命令传入参数
        NSLog(@"%@",input);
        return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"执行命令产生数据"];
            return nil;
        }];
    }];
    //switchToLatest获取最新发送的信号,只能用于信号中信号
    // 获取到信号后直接订阅
    [command.executionSignals.switchToLatest subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    [command execute:@100];
}

-(void)executionSignals
{
    // 创建命令
    RACCommand *command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        // 当前block执行命令的时候调用
        // input 执行命令传入参数
        NSLog(@"%@",input);
        return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"执行命令产生数据"];
            return nil;
        }];
    }];
    //executionSignals:信号中的信号,发送的数据就是信号
    // 订阅信号,必须要在执行命令之前订阅
    [command.executionSignals subscribeNext:^(RACSignal *x) {
        [x subscribeNext:^(id x) {
            NSLog(@"%@",x);
        }];
    }];
    [command execute:@100];
}

-(void)command
{
    // RACCommand:处理事件
    // RACCommand:不能返回一个空的信号，会闪退
    // 创建命令
    RACCommand *command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        // 当前block执行命令的时候调用
        // input 执行命令传入参数
        NSLog(@"%@",input);
        return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"执行命令产生数据"];
            return nil;
        }];
    }];
    // 如果要拿到执行命令产生的数据，执行命令返回一个信号，直接订阅信号
    RACSignal *signal =  [command execute:@1];
    // 订阅信号
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}
-(void)racmulticastConnection2
{
    // RACMulticastConnection使用步骤:
    // 1.创建信号 + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe
    // 2.创建连接 RACMulticastConnection *connect = [signal publish];
    // 3.订阅信号,注意：订阅的不在是之前的信号，而是连接的信号。 [connect.signal subscribeNext:nextBlock]
    // 4.连接 [connect connect]
    
    // RACMulticastConnection底层原理:
    // 1.创建connect，connect.sourceSignal -> RACSignal(原始信号)  connect.signal -> RACSubject
    // 2.订阅connect.signal，会调用RACSubject的subscribeNext，创建订阅者，而且把订阅者保存起来，不会执行block。
    // 3.[connect connect]内部会订阅RACSignal(原始信号)，并且订阅者是RACSubject
    // 3.1.订阅原始信号，就会调用原始信号中的didSubscribe
    // 3.2 didSubscribe，拿到订阅者调用sendNext，其实是调用RACSubject的sendNext
    // 4.RACSubject的sendNext,会遍历RACSubject所有订阅者发送信号。
    // 4.1 因为刚刚第二步，都是在订阅RACSubject，因此会拿到第二步所有的订阅者，调用他们的nextBlock
    
    
    // 需求：假设在一个信号中发送请求，每次订阅一次都会发送请求，这样就会导致多次请求。
    // 解决：使用RACMulticastConnection就能解决.
    
    // RACMulticastConnection:解决重复请求问题
    // 1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"发送请求");
        [subscriber sendNext:@1];
        return nil;
    }];
    
    // 2.创建连接
    RACMulticastConnection *connect = [signal publish];
    
    // 3.订阅信号，
    // 注意：订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过连接,当调用连接，就会一次性调用所有订阅者的sendNext:
    [connect.signal subscribeNext:^(id x) {
        NSLog(@"订阅者一信号");
    }];
    [connect.signal subscribeNext:^(id x) {
        NSLog(@"订阅者二信号");
    }];
    // 4.连接,激活信号
    [connect connect];
}
-(void)racmulticastConnection
{
    // 创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"发送请求热门数据");
        [subscriber sendNext:@100];
        return nil;
    }];
    // 把信号转换为连接类
    RACMulticastConnection *connection = [signal publish];
    
    // 订阅连接类信号  connection.sourceSignal =创建的信号
    // po connection.signal
    // <RACSubject: 0x7f99726072d0> name:
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者1：%@",x);
    }];
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者2：%@",x);
    }];
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者3：%@",x);
    }];
    // 连接
    [connection connect];
}
-(void)test4
{
    self.label = [[UILabel alloc]init];
    self.textfield = [[UITextField alloc]init];
    self.textfield.frame = CGRectMake(100, 100, 200, 30);
    
    [self.view addSubview:self.textfield];
    
    // 只要文本框中的文字改变就会修改lable中的文字
    RAC(self.label,text) = self.textfield.rac_textSignal;
    [self.textfield.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"%@",self.label.text);
    }];
    
    //RACObserve 监听某个对象的某个值，返回的是一个信号，其实就是ac_valuesForKeyPath函数
    [RACObserve(self, name) subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    // 把参数中的数据包装成元组
    RACTuple *tuple = RACTuplePack(@"xmg",@20);
    // 解包元组，会把元组的值，按顺序给参数里面的变量赋值
    // name = @"xmg" age = @20
    RACTupleUnpack(NSString *name,NSNumber *age) = tuple;
}
// 更新UI
- (void)updateUIWithR1:(id)data r2:(id)data1
{
    NSLog(@"更新UI%@  %@",data,data1);
}

-(void)test3
{
    //rac_signalForSelector：将某个select转换为一个信号，然后订阅这个信号，系统调用这个函数的时候会发出信号
    // 可以用来代替代理(但是不能传值)如果想传值使用RACSubject
    [[self rac_signalForSelector:@selector(didReceiveMemoryWarning)] subscribeNext:^(id x) {
        NSLog(@"系统调用了didReceiveMemoryWarning函数");
    }];
    
    
    // 代替KVO监听属性的改变这个函数需要导入NSObject+RACKVOWrapper.h头文件，这个文件默认没有导入
    [self rac_observeKeyPath:@"name" options:NSKeyValueObservingOptionNew observer:nil block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
        
        NSLog(@"rac_observeKeyPath监听到值改变了");
        
    }];
    //也可以将值改变转换为一个信号 然后订阅这个信号
    [[self rac_valuesForKeyPath:@"name" observer:nil] subscribeNext:^(id x) {
        NSLog(@"rac_valuesForKeyPath监听到值改变了");
    }];
    
    
    //监听按钮点击事件，返回一个信号，然后直接订阅这个信号
    [[self.button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        NSLog(@"按钮被点击了");
    }];
    
    // 代替通知中心
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"通知名称" object:nil] subscribeNext:^(id x) {
        NSLog(@"收到通知");
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"通知名称" object:nil];
    
    
    self.textfield = [[UITextField alloc]init];
    self.textfield.frame = CGRectMake(100, 100, 200, 30);
    [self.view addSubview:self.textfield];
    
    
    // 监听文本框值的改变
    [[self.textfield rac_textSignal] subscribeNext:^(id x) {
        NSLog(@"%@",x);//x是文本框中的值
    }];
    
    // 6.处理多个请求，都返回结果的时候，统一做处理.
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求1
        [subscriber sendNext:@"发送请求1"];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求2
        [subscriber sendNext:@"发送请求2"];
        return nil;
    }];
    // 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据。
    [self rac_liftSelector:@selector(updateUIWithR1:r2:) withSignalsFromArray:@[request1,request2]];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    self.name = @"程倩";
    
    
    
    self.textfield.text = @"文本框中的值改变了";
    
}

-(void)test2{
    NSDictionary *dict = @{@"name":@"程倩",@"age":@"26",@"sex":@"男"};
    // 遍历字典
    [dict.rac_sequence.signal subscribeNext:^(RACTuple *x) {
        
        // RACTupleUnpack  相当于 NSString *key = x[0];
        //                       NSString *value = x[1];
        RACTupleUnpack_(NSString *key,NSString *value) = x;
        NSLog(@"%@  %@",key,value);
        
    }];
}
-(void)enumdict{
    NSDictionary *dict = @{@"name":@"程倩",@"age":@"26",@"sex":@"男"};
    
    
    // 遍历字典
    [dict.rac_sequence.signal subscribeNext:^(RACTuple *x) {
        
                NSString *key = x[0];
                NSString *value = x[1];
        
        
//        RACTupleUnpack(NSString *key,NSString *value) = x;
        NSLog(@"%@  %@",key,value);
        
    }];
}

-(void)test
{
    NSMutableArray *mutablearray = [NSMutableArray array];
    
    for(int i=0;i<1000;i++)
    {
        [mutablearray addObject:@(i)];
    }
    
    
    
    
    NSDate *date = [NSDate date];
    
    double oldtime =  date.timeIntervalSince1970*1000;
    // 将数组转换层一个元组 RACTuple
    RACTuple *tuple = [RACTuple tupleWithObjectsFromArray:mutablearray];
    //可以链式调用
    [tuple.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"rac输出%@",x);
    }];
    
    double newtime =  date.timeIntervalSince1970*1000;
    NSLog(@"rac用的时间%f",newtime-oldtime);
    
    double oldtime1 =  date.timeIntervalSince1970*1000;
    for(int i=0;i<mutablearray.count;i++)
    {
        NSLog(@"%@",mutablearray[i]);
    }
    
    double newtime1 =  date.timeIntervalSince1970*1000;
    NSLog(@"自己循环用的时间%f",newtime1-oldtime1);
}

-(void)tuple
{
    // 将数组转换层一个元组 RACTuple
    RACTuple *tuple = [RACTuple tupleWithObjectsFromArray:@[@"1",@"2",@3,@4,@5]];
    // 将元组转换为rac中的集合类RACSequence
    RACSequence *sequence = tuple.rac_sequence;
    // 在将集合类(RACSequence)转换为信号(RACSignal)
    RACSignal *signal =  sequence.signal;
    // 订阅信号，激活信号，会自动把集合中的所有值，遍历出来
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    //可以链式调用
    [tuple.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
}

-(void)racreplaySubject
{
    RACReplaySubject *subjest = [RACReplaySubject subject];
    
    //2.调用subscribeNext订阅信号，遍历保存的所有值，一个一个调用订阅者的nextBlock
    RACDisposable *posable1 = [subjest subscribeNext:^(id x) {
        NSLog(@"第一个订阅者%@",x);
    }];
    
    RACDisposable *posable2 = [subjest subscribeNext:^(id x) {
        NSLog(@"第二个订阅者%@",x);
    }];
    //调用sendNext发送信号，把值保存起来，然后遍历刚刚保存的所有订阅者，一个一个调用订阅者的nextBlock
    [subjest sendNext:@100];
    [posable1 dispose];// 取消订阅
    
    [subjest sendNext:@120];
}
-(void)racsubject{
    // 1.创建信号 [RACSubject subject]，跟RACSiganl不一样，创建信号时没有block
    RACSubject *subject = [RACSubject subject];
    
    
    // 2.订阅信号 - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock
    // 返回的是订阅者
    RACDisposable *posable1 =  [subject subscribeNext:^(id x) {
        NSLog(@"第一个订阅者%@",x);
    }];
    RACDisposable *posable2 = [subject subscribeNext:^(id x) {
        NSLog(@"第二个订阅者%@",x);
    }];
    
    // RACSubject:底层实现和RACSignal不一样。
    // 1.调用subscribeNext订阅信号，只是把订阅者保存起来，并且订阅者的nextBlock已经赋值了。
    // 2.调用sendNext发送信号，遍历刚刚保存的所有订阅者，一个一个调用订阅者的nextBlock。
    
    //3.发送信号 sendNext:(id)value
    [subject sendNext:@100];
    [posable1 dispose];// 取消订阅信号
    [subject sendNext:@100];
    
    
}

-(void)racsignal{
        //  1.创建信号
      RACSignal *racsignal =  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          // 3.发送信号
          [subscriber sendNext:@100];
    
          // 订阅者subscriber不会被销毁永远不会取消订阅(在不主动取消的情况下)
          _subscriber = subscriber;
          self.disposable = [RACDisposable disposableWithBlock:^{
              NSLog(@"信号被取消订阅");
          }];
          return self.disposable;
      }];
        //  2.订阅信号 subscribeNext在函数内部创建订阅者
         [racsignal subscribeNext:^(id x) {
             NSLog(@"%@",x);
         }];
        
        // 取消订阅
        [self.disposable dispose];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
