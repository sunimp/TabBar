# TabBar 项目约定

## 开发

- 跟随现有 Swift/UIKit 风格，优先做最小完整修改。
- 修改公共 API、工程配置或依赖前，先确认影响范围。
- 新增或移动代码时同步更新调用方、测试和文档。
- 未明确要求时，不主动执行构建、测试或运行；执行后如实记录验证范围。
- iOS 27.1 / iPhone Duo API 用 `#if compiler(>=6.4)` + `#available(iOS 27.1, *)` 双重隔离，保证 CI 的 Xcode 26.x 可编译。

## iPhone Duo

参考 HIG [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)。

- 纵向判定唯一来源：`verticalBarEdge != .unspecified` 且 `layoutGuide(for: .bar(onEdge:extent:))` 非空；只有 `TabBarController` 设置 `TabBarView.isVertical`，不要在其他地方读 trait 判断。
- 轨道 frame、所在侧完全取自系统 guide；禁止自行按摄像头 occlusion、`midY` 或屏幕边缘计算位置。轨道已与状态栏、摄像头同列，并避开保留区域。
- 轨道宽度 `TabBarView.verticalBarExtent = 48`，与系统纵向栏按钮实测一致；改动需重新实测。
- bar guide 首次访问时 `layoutFrame` 为空，`viewDidLoad` 中需提前创建两侧 guide，否则姿态切换后首帧会错位。
- 纵向 TabBar 贴轨道底部（系统顺序：灵动岛、状态栏、Toolbar、TabBar），只显示图标。
- 预期布局：闭合外屏任意方向为纵向、与摄像头同列；展开内屏横握为纵向、与状态栏同列；展开内屏竖握为底部横向。
- Demo 自绘内容（消息区、输入栏等）约束到 `safeAreaLayoutGuide`，以避让左右两侧的纵向 TabBar 和摄像头列。plain `UITableView` 右侧约束到 safe area（否则分割线延伸进纵向栏区域）；`insetGrouped` 表格与容器控制器贴 view 边缘，由系统处理 safe area（否则靠纵向栏一侧丢失圆角）。
- Demo 只用系统导航：外层 `UINavigationController` 包 `DemoTabBarController`，不自绘导航栏。
- 聊天、设置继承 `ListDetailSplitViewController`（内含 `UISplitViewController`）：仅横纵 size class 均为 regular（Duo 展开内屏）时双栏，不用设备型号判断；其它情况（含 Pro Max 横屏、Duo 外屏）折叠为单栏。
- 单栏：显示外层导航栏，详情 push 到外层导航，TabBar 随前一页左移；双栏：隐藏外层导航栏，各栏用自身导航栏，详情替换 secondary 栏。
- 一级页面的列表须 `setContentScrollView(tableView)`，`ListDetailSplitViewController` 重写 `contentScrollView(for:)` 转发，`DemoTabBarController` 切 tab 时交给外层导航；否则大标题不跟随滚动（无下拉拉伸、不收起）。
- column 风格 split 折叠时用 `topColumnForCollapsingToProposedTopColumn` 返回 `.primary`；`collapseSecondary:onto:` 不生效。

## 验证

- 姿态切换使用 Xcode Device Hub，不使用 Simulator.app 菜单。
- 每次 Duo 布局改动，需在 Device Hub 依次验证：闭合（摄像头右上、右下、左上）、展开竖握、展开横握。
- 本地复现 CI：`DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer` 执行 README「验证」中的命令。

## 截图与文档

- Duo 截图由 Device Hub 截取（含机身外框），停在「聊天」页：
  - `Screenshots/iphone-duo-closed-1.png`：闭合外屏竖握（摄像头右上）。
  - `Screenshots/iphone-duo-closed-2.png`：闭合外屏横握（摄像头右下）。
  - `Screenshots/iphone-duo-open-1.png`：展开内屏横握。
  - `Screenshots/iphone-duo-open-2.png`：展开内屏竖握。
  - `Screenshots/iphone-duo-open-3.png`：半折叠。
- Duo 布局变化后重新生成全部 Duo 截图，并同步更新 `README.md` 的 Demo 截图表与「iPhone Duo」一节。
