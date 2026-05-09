//
//  DisplayLinkDriver.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

/// DisplayLink 回调链接的协议。
protocol SharedDisplayLinkDriverLink: AnyObject {
    /// 是否暂停回调。
    var isPaused: Bool { get set }
    /// 使链接失效，后续不再收到回调。
    func invalidate()
}

/// 是否为 iPad 设备（iPad 始终请求 120Hz）。
private let isPadDevice: Bool = UIDevice.current.userInterfaceIdiom == .pad

/// 共享的 CADisplayLink 驱动器。
///
/// 管理多个帧回调请求，复用单个 `CADisplayLink` 实例以减少系统开销。
/// 支持不同帧率的回调（如 30fps、60fps、max），自动根据最高需求调整 DisplayLink 的帧率范围。
///
/// 主要用于 `LiquidLensView` 在 lifted 状态下持续更新 lens 位置。
final class SharedDisplayLinkDriver {
    /// 帧率配置。
    enum FramesPerSecond: Comparable {
        /// 指定帧率（如 30、60）。
        case fps(Int)
        /// 设备最大帧率（ProMotion 设备为 120Hz）。
        case max

        static func < (lhs: FramesPerSecond, rhs: FramesPerSecond) -> Bool {
            switch lhs {
            case let .fps(lhsFps):
                switch rhs {
                case let .fps(rhsFps):
                    return lhsFps < rhsFps
                case .max:
                    return true
                }
            case .max:
                return false
            }
        }
    }

    typealias Link = SharedDisplayLinkDriverLink

    /// 全局单例。
    static let shared = SharedDisplayLinkDriver()

    /// 单个回调链接的实现。
    final class LinkImpl: Link {
        private let driver: SharedDisplayLinkDriver
        let framesPerSecond: FramesPerSecond
        let update: (CGFloat) -> Void
        var isValid = true
        var isPaused = false {
            didSet {
                if isPaused != oldValue {
                    driver.requestUpdate()
                }
            }
        }

        init(driver: SharedDisplayLinkDriver, framesPerSecond: FramesPerSecond, update: @escaping (CGFloat) -> Void) {
            self.driver = driver
            self.framesPerSecond = framesPerSecond
            self.update = update
        }

        func invalidate() {
            isValid = false
        }
    }

    /// 回调请求的上下文，持有对 LinkImpl 的弱引用。
    private final class RequestContext {
        weak var link: LinkImpl?
        let framesPerSecond: FramesPerSecond
        var lastDuration: Double = 0.0

        init(link: LinkImpl, framesPerSecond: FramesPerSecond) {
            self.link = link
            self.framesPerSecond = framesPerSecond
        }
    }

    private var displayLink: CADisplayLink?
    private var requests: [RequestContext] = []
    private var isInForeground = false
    private var isProcessingEvent = false
    private var isUpdateRequested = false

    private init() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.isInForeground = true
            self?.update()
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.isInForeground = false
            self?.update()
        }

        if Bundle.main.bundlePath.hasSuffix(".appex") {
            isInForeground = true
        } else {
            isInForeground = UIApplication.shared.applicationState == .active
        }

        update()
    }

    private func requestUpdate() {
        if isProcessingEvent {
            isUpdateRequested = true
        } else {
            update()
        }
    }

    private func update() {
        var hasActiveItems = false
        var maxFramesPerSecond: FramesPerSecond = .fps(30)

        for request in requests {
            if let link = request.link {
                if link.framesPerSecond > maxFramesPerSecond {
                    maxFramesPerSecond = link.framesPerSecond
                }
                if link.isValid, !link.isPaused {
                    hasActiveItems = true
                    break
                }
            }
        }

        if isInForeground, hasActiveItems {
            let displayLink: CADisplayLink
            if let current = self.displayLink {
                displayLink = current
            } else {
                displayLink = CADisplayLink(target: self, selector: #selector(displayLinkEvent))
                self.displayLink = displayLink
                displayLink.add(to: .main, forMode: .common)
            }

            let maxFps: Float = 120.0
            if maxFps > 61.0 {
                var frameRateRange: CAFrameRateRange
                switch maxFramesPerSecond {
                case let .fps(fps):
                    frameRateRange = fps > 60 ? CAFrameRateRange(minimum: 30.0, maximum: 120.0, preferred: 120.0) : .default
                case .max:
                    frameRateRange = CAFrameRateRange(minimum: 30.0, maximum: 120.0, preferred: 120.0)
                }

                if isPadDevice {
                    frameRateRange = CAFrameRateRange(minimum: 30.0, maximum: 120.0, preferred: 120.0)
                }

                if displayLink.preferredFrameRateRange != frameRateRange {
                    displayLink.preferredFrameRateRange = frameRateRange
                }
            }

            displayLink.isPaused = false
        } else if let displayLink = displayLink {
            self.displayLink = nil
            displayLink.invalidate()
        }
    }

    @objc private func displayLinkEvent(displayLink: CADisplayLink) {
        isProcessingEvent = true
        let duration = displayLink.targetTimestamp - displayLink.timestamp

        var removeIndices: [Int]?
        loop: for index in 0 ..< requests.count {
            let request = requests[index]
            if let link = request.link, link.isValid {
                if !link.isPaused {
                    var itemDuration = duration

                    switch request.framesPerSecond {
                    case let .fps(value):
                        let secondsPerFrame = 1.0 / CGFloat(value)
                        itemDuration = secondsPerFrame
                        request.lastDuration += duration
                        if request.lastDuration < secondsPerFrame * 0.95 {
                            continue loop
                        }
                    case .max:
                        break
                    }

                    request.lastDuration = 0.0
                    link.update(itemDuration)
                }
            } else {
                if removeIndices == nil {
                    removeIndices = [index]
                } else {
                    removeIndices?.append(index)
                }
            }
        }

        if let removeIndices = removeIndices {
            for index in removeIndices.reversed() {
                requests.remove(at: index)
            }
            if requests.isEmpty {
                isUpdateRequested = true
            }
        }

        isProcessingEvent = false
        if isUpdateRequested {
            isUpdateRequested = false
            update()
        }
    }

    /// 注册一个帧回调。
    ///
    /// - Parameters:
    ///   - framesPerSecond: 期望的帧率，默认 60fps。
    ///   - body: 每帧回调，参数为帧间隔时长（秒）。
    /// - Returns: 回调链接，调用 `invalidate()` 取消注册。
    func add(framesPerSecond: FramesPerSecond = .fps(60), _ body: @escaping (CGFloat) -> Void) -> Link {
        let link = LinkImpl(driver: self, framesPerSecond: framesPerSecond, update: body)
        requests.append(RequestContext(link: link, framesPerSecond: framesPerSecond))
        update()
        return link
    }
}
