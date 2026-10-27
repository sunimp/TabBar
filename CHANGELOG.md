# 更新日志

本文件记录项目的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，版本号遵循语义化版本。

## [Unreleased]

## [0.2.0] - 2026-10-27

### 新增

- iPhone Duo 适配：纵向 TabBar 跟随系统纵向栏轨道（宽 48pt），闭合外屏与摄像头同列、展开内屏横握与状态栏同列、展开内屏竖握回到底部横向；横向布局避开摄像头与折叠区域。
- Demo：聊天、设置在 Duo 展开内屏显示列表 + 详情双栏，其它 iPhone 为标准 push/pop。

### 修复

- 后台切换浅色/深色后，回到前台 TabBar 外观未同步（#1）。
- Duo 姿态切换后纵向 TabBar 首帧位置与宽度错误。
- Demo：大标题不跟随滚动、持续下拉回弹失效、会话列表标题缺失；设置页 Duo 上分组卡片无圆角、图标与详情文字不显示；单栏 push 时 TabBar 未随前一页移出。

### 变更

- Demo 移除自定义导航栏，全部使用系统导航栏；设置「外观」增加未读红点。
- CI 改为 Xcode 26.3 / 26.6 双版本测试并构建 Demo。
- 补充公开发布所需的仓库元信息与文档。

## [0.1.0]

- 首个版本：浮动胶囊 TabBar、液态选中效果、角标与 Lottie 图标动画。

[Unreleased]: https://github.com/sunimp/TabBar/compare/0.2.0...HEAD
[0.2.0]: https://github.com/sunimp/TabBar/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/sunimp/TabBar/releases/tag/0.1.0
