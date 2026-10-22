# Push Kit 服务端增强方案（真正离线提醒）

客户端长时任务只能提高生成期间退后台的存活率，不能保证“进程已被系统回收后”仍能执行网页 JS。

要实现真正可靠的完成提醒，应把“生成完成事件”移动到服务端：

1. HarmonyOS App 获取 Push Token。
2. App 登录 SillyTavern 后把 token 绑定到当前用户/设备。
3. 服务端在一轮生成完成时调用 Huawei Push Kit 服务端 API。
4. Push payload 带上 chatId / characterId（不要带敏感正文）。
5. 用户点击通知后由 Want 参数打开 App，再由 WebView 导航到相应聊天。

需要你在 AppGallery Connect 创建项目后提供：

- App ID / Client ID 等项目配置
- 签名与 Profile
- Push 服务端凭据或安全的服务端调用环境

这些凭据不应硬编码进 App 或提交到公开仓库。
