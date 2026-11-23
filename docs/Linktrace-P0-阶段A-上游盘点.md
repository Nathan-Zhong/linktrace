# 循迹 Linktrace · 阶段 A 上游盘点

版本：v1.0　日期：2026-11-24　盘点方式：只读文本检查（grep / wc / ls），未执行仓库内任何脚本、未构建

## 1. 基线锁定

| 项目 | 值 |
|---|---|
| 上游仓库 | https://github.com/Ckxkx/account-atlas |
| 基线 HEAD | `9349de429f35ac595dc5524f78de17f15b19fbd4` |
| 基线说明 | `v2.2：合并 dev（#2）`，main 分支，共 83 个提交 |
| 标签 | v2.0、v2.1、v2.2 |
| LICENSE（GPL-3.0）SHA-256 | `3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986`（35,149 字节） |
| NOTICE.md SHA-256 | `3b1544edaf20cb8531e2b569ae15a54dfc2860b59194f1e8973213bc5fabcf28`（2,632 字节） |
| README.md SHA-256 | `d7c7b965ff1bd423d53fd04f49cec04119bfce5d8ce51717d1d952064e16107d` |

注意：上游在 2026-11-21 分析之后又推进了（当时 HEAD 为 ec5b817、68 个提交）。新基线多了微信/Apple 登录卡片等功能，与 PRD F01（QQ/微信/Apple ID 身份）直接相关，复用价值上升。盘点以新基线为准，旧分析中的行数以本文件为准。

## 2. 代码规模

| 位置 | 文件 | 规模 |
|---|---|---|
| 网页版 | `app.js` | 1,653 行 |
| 网页版 | `index.html`、`styles.css`、`sw.js`、`manifest.webmanifest` | 见仓库 |
| Android（Kotlin） | 14 个 main 文件（Components、Crypto、Details、Forms、Icons、MainActivity、MapScreen、Model、Presets、Settings、SitesScreen、Store、Sync、WalletScreen） | 约 3,700 行 |
| iOS（Swift） | 11 个 `native/` 文件（AppStore、AtlasApp、Components、Details、Forms、MapView、Model、Presets、Settings、SitesView、Sync、WalletView） | 约 3,300 行 |
| 测试 | `InteropTest.kt`（三端同步密文互通） | 1 个文件 |
| CI | `.github/workflows/` | android、appicons、ios、release、web 共 5 个 |

## 3. 权限盘点

| 平台 | 声明的权限 | 评价 |
|---|---|---|
| Android（`AndroidManifest.xml`） | `INTERNET`、`VIBRATE` | 只有两个。无无障碍、无悬浮窗、无存储、无通讯录等高敏权限，符合 SEC-04 最小权限起点 |
| Android | `android:allowBackup="false"` | 已关闭自动备份，SEC-03 的好起点；但 Linktrace 须按版本分别验证备份/迁移排除，不能只凭这一行 |
| iOS | 未发现 `NS*UsageDescription`、Associated Domains、Autofill 凭据提供方等 entitlement | 上游本来就没有自动填充能力；Linktrace 须**新增** Associated Domains 与 Credential Provider 配置（P0 新增项，非复用项） |

## 4. 网络请求盘点

| 目标 | 用途（据代码上下文） | P0 影响 |
|---|---|---|
| `api.github.com`、`gitee.com/api/v5` | 关系同步：读写私密 Gist（`atlas.enc.json`） | 保留。只传端到端加密载荷；密码等秘密禁入（SEC-02） |
| `github.com/settings/tokens/new`、`gitee.com/profile/personal_access_tokens/new` | 跳转链接，引导用户建同步令牌 | 保留。只是链接，不传数据 |
| `github.com/Ckxkx/account-atlas/releases/latest` | 指向原作者 Releases（疑似更新检查/下载链接） | **必须改**：换成 Linktrace 自己的发布地址，禁指向原作者渠道 |
| `favicon.im/`、`www.google.com/s2/favicons` | 为非预设网站拉取 favicon | **隐私点**：请求会向第三方暴露用户在用哪些平台。P0 须离线资源化或单独告知并获同意（SEC-02）；默认不得联网拉取 |
| `itunes.apple.com/search` | iOS `AppStore.swift` 搜索 App（添加平台时） | **隐私点**：搜索词会传给 Apple。P0 须评估：离线预设为主，联网搜索须告知并获同意 |
| `apple.com` DTD | Info.plist 的 XML 声明 | 无实际请求 |

## 5. 第三方 SDK 与依赖盘点

