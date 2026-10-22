# HarmonyOS 7.0 / API 26 适配说明

- `compileSdkVersion`: `26.0.0`
- `targetSdkVersion`: `26.0.0`
- `compatibleSdkVersion`: `5.0.0(12)`
- GitHub Actions Command Line Tools: `26.0.0.821`
- `modelVersion`: `26.0.0`

## 已修复的 ArkTS 编译问题

1. `notificationManager.addSlot()` 参数由错误的 `NotificationSlot` 对象改为 `SlotType.SOCIAL_COMMUNICATION`。
2. `WantAgentInfo.actionFlags` 改为正确字段 `wantAgentFlags`（通知点击与长时任务两处）。
3. Web 组件显式保留 ArkWeb 默认文件选择器，支持 SillyTavern 的 H5 文件导入入口。

## CI

工作流：`.github/workflows/build-hap.yml`

Actions 手动执行 `Build HarmonyOS 7 HAP (API 26)`，构建结束后在 Artifacts 下载 HAP。
