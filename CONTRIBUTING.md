# 贡献指南

感谢你愿意改进 TabBar。

## 开发准备

1. 克隆仓库。
2. 用 Xcode 打开 `Package.swift`，或直接使用 Swift Package Manager。
3. 提交前运行 iOS Simulator 测试。
4. 调试 demo 时，打开 `Demo/TabBarDemo.xcodeproj` 并运行 `TabBarDemo` scheme。

推荐测试命令：

```bash
DESTINATION_ID="$(xcrun simctl list devices available --json | python3 -c 'import json, sys; devices = [device for runtime in json.load(sys.stdin)["devices"].values() for device in runtime]; phones = [device for device in devices if device.get("isAvailable") and device.get("name", "").startswith("iPhone")]; print(phones[0]["udid"])')"
xcodebuild test \
  -scheme TabBar \
  -destination "platform=iOS Simulator,id=${DESTINATION_ID}"
```

## 代码规范

- 公开 API 保持克制，重点围绕 `TabBarController`、`TabBarView`、`TabBarItem` 和 `TabBarStyle`。
- 内部实现放在 `Sources/TabBar/Internal`。
- 优先使用 UIKit 原生能力，除组件确实需要外，不新增依赖。
- 修改 Swift 文件后，对改动文件执行 `swiftformat <file>`。

## Pull Request

提交 PR 前请确认：

- 行为变更已补充或更新测试。
- 公开用法变化已同步更新 `README.md`。
- 不包含无关重构。
- 视觉变化尽量附带截图或录屏。
