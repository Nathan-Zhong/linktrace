# 构建验证记录 · import/upstream-v2.2（5c48708）

日期：2026-11-24　验证对象：`import/upstream-v2.2` 分支（上游 account-atlas v2.2 + Linktrace 去品牌化）

## 结论

| 目标 | 结果 | 说明 |
|---|---|---|
| 网页版 | 通过 | `node --check app.js`（node v24.22.1）语法通过；`index.html` 引用的图标、manifest、样式、脚本文件齐全；manifest 已是 循迹 Linktrace |
| Android | 未能验证（环境限制） | 不是代码问题，构建根本没启动 |
| iOS | 未验证 | 本机无 macOS/Xcode，需 macOS runner |

未合并任何内容，未修改分支；main 仍在 a8aca11 且干净。

## Android 未能验证的根因（已独立复现）

Gradle 守护进程 IPC 必须走 JVM 回环 TCP；本机 VM 的沙箱拦截了 JVM 进程的 TCP 连接（含回环），返回策略消息：

> muse: Other TCP connections is turned off for this assistant. To allow it, ask the user to open Muse settings -> Permissions -> Direct network protocols and switch other_tcp from Deny to Ask.

独立复现（Java 回环测试）：向 `127.0.0.1` 上自己绑定的端口发包，读到的不是服务器回复，而是上述 193 字节策略消息；Python 同款回环测试正常。Gradle 报错 `Unexpected type tag 109` 中的 109 正是该消息首字母 `m` 的 ASCII 码。三次 Gradle 尝试（wrapper 下载超时、手动 Gradle 8.13 两次）均在握手阶段失败，构建从未启动，**没有观察到任何编译错误**。

附带事实：Gradle 8.13（与 wrapper 要求一致）；SDK `android-36` 平台已安装，与 `compileSdk = 36` 相符；build-tools 只有 35.0.0；未安装任何 SDK 组件（构建没走到那一步）。`gradle.properties` 写死 `-Xmx4g`，本机可用内存仅约 200–550 MB，重跑须用 `-Xmx1024m --max-workers=1` 覆盖；CI runner 内存充足则不受影响。

## 解锁 Android 验证的两条路

1. 用户在 Muse 设置 → Permissions → Direct network protocols，把 `other_tcp` 从 Deny 改为 Ask，然后重跑本次验证。
2. 改走 GitHub Actions CI 验证——需要新增 workflow 文件（分支有意排除了上游工作流，Linktrace CI 另行决策）。

## iOS 结构检查（未构建，仅确认文件齐全）

- `native/*.swift` 12 个文件齐全；`native/Info.plist` 显示名/包名 = 循迹，Bundle ID = `dev.linktrace.app`（`CFBundleExecutable` 仍为 `Atlas`，与既定决策一致）
- AppIcon 占位图有效 PNG 1024×1024；安卓图标同样有效，`icon-512.png` 512×512、`icon.png` 180×180

## 更新：GitHub Actions CI 验证（2026-11-24 00:59，全部通过）

用户 2026-11-24 00:54 选择走 GitHub Actions 验证。分支新增提交 `f33149a`（仅在 `import/upstream-v2.2` 上，main 未动），加入三份 Linktrace 工作流（`.github/workflows/web.yml`、`android.yml`、`ios.yml`，改编自上游工作流：只做构建验证，不发版、不签名、不部署、无 secrets、无上游引用）。

三次运行全部成功（已从 API 独立核实状态与产物）：

| 目标 | 运行 | 耗时 | 产物 |
|---|---|---|---|
| 网页版 | [Verify web app](https://github.com/Nathan-Zhong/linktrace/actions/runs/45221936326) | 8 秒 | 无（仅验证） |
| Android | [Build Android APK](https://github.com/Nathan-Zhong/linktrace/actions/runs/45221935714) | 3 分 43 秒 | `Linktrace-apk`，18,694,220 字节（debug APK） |
| iOS | [Build iOS IPA](https://github.com/Nathan-Zhong/linktrace/actions/runs/45221936150) | 2 分 19 秒 | `Linktrace-ipa`，2,657,718 字节（未签名 IPA） |

与上游构建命令的差异（均有意为之）：Android 只跑 `./gradlew assembleDebug`（上游是签名 release + 单元测试）；iOS 的 swiftc 命令与上游逐字相同，只改了 IPA/产物名，`VERSION` 写死 `dev`；Web 只验证不部署。附带注解：Android 运行上有 action 版本过期提示（setup-java v4 建议迁到 v5 等），不影响结果，合并后长期维护 CI 时可顺手升级。

结论：分支上的三端代码确实都能编出来；之前本机验证被沙箱挡住的问题云端不存在。合并决定待用户确认。
