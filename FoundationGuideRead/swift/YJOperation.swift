// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch
import UIKit
import Foundation
import CoreFoundation

internal let _NSOperationIsFinished = "isFinished"
internal let _NSOperationIsFinishedAlternate = "finished"
internal let _NSOperationIsExecuting = "isExecuting"
internal let _NSOperationIsExecutingAlternate = "executing"
internal let _NSOperationIsReady = "isReady"
internal let _NSOperationIsReadyAlternate = "ready"
internal let _NSOperationIsCancelled = "isCancelled"
internal let _NSOperationIsCancelledAlternate = "cancelled"
internal let _NSOperationIsAsynchronous = "isAsynchronous"
internal let _NSOperationQueuePriority = "queuePriority"
internal let _NSOperationThreadPriority = "threadPriority"
internal let _NSOperationCompletionBlock = "completionBlock"
internal let _NSOperationName = "name"
internal let _NSOperationDependencies = "dependencies"
internal let _NSOperationQualityOfService = "qualityOfService"
internal let _NSOperationQueueOperationsKeyPath = "operations"
internal let _NSOperationQueueOperationCountKeyPath = "operationCount"
internal let _NSOperationQueueSuspendedKeyPath = "suspended"

extension QualityOfService {
#if canImport(Darwin)
    internal init(_ qos: qos_class_t) {
        switch qos {
        case QOS_CLASS_DEFAULT: self = .default
        case QOS_CLASS_USER_INTERACTIVE: self = .userInteractive
        case QOS_CLASS_USER_INITIATED: self = .userInitiated
        case QOS_CLASS_UTILITY: self = .utility
        case QOS_CLASS_BACKGROUND: self = .background
        default: fatalError("Unsupported qos")
        }
    }
#endif
    internal var qosClass: DispatchQoS {
        switch self {
        case .userInteractive: return .userInteractive
        case .userInitiated: return .userInitiated
        case .utility: return .utility
        case .background: return .background
        case .default: return .default
        }
    }
}

open class YJOperation : NSObject {
    struct PointerHashedUnmanagedBox<T: AnyObject>: Hashable {
        var contents: Unmanaged<T>
        func hash(into hasher: inout Hasher) {
            hasher.combine(contents.toOpaque())
        }
        static func == (_ lhs: PointerHashedUnmanagedBox, _ rhs: PointerHashedUnmanagedBox) -> Bool {
            return lhs.contents.toOpaque() == rhs.contents.toOpaque()
        }
    }
    enum __NSOperationState : UInt8 {
        case initialized = 0x00
        case enqueuing = 0x48
        case enqueued = 0x50
        case dispatching = 0x88
        case starting = 0xD8
        case executing = 0xE0
        case finishing = 0xF0
        case finished = 0xF4
    }
    
    internal var __previousOperation: Unmanaged<YJOperation>?
    internal var __nextOperation: Unmanaged<YJOperation>?
    internal var __nextPriorityOperation: Unmanaged<YJOperation>?
    internal var __queue: Unmanaged<YJOperationQueue>?
    
    internal var __dependencies = [YJOperation]() // 自己依赖的Operation
    internal var __downDependencies = Set<PointerHashedUnmanagedBox<YJOperation>>() // 依赖自己的Operation
    
    internal var __unfinishedDependencyCount: Int = 0
    internal var __completion: (() -> Void)?
    internal var __name: String?
    internal var __schedule: DispatchWorkItem?
    internal var __state: __NSOperationState = .initialized
    internal var __priorityValue: YJOperation.QueuePriority.RawValue?
    internal var __cachedIsReady: Bool = true
    internal var __isCancelled: Bool = false
    internal var __propertyQoS: QualityOfService?
    
    var __waitCondition = NSCondition()
    var __lock = NSLock()
    var __atomicLoad = NSLock()
    
