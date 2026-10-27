## 变更摘要

- 

## 测试

- [ ] `xcodebuild test -scheme TabBar -destination "platform=iOS Simulator,id=${DESTINATION_ID}"`
- [ ] `xcodebuild build -project Demo/TabBarDemo.xcodeproj -scheme TabBarDemo -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`
- [ ] 涉及 Duo：使用 Xcode 27.1+ 验证内外屏、旋转、保留区域和选中状态连续性。

## 截图或录屏

如果涉及视觉变化，请补充截图或录屏。
