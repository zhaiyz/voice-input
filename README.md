# VoiceInput

<div align="center">

macOS 语音输入工具 - 按住 Fn 键说话，自动转录并注入文字

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

</div>

## ✨ 功能特性

- 🎤 **Fn 键全局监听** - 按住 Fn 键即可开始录音，不干扰系统功能
- ⚡ **设备端语音识别** - 使用 Apple Speech Framework，识别速度快，无时长限制
- 🎨 **优雅的悬浮窗** - 胶囊状设计，实时显示转录文本和波形动画
- 🤖 **LLM 精炼** - 支持 OpenAI 兼容 API，自动纠错和优化文本
- 🌍 **多语言支持** - 支持中文、英文、日文、韩文、繁体中文
- 🔒 **隐私优先** - 设备端识别，数据不上传云端

## 📋 系统要求

- macOS 14.0 或更高版本
- 麦克风权限
- 语音识别权限
- 辅助功能权限

## 🚀 安装

### 方法 1：从源码构建

```bash
# 克隆仓库
git clone https://github.com/zhaiyazhou/voice-input.git
cd voice-input

# 构建并安装
make install
```

### 方法 2：仅构建

```bash
make build
```

## 📖 使用方法

### 基本使用

1. **打开应用** - VoiceInput 会出现在菜单栏
2. **按住 Fn 键** - 屏幕底部会出现悬浮窗
3. **开始说话** - 实时查看转录的文字
4. **松开 Fn 键** - 文字自动注入到当前输入框

### 配置 LLM 精炼（可选）

1. 点击菜单栏图标
2. 选择 **LLM Refinement → Settings...**
3. 填写 API 配置：
   - **API Base URL**: 例如 `https://api.openai.com/v1`
   - **API Key**: 你的 API 密钥
   - **Model**: 模型名称，如 `gpt-4o-mini`
4. 点击 **Test** 测试连接
5. 点击 **Save** 保存配置
6. 勾选 **Enable LLM Refinement** 启用功能

### 切换识别语言

点击菜单栏图标，选择对应的语言即可。

## 🛠️ 开发指南

### 项目结构

```
voice-input/
├── Package.swift              # Swift Package Manager 配置
├── Makefile                   # 构建脚本
├── Sources/VoiceInput/
│   ├── VoiceInputApp.swift    # SwiftUI 应用入口
│   ├── AppDelegate.swift      # 应用生命周期管理
│   ├── GlobalEventMonitor.swift   # 全局 Fn 键监听
│   ├── SpeechRecorder.swift   # 语音录制和识别
│   ├── RecordingOverlayWindow.swift  # 悬浮窗 UI
│   ├── WaveformView.swift     # 波形动画
│   ├── TextInjector.swift     # 文字注入
│   ├── LLMRefiner.swift       # LLM API 调用
│   ├── SettingsViewController.swift  # 设置界面
│   └── LanguageManager.swift  # 语言管理
└── Resources/
    └── Info.plist             # 应用配置
```

### 构建命令

```bash
make build    # 构建应用
make run      # 构建并运行
make install  # 安装到 /Applications
make clean    # 清理构建产物
```

### 代码统计

- **总文件数**: 10 个 Swift 文件
- **总代码行数**: 1,175 行
- **类/结构体数**: 11 个

## ⚙️ 技术栈

- **语言**: Swift 5.9
- **UI 框架**: SwiftUI + AppKit
- **语音识别**: Apple Speech Framework (设备端)
- **音频处理**: AVAudioEngine
- **输入法管理**: Carbon TIS API
- **包管理**: Swift Package Manager

## 🔐 权限说明

VoiceInput 需要以下权限才能正常工作：

| 权限 | 用途 |
|------|------|
| 麦克风 | 录制语音 |
| 语音识别 | 将语音转换为文字 |
| 辅助功能 | 监听全局 Fn 键事件 |

所有语音识别都在设备本地完成，不会上传到云端。

## 📝 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📮 联系方式

如有问题或建议，请在 GitHub 上创建 Issue。

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

</div>