    internal var _state: __NSOperationState {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __state
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __state = newValue
        }
    }
    
    // if == return yes and update。 if ！= ，return no
    internal func _compareAndSwapState(_ old: __NSOperationState, _ new: __NSOperationState) -> Bool {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        if __state != old { return false }
        __state = new
        return true
    }
    
    internal func _lock() {
        __lock.lock()
    }
    
    internal func _unlock() {
        __lock.unlock()
    }
    
    internal var _queue: YJOperationQueue? {
        _lock()
        defer { _unlock() }
        return __queue?.takeRetainedValue()
    }
    
    internal func _adopt(queue: YJOperationQueue, schedule: DispatchWorkItem) {
        _lock()
        defer { _unlock() }
        __queue = Unmanaged.passRetained(queue)
        __schedule = schedule
    }
    
    internal var _isCancelled: Bool {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        return __isCancelled
    }
    
    internal var _unfinishedDependencyCount: Int {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __unfinishedDependencyCount
        }
    }
    
    internal func _incrementUnfinishedDependencyCount(by amount: Int = 1) {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        __unfinishedDependencyCount += amount
    }
    
    internal func _decrementUnfinishedDependencyCount(by amount: Int = 1) {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        __unfinishedDependencyCount -= amount
    }
    
    // 添加一些依赖自己的op。
    internal func _addParent(_ parent: YJOperation) {
        __downDependencies.insert(PointerHashedUnmanagedBox(contents: .passUnretained(parent)))
    }
    
    internal func _removeParent(_ parent: YJOperation) {
        __downDependencies.remove(PointerHashedUnmanagedBox(contents: .passUnretained(parent)))
    }
    
    internal var _cachedIsReady: Bool {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __cachedIsReady
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __cachedIsReady = newValue
        }
    }
    
    internal func _fetchCachedIsReady(_ retest: inout Bool) -> Bool {
        let setting = _cachedIsReady
        if !setting {
            _lock()
            retest = __unfinishedDependencyCount == 0
            _unlock()
        }
        return setting
    }
    
    internal func _invalidateQueue() {
        _lock()
        __schedule = nil
        let queue = __queue
        __queue = nil
        _unlock()
        queue?.release()
    }
    
    internal func _removeAllDependencies() {
        _lock()
        let deps = __dependencies
        __dependencies.removeAll()
        _unlock()
        
        for dep in deps {
            dep._lock()
            _lock()
            let upIsFinished = dep._state == .finished
            if !upIsFinished && !_isCancelled {
                _decrementUnfinishedDependencyCount()
            }
            dep._removeParent(self)
            _unlock()
            dep._unlock()
        }
    }
    
    internal static func observeValue(forKeyPath keyPath: String, ofObject op: YJOperation) {
        enum Transition {
            case toFinished
            case toExecuting
            case toReady
        }
        
        let kind: Transition?
        if keyPath == _NSOperationIsFinished || keyPath == _NSOperationIsFinishedAlternate {
            kind = .toFinished
        } else if keyPath == _NSOperationIsExecuting || keyPath == _NSOperationIsReadyAlternate {
            kind = .toExecuting
        } else if keyPath == _NSOperationIsReady || keyPath == _NSOperationIsReadyAlternate {
            kind = .toReady
        } else {
            kind = nil
        }
        if let transition = kind {
            switch transition {
            case .toFinished: // we only care about NO -> YES
                if !op.isFinished {
                    return
                }
                
                // 这里就是一些保证 _state 是 finishing。如果是finished，直接退出。
                op._lock()
                let state = op._state
                if op.__queue != nil && state.rawValue < __NSOperationState.starting.rawValue {
                    print("*** \(type(of: op)) \(Unmanaged.passUnretained(op).toOpaque()) went isFinished=YES without being started by the queue it is in")
                }
                if state.rawValue < __NSOperationState.finishing.rawValue {
                    op._state = .finishing
                } else if state == .finished {
                    op._unlock()
                    return
                }
                
                
                // 对所有依赖自己的op，未完成count - 1.
                // 如果本来就是1，说明就等的自己。放到ready_deps里面。
                var ready_deps = [YJOperation]()
                let down_deps = op.__downDependencies
                op.__downDependencies.removeAll()
                if 0 < down_deps.count {
                    for down in down_deps {
                        let idown = down.contents.takeUnretainedValue()
                        idown._lock()
                        if idown._unfinishedDependencyCount == 1 {
                            ready_deps.append(idown)
                        } else if idown._unfinishedDependencyCount > 1 {
                            idown._decrementUnfinishedDependencyCount()
                        } else {
                            assert(idown._unfinishedDependencyCount  == 0)
                            assert(idown._isCancelled == true)
                        }
                        idown._unlock()
                    }
                }
                
                // op彻底结束，收尾工作。
                op._state = .finished
                let opreationQue = op.__queue
                op.__queue = nil
                op._unlock()
                
                // 对 ready_deps 中的op发送信号。可以去执行start了。
                if 0 < ready_deps.count {
                    for down in ready_deps {
                        down._lock()
                        if down._unfinishedDependencyCount >= 1 {
                            down._decrementUnfinishedDependencyCount()
                        }
                        down._unlock()
                        YJOperation.observeValue(forKeyPath: _NSOperationIsReady, ofObject: down)
                    }
                }
                
                // wait until finish 的那些线程，得以解锁。
                op.__waitCondition.lock()
                op.__waitCondition.broadcast()
                op.__waitCondition.unlock()
                if let complete = op.__completion {
                    let held = Unmanaged.passRetained(op)
                    DispatchQueue.global(qos: .default).async {
                        complete()
                        held.release()
                    }
                }
                if let queue = opreationQue {
                    queue.takeUnretainedValue()._operationFinished(op, state)
                    queue.release()
                }
            case .toExecuting:
                let isExecuting = op.isExecuting
                op._lock()
                if op._state.rawValue < __NSOperationState.executing.rawValue && isExecuting {
                    op._state = .executing
                }
                op._unlock()
            case .toReady:
                let r = op.isReady
                op._cachedIsReady = r
                let q = op._queue
                if r {
                    q?._schedule()
                }
            }
        }
    }
    
    public override init() {
    }
    
    // 简单说，执行了main函数，并且发出一些信号
    open func start() {
        let state = _state
        if __NSOperationState.finished == state { return }
        if !_compareAndSwapState(__NSOperationState.initialized, __NSOperationState.starting) && !(__NSOperationState.starting == state && __queue != nil) {
            switch state {
            case .executing: fallthrough
            case .finishing:
                fatalError("\(self): receiver is already executing")
            default:
                fatalError("\(self): something is trying to start the receiver simultaneously from more than one thread")
            }
        }
        
        if state.rawValue < __NSOperationState.enqueued.rawValue && !isReady {
            _state = state
            fatalError("\(self): receiver is not yet ready to execute")
        }
        
        let isCanc = _isCancelled
        if !isCanc {
            _state = .executing
            YJOperation.observeValue(forKeyPath: _NSOperationIsExecuting, ofObject: self)
            
            // _execute 没有找到。所以默认main()
            _queue?._execute(self) ?? main()
        }
        
        if __NSOperationState.executing == _state {
            _state = .finishing
            YJOperation.observeValue(forKeyPath: _NSOperationIsExecuting, ofObject: self)
            YJOperation.observeValue(forKeyPath: _NSOperationIsFinished, ofObject: self)
        } else {
            _state = .finishing
            YJOperation.observeValue(forKeyPath: _NSOperationIsFinished, ofObject: self)
        }
    }
    
    open func main() { }
    
    open var isCancelled: Bool {
        return _isCancelled
    }
    
    open func cancel() {
        if isFinished { return }
        
        __atomicLoad.lock()
        __isCancelled = true
        __atomicLoad.unlock()
        
        if __NSOperationState.executing.rawValue <= _state.rawValue {
            return
        }
        
        _lock()
        __unfinishedDependencyCount = 0
        _unlock()
        YJOperation.observeValue(forKeyPath: _NSOperationIsReady, ofObject: self)
    }
    
    
    open var isExecuting: Bool {
        return __NSOperationState.executing == _state
    }
    
    open var isFinished: Bool {
        return __NSOperationState.finishing.rawValue <= _state.rawValue
    }
    
    open var isAsynchronous: Bool {
        return false
    }
    
    open var isReady: Bool {
        _lock()
        defer { _unlock() }
        return __unfinishedDependencyCount == 0
    }
    
    internal func _addDependency(_ op: YJOperation) {
        withExtendedLifetime(self) {
            withExtendedLifetime(op) {
                var up: YJOperation?
                _lock()
                if __dependencies.first(where: { $0 === op }) == nil {
                    __dependencies.append(op)
                    up = op
                }
                _unlock()
                
                if let upwards = up {
                    upwards._lock()
                    _lock()
                    let upIsFinished = upwards._state == __NSOperationState.finished
                    // 自己没有被取消。 依赖的op没有结束。形成依赖。
                    if !upIsFinished && !_isCancelled {
                        assert(_unfinishedDependencyCount >= 0)
                        _incrementUnfinishedDependencyCount()
                        // self依赖upwards，upwards的
                        upwards._addParent(self)
                    }
                    _unlock()
                    upwards._unlock()
                }
                YJOperation.observeValue(forKeyPath: _NSOperationIsReady, ofObject: self)
            }
        }
    }
    
    open func addDependency(_ op: YJOperation) {
        _addDependency(op)
    }
    
    open func removeDependency(_ op: YJOperation) {
        withExtendedLifetime(self) {
            withExtendedLifetime(op) {
                var up_canidate: YJOperation?
                _lock()
                let idxCanidate = __dependencies.firstIndex { $0 === op }
                if idxCanidate != nil {
                    up_canidate = op
                }
                _unlock()
                
                if let canidate = up_canidate {
                    canidate._lock()
                    _lock()
                    if let idx = __dependencies.firstIndex(where: { $0 === op }) {
                        if canidate._state == .finished && _isCancelled {
                            _decrementUnfinishedDependencyCount()
                        }
                        canidate._removeParent(self)
                        __dependencies.remove(at: idx)
                    }
                    
                    _unlock()
                    canidate._unlock()
                }
                YJOperation.observeValue(forKeyPath: _NSOperationIsReady, ofObject: self)
            }
        }
    }
    
    open var dependencies: [YJOperation] {
        get {
            _lock()
            defer { _unlock() }
            return __dependencies.filter { !($0 is _BarrierOperation) }
        }
    }
    
    internal func changePriority(_ newPri: YJOperation.QueuePriority.RawValue) {
        _lock()
        guard let oq = __queue?.takeRetainedValue() else {
            __priorityValue = newPri
            _unlock()
            return
        }
        _unlock()
        oq._lock()
        var oldPri = __priorityValue
        if oldPri == nil {
            if let v = (0 == oq.__actualMaxNumOps) ? nil : __propertyQoS {
                switch v {
                case .default: oldPri = YJOperation.QueuePriority.normal.rawValue
                case .userInteractive: oldPri = YJOperation.QueuePriority.veryHigh.rawValue
                case .userInitiated: oldPri = YJOperation.QueuePriority.high.rawValue
                case .utility: oldPri = YJOperation.QueuePriority.low.rawValue
                case .background: oldPri = YJOperation.QueuePriority.veryLow.rawValue
                }
            } else {
                oldPri = YJOperation.QueuePriority.normal.rawValue
            }
        }
        if oldPri == newPri {
            oq._unlock()
            return
        }
        __priorityValue = newPri
        var op = oq._firstPriorityOperation(oldPri)
        var prev: Unmanaged<YJOperation>?
        while let YJOperation = op?.takeUnretainedValue() {
            let nextOp = YJOperation.__nextPriorityOperation
            if YJOperation === self {
                // Remove from old list
                if let previous = prev?.takeUnretainedValue() {
                    previous.__nextPriorityOperation = nextOp
                } else {
                    oq._setFirstPriorityOperation(oldPri!, nextOp)
                }
                if nextOp == nil {
                    oq._setlastPriorityOperation(oldPri!, prev)
                }
                
                __nextPriorityOperation = nil
                
                // Append to new list
                if let oldLast = oq._lastPriorityOperation(newPri)?.takeUnretainedValue() {
                    oldLast.__nextPriorityOperation = Unmanaged.passUnretained(self)
                } else {
                    oq._setFirstPriorityOperation(newPri, Unmanaged.passUnretained(self))
                }
                oq._setlastPriorityOperation(newPri, Unmanaged.passUnretained(self))
                break
            }
            prev = op
            op = nextOp
        }
        oq._unlock()
    }
    
    open var queuePriority: YJOperation.QueuePriority {
        get {
            guard let prioValue = __priorityValue else {
                return YJOperation.QueuePriority.normal
            }
            
            if __priorityValue == YJOperation.QueuePriority.barrier {
//                return YJOperation.QueuePriority.barrier
            }
            
            return YJOperation.QueuePriority(rawValue: prioValue) ?? .veryHigh
        }
        set(newValue) {
            let newPri: YJOperation.QueuePriority.RawValue
            if YJOperation.QueuePriority.veryHigh.rawValue <= newValue.rawValue {
                newPri = YJOperation.QueuePriority.veryHigh.rawValue
            } else if YJOperation.QueuePriority.high.rawValue <= newValue.rawValue {
                newPri = YJOperation.QueuePriority.high.rawValue
            } else if YJOperation.QueuePriority.normal.rawValue <= newValue.rawValue {
                newPri = YJOperation.QueuePriority.normal.rawValue
            } else if YJOperation.QueuePriority.low.rawValue < newValue.rawValue {
                newPri = YJOperation.QueuePriority.normal.rawValue
            } else if YJOperation.QueuePriority.veryLow.rawValue < newValue.rawValue {
                newPri = YJOperation.QueuePriority.low.rawValue
            } else {
                newPri = YJOperation.QueuePriority.veryLow.rawValue
            }
            if __priorityValue != newPri {
                changePriority(newPri)
            }
        }
    }
    
    
    open var completionBlock: (() -> Void)? {
        get {
            _lock()
            defer { _unlock() }
            return __completion
        }
        set(newValue) {
            _lock()
            defer { _unlock() }
            __completion = newValue
        }
    }
    
    open func waitUntilFinished() {
        __waitCondition.lock()
        while !isFinished {
            __waitCondition.wait()
        }
        __waitCondition.unlock()
    }
    
    open var qualityOfService: QualityOfService {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __propertyQoS ?? QualityOfService.default
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __propertyQoS = newValue
        }
    }
    
    open var name: String? {
        get {
            return __name
        }
        set(newValue) {
            __name = newValue
        }
    }
}

