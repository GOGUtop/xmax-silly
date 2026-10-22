# GitHub Actions 自动编译 HAP

本工程已经包含 `.github/workflows/build-hap.yml`。

## 最快使用方式

1. 在 GitHub 新建一个仓库。
2. 把 `SillyTavernHarmonyShell` 目录中的所有文件上传到仓库根目录，注意必须包含隐藏目录 `.github`。
3. 打开仓库的 **Actions** 页面。
4. 选择 **Build HarmonyOS HAP**。
5. 点击 **Run workflow**，第一次建议选择 `debug`。
6. 构建完成后，在该次运行页面底部 **Artifacts** 下载 `SillyTavern-HarmonyOS-debug-...`。

## 自动触发

推送到 `main` 或 `master` 分支时会自动构建；PR 也会做构建验证。

## 当前签名状态

CI 默认生成未签名 HAP。它适合验证“项目是否能编译通过”，但真机安装通常还需要开发者签名。

如果需要 GitHub Actions 直接生成可安装的签名 HAP，需要准备华为开发者签名材料，并将证书/密码通过 GitHub Actions Secrets 注入。不要把 `.p12`、`.cer`、`.p7b` 或密码直接提交进仓库。

## 工具链

工作流目前使用 HarmonyOS 6.1 命令行工具的公开 GitHub 镜像。若希望完全由自己控制供应链，可以把 `COMMANDLINE_TOOLS_URL` 改成你自己的 GitHub Release、Cloudflare R2、OSS 或其他对象存储地址。

工程配置：

- modelVersion: `6.1.0`
- compileSdkVersion: `26.0.0`
- targetSdkVersion: `26.0.0`
- compatibleSdkVersion: `5.0.0(12)`
- Node.js: `18.20.1`
- Java: `17`

## 常见问题

### Actions 看不到工作流

确认 `.github/workflows/build-hap.yml` 已经上传，并且仓库 Actions 没有被禁用。

### 构建成功但不能安装

这是未签名 HAP 的正常情况。需要加入调试/发布签名。

### 下载工具链失败

修改 `.github/workflows/build-hap.yml` 中的 `COMMANDLINE_TOOLS_URL`，换成可访问的镜像地址。

### 网站打不开

应用首页固定为：

`http://aaa.xixisillytavern.top:8001/`

这是 HTTP 明文站点。如果后续系统策略、网络或服务器反向代理限制明文 HTTP，建议给域名配置 HTTPS。
