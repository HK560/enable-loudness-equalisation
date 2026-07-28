# 开启响度均衡 Enable Loudness Equalisation (HK560 Fork)

语言: [English](README.md) | **简体中文**

> **仓库地址**: [https://github.com/HK560/enable-loudness-equalisation](https://github.com/HK560/enable-loudness-equalisation)  
> *(Fork 自 [Falcosc/enable-loudness-equalisation](https://github.com/Falcosc/enable-loudness-equalisation))*

自动为 Windows 上的任何音频播放设备添加并开启“响度均衡”（Loudness Equalisation）功能。

仅当您当前选定的声卡驱动程序本身支持扬声器音效增强、但未对其他输出设备（如耳机、HDMI/DP 显示器音频）开放该功能时有效。本脚本可以解锁并暴露驱动中隐藏的增强支持；如果驱动程序完全没有包含音效处理模块，则无法生效。

| 执行前（无增强页） | 执行后（成功添加增强页与响度均衡） |
| --------------- | -------------- |
| ![Enhancements Missing](EnhancementsMissing.png)  | ![Enhancements Added](EnhancementsAdded.png)  |

如果您正在寻找低音增强（Bass Boost）功能，可以使用功能更复杂的版本：[Falcosc/enable-bass-boost](https://github.com/Falcosc/enable-bass-boost)。

---

## 🌟 HK560 Fork 版本修改内容

本 Fork 版本对 `EnableLoudness.ps1` 进行了多项易用性与稳定性方面的改进：

1. **📱 交互式输出设备菜单选择**
   - 当运行 `EnableLoudness.ps1` 未传入 `-playbackDeviceName` 参数时，脚本会自动检索当前所有**活跃**的声音输出设备（`DeviceState -eq 1`）。
   - 自动在控制台中打印带有序号的设备选择菜单，方便直接按数字选择目标设备。
   - 如果系统当前仅有 1 个活跃音频输出设备，脚本会自动选中该设备，无需手动输入。
2. **🔍 设备名称智能识别与特殊字符处理**
   - 友好格式化设备显示名称，如 `Realtek High Definition Audio (Realtek Audio)`。
   - 自动过滤清洗部分驱动注册表中包含的不可见/非法 Unicode 控制字符，防止设备匹配失败。
   - 支持对设备名称、FriendlyName、DeviceDesc 及其注册表属性键进行模糊搜索匹配。
3. **🔑 智能管理员权限提权 (UAC)**
   - 选定设备后，若脚本需要 UAC 管理员提权运行，会自动将选择的设备名称与参数（如 `-releaseTime`）传递至新弹出的管理员 PowerShell 窗口，避免重复选择。
4. **🎨 精致终端控制台交互与彩色输出**
   - 包含高亮 Console Banner 标头，并采用青/绿/黄/红彩色字体明确区分信息提示、选择列表与错误警示。

---

## 🚀 如何下载与运行

### 使用 PowerShell 快速下载并运行
在 PowerShell 中运行以下命令（自动下载、允许脚本运行并立即启动）：

```powershell
Invoke-WebRequest "https://raw.githubusercontent.com/HK560/enable-loudness-equalisation/main/EnableLoudness.ps1" -OutFile "$env:USERPROFILE\EnableLoudness.ps1"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
& "$env:USERPROFILE\EnableLoudness.ps1"
```
*(提示：这里使用 `$env:USERPROFILE` 替代了原版 README 中的 `$env:HOMEPATH`，避免当前处于非 C 盘目录下找不到文件的问题)*

### 基本用法选项

1. **交互模式（推荐）**：
   无需附加任何参数，直接运行脚本即可从列表中菜单式选择当前活跃的设备：
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1"
   ```

2. **指定设备名称运行**：
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1" -playbackDeviceName BE279
   ```

3. **自定义响应速度（Release Time）**：
   设置音量调整的响应速度，范围从 `2`（最快）到 `7`（最慢，默认值为 `4`）：
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1" -releaseTime 2
   ```
   *(注：在一些竞技类 FPS 游戏中使用更快响应时间 `2` 能够更快平抑突发爆音，但在日常听歌使用中较快响应可能会有轻微压缩感)*

---

## 🖥️ 使用带有 GUI 的切换版本 (Toggle Version)

本仓库包含一个借助 AutoHotkey (AHK) 实现的 GUI 图形界面切换脚本：
1. 请先安装 **[AutoHotkey v2.0+](https://www.autohotkey.com/)**。
2. 将 `ToggleGui.ahk` 保存在与 `EnableLoudness.ps1` 相同的目录下。
3. 运行 `ToggleGui.ahk` 即可打开一个简单的按钮窗口，点击按钮即可快捷切换响度均衡开/关状态。

### 切换脚本所需的环境变量
为使 GUI/切换脚本正常工作，请在系统中配置以下环境变量：
- **`HeadphonesName`**：指定目标播放设备名称（与系统中显示的设备名称开头相匹配）。
  - 示例（命令提示符 CMD 中运行）：
    ```cmd
    setx HeadphonesName "YourDeviceName"
    ```
- **`ReleaseTime`**：设置音量调整的响应速度（从 2 到 7）。
  - 示例：
    ```cmd
    setx ReleaseTime "4"
    ```

### 如何设置环境变量
1. 以管理员身份打开命令提示符 (CMD)。
2. 使用 `setx` 命令配置环境变量：
   ```cmd
   setx HeadphonesName "YourDeviceName"
   setx ReleaseTime "4"
   ```
3. 重新启动终端或重启电脑以使环境变量全局生效。

---

## ❓ 什么时候需要此脚本？
- HDMI、DisplayPort 或数字光纤输出设备通常默认未开放响度均衡选项。
- 找不到能为指定音频设备暴露“响度均衡”选项的声卡驱动版本。
- 无法在驱动控制面板中全局开启音效增强。

---

## 💡 为什么需要脚本化？
- 希望通过快捷键或一键按钮快速切换“响度均衡”开关。
- Windows 更新经常重置或覆盖声卡驱动配置。
- 某些使用场景（如重新插拔显示器、睡眠唤醒）会导致 HDMI 或 DisplayPort 设备重新注册，从而清除已设置的音效属性。

---

## ⚙️ 脚本具体做了什么？
1. 在 Windows 注册表 `MMDevices\Audio\Render` 中按名称/属性匹配并检索活跃播放设备。
2. 写入并导入音频增强注册表项：
    - `PreMixEffectClsid` 与 `PostMixEffectClsid`
    - `StreamEffectClsid` 与 `ModeEffectClsid`
    - 音效增强标签页（Enhancement Tab）UI 定义
    - 响度均衡（Loudness Equalisation）使能标志
    - 响应时间（Release Time）配置值
3. 强制重启 Windows Audio 服务（`audiosrv`）使注册表修改生效。

---

## ⚠️ 已知问题
- 注册表 `fc52a749-4be9-4510-896e-966ba6525980` 中的所有配置标志会被覆盖，而不是只单点修改响度均衡使能位。
- 注册表标志键值在不同 Windows 版本之间可能存在差异；脚本中使用的 `fc52a749-4be9-4510-896e-966ba6525980` 已验证支持 Windows 11 及 Windows 10。
- 如果播放设备被重新识别，音频服务重启后可能会短暂将系统主音量恢复为默认的 100%。
- 如果在音频服务重启时“声音设置”窗口正处于打开状态，窗口可能显示音量为 0%（重新打开声音设置窗口即可恢复）。
- 在某些情况下，电脑从睡眠唤醒后重启音频服务可能会导致任务栏右下角音量滑块失效（但键盘媒体键及系统 sound control 依然正常工作，完整重启系统后可修复滑块）。
- 如果当前使用的声卡驱动包完全不包含任何音效处理组件（FX Package），则脚本无法生效，建议尝试安装不同版本的驱动程序。
- 不兼容的音频设备导入该配置后可能无法输出声音，直至恢复原始驱动设置。

---

## 🔄 恢复原始设置 / 卸载

### 方法 1：使用卸载脚本自动还原（推荐）
在 PowerShell 中运行以下一键脚本即可移除已启用的响度均衡配置并恢复系统默认音效设置：

```powershell
Invoke-WebRequest "https://raw.githubusercontent.com/HK560/enable-loudness-equalisation/main/DisableLoudness.ps1" -OutFile "$env:USERPROFILE\DisableLoudness.ps1"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
& "$env:USERPROFILE\DisableLoudness.ps1"
```

你也可以在本地直接运行该脚本并从菜单中选择目标设备：
```powershell
& "$env:USERPROFILE\DisableLoudness.ps1"
# 或者指定设备名称：
& "$env:USERPROFILE\DisableLoudness.ps1" -playbackDeviceName BE279
```

### 方法 2：通过设备管理器重置声卡
如果需要完全重置声卡，也可以通过设备管理器重置声卡设置（参考 [#28](https://github.com/Falcosc/enable-loudness-equalisation/issues/28)）：
1. 打开**设备管理器**（Device Manager）。
2. 展开**声音、视频和游戏控制器**。
3. 右键点击您的音频设备。
4. 选择**卸载设备**（**切勿**勾选“尝试删除此设备的驱动程序”）。
5. 重启电脑。

---

## ⏰ 配合计划任务使用 (登录/开机自动启用)
1. 打开 **任务计划程序** (Task Scheduler)。
2. 点击 **操作 -> Create Task...**
3. 在 **常规** 选项卡中，勾选 **使用最高权限运行**。  
   ![使用最高权限运行](TaskAdmin.png)
4. 在 **触发器** 选项卡中，点击 **新建...** 设置触发条件（如登录时或开机时）。  
   ![触发器设置](TaskTrigger.png)
5. 在 **操作** 选项卡中，点击 **新建...**：
    - **操作**：启动程序
    - **程序或脚本**：`powershell`
    - **添加参数**：`-WindowStyle hidden -f "%USERPROFILE%\EnableLoudness.ps1" -playbackDeviceName BE279`
6. 测试方法：可以使用不存在的设备名称（如 `-playbackDeviceName XXX`），登录后若弹出错误提示框则说明计划任务配置成功。  
   ![测试错误提示](ErrorTest.png)