extension YJOperation {
    public override func willChangeValue(forKey key: String) {
        // do nothing
    }
    
    public override func didChangeValue(forKey key: String) {
        YJOperation.observeValue(forKeyPath: key, ofObject: self)
    }
    
    public func willChangeValue<Value>(for keyPath: KeyPath<Operation, Value>) {
        // do nothing
    }
    
    public func didChangeValue<Value>(for keyPath: KeyPath<Operation, Value>) {
        switch keyPath {
        case \Operation.isFinished: didChangeValue(forKey: _NSOperationIsFinished)
        case \Operation.isReady: didChangeValue(forKey: _NSOperationIsReady)
        case \Operation.isCancelled: didChangeValue(forKey: _NSOperationIsCancelled)
        case \Operation.isExecuting: didChangeValue(forKey: _NSOperationIsExecuting)
        default: break
        }
    }
}

extension YJOperation {
    public enum QueuePriority : Int {
        case veryLow = -8
        case low = -4
        case normal = 0
        case high = 4
        case veryHigh = 8
        
        internal static var barrier = 12
        internal static let priorities = [
            YJOperation.QueuePriority.barrier,
            YJOperation.QueuePriority.veryHigh.rawValue,
            YJOperation.QueuePriority.high.rawValue,
            YJOperation.QueuePriority.normal.rawValue,
            YJOperation.QueuePriority.low.rawValue,
            YJOperation.QueuePriority.veryLow.rawValue
        ]
    }
}

