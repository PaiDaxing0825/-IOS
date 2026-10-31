# 心息验证版设计

用户选择方案 A：原生 iOS、Windows 侧载、云端编译、无开发者会员付费，并同意先验证数据链路。

技术：SwiftUI + HealthKit + Charts；iOS 17 起；XcodeGen 生成工程，GitHub Actions macOS runner 构建未签名 IPA，AltStore 在本机签名。

首版读取最近七天 SDNN，不写入健康数据；展示最新值、时间、来源、散点图、历史列表、错误及空态。用户点击才请求权限。没有服务器、不保存健康数据到磁盘、不上传。

备选：若免费签名不支持 HealthKit，原生 App 保留，但另行实现快捷指令导入。目前不实现该分支。SideStore 可后续验证，首版以 AltStore 官方 Windows 流程为准。

验收门槛：云端编译通过、真机安装成功、权限和真实数据读取成功、刷新签名成功。不能在 Windows 静态检查后宣称完成这些验收。
