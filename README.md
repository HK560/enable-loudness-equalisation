# Enable Loudness Equalisation (HK560 Fork)

Language: **English** | [简体中文](README_zh.md)

> **Repository URL**: [https://github.com/HK560/enable-loudness-equalisation](https://github.com/HK560/enable-loudness-equalisation)  
> *(Forked from [Falcosc/enable-loudness-equalisation](https://github.com/Falcosc/enable-loudness-equalisation))*

Automatically adds and enables Loudness Equalisation to any playback device on Windows.

Only works if your selected driver supports enhancements for speakers, but didn't expose this support for any other output devices. This script will expose any existing support, but cannot work if the driver doesn't ship any.

| before execution | after execution |
| --------------- | -------------- |
| ![Enhancements Missing](EnhancementsMissing.png)  | ![Enhancements Added](EnhancementsAdded.png)  |

If you are looking for bass boost, you can use the more complex version of this script [Falcosc/enable-bass-boost](https://github.com/Falcosc/enable-bass-boost).

---

## 🌟 What's New in HK560 Fork

This fork introduces several key usability and reliability improvements to `EnableLoudness.ps1`:

1. **📱 Interactive Audio Device Selection**
   - When running `EnableLoudness.ps1` without specifying `-playbackDeviceName`, the script automatically detects and lists all currently **active** audio rendering devices (`DeviceState -eq 1`).
   - Presents an intuitive, numbered interactive console menu to select your desired playback device.
   - If only 1 active playback device is detected on your system, it automatically selects it without prompting.
2. **🔍 Smart Device Matching & Invisible Character Filtering**
   - Displays friendly formatted names like `Realtek High Definition Audio (Realtek Audio)`.
   - Filters out non-printable/invisible Unicode control characters that often break device lookup in registry keys.
   - Supports fuzzy searching across `Name`, `FriendlyName`, `DeviceDesc`, and device registry property keys.
3. **🔑 Seamless Administrator Elevation**
   - If the script requires administrator elevation (UAC), it preserves the selected device name and parameters (e.g. `-releaseTime`) when spawning the elevated PowerShell window, avoiding repeated selections.
4. **🎨 Enhanced UI & Color-Coded Console Output**
   - Features a clean CLI banner and color-coded status messages (cyan/green/yellow/red) for easier debugging and user feedback.

---

## 🚀 How to Download and Run

### Quick Download & Run via PowerShell
Run the following in PowerShell:

```powershell
Invoke-WebRequest "https://raw.githubusercontent.com/HK560/enable-loudness-equalisation/main/EnableLoudness.ps1" -OutFile "$env:USERPROFILE\EnableLoudness.ps1"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
& "$env:USERPROFILE\EnableLoudness.ps1"
```

*(Note: We use `$env:USERPROFILE` instead of `$env:HOMEPATH` to avoid drive letter mismatch issues on non-C: drives).*

### Basic Usage Options

1. **Interactive Mode (Recommended)**:
   Simply run the script without parameters to interactively pick an active output device from a list:
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1"
   ```

2. **Specify Playback Device Name**:
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1" -playbackDeviceName BE279
   ```

3. **Custom Release Time**:
   Set the release time for sound level adjustments from `2` (fastest) to `7` (slowest, default is `4`):
   ```powershell
   & "$env:USERPROFILE\EnableLoudness.ps1" -releaseTime 2
   ```

---

## 🖥️ Using the Toggle Version with GUI

This script includes a toggle version with an AutoHotkey (AHK) GUI script for easier use:
1. **Install [AutoHotkey v2.0+](https://www.autohotkey.com/)** if you haven't already.
2. Save the `ToggleGui.ahk` script in the same folder as `EnableLoudness.ps1`.
3. Run `ToggleGui.ahk` to open a simple window with a button that toggles loudness equalisation when clicked.

### Environment Variables for the Toggle Script
For the toggle script to work correctly, the following environment variables must be set:
- **`HeadphonesName`**: Specifies the playback device name. This should match the beginning of the device name as shown in your system.
  - Example: 
    ```cmd
    setx HeadphonesName "YourDeviceName"
    ```
- **`ReleaseTime`**: Sets the release time for audio level adjustment, from 2 (fastest) to 7 (slowest).
  - Example:
    ```cmd
    setx ReleaseTime "4"
    ```

> **Note**: Setting these variables ensures the toggle script works with the intended playback device and adjustment speed.

### How to Set Environment Variables
1. Open Command Prompt as an administrator.
2. Use `setx` to set the environment variables:
   ```cmd
   setx HeadphonesName "YourDeviceName"
   setx ReleaseTime "4"
   ```
3. Restart Command Prompt or PowerShell to apply the changes, or reboot your system for a global update.

---

## ❓ When is it needed?
- HDMI, Display Port, Digital Optical Output playback devices usually don't have it exposed.
- If you cannot find an audio driver version which adds loudness equalisation to any of your playback devices.
- You can't enable it globally in your driver.

---

## 💡 Why does it need to be scripted?
- If you want to toggle it via hotkey.
- Windows updates mess with your audio drivers.
- Some use cases lead into re-registration of HDMI or DisplayPort playback devices, which will purge your settings every time.

---

## ⚙️ What does it do?
1. Searches for active playback devices by name/registry properties in Windows `MMDevices\Audio\Render`.
2. Imports audio enhancement registry settings:
    - `PreMixEffectClsid` and `PostMixEffectClsid`
    - `StreamEffectClsid` and `ModeEffectClsid`
    - Enhancement Tab UI definition
    - Loudness Equalisation flag
    - Release time value
3. Restarts the Windows Audio service (`audiosrv`) to apply changed registry values.

---

## ⚠️ Known Issues
- All setting flags stored in `fc52a749-4be9-4510-896e-966ba6525980` get overwritten, instead of just enabling loudness equalisation.
- Flags key are different across Windows versions; `fc52a749-4be9-4510-896e-966ba6525980` used in this script works for Windows 11, and Windows 10 as well.
- If the playback device gets re-detected, the audio service reboot might set volume to default 100%.
- Sound Settings UI shows 0% volume if it was open during restart (reopening fixes it).
- Restarting audio service after sleep does break the taskbar tray icon volume slider in some situations.
    - Media keys and Sound Settings UI volume control still work fine.
    - Tray icon slider gets fixed with full reboot.
- Does not work if your driver doesn't have any enhancements; try a different audio driver package.
- Incompatible devices will be unable to output audio until settings are restored.

---

## 🔄 Restore Settings
Most drivers restore default settings if the registry key gets removed, which is the manual way to restore.
Alternatively, reset settings via Device Manager (see [#28](https://github.com/Falcosc/enable-loudness-equalisation/issues/28)):
1. Open **Device Manager**.
2. Expand **Sound, video and game controllers**.
3. Right-click on your Audio Device.
4. Select **Uninstall device** (do **NOT** check "Delete driver software").
5. Reboot your system.

---

## ⏰ Install as Task
1. Open **Task Scheduler**.
2. Click **Action -> Create Task...**
3. Under **General**, check **Run with highest privileges**.  
   ![Run with highest privileges](TaskAdmin.png)
4. Under **Triggers**, click **New...**  
   ![Additional Triggers](TaskTrigger.png)
5. Under **Actions**, click **New...**:
    - **Action**: Start a program
    - **Program/script**: `powershell`
    - **Add arguments**: `-WindowStyle hidden -f "%USERPROFILE%\EnableLoudness.ps1" -playbackDeviceName BE279`
6. To test it, use an invalid DeviceName like `-playbackDeviceName XXX`; an error pop-up will appear upon login.  
   ![Test Error](ErrorTest.png)
