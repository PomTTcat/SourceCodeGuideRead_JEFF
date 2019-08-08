//
//  CurrentThreadScheduler.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 8/30/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import class Foundation.NSObject
import protocol Foundation.NSCopying
import class Foundation.Thread
import Dispatch

#if os(Linux)
    import struct Foundation.pthread_key_t
    import func Foundation.pthread_setspecific
    import func Foundation.pthread_getspecific
    import func Foundation.pthread_key_create
    
    fileprivate enum CurrentThreadSchedulerQueueKey {
        fileprivate static let instance = "RxSwift.CurrentThreadScheduler.Queue"
    }
#else
    private class CurrentThreadSchedulerQueueKey: NSObject, NSCopying {
        static let instance = CurrentThreadSchedulerQueueKey()
        private override init() {
            super.init()
        }

        override var hash: Int {
            return 0
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            return self
        }
    }
#endif

/// Represents an object that schedules units of work on the current thread.
///
/// This is the default scheduler for operators that generate elements.
///
/// This scheduler is also sometimes called `trampoline scheduler`.
public class CurrentThreadScheduler : ImmediateSchedulerType {
    typealias ScheduleQueue = RxMutableBox<Queue<ScheduledItemType>>

    /// The singleton instance of the current thread scheduler.
    public static let instance = CurrentThreadScheduler()

    // {()->xx in ... return xx}() 这种格式相当于代码运行后返回了xx类型
    private static var isScheduleRequiredKey: pthread_key_t = { () -> pthread_key_t in
        
        // https://onevcat.com/2015/01/swift-pointer/
        // key是pthread_key_t的指针
        let key = UnsafeMutablePointer<pthread_key_t>.allocate(capacity: 1)
        defer { key.deallocate() }
        
        // https://www.jianshu.com/p/d52c1ebf808a
        // 函数成功返回0。 每pthread_key_create一次，返回的key值都不同。（递增1）
        guard pthread_key_create(key, nil) == 0 else {
            rxFatalError("isScheduleRequired key creation failed")
        }

        // 是个数字，比如这一次是278. 以数字为key。
        return key.pointee
    }()

    // 哨兵指针。
    private static var scheduleInProgressSentinel: UnsafeRawPointer = { () -> UnsafeRawPointer in
        return UnsafeRawPointer(UnsafeMutablePointer<Int>.allocate(capacity: 1))
    }()

    static var queue : ScheduleQueue? {
        get {
            return Thread.getThreadLocalStorageValueForKey(CurrentThreadSchedulerQueueKey.instance)
        }
        set {
            Thread.setThreadLocalStorageValue(newValue, forKey: CurrentThreadSchedulerQueueKey.instance)
        }
    }

    /// Gets a value that indicates whether the caller must call a `schedule` method.
    /// 获取一个值，该值指示调用者是否必须调用`schedule`方法。
    /// isScheduleRequired第一获取是true，第二次肯定是false(手动置fa)。仅仅用来标记，在这个线程是不是第一次操作。
    public static fileprivate(set) var isScheduleRequired: Bool {
        get {
            // 第一次直接获取肯定是true. 因为还没有依据key，去存储值。
            let b = pthread_getspecific(CurrentThreadScheduler.isScheduleRequiredKey) == nil
            return b
        }
        set(isScheduleRequired) {
            // true->nil false->哨兵
            if pthread_setspecific(CurrentThreadScheduler.isScheduleRequiredKey, isScheduleRequired ? nil : scheduleInProgressSentinel) != 0 {
                rxFatalError("pthread_setspecific failed")
            }
            // pthread_setspecific 函数成功返回0.
        }
    }

    /**
    Schedules an action to be executed as soon as possible on current thread.

    If this method is called on some thread that doesn't have `CurrentThreadScheduler` installed, scheduler will be
    automatically installed and uninstalled after all work is performed.

    - parameter state: State passed to the action to be executed.
    - parameter action: Action to be executed.
    - returns: The disposable object used to cancel the scheduled action (best effort).
    */
    public func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        if CurrentThreadScheduler.isScheduleRequired {
            CurrentThreadScheduler.isScheduleRequired = false

            // 这一步里面调用了run闭包。即产生序列（如create）的闭包发生了调用。 （这一般是个异步操作，比如网络请求，IO读取。）
            let disposable = action(state)

            defer {
                CurrentThreadScheduler.isScheduleRequired = true
                CurrentThreadScheduler.queue = nil
            }

            guard let queue = CurrentThreadScheduler.queue else {
                return disposable
            }

            while let latest = queue.value.dequeue() {
                if latest.isDisposed {
                    continue
                }
                latest.invoke()
            }

            return disposable
        }

        let existingQueue = CurrentThreadScheduler.queue

        let queue: RxMutableBox<Queue<ScheduledItemType>>
        if let existingQueue = existingQueue {
            queue = existingQueue
        }
        else {
            queue = RxMutableBox(Queue<ScheduledItemType>(capacity: 1))
            CurrentThreadScheduler.queue = queue
        }

        let scheduledItem = ScheduledItem(action: action, state: state)
        queue.value.enqueue(scheduledItem)

        return scheduledItem
    }
}
