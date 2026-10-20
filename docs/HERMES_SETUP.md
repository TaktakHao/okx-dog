# OKX-Dog v6.0 - Hermes Agent 多角色设定与通讯网关配置指南

OKX-Dog v6.0 全面采用 Nous Research 开源的 **Hermes Agent (`nousresearch/hermes-agent`)** 替代原有的 Web 看板方案。  
通过 Hermes 原生支持的 **多角色设定 (Multi-Persona)**、**消息通讯网关 (Gateway)** 与 **本地 CLI 执行能力**，你可以在手机即时通讯工具（微信、QQ、Telegram、Discord、Slack 等）中直接与 6 大虚拟量化员工对话、下发任务、查看战绩并接收紧急风控报警。

---

## 1. 为什么选择 Hermes Agent 多角色架构？

| 维度 | 原 Paperclip 方案 | Hermes Agent 方案 |
| :--- | :--- | :--- |
| **交互入口** | 依赖浏览器登录 Web 看板 (`:3100`) | **直接在手机聊天软件 (微信/TG/QQ) 中对话** |
| **突发报警** | 无法主动弹窗，需定时刷新网页 | **即时消息唤醒、手机秒级振动报警** |
| **晨间复盘** | 生成网页工单 Issue | **每日 08:00 自动推送图文战绩日报卡片** |
| **系统开销** | Node.js + 嵌入式 PostgreSQL (~350MB) | **宿主机极轻量 Python/uv 进程 (~100MB)** |
| **调参审批** | 网页点击 Approval 按钮 | **聊天中回复“确认”即可原子生效并快照备份** |

---

## 2. 6 大虚拟员工在册花名册与职责

所有员工配置与提示词位于仓库 `hermes/personas/` 目录，契约对齐于 `contracts/hermes/personas_contract.json`：

| 员工代码 | 姓名 | 岗位头衔 | 核心职能与例程 | 配置文件 |
| :--- | :--- | :--- | :--- | :--- |
| `CHIEF_ARBITER` | **陈守拙** | 首席投决仲裁官 (执行 CEO) | 统筹协调、多空冲突仲裁、经验知识库沉淀、调参提案审批 | `hermes/personas/chen_shouzhuo.md` |
| `BULL_SPECIALIST` | **张大炮** | 多头趋势研究员 | 均线共振突破动量挖掘、每周日夜间样本外网格调参提案 | `hermes/personas/zhang_dapao.md` |
| `BEAR_CRITIC` | **周铁山** | 铁血风控审计官 (红队) | 7x24h 盯盘巡检 (每5分钟)、单日回撤熔断、红队紧急停机 | `hermes/personas/zhou_tieshan.md` |
| `MACRO_NEWS` | **林望远** | 宏观与资讯分析师 | 美联储利率决议/CPI追踪、宏观情绪研判、黑天鹅舆情预警 | `hermes/personas/lin_wangyuan.md` |
| `MICROSTRUCTURE` | **赵小刀** | 盘口微观结构交易员 | 盘口挂单深度异动监控、Smart Pegging Post-Only 执行优化 | `hermes/personas/zhao_xiaodao.md` |
| `CFO_AUDITOR` | **钱公道** | CFO / 战绩审计总监 | 每日 08:00 战绩复盘推送、夏普比率计算、战绩额度奖惩 | `hermes/personas/qian_gongdao.md` |

---

## 3. 安装与初始化 Hermes Agent

### 3.1 一键安装 Hermes CLI
在 Mac mini 终端中运行官方安装脚本：

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.zshrc
```

### 3.2 运行环境自检
OKX-Dog 提供了开箱即用的自动化自检脚本：

```bash
python3 scripts/setup_hermes.py
```
期望输出：
* ✔ 6 大虚拟员工多角色配置已就绪；
* ✔ Hermes 专属技能包 (`hermes/skills/okxdog_ops/SKILL.md`) 规范有效；
* ✔ 本地安全运维 CLI (`scripts/okxdog_ops_cli.py`) 通信正常。

---

---

## 4. Hermes Web Dashboard 看板与桌面端

Hermes 官方提供了完善的 Web 管理面板与桌面端，让您无需仅依赖命令行：

### 4.1 启动 Web Dashboard 看板 (端口: 9119)
```bash
# 启动本地看板 (自动打开 http://127.0.0.1:9119)
hermes dashboard

