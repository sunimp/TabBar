# TabBar 项目约定

## iPhone Duo 验证

- Duo 姿态必须使用 Xcode Device Hub 验证，不使用 Simulator 菜单模拟折叠或展开。
- 纵向 TabBar 贴 leading/trailing 控制轨道边缘，位于 Toolbar 下方、底部系统保留区域上方；不要按整个屏幕 `midY` 居中。
- 纵向 TabBar 隐藏标题，使用系统 safe area 和 reserved regions 避让摄像头、折叠区域及其他系统控件。
- 展开内屏使用 `UISplitViewController` 组织会话列表和详情；compact 姿态自动折叠为单列。
- Demo 的列表、详情和输入栏必须使用 safe area，不能覆盖纵向 TabBar 区域。

## 截图

- Duo 截图保存于 `Screenshots/iphone-duo-closed.png` 和 `Screenshots/iphone-duo-open.png`。
- 更新 Duo 布局后，使用 Device Hub 重新生成闭合外屏和展开内屏截图，并同步更新 `README.md`。