open class BlockOperation : YJOperation {
    var _block: (() -> Void)?
    var _executionBlocks: [() -> Void]?
    
    public override init() {
        
    }
    
    public convenience init(block: @escaping () -> Void) {
        self.init()
        _block = block
    }
    
    open func addExecutionBlock(_ block: @escaping () -> Void) {
        if isExecuting || isFinished {
            fatalError("blocks cannot be added after the YJOperation has started executing or finished")
        }
        _lock()
        defer { _unlock() }
        if _block == nil && _executionBlocks == nil {
            _block = block
        } else {
            if _executionBlocks == nil {
                if let existing = _block {
                    _executionBlocks = [existing, block]
                } else {
                    _executionBlocks = [block]
                }
            } else {
                _executionBlocks?.append(block)
            }
        }
    }
    
    open var executionBlocks: [@convention(block) () -> Void] {
        get {
            _lock()
            defer { _unlock() }
            var blocks = [() -> Void]()
            if let existing = _block {
                blocks.append(existing)
            }
            if let existing = _executionBlocks {
                blocks.append(contentsOf: existing)
            }
            return blocks
        }
    }
    
    open override func main() {
        var blocks = [() -> Void]()
        _lock()
        if let existing = _block {
            blocks.append(existing)
        }
        if let existing = _executionBlocks {
            blocks.append(contentsOf: existing)
        }
        _unlock()
        for block in blocks {
            block()
        }
    }
}

internal final class _BarrierOperation : YJOperation {
    var _block: (() -> Void)?
    init(_ block: @escaping () -> Void) {
        _block = block
    }
    
    override func main() {
        _lock()
        let block = _block
        _block = nil
        _unlock()
        block?()
        _removeAllDependencies()
    }
}

internal final class _OperationQueueProgress : Progress {
    var queue: Unmanaged<YJOperationQueue>?
    let lock = NSLock()
    
    init(_ queue: YJOperationQueue) {
        self.queue = Unmanaged.passUnretained(queue)
        super.init(parent: nil, userInfo: nil)
    }
    
    func invalidateQueue() {
        lock.lock()
        queue = nil
        lock.unlock()
    }
    
    override var totalUnitCount: Int64 {
        get {
            return super.totalUnitCount
        }
        set(newValue) {
            super.totalUnitCount = newValue
            lock.lock()
            queue?.takeUnretainedValue().__progressReporting = true
            lock.unlock()
        }
    }
}

extension YJOperationQueue {
    public static let defaultMaxConcurrentOperationCount: Int = -1
}

