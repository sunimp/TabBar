# TabBar

[![CI](https://github.com/sunimp/TabBar/actions/workflows/ci.yml/badge.svg)](https://github.com/sunimp/TabBar/actions/workflows/ci.yml)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

TabBar 是一个 UIKit 自定义底部导航组件，提供浮动胶囊布局、液态选中指示器、角标和 Lottie 图标动画。

## 效果预览

| iOS 15+ 亮色 | iOS 15+ 暗色 |
| --- | --- |
| <img src="Screenshots/ios15+_light.png" alt="iOS 15+ 亮色效果" width="300"> | <img src="Screenshots/ios15+_dark.png" alt="iOS 15+ 暗色效果" width="300"> |

| iOS 26+ 亮色 | iOS 26+ 暗色 |
| --- | --- |
| <img src="Screenshots/ios26+_light.png" alt="iOS 26+ 亮色效果" width="300"> | <img src="Screenshots/ios26+_dark.png" alt="iOS 26+ 暗色效果" width="300"> |

## 特性

- 适用于 UIKit App 的浮动胶囊式 TabBar。
- 液态选中指示器和玻璃背景渲染。
- 支持未读数和短文本角标。
- 支持静态 `UIImage` 图标和 Lottie 动画图标。
- 提供选中、重选、双击、长按等代理回调。
- 内置亮色和暗色样式，并支持自定义颜色。

## 环境要求

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+
- Swift Package Manager

## 安装

在 Xcode 中添加 Swift Package：

```text
https://github.com/sunimp/TabBar.git
```

或在 `Package.swift` 中添加依赖：

```swift
.package(url: "https://github.com/sunimp/TabBar.git", from: "0.1.0")
```

然后把 `TabBar` 加到目标依赖中：

```swift
.product(name: "TabBar", package: "TabBar")
```

## 公开 API

- `TabBarController`
- `TabBarView`
- `TabBarItem`
- `TabBarItemAnimation`
- `TabBarStyle`

## 快速开始

```swift
import TabBar
import UIKit

let chats = UIViewController()
let chatsItem = TabBarItem(
    id: "chats",
    title: "聊天",
    image: UIImage(systemName: "bubble.left.and.bubble.right"),
    selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill"),
    badgeValue: "3",
    animation: TabBarItemAnimation(name: "TabChats")
)

let contacts = UIViewController()
let contactsItem = TabBarItem(
    id: "contacts",
    title: "联系人",
    image: UIImage(systemName: "person.2"),
    selectedImage: UIImage(systemName: "person.2.fill")
)

let controller = TabBarController(style: .default)
controller.setViewControllers(
    [chats, contacts],
    items: [chatsItem, contactsItem],
    selectedIndex: 0
)
```

## 样式定制

通过 `TabBarStyle` 定制颜色：

```swift
var style = TabBarStyle.default
style.backgroundColor = .systemBackground
style.selectedIconColor = .systemBlue
style.selectedTextColor = .systemBlue

controller.style = style
```

通过代理处理交互事件：

```swift
final class HomeController: TabBarControllerDelegate {
    func tabBarController(_ controller: TabBarController, didReselect viewController: UIViewController, at index: Int) {
        // 可在这里执行滚动到顶部、刷新等业务动作。
    }
}
```

## Demo

打开 `Demo/TabBarDemo.xcodeproj`，运行 `TabBarDemo` scheme。

如果需要重新生成 demo 工程文件，使用 XcodeGen：

```bash
cd Demo
xcodegen generate
```

## 开发

运行 iOS Simulator 测试：

```bash
DESTINATION_ID="$(xcrun simctl list devices available --json | python3 -c 'import json, sys; devices = [device for runtime in json.load(sys.stdin)["devices"].values() for device in runtime]; phones = [device for device in devices if device.get("isAvailable") and device.get("name", "").startswith("iPhone")]; print(phones[0]["udid"])')"
xcodebuild test \
  -scheme TabBar \
  -destination "platform=iOS Simulator,id=${DESTINATION_ID}"
```

命令行构建 Swift Package 时，需要显式指定 iOS SDK：

```bash
swift build --build-tests \
  --triple arm64-apple-ios18.6-simulator \
  --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"
```

## 说明

`TabBar` 是 UIKit 组件。部分视觉效果会在运行时检查平台能力；能力不可用时，会自动回退到受支持的渲染路径。

## License

TabBar 使用 MIT License 开源，详见 [LICENSE](LICENSE)。
