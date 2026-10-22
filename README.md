# HarmonyOS 7 / API 26 GitHub Actions 版

> 本分支已按 HarmonyOS 7.0 / API 26.0.0 调整。GitHub Actions 使用 Command Line Tools 26.0.0.821。
> 关键兼容修复：Notification `addSlot(SlotType)`、WantAgent `wantAgentFlags`。

# SillyTavern HarmonyOS Shell

这是一个用于 HarmonyOS / HarmonyOS NEXT 的 ArkTS + ArkWeb 壳工程骨架，默认打开：

`http://aaa.xixisillytavern.top:8001/`

## 已实现

- ArkWeb 内嵌 SillyTavern
- JavaScript / DOM Storage / 文件访问
- 网页文件上传（ArkWeb 默认文件选择器；兼容 SillyTavern 导入）
- 网页下载代理，弹出系统“保存文件”选择器（兼容 SillyTavern 导出）
- 后退 / 前进 / 刷新 / 首页 / 清缓存
- SillyTavern 生成事件桥：`GENERATION_STARTED` / `GENERATION_ENDED`，兼容回退 `MESSAGE_RECEIVED`
- AI 回复完成后发送高优先级通知
- 生成期间申请 `dataTransfer` 长时任务，尽量保证退后台后生成不中断
- `module.json5` 已声明 `INTERNET`、`KEEP_BACKGROUND_RUNNING`、`VIBRATE` 与 `backgroundModes: ["dataTransfer"]`

## 最稳的使用方式

1. 用 DevEco Studio 6.1+ 新建一个 **Empty Ability / ArkTS / Stage 模型** 的 HarmonyOS 应用。
2. 将本压缩包的 `entry/src/main/` 覆盖到新项目对应目录。
3. 将 `AppScope/resources/base/element/string.json` 合并到项目同名文件。
4. 如果你的工程模板使用不同的资源名，请按 IDE 报错替换资源引用。
5. 真机运行。ArkWeb 在 Previewer 中不能完整预览。

> 本包也附带了常见的工程级配置文件，方便直接导入；但不同 DevEco / SDK 模板的 hvigor 版本会变化，若工程级配置报版本错误，优先采用上面的“新建空工程后覆盖 entry/src/main”方式。

## 重要：后台通知的能力边界

本项目在“AI 正在生成”期间申请 HarmonyOS 合法的 `dataTransfer` 长时任务，因为此时确实存在持续的数据传输。系统会显示用户可感知的持续任务通知。

这会显著提高退后台后的存活概率，但 **任何第三方应用都不能保证进程永远不被系统回收**。如果你要求：

- 锁屏很久；
- 应用被系统回收；
- 甚至手动划掉应用；
- AI 回复完成仍 100% 收到提醒；

则需要在 SillyTavern 服务端接入 **Huawei Push Kit**：服务端在生成完成后向手机 Push Token 推送。客户端单独靠 WebView 无法做到 100% 离线可靠提醒。

## HTTP 地址说明

你的地址是 HTTP 而不是 HTTPS。工程已开启网络权限，并允许 Web 组件混合内容。正式长期使用建议给站点加 HTTPS，避免明文传输 Cookie、聊天内容和登录信息。

## AI 回复完成桥接

`Index.ets` 在页面加载后注入脚本：

- 优先使用 `window.SillyTavern.getContext()`
- 监听 `event_types.GENERATION_STARTED`
- 监听 `event_types.GENERATION_ENDED`
- 若不存在 `GENERATION_ENDED`，回退到 `MESSAGE_RECEIVED`

网页通过 `window.HarmonyBridge` 调用 ArkTS 原生方法，从而启动/停止后台任务并发送通知。

## 下载/导出

ArkWeb 的下载默认保存在应用沙箱，用户看不到。因此本项目注册 `WebDownloadDelegate`，在下载开始时调用系统 Document Picker，让用户选择导出的保存位置。

若你使用的 SDK 对 `DocumentViewPicker.save()` 返回路径格式有变化，可把 `DownloadService.ets` 中的目标路径改为 `context.cacheDir + '/' + filename`，即可先确保下载正常，再增加二次“另存为”。

## Push Kit（可选，真正强后台）

本包未写死 AppGallery Connect 的 App ID、证书或服务端凭据。要做真正离线 Push，需要你自己的 AGC 项目资料。建议流程：

1. App 首次启动获取 Push Token。
2. 将 token 登录绑定到你的 SillyTavern 服务端用户。
3. SillyTavern 生成结束事件在服务端触发 Push Kit REST 推送。
4. 用户点击通知直接回到本 App / 当前聊天。

## 安全建议

JavaScriptProxy 只暴露三个无敏感数据方法：开始、完成、停止生成。不要向任意第三方网页暴露 Token、文件系统或系统设置能力。

## GitHub Actions 自动编译

工程已内置 `.github/workflows/build-hap.yml`。把整个项目上传到 GitHub 后，进入 Actions → Build HarmonyOS HAP → Run workflow，即可编译 HAP。首次建议使用 debug 模式。详细步骤见 `docs/GITHUB_ACTIONS_BUILD.md`。