@available(OSX 10.5, *)
open class YJOperationQueue : NSObject, ProgressReporting {
    let __queueLock = NSLock()
    let __atomicLoad = NSLock()
    var __firstOperation: Unmanaged<YJOperation>?
    var __lastOperation: Unmanaged<YJOperation>?
    var __firstPriorityOperation: (barrier: Unmanaged<YJOperation>?,
                                   veryHigh: Unmanaged<YJOperation>?,
                                   high: Unmanaged<YJOperation>?,
                                   normal: Unmanaged<YJOperation>?,
                                   low: Unmanaged<YJOperation>?,
                                   veryLow: Unmanaged<YJOperation>?)
    var __lastPriorityOperation: (barrier: Unmanaged<YJOperation>?,
                                  veryHigh: Unmanaged<YJOperation>?,
                                  high: Unmanaged<YJOperation>?,
                                  normal: Unmanaged<YJOperation>?,
                                  low: Unmanaged<YJOperation>?,
                                  veryLow: Unmanaged<YJOperation>?)
    var _barriers = [_BarrierOperation]()
    var _progress: _OperationQueueProgress?
    var __operationCount: Int = 0
    var __maxNumOps: Int = YJOperationQueue.defaultMaxConcurrentOperationCount
    var __actualMaxNumOps: Int32 = .max
    var __numExecOps: Int32 = 0
    var __dispatch_queue: DispatchQueue?
    var __backingQueue: DispatchQueue?
    var __name: String?
    var __suspended: Bool = false
    var __overcommit: Bool = false
    var __propertyQoS: QualityOfService?
    var __mainQ: Bool = false
    var __progressReporting: Bool = false
    
    internal func _lock() {
        __queueLock.lock()
    }
    
    internal func _unlock() {
        __queueLock.unlock()
    }
    
    internal var _suspended: Bool {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        return __suspended
    }
    
    internal func _incrementExecutingOperations() {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        __numExecOps += 1
    }
    
    internal func _decrementExecutingOperations() {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        if __numExecOps > 0 {
           __numExecOps -= 1
        }
    }
    
    internal func _incrementOperationCount(by amount: Int = 1) {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        __operationCount += amount
    }
    
    internal func _decrementOperationCount(by amount: Int = 1) {
        __atomicLoad.lock()
        defer { __atomicLoad.unlock() }
        __operationCount -= amount
    }
    
    internal func _firstPriorityOperation(_ prio: YJOperation.QueuePriority.RawValue?) -> Unmanaged<YJOperation>? {
        guard let priority = prio else { return nil }
        switch priority {
        case YJOperation.QueuePriority.barrier: return __firstPriorityOperation.barrier
        case YJOperation.QueuePriority.veryHigh.rawValue: return __firstPriorityOperation.veryHigh
        case YJOperation.QueuePriority.high.rawValue: return __firstPriorityOperation.high
        case YJOperation.QueuePriority.normal.rawValue: return __firstPriorityOperation.normal
        case YJOperation.QueuePriority.low.rawValue: return __firstPriorityOperation.low
        case YJOperation.QueuePriority.veryLow.rawValue: return __firstPriorityOperation.veryLow
        default: fatalError("unsupported priority")
        }
    }
    
    internal func _setFirstPriorityOperation(_ prio: YJOperation.QueuePriority.RawValue, _ Operation: Unmanaged<YJOperation>?) {
        switch prio {
        case YJOperation.QueuePriority.barrier: __firstPriorityOperation.barrier = Operation
        case YJOperation.QueuePriority.veryHigh.rawValue: __firstPriorityOperation.veryHigh = Operation
        case YJOperation.QueuePriority.high.rawValue: __firstPriorityOperation.high = Operation
        case YJOperation.QueuePriority.normal.rawValue: __firstPriorityOperation.normal = Operation
        case YJOperation.QueuePriority.low.rawValue: __firstPriorityOperation.low = Operation
        case YJOperation.QueuePriority.veryLow.rawValue: __firstPriorityOperation.veryLow = Operation
        default: fatalError("unsupported priority")
        }
    }
    
    internal func _lastPriorityOperation(_ prio: YJOperation.QueuePriority.RawValue?) -> Unmanaged<YJOperation>? {
        guard let priority = prio else { return nil }
        switch priority {
        case YJOperation.QueuePriority.barrier: return __lastPriorityOperation.barrier
        case YJOperation.QueuePriority.veryHigh.rawValue: return __lastPriorityOperation.veryHigh
        case YJOperation.QueuePriority.high.rawValue: return __lastPriorityOperation.high
        case YJOperation.QueuePriority.normal.rawValue: return __lastPriorityOperation.normal
        case YJOperation.QueuePriority.low.rawValue: return __lastPriorityOperation.low
        case YJOperation.QueuePriority.veryLow.rawValue: return __lastPriorityOperation.veryLow
        default: fatalError("unsupported priority")
        }
    }
    
    internal func _setlastPriorityOperation(_ prio: YJOperation.QueuePriority.RawValue, _ op: Unmanaged<YJOperation>?) {
//        if let yjop = op?.takeUnretainedValue() {
//            if prio == 12 {
//                // ? = 8
//                print("qp = \(yjop.queuePriority.rawValue)")
//            }
//            assert(yjop.queuePriority.rawValue == prio)
//        }
        switch prio {
        case YJOperation.QueuePriority.barrier: __lastPriorityOperation.barrier = op
        case YJOperation.QueuePriority.veryHigh.rawValue: __lastPriorityOperation.veryHigh = op
        case YJOperation.QueuePriority.high.rawValue: __lastPriorityOperation.high = op
        case YJOperation.QueuePriority.normal.rawValue: __lastPriorityOperation.normal = op
        case YJOperation.QueuePriority.low.rawValue: __lastPriorityOperation.low = op
        case YJOperation.QueuePriority.veryLow.rawValue: __lastPriorityOperation.veryLow = op
        default: fatalError("unsupported priority")
        }
    }
    
