# SmarterGamers DLSS 5 Swapper · 简体中文汉化版

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/version-2.3.0-2ea44f.svg)](#)

本仓库是 [**SmarterGamers/SmarterGamers-DLSS5-Swapper**](https://github.com/SmarterGamers/SmarterGamers-DLSS5-Swapper) v2.3.0 的**简体中文汉化版**，由社区独立维护。

上游项目以 MIT 协议开源。本仓库**只翻译界面文案**，不改动任何功能逻辑。

> **非官方项目**。上游与本仓库无隶属关系。遇到功能问题请先在本仓库还原原版，确认是否汉化引入。

---

## 一、下载

不想自己折腾？直接下打包好的成品：

| 下载 | 大小 | 说明 |
|---|---|---|
| **[汉化便携版](../../releases)** | ~902 MB | 解压即用，`resources\app.asar` 已是中文 |
| **[汉化补丁包](../../releases)** | ~300 MB | 给已装官方 2.3.0 的用户，换掉 asar 即可 |

补丁包内附 `install-zh-CN.ps1` / `restore-original.ps1`，双击运行，自带备份与 SHA-256 校验。

**安装补丁**：右键 `install-zh-CN.ps1` → 使用 PowerShell 运行 → 按提示选安装位置。
**还原原版**：右键 `restore-original.ps1` → 使用 PowerShell 运行。

两个脚本的行为：

- 覆盖前把原包备份成 `app.asar.original-2.3.0`，**已存在的备份绝不覆盖**
- 复制完重算 SHA-256，不符自动回滚
- 读取目标 asar 内的 `package.json` 确认版本是 2.3.0，不是则要求二次确认
- 已经是汉化版就跳过，不重复写盘

---

## 二、汉化覆盖到什么程度

| 项 | 上游 2.3.0 | 本仓库 |
|---|---:|---:|
| 主字典 `src/renderer/i18n.js` 中文键 | 81 / 268（30.2%） | **278 / 278（100%）** |
| 副字典 `src/shared/feature-i18n.js` 中文键 | 83 / 86（96.5%） | **86 / 86（100%）** |
| 游戏内叠加层（独立离屏文档） | 全英文 | **可译文本清零** |
| 托盘菜单 | 英文 | 中文（随语言设置切换） |
| 主界面 `data-i18n` 挂载点 | 39 | 39（未新增，补全了原有挂载） |

### 数字为什么对不上 268 和 278

上游 2.3.0 的 `en` 字典有 **268** 个键，但界面里存在**没有登记在字典里的硬编码英文**，以及上游删掉键之后 HTML 仍在引用的**孤儿键**。汉化时这两类都要补进去，所以最终中文键数是 **278**：

- 268 个上游已有键 → 全部给中文
- 5 个上游已删、但 HTML 仍在用的键 → `olHotkeyTitle` / `olKeyHelp` / `olCustomTitle2` / `olKeyCancel` / `olKeySave`
- 5 个上游从未登记、硬编码在 JS 里的键 → 例如扫描摘要 `Found N games across M sources`

副字典同理：上游 `en` 86 键、中文本有 83，补上 `errOptiVulkanLayer`、`errOptiConflict`、`legacyDownloadHint` 三条。

---

## 三、改了哪些文件

**改动的源码文件恰好 10 个**。其余 **132 个文件与上游 v2.3.0 逐字节相同**（已用 git blob 哈希逐个核对，不只是 `diff` 无输出）。

| 文件 | 上游 | 汉化后 | 性质 |
|---|---:|---:|---|
| `main.js` | 95,740 | 93,898 | 托盘译文同步、切语言时通知游戏内面板 |
| `src/renderer/i18n.js` | 78,197 | 95,083 | 主字典 |
| `src/shared/feature-i18n.js` | 373,124 | 381,548 | 副字典 |
| `src/renderer/index.html` | 28,565 | 28,450 | 补 `data-i18n` 挂载点 |
| `src/renderer/renderer.js` | 77,429 | 76,536 | 启动推送托盘译文、扫描摘要走字典 |
| `src/renderer/overlay-panel.js` | 5,851 | 16,249 | 叠加层翻译层 |
| `src/renderer/overlay-gallery.js` | 11,991 | 13,867 | 叠加层画廊翻译 |
| `src/renderer/chat.js` | 43,669 | 45,048 | 聊天页中文映射 |
| `src/renderer/community.js` | 91,089 | 94,795 | 社区页中文映射 + 计数修正 |
| `src/overlay-bridge.js` | 11,039 | 11,443 | 语言同步通道 |

换行符说明：上游工作区是 CRLF、索引存 LF。本仓库沿用上游的 `core.autocrlf` 策略，提交进索引的仍是 LF，所以 diff 里不会出现"整文件重写"的假象。

### 必须如实说明

**业务逻辑零改动，但不是"只有文本变了"。**

`overlay-panel.js`、`overlay-gallery.js`、`overlay-bridge.js` 三个文件带**翻译层代码**。原因：游戏内叠加层是独立的离屏文档（`overlay-panel.html`），不经过主界面的 `data-i18n` 机制，只能用文本节点替换 + `MutationObserver` 实现翻译。这套做法沿用自 2.2.9 汉化。

其余 7 个文件是纯文本替换或字典数据，代码骨架逐字未变。

---

## 四、修掉的两个上游缺陷

这两个不是汉化问题，是 2.3.0 本身的问题，顺手修了：

1. **插件页显示 `null替换内置插件`**
   `main.js:141` 的 `label: known.name || label` 中，payload 来源传来的 `label` 是 `null`；`renderer.js:4` 的 `esc()` 里 `String(null)` 得到字符串 `"null"`。
   修法：`esc(a.label || a.file)`。

2. **社区页切换语言后计数不刷新**
   `community.js` 的 `applyLanguage()` 重置了所有筛选标签，唯独没重新渲染游戏计数。
   修法：记住服务端返回的 total，切语言时按当前范围重算。

---

## 五、术语口径

**专有名词保持英文原文**：DirectX、DLSS、ReShade、Feeder、RenoDX、OptiScaler、NVIDIA、Steam、Vulkan、OpenGL、SmarterGamers。

**通用词翻译**（完整 278 条见 [`docs/术语对照表.md`](docs/术语对照表.md)，该表由出货字典直接生成，不会与程序实际文案脱节）：

| English | 简体中文 |
|---|---|
| Install | 安装 |
| Restore originals | 还原原文件 |
| Overlay | 叠加层 |
| Add-ons | 插件 |
| Hotkey | 热键 |
| Route | 安装方式 |
| Rendering API | 渲染 API |
| Community-tested games | 社区实测游戏 |
| Working / Works with issues / Not working | 可用 / 可用但有瑕疵 / 不可用 |

**不算"英文残留"的**：游戏名（`IXION`、`STEINS;GATE`…）、文件路径（`E:\SteamLibrary\...`）、渲染 API 徽标、`BETA` / `LIVE` 状态徽标、`by SmarterGamers` 品牌行、DLL 文件名。

---

## 六、升级之后怎么办

上游**没有内置自动更新器**（全部 JS 里搜不到 `autoUpdater` / `electron-updater` / `checkForUpdates`），但**手动重装新版会整包覆盖 `resources\app.asar`**，汉化会消失。

重装之后：

1. 版本号仍是 **2.3.0** → 直接再跑 `install-zh-CN.ps1`
2. 版本号变了 → **不能复用此补丁**，字典结构可能已变，需重新制作

判断版本：设置页底部，或安装目录 `resources\app.asar` 的时间戳。

---

## 七、从源码构建

```bash
git clone https://github.com/CBEdwin/SmarterGamers-DLSS5-Swapper-CN.git
cd SmarterGamers-DLSS5-Swapper-CN
npm install
npm start          # 开发模式运行
npm run dist       # 打包成安装版与便携版，产物在 dist/
```

前置：Windows 10/11 64 位、Node.js 18+、Git。

大文件 `resources/payload/streamline/nvngx_dlssnr.dll` 通过 **Git LFS** 存储，克隆前请先 `git lfs install`。

---

## 八、与上游同步

本仓库**不保留上游 git 历史**（首个提交是导入 v2.3.0 文件树的根提交），因此不能用 `git rebase` 同步。上游发新版时的做法：

1. 下载新版源码树
2. 用本仓库的 10 个汉化文件覆盖对应路径
3. 逐项核对是否有新增英文字符串需要翻译（重点看 `i18n.js` 的 en 块与各渲染器里的硬编码文案）
4. 重新打包 asar，跑一遍可见英文审计

---

## 九、许可证与致谢

本仓库同样以 **MIT** 协议发布，见 [LICENSE](LICENSE)。上游版权声明保留在 LICENSE 文件与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 中。

- **SmarterGamers DLSS 5 Swapper** — [SmarterGamers](https://SmarterGamers.com)，MIT
- **原版 DLSS 5 Swapper 架构** — Rakan Alkhaldi（[rakanki911](https://github.com/rakanki911)），MIT
- **DLSS5-Feeder** — [jlrouzies-fr](https://github.com/jlrouzies-fr/DLSS5-Feeder)，MIT
- **OptiScaler DLSS-NR** — [Dagherbou](https://github.com/Dagherbou/OptiScaler_DLSSNR)、[wilsjo2](https://github.com/wilsjo2/OptiScaler-DLSSNR-PreSR-Multipass)，GPL-3.0
- **RenoDX** — [ShortFuse](https://github.com/clshortfuse/renodx)
- **dgVoodoo2** — [Dege](https://github.com/dege-diosg/dgVoodoo2)
- **LumeniteFX** — [umar-afzaal](https://github.com/umar-afzaal/LumeniteFX)

上游项目地址：https://github.com/SmarterGamers/SmarterGamers-DLSS5-Swapper
