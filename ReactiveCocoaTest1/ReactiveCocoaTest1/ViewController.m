//
//  ViewController.m
//  ReactiveCocoaTest1
//
//  Created by 程倩 on 16/5/12.
//  Copyright © 2016年 CQ. All rights reserved.
//

#import "ViewController.h"
#import "Header.h"
#import "NSObject+RACKVOWrapper.h"
#import "RACReturnSignal.h"
@interface ViewController ()
@property(nonatomic,strong)id<RACSubscriber> subscriber;
@property(nonatomic,strong)RACDisposable *disposable;

@property(nonatomic,strong)UIButton *button;
@property(nonatomic,strong)UILabel *label;
@property(nonatomic,strong)UITextField *textfield;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
 
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