    internal func _operationFinished(_ op: YJOperation, _ previousState: YJOperation.__NSOperationState) {
        // There are only three cases where an YJOperation might have a nil queue
        // A) The YJOperation was never added to a queue and we got here by a normal KVO change
        // B) The YJOperation was somehow already finished
        // C) the YJOperation was attempted to be added to a queue but an exception occured and was ignored...
        // Option C is NOT supported!
        let isBarrier = op is _BarrierOperation
        _lock()
        let nextOp = op.__nextOperation
        if YJOperation.__NSOperationState.finished == op._state {
            
            // 把op从整个__firstOperation到__lastOperation的链表中移除，纯粹链表操作。
            let prevOp = op.__previousOperation
            if let prev = prevOp {
                prev.takeUnretainedValue().__nextOperation = nextOp
            } else {
                __firstOperation = nextOp
            }
            if let next = nextOp {
                next.takeUnretainedValue().__previousOperation = prevOp
            } else {
                __lastOperation = prevOp
            }
            
            
            // only decrement execution count on YJOperations that were executing! (the execution was initially set to __NSOperationStateDispatching so we must compare from that or later)
            // else the number of executing YJOperations might underflow
            if previousState.rawValue >= YJOperation.__NSOperationState.dispatching.rawValue {
                _decrementExecutingOperations()
            }
            op.__previousOperation = nil
            op.__nextOperation = nil
            op._invalidateQueue()
        }
        if !isBarrier {
            _decrementOperationCount()
        }
        _unlock()
        
        _schedule()
        
        if previousState.rawValue >= YJOperation.__NSOperationState.enqueuing.rawValue {
            Unmanaged.passUnretained(op).release()
        }
    }
    