# 或通过全生命周期脚本一并拉起
./company.sh start
```
看板包含三大核心功能板块：
* **🧩 Skills（技能管理）**：查看已加载的量化运维技能 `okxdog_ops`，支持点击「Learn a skill」直接输入文档 URL 或代码目录一键学习扩展新能力；
* **🔌 Gateway（通讯网关）**：图形化开启和管理微信、QQ、Telegram、Discord 等消息连接；
* **⚙️ System Settings**：管理 API Key、Cron 定时任务与持久化长期记忆（Persistent Memory）。

### 4.2 桌面端客户端 (Hermes Desktop)
* 可在终端直接运行 `hermes desktop` 唤出原生窗口；
* 或前往 [官网下载 DMG 安装包](https://hermes-assets.nousresearch.com/Hermes-Setup.dmg?build=226eeeb4c21c)。

---

## 5. 手机通讯通道接入 (Hermes Gateway)

Hermes Agent 原生自带统一消息网关 `hermes gateway`，可将聊天消息直接转译给对应的虚拟员工：

### 5.1 绑定 微信 (WeChat / 企业微信)
1. **个人微信（免公网 IP，扫码即用）**：
   * Hermes 原生支持腾讯官方 **iLink Bot API**，采用 Long-Polling 长轮询机制，**无需公网 IP 和 Webhook**；
   * 在 Dashboard 的 Gateway 页面或执行 `hermes gateway setup`，选择 Weixin / WeChat；
   * 手机微信扫描屏幕上的二维码完成授权，即可直接私聊对话。
2. **企业微信 (WeCom)**：
   * 支持企业微信 **AI Bot WebSocket Gateway**，直接走全双工长连接，配置机器人凭据即可无感双向收发。

### 5.2 绑定 QQ (QQ Bot)
1. **官方 QQ 机器人（腾讯开放平台 API v2）**：
   * 在 [QQ 开放平台 (q.qq.com)](https://q.qq.com) 创建机器人，在 Hermes Dashboard 填入 `AppID` 和 `ClientSecret`；
2. **NapCatQQ 机器人框架**：
   * Hermes 内置 NapCat WebSocket 客户端适配器，配置本地 WebSocket 地址（如 `ws://127.0.0.1:8646/napcat/ws`）即可收发群消息与私信。

### 5.3 对接 Telegram / Discord
执行官方配置向导：
```bash
hermes gateway setup
```
输入 Telegram Bot Token 或 Discord Token 即可秒级开启。

---

## 6. 跨机器远程 Hermes 环境一键启动

如果您在**另一台电脑（如另一台 Mac mini、Linux 服务器或云主机）**上已经配置好了 Hermes 环境、大模型凭据和微信/QQ 登录态，OKX-Dog 提供了**一键跨机器远程启动与安全隧道映射**支持：

```bash
# 1. 一键拉起全套交易内核，并自动通过 SSH 唤醒远端电脑的 Hermes 并建立端口映射
./company.sh start user@192.168.1.100

# 2. 或者在环境变量中设定默认远程主机
export HERMES_REMOTE_HOST="user@192.168.1.100"
./company.sh start

# 3. 单独远程拉起、停止或查询另一台电脑上的 Hermes
./company.sh remote-hermes user@192.168.1.100 start
./company.sh remote-hermes user@192.168.1.100 status
./company.sh remote-hermes user@192.168.1.100 stop
```

**工作机制**：
* 脚本通过 SSH 自动在远端拉起 `hermes gateway (8088)` 与 `hermes dashboard (9119)`；
* 并在本地建立 SSH 隧道，将远端端口直接映射到本地 `localhost:9119` 和 `localhost:8088`；
* 您在本机打开 `http://localhost:9119`，就能完全无感、像操作本地一样访问远端电脑上的 Hermes 看板与微信/QQ 状态！

