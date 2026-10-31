# 心息 · HRV 原生 iPhone 验证版

SwiftUI + HealthKit。读取最近七天 HRV SDNN，显示最新值、时间、来源、散点图和全部记录。不上传、不写入健康数据，无第三方运行依赖。

## 当前状态

已准备源码和 GitHub Actions 构建配置，尚未运行 Xcode 编译或真机测试。Windows 本地无法执行 Apple SDK 编译。不能将源码交付视为安装成功。

最低 iOS 17。用户设备为 iPhone 17 / iOS 27.2；该版本的侧载工具兼容性仍需实测。Apple Watch 只作为苹果健康数据来源，首版没有 watchOS App。

## 1. 免费云端构建

1. 登录 GitHub，新建空仓库，例如 `hrv-companion`。私有仓库使用免费 Actions 配额；公开仓库标准运行器免费，但源码将公开。不要提交健康数据或 Apple 账号凭据。
2. 将本目录文件上传到仓库，必须包含 `.github/workflows/build-ios.yml`、`Sources`、`project.yml`。如使用网页上传，要检查隐藏目录也上传成功。推荐 GitHub Desktop 添加本目录并发布仓库。
3. 默认分支为 `main` 时上传会触发构建；其他分支可在 Actions → Build unsigned iOS app → Run workflow 手动触发。
4. 构建绿色通过后，在该次运行底部 Artifacts 下载 `HRVCompanion-unsigned` ZIP，解压得到 IPA。
5. 该 IPA 未签名，不能直接点击安装，必须通过下一步侧载签名。整个云端构建无需 Apple ID、密码或签名证书。

免费额度用尽时停止构建，不开通付费额度。构建失败时保留错误日志用于修复。

## 2. Windows 安装

按 AltStore Classic 官方指南配置 AltServer、所需 Apple 驱动和 iCloud/iTunes：
https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows

1. 用数据线连接解锁的 iPhone，点击信任电脑，按官方指南启用 Wi-Fi 同步。
2. 从 AltServer 安装 AltStore，Apple 账号和验证码只在本机官方安装工具里输入，不发给聊天或写进仓库。
3. 在 iPhone 设置中信任开发者，按需要启用开发者模式并重启。
4. 将 IPA 传到 iPhone 文件 App，再从 AltStore 的 My Apps 页面导入。
5. 如果提示移除权限，不能移除 `com.apple.developer.healthkit` 后仍声称支持健康读取。保存完整错误信息。如果免费签名无法包含该权限，停止此路径，改做快捷指令导入的原生版。

免费签名在 7 天后到期。在到期前，通过 AltStore Refresh All 续签；Windows AltServer 需要可连接。后台自动刷新可能失败，请检查到期时间。不要通过删除 App 来代替正常刷新。

## 3. 真机验收（未完成）

- [ ] IPA 能安装，重启后能打开。
- [ ] 点击“连接 / 刷新苹果健康”，系统显示读取 HRV 权限。
- [ ] 允许读取后，与苹果健康中同一条样本的时间、来源、数值对照。
- [ ] 没有样本或拒绝读取时显示解释，不生成演示数值，不误称已经授权。
- [ ] 断网后仍可读取已在手机上的健康数据。
- [ ] 重新刷新能显示新的已同步记录；刷新按钮不可并发触发请求。
- [ ] 在有效期内续签成功，App 仍可读取数据。

HealthKit 不向应用披露读取权限是否被拒绝，授权请求完成不代表拿到了数据。App 据此将无数据和未授权统一解释。

## 范围

这是一款用于验证安装与数据链路的原生 App。它不启动手表采样、不保证后台持续监测、不提供心理压力诊断、不计算未经验证的压力分数。完整产品需在以上验收通过后继续开发。
