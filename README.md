# 循迹 Linktrace

本地优先的数字身份、平台账号与密码管理器。

> **状态：P0 开发中，尚未达到发布标准。** 安全与隐私高于功能、进度与发布目标；全部 P0 验收门槛通过之前，不发布、不宣称安全。当前验收状态见 [docs/Linktrace-P0-验收矩阵.md](docs/Linktrace-P0-验收矩阵.md)。

## 它是什么

记清哪个邮箱、手机号、QQ、微信、Apple ID 注册/绑定了哪些网站和 App；在系统支持的登录场景中，经用户许可安全保存与填充凭据。

- 身份与账号关系：本地管理，多身份、多账号、多标签、多分组
- 本地密码保险库：主密码 + 生物识别解锁，认证加密存储（规划中）
- 系统级保存与填充：Android Autofill / Credential Manager、iOS Credential Provider（规划中）
- 加密同步（仅账号关系，默认关闭）与加密备份：密码永不同步

## 非官方二创

本项目是 [Ckxkx/account-atlas](https://github.com/Ckxkx/account-atlas) 的非官方二次创作，与原作者无关，未获原作者背书。代码采用 GPL-3.0，详见 [NOTICE.md](NOTICE.md) 与 [LICENSE](LICENSE)。上游基线：account-atlas HEAD `9349de4`（v2.2）。

## 仓库内容

| 内容 | 说明 |
|---|---|
| `docs/Linktrace-P0-验收矩阵.md` | P0 逐项验收状态（当前全部未通过） |
| `docs/Linktrace-P0-阶段A-威胁模型与安全架构.md` | 威胁模型、数据分域、加密方案草案 |
| `docs/Linktrace-P0-阶段A-上游盘点.md` | 上游基线、权限、网络、依赖、素材盘点 |
| `SECURITY.md` | 安全漏洞私密报告渠道 |

代码尚未导入：当前仓库只有许可、声明与阶段 A 文档。代码导入（上游代码去品牌化 + 保险库等新模块）按阶段 B 推进。

## 许可

代码采用 GPL-3.0。原项目 Logo 与应用图标不在 GPL 范围内，本项目不使用。