- **广告/分析/崩溃上报 SDK：无。** 全仓库 grep（firebase、analytics、crashlytics、sentry、admob 等）零命中。符合 SEC-02 默认不接入的起点。
- Android 依赖（`build.gradle.kts`，均须在 Linktrace 中锁定版本并做 SCA 扫描）：Compose BOM、material3、material-icons-extended、activity-compose 1.10.1、core-ktx 1.16.0、kotlinx-serialization-json 1.9.0、kotlinx-coroutines-android 1.10.2、OkHttp 4.12.0；测试 JUnit 4.13.2。
- iOS：无包依赖，直接 `swiftc` 编译 `native/*.swift`。
- 网页版：零依赖（纯 HTML/CSS/JS）。

## 6. 存储盘点

| 平台 | 现有存储方式 | P0 缺口 |
|---|---|---|
| 网页版 | `localStorage`（19 处引用） | 关系数据可用；**密码保险库禁入 LocalStorage**，P0 网页版不做保险库 |
| Android | `SharedPreferences`（3 处） | 关系数据与配置可用；秘密须另建加密保险库 + Android Keystore，现有代码**无 Keystore 使用** |
| iOS | `UserDefaults`（22 处） | 同上；秘密须另建加密保险库 + Keychain（`ThisDeviceOnly` 类属性），现有代码**无 Keychain 使用** |
| 三端 | 无 Room/SQLite、无加密数据库 | 保险库存储层是 P0 新建模块，不是复用项 |

## 7. 数据模型盘点（与 PRD 的对应）

上游已有模型（Android `Model.kt` 281 行、iOS `Model.swift` 562 行、网页 `app.js` 同构 JSON）：

- `Identity`：id、type（email/phone）、value、label、color、notes、updatedAt、order。
- `Account`：id、name、domain、category、identityIds、notes、handle、createdAt、updatedAt。
- `AtlasData`：identities、accounts、deleted（墓碑）、demo。
- 分类：社交、购物、支付金融、开发、AI、娱乐、游戏、出行、工具、加密、其他（11 个）。
- 预设：`icons/` 112 个网站/App 图标（1.9 MB），预设 100+。

P0 需要在模型上做的加法（非复用项）：身份类型扩展 QQ/微信/Apple ID/自定义；登录/绑定/恢复关系区分；密码凭据实体（与关系数据分域存放）；敏感自定义字段标记；密码历史与回收站实体；Passkey 预留字段（只记录，不实际保存）；变更历史实体。

同步加密信封（已验证互通）：PBKDF2-HMAC-SHA256 31 万次 → AES-GCM，`{v:1,salt,iv,ct,at}`，文件 `atlas.enc.json`，`InteropTest.kt` + 网页密文 fixture 证明三端同信封。P0 沿用该信封**只同步关系数据**的边界，参数与实现须重新审查确认。

## 8. 品牌与第三方素材盘点（SEC-06）

必须替换的原作者专有素材（均已确认存在）：

| 文件 | 说明 |
|---|---|
| `logo.svg`（67 KB） | 网页 Logo / favicon |
| `icon.png`、`icon-512.png` | 网页/PWA 图标、README Logo |
| `android/icon-src/icon-1024.png`（873 KB） | 安卓启动图标源文件 |
| `ios/Assets.xcassets/AppIcon.appiconset/icon-1024.png` | iOS AppIcon |
| `docs/wechat-reward.jpg` | 作者个人微信赞赏码 |

须逐一审查的第三方素材：`icons/` 下 112 个网站/App 图标归各自所有者，只能用于识别对应服务，不在本项目许可范围内；Linktrace 须逐个确认使用依据，不得宣称拥有。

同时须改：Android `applicationId`/`namespace`（现为 `dev.huichen.atlas`）、iOS Bundle ID、PWA manifest、CI 工作流、APK/IPA 文件名、指向 `huichen.dev` 与原作者 Releases 的链接；不复用原作者的签名密钥与发布配置。

## 9. 盘点结论

- **可复用的**：账号关系数据模型、三端同构 JSON、同步加密信封与互通测试、卡片/关系图/搜索等 UI 结构、零第三方 SDK 的干净起点、Android 仅 2 个权限。
- **必须新建的**：密码保险库与密钥管理（Argon2id + AES-256-GCM + Keystore/Keychain）、Android Autofill / Credential Manager 提供方、iOS Credential Provider Extension、备份加密与恢复、CSV 导入与冲突处理、安全中心、锁定/遮罩/剪贴板保护。
- **必须改掉的**：品牌素材、包名/域名/发布渠道、favicon 与 App Store 搜索的联网隐私点。
- 本盘点只覆盖“有什么”；“是否安全”须由后续的密钥与存储安全测试、抓包/备份/日志测试与独立审查回答，见《Linktrace-P0-验收矩阵》。
