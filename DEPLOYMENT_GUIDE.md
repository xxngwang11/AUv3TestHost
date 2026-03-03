# iOS 部署验证指南

## 项目架构（3 个 Target）

```
┌─────────────────────────────────────────────────┐
│  AUv3TestHost （宿主 App）                        │
│  Bundle ID: com.test.AUv3TestHost               │
│  作用：扫描系统中所有 AUv3 插件并加载             │
│  → 第 ② 步部署                                   │
└─────────────────────────────────────────────────┘
        ↓ 扫描并加载

┌─────────────────────────────────────────────────┐
│  TestPluginContainer （插件容器 App）              │
│  Bundle ID: com.test.TestPluginContainer         │
│  作用：携带 TestEffectAUv3 扩展并将其注册到系统   │
│  → 第 ① 步部署                                   │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │  TestEffectAUv3 （AUv3 App Extension）       │ │
│  │  Bundle ID:                                  │ │
│  │    com.test.TestPluginContainer.TestEffectAUv3│ │
│  │  类型: aufx / 效果器                          │ │
│  │  名称: TestCompany: Test Effect              │ │
│  │  作用：实际的音频处理插件                     │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**关键关系：**
- `TestEffectAUv3` 是一个 App Extension，嵌入在 `TestPluginContainer` 中
- 部署 `TestPluginContainer` 时会自动安装 `TestEffectAUv3` 扩展
- `AUv3TestHost` 通过系统 API 扫描并加载已注册的 AUv3 扩展

---

## 部署步骤（先后顺序）

### 前提条件

- macOS 14.0+、Xcode 15.0+
- 真机 iOS 17.0+（**推荐使用真机**，模拟器对 AUv3 支持有限）
- Apple 开发者账号（用于代码签名）
- 两个 App 部署到**同一台设备**

### 第 ① 步：部署 TestPluginContainer（插件容器）

> **必须先部署！** 这一步将插件扩展安装到设备的系统中。

1. 在 Xcode 中打开 `AUv3TestHost.xcodeproj`
2. 左上角 Scheme 选择器 → 选择 **`TestPluginContainer`**
3. 设备选择器 → 选择你的 **iOS 真机**
4. 设置代码签名：
   - 选中 **TestPluginContainer** Target → Signing & Capabilities → 选择你的 Team
   - 选中 **TestEffectAUv3** Target → Signing & Capabilities → 选择 **同一个** Team
5. **Product → Run（⌘R）**
6. 设备上会出现一个简单的引导界面（"测试效果器插件"）
7. 看到界面后即表示扩展已注册成功
8. 可以关闭此 App（**不需要保持运行**）

**验证方式：** 在设备上打开 设置 → 通用 → 描述文件与设备管理，可以看到 TestPluginContainer 已安装。

### 第 ② 步：部署 AUv3TestHost（宿主 App）

> 在插件已安装之后部署宿主 App。

1. Scheme 选择器 → 选择 **`AUv3TestHost`**
2. 设备选择器 → 选择 **同一台 iOS 真机**
3. 设置代码签名：
   - 选中 **AUv3TestHost** Target → Signing & Capabilities → 选择你的 Team
4. **Product → Run（⌘R）**
5. App 启动后自动扫描系统中的 AUv3 插件

### 第 ③ 步：在宿主中加载插件并验证 UI

1. 打开 AUv3TestHost App
2. 顶部类型选择器 → 选择 **"Effect"**
3. 点击 **"刷新插件列表"**
4. 在列表中找到 **"TestCompany: Test Effect"**（由 Test 制造）
5. 点击该插件 → 进入插件详情页
6. 点击右上角 **"加载"** 按钮

**预期结果：**
- ✅ 插件加载成功，显示加载性能指标
- ✅ 插件 UI 区域显示效果器界面：
  - 标题："测试效果器"
  - 旁通开关
  - 增益滑块（0.0 ~ 2.0）
  - 状态显示
- ✅ 点击"播放测试音频"可以听到声音
- ✅ 拖动增益滑块可以改变音量

---

## 常见问题排查

| 问题 | 原因 | 解决方法 |
|------|------|----------|
| 插件列表中找不到 "Test Effect" | 容器 App 未安装或未注册 | 重新运行 TestPluginContainer → 等待出现界面 → 重启设备 → 再试 |
| 提示"无插件界面" | 插件 UI 加载失败 | 检查 Info.plist 中 `NSExtensionPrincipalClass` 是否为 `EffectViewController` |
| 加载时 EXC_BAD_ACCESS 崩溃 | 渲染线程访问了不安全的对象 | 确认已使用最新版本的 TestEffectAudioUnit（使用裸指针而非 AUParameter） |
| 加载时报错 | 代码签名问题 | 确保 TestPluginContainer 和 TestEffectAUv3 使用同一个 Team 签名 |
| 模拟器上找不到插件 | 模拟器对 AUv3 支持有限 | **使用真机测试** |

---

## 进程外 vs 进程内加载

宿主 App 界面上有一个 **"进程外加载"** 开关：

| 模式 | 说明 | 推荐场景 |
|------|------|----------|
| **进程外（默认开）** | 插件在独立进程中运行。插件崩溃不会导致宿主崩溃 | 正常使用 |
| **进程内（关闭开关）** | 插件在宿主进程内运行。调试更方便，但插件崩溃会影响宿主 | 调试插件代码 |

### 调试插件代码的技巧

如果需要在 Xcode 中断点调试 TestEffectAUv3 的代码：

1. 关闭宿主 App 的"进程外加载"开关
2. 在 Xcode 中选择 **AUv3TestHost** scheme 运行
3. 在 TestEffectAudioUnit.swift 或 EffectViewController.swift 中设置断点
4. 在宿主中加载插件 → 断点会被触发

或者使用进程外模式调试：

1. 在 Xcode 中运行 AUv3TestHost
2. **Debug → Attach to Process** → 找到 TestEffectAUv3 进程
3. 附加后即可断点调试

---

## 快速检查清单

- [ ] Xcode 中有 3 个 Target：AUv3TestHost、TestPluginContainer、TestEffectAUv3
- [ ] TestEffectAUv3 嵌入在 TestPluginContainer 中（Build Phases → Embed Foundation Extensions）
- [ ] 3 个 Target 全部设置了代码签名 Team
- [ ] 部署目标都是 iOS 17.0+
- [ ] 先在真机上运行了 TestPluginContainer
- [ ] 再在同一真机上运行 AUv3TestHost
- [ ] 在 Effect 类型下找到 "TestCompany: Test Effect"
- [ ] 加载后显示插件 UI（增益滑块 + 旁通开关）