---

## 7. 本地安全 CLI 与防误触防护

员工在聊天中执行的所有操作均被严格限制在 [`scripts/okxdog_ops_cli.py`](file:///Users/wesson/OKX-dog/scripts/okxdog_ops_cli.py) 白名单内：

```bash
# 1. 查询系统状态与持仓
python3 scripts/okxdog_ops_cli.py status

# 2. 紧急停机 (周铁山 / 微信红队避险指令)
python3 scripts/okxdog_ops_cli.py stop-autopilot --reason "来自手机紧急避险"

# 3. 提交调参提案 (受最大单次步长限制)
python3 scripts/okxdog_ops_cli.py create-proposal --target AUTO_PILOT_CONFIG --patch '{"min_confidence": 0.88}'

# 4. 生效或回滚配置 (需回复确认后触发)
python3 scripts/okxdog_ops_cli.py apply-proposal --proposal-id prop_123
python3 scripts/okxdog_ops_cli.py rollback-version --version-id ver_456
```

### 核心安全规则：
- **两阶段调参**：AI 员工提出调参建议时，必须在手机中生成“修改前数值”、“修改后数值”与“回测夏普数据”，用户在手机明确回复“确认”后才触发 `apply-proposal`；
- **出金物理隔离**：系统代码库不包含任何提现或转账权限，彻底杜绝资金风险。

---

## 8. 本地 CLI 与大模型配置 (零成本 / 免付费 API Key)

Hermes Agent 支持多种本地大模型提供方，无需向第三方购买付费 API 即可畅快运行：

### 8.1 方案 A：使用本机自带的 Antigravity CLI 网关 (推荐·已内置配置)
本项目原生运行了一个本地 OpenAI 兼容网关服务 (`antigravity_server.py`，端口 `8001`)，该服务直接调用 Mac mini 本地已安装且已登录的 **Google Antigravity CLI (`agy`)** 引擎，提供 `gemini-3.7-flash` 模型推理，**完全免费且具备极强推理能力**。

1. **环境已自动写入 `~/.hermes/.env`**：
   ```bash
   OPENAI_API_BASE=http://127.0.0.1:8001/v1
   OPENAI_BASE_URL=http://127.0.0.1:8001/v1
   OPENAI_API_KEY=local-antigravity
   ```
2. **所有 6 位员工已自动软链接共享此环境**：
   ```bash
   hermes config set model.provider openai
   hermes config set model.default gemini-3.7-flash
   ```
3. **在终端直接呼叫员工**：
   ```bash
   chen -z "你好，请汇报一下当前市场看法"   # 首席投决仲裁官 · 陈守拙
   zhou -z "你好，请检查当前仓位是否有穿仓风险" # 铁血风控审计官 · 周铁山
   zhang -z "请扫描当前的突破动量"          # 多头趋势研究员 · 张大炮
   zhao -z "盘口挂单深度有什么异常吗"       # 盘口微观交易员 · 赵小刀
   lin -z "最近有美联储降息或宏观新闻吗"     # 宏观与资讯分析师 · 林望远
   qian -z "请统计今天的战绩与夏普率"       # CFO战绩审计总监 · 钱公道
   ```
   *(不加 `-z` 则直接进入交互式终端对话模式)*

### 8.2 方案 B：使用本地 Ollama 离线开源模型 (完全离线)
如果你希望完全单机离线运行（如 DeepSeek-R1、Qwen2.5 等开源模型）：

1. **启动 Ollama 并拉取模型**：
   ```bash
   ollama run deepseek-r1:8b
   # 或
   ollama run qwen2.5:7b
   ```
2. **将 Hermes 切换至 Ollama 提供商**：
   ```bash
   # 为当前 profile 切换为 ollama
   hermes config set model.provider ollama
   hermes config set model.default deepseek-r1:8b
   ```
   *(Ollama 默认运行在 `http://127.0.0.1:11434`，Hermes 会自动识别接入)*

