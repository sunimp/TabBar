# TabBar 项目约定

## 开发

- 跟随现有 Swift/UIKit 风格，优先做最小完整修改。
- 修改公共 API、工程配置或依赖前，先确认影响范围。
- 新增或移动代码时同步更新调用方、测试和文档。
- 未明确要求时，不主动执行构建、测试或运行；执行后如实记录验证范围。

## iPhone Duo

- 姿态验证使用 Xcode Device Hub，不使用 Simulator 菜单模拟折叠或展开。
- 纵向 TabBar 贴系统指定的 leading/trailing 控制轨道，位于 Toolbar 下方和底部保留区域上方；禁止按全屏 `midY` 居中。
- 纵向布局隐藏标题，使用 safe area 和 reserved regions 避让摄像头、折叠区域及系统控件。
- 展开内屏使用 `UISplitViewController`；compact 姿态自动折叠为单列。
- Demo 的列表、详情和输入栏必须避让纵向 TabBar。

## 截图与文档

- Duo 截图：`Screenshots/iphone-duo-closed.png`、`Screenshots/iphone-duo-open.png`。
- Duo 布局变化后，用 Device Hub 重新生成两种姿态截图，并同步更新 `README.md`。
