//
//  ViewController.swift
//  RxDemoSelf
//
//  Created by PomCat on 2019/7/18.
//  PomCat
//
/*
 
 RXSwift源码浅析(一)
 https://juejin.im/post/5a355ab15188252bca04f0fd#heading-25
 
 RXSwift源码浅析(二)
 https://juejin.im/post/5a38d34ff265da430d582355
 
 RxSwift 的概念
 https://zhang759740844.github.io/2017/10/26/RxSwift%E4%B8%80%E4%BA%9B%E6%A6%82%E5%BF%B5/
 https://zhang759740844.github.io/2017/11/14/RxSwift%E5%8E%9F%E7%90%86/
 https://zhang759740844.github.io/2017/11/03/RxCocoa%E5%BA%94%E7%94%A8/ // cocoa
 
 官方文档
 https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/more_demo/calculator.html
 */
import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        
        let type = UIViewController.rx
        print(type)
        
        let vc = UIViewController()
//        vc.rx
        
        ObservablesDemo()
//        SubjectsDemo()
//        operatorsBeforeDoDemo()
//        operatorsAfterDoDemo()
//        operatorsToSome()
//        actionHappen()
    }
    
    func ObservablesDemo() {
        //        let observable = Observable<Int>.just(1)
        //        let observable2 = Observable.of(1, 2, 3)
        //        let observable3 = Observable.from([1, 2, 3])
        //        let observable4 = Observable<Void>.empty()
        //        let observable5 = Observable<Any>.never()
        
        // 通过create创建一个可观察序列
        let observable = Observable<String>.create { observer in
            
            // 实际使用：这里可以是异步发起一个请求，然后请求回来之后发出一些信号。比如请求错误，请求返回json.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // your code here
                observer.onNext("1")
                
                observer.onNext("121")
                
                observer.onCompleted()
                
                observer.onNext("???")
            }
            
            return Disposables.create()
        }
        
        
        let ob = observable.subscribe(onNext: { (element) in
            print("Hi \(element)")
        }, onError: { (error) in
            print("error")
        }, onCompleted: {
            print("finish")
        })
        
        ob.disposed(by: disposeBag)
    }
    
    func SubjectsDemo() {
        
        // 订阅后接受事件
        func PublishSubject1() {
            let disposeBag = DisposeBag()
            // 创建 PublishSubject
            let subject = PublishSubject<Int>()
            // 订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: disposeBag)
            // 发送事件
            subject.onNext(1)                            //1
            // 结束订阅
            subject.onCompleted()                        //completed
            // 再次订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: disposeBag)            //completed
            // 发送事件
            subject.onNext(2)
        }
        
        // 有初始值的subject
        func BehaviorSubjects1() {
            let bag = DisposeBag()
            // 创建 BehaviorSubject
            let subject = BehaviorSubject(value: "Initial value")
            // 订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: bag)                    // Initial Value
            // 发送事件
            subject.onNext("X")                            // X
            // 错误事件
            subject.onError(MyError.anError)            // anError
            // 再次订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: bag)                    // anError
            // 发送事件。
            subject.onNext("X") // 订阅接收到errorb之后，就不再接收信息。
        }
        
        // 有一定的缓存信息。此处设置缓存大小为2.
        func ReplaySubjects1() {
            let bag = DisposeBag()
            // 创建 ReplaySubject
            let subject = ReplaySubject<String>.create(bufferSize: 2)
            // 发送事件
            subject.onNext("1")
            subject.onNext("2")
            // 订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: bag)                // 1    2
            // 发送错误
            subject.onError(MyError.annError)        // annError
            // 再次订阅
            subject.subscribe { print($0.element ?? $0) }
                .disposed(by: bag)                // 1    2    annError
            // 发送事件
            subject.onNext("3")                        // 没有任何反应
        }
        
        
        PublishSubject1()
//        BehaviorSubjects1()
//        ReplaySubjects1()
    }
    
    // 接受某个事件之前的所有事件，之后的都不接受。
    func operatorsBeforeDoDemo() {
        let bag = DisposeBag()
        func takeDemo() {
            Observable.of(1, 2, 3, 4, 5)
                .take(2)
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        // 取到某个不满足条件的事件
        func takeWhileDemo() {
            Observable.of(2, 2, 1, 4, 5)
                .enumerated().takeWhile{i,v in
                    print("this v:",v)
                    // 只有前两个是满足的，第三个不满足。complete
                    return i < 2
                }.subscribe {
                    print($0.element ?? $0)
                    print("good")
                }
                .disposed(by: bag)
        }
        
        func takeUntilDemo() {
            let subject = PublishSubject<String>()
            let trigger = PublishSubject<String>()
            
            subject.takeUntil(trigger)
                .subscribe { print($0.element ?? $0 )}
                .disposed(by: bag)
            // ... 此时一直接受 next 事件
            trigger.onNext("x")
            // ... 现在忽略所有的 next 事件了
        }
        
        // 忽略数值一样的序列
        func distinctUntilChangedDemo() {
            Observable.of(1, 2, 2, 1)
                .distinctUntilChanged()
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        func distinctUntilChangedDemo2() {
            Observable.of(1, 2, 3, 2, 1)
                .distinctUntilChanged { (a:Int, b) in
                    // 1,2 这种情况就被忽略了。
                    if a == 1 && b == 2 {
                        return true
                    }
                    return false
                }.subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }

        
        takeDemo()
//        takeWhileDemo()
//        takeUntilDemo()
//        distinctUntilChangedDemo()
//        distinctUntilChangedDemo2()
    }
    
    func operatorsAfterDoDemo() {
        let bag = DisposeBag()
        
        // 用来忽略所有的 .next 事件。所以用来指接受 completed 事件
        func ignoreElementsDemo() {
            let strikes = PublishSubject<String>()
            
            strikes.ignoreElements()
                .subscribe{_ in print("You are out")}
                .disposed(by: bag)
            
            strikes.onNext("2")
        }
        
        // 获取索引序号的事件，忽略其他的所有 .next.从0开始。
        func elementAtDemo() {
            let strikes = PublishSubject<String>()
            
            strikes.elementAt(1)
                .subscribe{ element in print("this element:\(element)")}
                .disposed(by: bag)
            
            strikes.onNext("this 0")
            strikes.onNext("this 1")
            strikes.onNext("this 2")
            strikes.onNext("this 3")
            /*
             this element:next(this 1)
             this element:completed
             */
        }
        
        func filterDemo() {
            Observable.of(1, 2, 3, 4, 5)
                .filter { $0 % 2 == 0}
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
            // 2 4
        }
        
        func skipDemo() {
            Observable.of(1, 2, 3, 4, 5)
                .skip(2)
                .subscribe { print($0.element ?? $0)}
                .disposed(by: bag)
            // 3,4,5
        }
        
        // skipWhile 遍历数据，直到为否
        func skipWhileDemo() {
            Observable.of(3, 5, 7, 4, 5)
                .skipWhile({ (number: Int) -> Bool in
                    print("look look :",number)
                    return number % 2 == 1
                    // 一旦为否，跳出循环。
                })
                .subscribe { print($0.element ?? $0)}
                .disposed(by: bag)
            /*
             look look : 3
             look look : 5
             look look : 7
             look look : 4
             4
             5
             completed
             */
        }
        
        // 直到trigger有信号，subject才接受信号。
        func skipUntilDemo() {
            let subject = PublishSubject<String>()
            let trigger = PublishSubject<String>()
            
            subject.skipUntil(trigger)
                .subscribe { print( $0.element ?? $0) }
                .disposed(by: bag)
            // ... 当前时刻虽然订阅了，但是发送事件是无反应的
            subject.onNext("this 1")
            subject.onNext("this 2")
            trigger.onNext("a")
            subject.onNext("this 3")
        }
        
//        ignoreElementsDemo()
//        elementAtDemo()
//        filterDemo()
//        skipDemo()
//        skipWhileDemo()
        skipUntilDemo()
        

    }
    
    func operatorsToSome() {
        let bag = DisposeBag()
        
        // 序列成组输出
        func toArrayDemo() {
            Observable.of("A", "B", "C")
                .toArray()
                .subscribe({ print($0) })
                .disposed(by: bag)                    // ["A", "B", "c"]
        }
        
        func mapDemo() {
            Observable.of(1, 2, 3)
                .map{ $0 * 2}
                .subscribe{ print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        //MARK: TODO这个还是不太懂
        func flatMapDemo() {
            // https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/flatMap.html
            let first = BehaviorSubject(value: "👦🏻")
            let second = BehaviorSubject(value: "🅰️")
            let variable = Variable(first)
            
            variable.asObservable()
//                .flatMap({ (subj)  in
//                    print(subj)
//                    return subj
//                })
                .flatMap { $0 }
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
            
            first.onNext("🐱")
            variable.value = second
            second.onNext("🅱️")
            first.onNext("🐶")
        }
        
        // 插入新的元素，返回新的Observable
        func startWithDemo() {
            let numbers = Observable.of(2, 3, 4)
            let observable = numbers.startWith(1)
            observable.subscribe{ print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        // 内部的时间序列都 completed 后，merge 产生的事件序列才会 completed
        func mergeDemo() {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            // 将两个事件序列作为事件值
            let source = Observable.of(left.asObservable(), right.asObservable())
            // 将新的事件序列的元素合并，返回一个新的事件序列
            let observable = source.merge()
            
            observable.subscribe{ print($0.element ?? $0) }
                .disposed(by: bag)
            
            left.onNext("this l1")
            left.onNext("this l2")
            right.onNext("this r1")
            left.onNext("this l3")
            right.onNext("this r2")
            left.onCompleted()
            right.onNext("this r3")
            right.onCompleted()
        }
        
        // 每有一个信号，合并两个源的最新状态。
        func combineLatestDemo() {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            let observable = Observable.combineLatest(left, right, resultSelector: {
                lastLeft, lastRight in
                "\(lastLeft) \(lastRight)"
            })
            observable.subscribe(onNext: { value in
                print(value)
            }).disposed(by: bag)
            
            left.onNext("this l1")
            left.onNext("this l2")
            right.onNext("this r1")
            left.onNext("this l3")
            right.onNext("this r2")
            left.onCompleted()
            right.onNext("this r3")
            right.onNext("this r4") // 这个时候left已经结束，就用的left最后一个值。l3
            right.onCompleted()
        }
        
        // 和上面的 combineLatest 不同，zip 要求必须每个子序列都有新消息的时候，才触发事件。
        func zipDemo() {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            let observable = Observable.zip(left, right) {
                lastLeft, lastRight in
                "\(lastLeft) \(lastRight)"
            }
            
            observable.subscribe(onNext: { value in
            print(value)
            }).disposed(by: bag)
            
            left.onNext("this l1")
            left.onNext("this l2")
            right.onNext("this r1")
            left.onNext("this l3")
            right.onNext("this r2")
            left.onCompleted()
            right.onNext("this r3")
            right.onNext("this r4") // 这个时候left已经结束，r4永远不会匹配。
            right.onCompleted()
        }
        
//        toArrayDemo()
//        mapDemo()
        flatMapDemo()
//        startWithDemo()
//        mergeDemo()
//        combineLatestDemo()
//        zipDemo()
    }
    
    func actionHappen() {
        let bag = DisposeBag()
        
        // 点击按钮后，获取textField最新的字符串。
        func withLatestFromDemo() {
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
            
            button.withLatestFrom(textField)
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        // Observable 没有更新值，那么不会触发事件，类似于 distinctUntilChanged
        func simpleDemo() {
            let button = PublishSubject<Void>()
            let textField = PublishSubject<String>()
            let Observable = textField.sample(button)
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }
        Void()
        // 最先触发就一直订阅哪一个。会自动取消订阅另一个。
        func ambDemo() {
            let left = PublishSubject<String>()
            let right = PublishSubject<String>()
            
            left.amb(right)
                .subscribe { print($0.element ?? $0) }
                .disposed(by: bag)
        }
        
        // 手动去订阅其他信号源。
        func switchLatestDemo() {
            let one = PublishSubject<String>()
            let two = PublishSubject<String>()
            let three = PublishSubject<String>()
            
            // source 的事件值类型是 Observable 类型
            let source = PublishSubject<Observable<String>>()
            
            let observable = source.switchLatest()
            let disposable = observable.subscribe(onNext: { value in print(value) })
            
            // 选择Observable one
            source.onNext(one)
            one.onNext("emit one")                 // emit
            two.onNext("emit two")                // 没有 emit
            // 选择Observable two
            source.onNext(two)
            two.onNext("emit two")                // emit
        }
        
        // 一串序列经过计算，最后返回一个值
        func reduceDemo() {
            Observable.of(1, 2, 3)
                .reduce(10) { summary, newValue in
                    return summary + newValue
                }.subscribe { print($0.element ?? "OK") }
                .disposed(by: bag)
        }
        
        // scan 和 reduce 的不同在于，reduce 是一锤子买卖，scan 每次接收到事件值时都会触发一个事件：
        func scanDemo() {
            Observable.of(1, 2, 3)
                .scan(0, accumulator: +)
                .subscribe(onNext: { value in print(value) })
                .disposed(by: bag)
        }
        
        // 假设replay值为2，有新的订阅者订阅时，会立即触发最近的3个事件。缓存了2个信号。
        func replayDemo() {
            let interval = Observable<Int>.interval(1,
                                                    scheduler:MainScheduler.instance).replay(2)
            
            _ = interval.connect()
            
            let d = Date()
            print("Subscriber 2: start - at \(d)")
            // (2,3) 4 5 ...
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                _ = interval.subscribe(onNext: {
                    let d = Date()
                    print("Subscriber 2: Event - \($0) at \(d)")
                })
            }
            /*
             Subscriber 2: start - at 2019-07-19 09:32:44 +0000
             Subscriber 2: Event - 2 at 2019-07-19 09:32:49 +0000 // 缓存的
             Subscriber 2: Event - 3 at 2019-07-19 09:32:49 +0000 // 缓存的
             Subscriber 2: Event - 4 at 2019-07-19 09:32:49 +0000 // 新的信号
             Subscriber 2: Event - 5 at 2019-07-19 09:32:50 +0000
             Subscriber 2: Event - 6 at 2019-07-19 09:32:51 +0000
             */
            
        }
        
//        buffer 时间和数量，其中一个条件满足，就发送数组信号。
        func bufferDemo() {
            let subject = PublishSubject<String>()
            
            //每缓存3个元素则组合起来一起发出。
            //如果1秒钟内不够3个也会发出（有几个发几个，一个都没有发空数组 []）
            subject
                .buffer(timeSpan: 1.0, count: 3, scheduler: MainScheduler.instance)
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
            
            subject.onNext("a")
            subject.onNext("b")
            subject.onNext("c")
            
            subject.onNext("1")
            subject.onNext("2")
            subject.onNext("3")
        }
        
        // 延时订阅
        func delaySubscriptionDemo() {
            Observable.of(1, 2, 1)
                .delaySubscription(3, scheduler: MainScheduler.instance) //延迟3秒才开始订阅
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)
        }
        
        // 将序列中的所有事件延迟执行，所以并不会忽略掉事件
        func delayDemo() {
            Observable.of(1, 2, 3, 4, 5)
                .delay(1, scheduler: MainScheduler.instance)
                .subscribe{ print($0.element ?? $0) }
        }
        
        // 一直重复
        func intervalDemo() {
//            Observable<Int>.interval(2, scheduler: MainScheduler.instance)
//                .subscribe{ print("do it") }
//                .disposed(by: bag)
            
            let scheduler = SerialDispatchQueueScheduler(qos: .default)
            let subscription = Observable<Int>.interval(.milliseconds(300), scheduler: scheduler)
                .subscribe { event in
                    print(event)
                    print("\(Thread.current)")
            }
            
            // 主线程3秒之后把订阅关掉
            Thread.sleep(forTimeInterval: 3.0)
            subscription.dispose()
        }
        
        // 可以设置重复值
        func timerDemo() {
            print("\(Date.init())")
            let scheduler = SerialDispatchQueueScheduler(qos: .default)
            let subscription = Observable<Int>.timer(.seconds(3), period:.seconds(3), scheduler: scheduler).subscribe { event in
                print(event)
                print("\(Date.init())")
            }
            // 主线程3秒之后把订阅关掉
            Thread.sleep(forTimeInterval: 10.0)
            subscription.dispose()
        }

//        switchLatestDemo()
//        reduceDemo()
//        replayDemo()
        bufferDemo()
//        delaySubscriptionDemo()
//        delayDemo()
//        intervalDemo()
        
//        timerDemo()
    }
}



enum MyError: Error {
    case anError
    case annError
    case level1Error
    case level2Error
    case level3Error
}