    internal var _propertyQoS: QualityOfService? {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __propertyQoS
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __propertyQoS = newValue
        }
    }
    
    internal func _synthesizeBackingQueue() -> DispatchQueue {
        guard let queue = __backingQueue else {
            let queue: DispatchQueue
            if let qos = _propertyQoS {
                if let name = __name {
                    queue = DispatchQueue(label: name, qos: qos.qosClass)
                } else {
                    queue = DispatchQueue(label: "NSOperationQueue \(Unmanaged.passUnretained(self).toOpaque())", qos: qos.qosClass)
                }
            } else {
                if let name = __name {
                    queue = DispatchQueue(label: name)
                } else {
                    queue = DispatchQueue(label: "NSOperationQueue \(Unmanaged.passUnretained(self).toOpaque())")
                }
            }
            __backingQueue = queue
            return queue
        }
        return queue
    }


    static internal var _currentQueue = NSThreadSpecific<YJOperationQueue>()
    
    // op start
    internal func _schedule(_ op: YJOperation) {
        op._state = .starting
        // set current tsd
        YJOperationQueue._currentQueue.set(self)
        op.start()
        YJOperationQueue._currentQueue.clear()
        
        // unset current tsd
        // 结束 && ???
        // __NSOperationState.finishing.rawValue <= _state.rawValue < __NSOperationState.finishing.rawValue
        if op.isFinished && op._state.rawValue < YJOperation.__NSOperationState.finishing.rawValue {
            YJOperation.observeValue(forKeyPath: _NSOperationIsFinished, ofObject: op)
        }
    }
    
    internal func _schedule() {
        var retestOps = [YJOperation]()
        _lock()
        var slotsAvail = __actualMaxNumOps - __numExecOps
        // 优先级由高到低进行遍历。最高为barrier。。。所以，优先级高，确实会先执行。
        for prio in YJOperation.QueuePriority.priorities {
            if 0 >= slotsAvail || _suspended {
                break
            }
            var op = _firstPriorityOperation(prio)
            var prev: Unmanaged<YJOperation>?
            while let inOp = op?.takeUnretainedValue() {
                if 0 >= slotsAvail || _suspended {
                    break
                }
                let next = inOp.__nextPriorityOperation
                var retest = false
                
                // if the cached state is possibly not valid then the isReady value needs to be re-updated
                if YJOperation.__NSOperationState.enqueued == inOp._state && inOp._fetchCachedIsReady(&retest) {
                    if let previous = prev?.takeUnretainedValue() {
                        previous.__nextOperation = next
                    } else {
                        _setFirstPriorityOperation(prio, next) // 因为第一个op要被执行了，所以把第二个op设置成第一个。
                    }
                    if next == nil {
                        _setlastPriorityOperation(prio, prev)
                    }

                    // 链表操作，计数操作
                    inOp.__nextPriorityOperation = nil
                    inOp._state = .dispatching
                    _incrementExecutingOperations()
                    slotsAvail -= 1

                    // 保证op是异步执行
                    let queue: DispatchQueue
                    if __mainQ {
                        queue = DispatchQueue.main
                    } else {
                        queue = __dispatch_queue ?? _synthesizeBackingQueue() // 返回自己
                    }

                    if let schedule = inOp.__schedule {
                        if inOp is _BarrierOperation {
                            queue.async(flags: .barrier, execute: {
                                schedule.perform()
                            })
                        } else {
                            queue.async(execute: schedule)
                        }
                    }

                    op = next
                } else {
                    if retest {
                        retestOps.append(inOp)
                    }
                    prev = op
                    op = next
                }
            }
        }
        _unlock()
        
        for op in retestOps {
            if op.isReady {
                op._cachedIsReady = true
            }
        }
    }
    
    internal var _isReportingProgress: Bool {
        return __progressReporting
    }
    
    internal func _execute(_ op: YJOperation) {
        var YJOperationProgress: Progress? = nil
        if !(op is _BarrierOperation) && _isReportingProgress {
            let opProgress = Progress(parent: nil, userInfo: nil)
            opProgress.totalUnitCount = 1
            progress.addChild(opProgress, withPendingUnitCount: 1)
            YJOperationProgress = opProgress
        }
        YJOperationProgress?.becomeCurrent(withPendingUnitCount: 1)
        defer { YJOperationProgress?.resignCurrent() }
        
        op.main()
    }
    
    internal var _maxNumOps: Int {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __maxNumOps
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __maxNumOps = newValue
        }
    }
    
    internal var _isSuspended: Bool {
        get {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            return __suspended
        }
        set(newValue) {
            __atomicLoad.lock()
            defer { __atomicLoad.unlock() }
            __suspended = newValue
        }
    }
    
    internal var _operationCount: Int {
        _lock()
        defer { _unlock() }
        var op = __firstOperation
        var cnt = 0
        if let YJOperation = op?.takeUnretainedValue() {
            if !(YJOperation is _BarrierOperation) {
                cnt += 1
            }
            op = YJOperation.__nextOperation
        }
        return cnt
    }
    
    internal func _operations(includingBarriers: Bool = false) -> [YJOperation] {
        _lock()
        defer { _unlock() }
        var YJOperations = [YJOperation]()
        var op = __firstOperation
        if let YJOperation = op?.takeUnretainedValue() {
            if includingBarriers || !(YJOperation is _BarrierOperation) {
                YJOperations.append(YJOperation)
            }
            op = YJOperation.__nextOperation
        }
        return YJOperations
    }
    
    public override init() {
        super.init()
        __name = "NSOperationQueue \(Unmanaged<YJOperationQueue>.passUnretained(self).toOpaque())"
        __name = "QiBi"
    }
    
    internal init(asMainQueue: ()) {
        super.init()
        __mainQ = true
        __maxNumOps = 1
        __actualMaxNumOps = 1
        __name = "NSOperationQueue Main Queue"
#if canImport(Darwin)
        __propertyQoS = QualityOfService(qos_class_main())
#else
        __propertyQoS = QualityOfService.userInteractive
#endif
        
    }
    
    deinit {
        print("dead now")
    }
    
    open var progress: Progress {
        get {
            _lock()
            defer { _unlock() }
            guard let progress = _progress else {
                let progress = _OperationQueueProgress(self)
                _progress = progress
                return progress
            }
            return progress
        }
    }
    
    internal func _addOperations(_ ops: [YJOperation], barrier: Bool = false) {
        if ops.isEmpty { return }
        
        var failures = 0
        var successes = 0
        var firstNewOp: Unmanaged<YJOperation>?
        var lastNewOp: Unmanaged<YJOperation>?
        
        // ops 成为一个双向链表
        for op in ops {
            // initialized -> enqueuing
            if op._compareAndSwapState(.initialized, .enqueuing) {
                successes += 1
                if 0 == failures {
                    let retained = Unmanaged.passRetained(op)
                    op._cachedIsReady = op.isReady
                    
                    // 依据qos对对op进行分级
                    let schedule: DispatchWorkItem
                    if let qos = op.__propertyQoS?.qosClass {
                        schedule = DispatchWorkItem.init(qos: qos, flags: .enforceQoS, block: {
                            self._schedule(op)
                        })
                    } else {
                        schedule = DispatchWorkItem(flags: .assignCurrentContext, block: {
                            self._schedule(op)
                        })
                    }
                    
                    op._adopt(queue: self, schedule: schedule)
                    op.__previousOperation = lastNewOp
                    op.__nextOperation = nil
                    if let lastNewOperation = lastNewOp?.takeUnretainedValue() {
                        lastNewOperation.__nextOperation = retained
                    } else {
                        firstNewOp = retained
                    }
                    lastNewOp = retained
                } else {
                    _ = op._compareAndSwapState(.enqueuing, .initialized)
                }
            } else {
                failures += 1
            }
        }
        
        // 可能发生了一些错误。所以的op都清空。
        if 0 < failures {
            while let firstNewOperation = firstNewOp?.takeUnretainedValue() {
                let nextNewOp = firstNewOperation.__nextOperation
                firstNewOperation._invalidateQueue()
                firstNewOperation.__previousOperation = nil
                firstNewOperation.__nextOperation = nil
                _ = firstNewOperation._compareAndSwapState(.enqueuing, .initialized)
                firstNewOp?.release()
                firstNewOp = nextNewOp
            }
            fatalError("operations finished, executing or already in a queue cannot be enqueued")
        }
        
        // Attach any YJOperations pending attachment to main list
        
        if !barrier {
            _lock()
            _incrementOperationCount()
        }
        
        // 原来的A,B,C. 现在 D,E,F. make queue to A,B,C,D,E,F.
        var pending = firstNewOp
        if let pendingOperation = pending?.takeUnretainedValue() {
            let old_last = __lastOperation
            pendingOperation.__previousOperation = old_last
            
            if let old = old_last?.takeUnretainedValue() {
                old.__nextOperation = pending
            } else {
                __firstOperation = pending
            }
            __lastOperation = lastNewOp
        }
        
        // D,E,F.pendingOperation = D
        while let pendingOperation = pending?.takeUnretainedValue() {
            if !barrier {
                
                // 没有barrier,就用上一次的barrier。
                var barrierOp = _firstPriorityOperation(YJOperation.QueuePriority.barrier)
                while let barrierOperation = barrierOp?.takeUnretainedValue() {
                    pendingOperation._addDependency(barrierOperation)
                    barrierOp = barrierOperation.__nextPriorityOperation
                }
            } else {
                print(ops)
            }
            
            _ = pendingOperation._compareAndSwapState(.enqueuing, .enqueued)
            var pri = pendingOperation.__priorityValue
            // 确保有一个pri值。最后默认为normal。
            if pri == nil {
                // 看看queue能不能并发。（Mainqueue就不能并发，max == 1）
                // 获取优先级
                let v = __actualMaxNumOps == 1 ? nil : pendingOperation.__propertyQoS
                if let qos = v {
                    switch qos {
                    case .default: pri = YJOperation.QueuePriority.normal.rawValue
                    case .userInteractive: pri = YJOperation.QueuePriority.veryHigh.rawValue
                    case .userInitiated: pri = YJOperation.QueuePriority.high.rawValue
                    case .utility: pri = YJOperation.QueuePriority.low.rawValue
                    case .background: pri = YJOperation.QueuePriority.veryLow.rawValue
                    }
                } else {
                    pri = YJOperation.QueuePriority.normal.rawValue
                }
            }
            
            // 依据优先级，获取同一优先级的op链条。不同优先级，有不同的op链条。
            // 更新进优先级op链表
            pendingOperation.__nextPriorityOperation = nil
            if let old_last = _lastPriorityOperation(pri)?.takeUnretainedValue() {
                old_last.__nextPriorityOperation = pending
            } else {
                _setFirstPriorityOperation(pri!, pending)
            }
            
            // 更新该优先级lastOp
            _setlastPriorityOperation(pri!, pending)
            
            // 操作完D，操作E。
            pending = pendingOperation.__nextOperation
        }
        
        if !barrier {
            _unlock()
        }
        
        if !barrier {
            _schedule()
        }
    }
    
    open func addOperation(_ op: YJOperation) {
        _addOperations([op], barrier: false)
    }
    
    open func addOperations(_ ops: [YJOperation], waitUntilFinished wait: Bool) {
        _addOperations(ops, barrier: false)
        if wait {
            for op in ops {
                op.waitUntilFinished()
            }
        }
    }
    
    open func addOperation(_ block: @escaping () -> Void) {
        let op = BlockOperation(block: block)
        if let qos = __propertyQoS {
            op.qualityOfService = qos
        }
        addOperation(op)
    }
    
    open func addBarrierBlock(_ barrier: @escaping () -> Void) {
        var queue: DispatchQueue?
        _lock()
        if let op = __firstOperation {
            let barrierOperation = _BarrierOperation(barrier)
            barrierOperation.__priorityValue = YJOperation.QueuePriority.barrier
            var iterOp: Unmanaged<YJOperation>? = op
            while let yjop = iterOp?.takeUnretainedValue() {
                barrierOperation.addDependency(yjop)
                iterOp = yjop.__nextOperation
            }
            _addOperations([barrierOperation], barrier: true)
        } else {
            queue = _synthesizeBackingQueue()
        }
        _unlock()
        
        if let q = queue {
            q.async(flags: .barrier, execute: barrier)
        } else {
            _schedule()
        }
    }
    
    open var maxConcurrentOperationCount: Int {
        get {
            return _maxNumOps
        }
        set(newValue) {
            if newValue < 0 && newValue != YJOperationQueue.defaultMaxConcurrentOperationCount {
                fatalError("count (\(newValue)) cannot be negative")
            }
            if !__mainQ {
                _lock()
                _maxNumOps = newValue
                let acnt = YJOperationQueue.defaultMaxConcurrentOperationCount == newValue || Int32.max < newValue ? Int32.max : Int32(newValue)
                __actualMaxNumOps = acnt
                _unlock()
                _schedule()
            }
            
        }
    }
    
    open var isSuspended: Bool {
        get {
            return _isSuspended
        }
        set(newValue) {
            if !__mainQ {
                _isSuspended = newValue
                if !newValue {
                    _schedule()
                }
            }
        }
    }
    
    open var name: String? {
        get {
            _lock()
            defer { _unlock() }
            return __name ?? "NSOperationQueue \(Unmanaged.passUnretained(self).toOpaque())"
        }
        set(newValue) {
            if !__mainQ {
                _lock()
                __name = newValue ?? ""
                _unlock()
            }
        }
    }
    
    open var qualityOfService: QualityOfService {
        get {
            return _propertyQoS ?? .default
        }
        set(newValue) {
            if !__mainQ {
                _lock()
                _propertyQoS = newValue
                _unlock()
            }
        }
    }
    
    unowned(unsafe) open var underlyingQueue: DispatchQueue? {
        get {
            if __mainQ {
                return DispatchQueue.main
            } else {
                _lock()
                defer { _unlock() }
                return __dispatch_queue
            }
        }
        set(newValue) {
            if !__mainQ {
                if 0 < _operationCount {
                    fatalError("operation queue must be empty in order to change underlying dispatch queue")
                }
                __dispatch_queue = newValue
            }
        }
    }
    
    open func cancelAllOperations() {
        if !__mainQ {
            for op in _operations(includingBarriers: true) {
                op.cancel()
            }
        }
    }
    
    open func waitUntilAllOperationsAreFinished() {
        var ops = _operations(includingBarriers: true)
        while 0 < ops.count {
            for op in ops {
                op.waitUntilFinished()
            }
            ops = _operations(includingBarriers: true)
        }
    }
    
    open class var current: YJOperationQueue? {
        get {
            if Thread.isMainThread {
                return main
            }
            return YJOperationQueue._currentQueue.current
        }
    }
    
    open class var main: YJOperationQueue {
        get {
            struct Once {
                static let mainQ = YJOperationQueue(asMainQueue: ())
            }
            return Once.mainQ
        }
    }
}

extension YJOperationQueue {
    // These two functions are inherently a race condition and should be avoided if possible
    
    @available(OSX, introduced: 10.5, deprecated: 100000, message: "access to YJOperations is inherently a race condition, it should not be used. For barrier style behaviors please use addBarrierBlock: instead")
    open var YJOperations: [YJOperation] {
        get {
            return _operations(includingBarriers: false)
        }
    }
    
    
    @available(OSX, introduced: 10.6, deprecated: 100000)
    open var YJOperationCount: Int {
        get {
            return _operationCount
        }
    }
}

internal class NSThreadSpecific<T: NSObject> {
    private var key = "queue"

    internal var current: T? {
        let threadDict = Thread.current.threadDictionary
        return threadDict[key] as? T
    }

    internal func set(_ value: T) {
        let threadDict = Thread.current.threadDictionary
        threadDict[key] = value
        
    }
    
    internal func clear() {
        let threadDict = Thread.current.threadDictionary
        threadDict[key] = nil
    }
}
