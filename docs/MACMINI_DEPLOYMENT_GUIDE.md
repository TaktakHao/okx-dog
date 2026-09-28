# OKX-Dog v6.0 家用 Mac mini 7x24h 混合部署与常驻运维实战指南

> 适用硬件：Mac mini (Apple Silicon M1 / M2 / M4，8GB / 16GB / 24GB 统一内存)  
> 运行理念：低功耗静音常驻、宿主机原生高保真 CLI、容器隔离控制中枢、Tailscale 外网安全穿透

---

## 1. 为什么采用“宿主机 + 轻量容器”混合拓扑？

| 方案 | 内存占用 | CLI 调用复杂度 | 网络延迟 | 推荐指数 |
| :--- | :--- | :--- | :--- | :--- |
| **混合架构 (推荐)** | **~600MB - 800MB** | **原生极速调用 (直接调用系统 `agy`)** | **毫秒级 (Native)** | ⭐⭐⭐⭐⭐ |
| 全容器化 (全部打包) | ~1.5GB - 2.5GB | 需将 CLI 密钥挂载进容器，易鉴权失效 | 有 Docker 网络桥接损耗 | ⭐⭐⭐ |
| 全宿主机 (纯手动) | ~500MB | 原生调用 | 毫秒级 | 维护繁琐 (需本地配 Postgres) | ⭐⭐⭐ |

* **宿主机原生层**：运行 `OKX-Dog Backend` (FastAPI) 与 `Antigravity CLI (agy)`。享受原生 Python 与系统的进程调用速度，无需处理复杂的容器内证书与终端凭证挂载。
* **轻量容器层**：运行 `Paperclip` 与 `PostgreSQL 17`。享受容器带来的数据库沙盒隔离与 Web 控制台开箱即用体验。

---

## 2. 准备工作：容器环境安装 (强烈推荐 OrbStack)

在 macOS 上，传统的 Docker Desktop 往往占用 2GB~4GB 内存且发热明显。  
**强烈推荐使用专为 macOS 原生打造的 [OrbStack](https://orbstack.dev/)**：

1. **一键安装 OrbStack**：
   ```bash
   brew install --cask orbstack
   ```
2. **启动 OrbStack**：
   - 打开 OrbStack 应用，在菜单栏常驻；
   - 它的空载内存占用不到 100MB，并且原生支持 `docker` 和 `docker compose` 命令行，完全无缝兼容。

---

## 3. 一键启动集群

在主工程根目录下，执行专为 Mac mini 打造的一键启动脚本：

```bash
bash start_company_macmini.sh
```

脚本将自动执行：
1. 检查本地 `agy` CLI 命令行就绪状态；
2. 通过 Docker/OrbStack 拉起 `docker-compose.paperclip.yml`（Postgres + Paperclip 容器）；
3. 在宿主机后台拉起 OKX-Dog AI 决策网关与 CFO 配额中枢（端口 8001）；
4. 在宿主机后台拉起 OKX-Dog 7x24h 毫秒级交易与风控引擎（端口 8000）。

启动完成后，即可打开浏览器访问：
* **Paperclip 虚拟公司看板**: `http://localhost:3100`
* **OKX-Dog 暗黑交易大屏**: `http://localhost:3000`
* **CFO 员工配额 API**: `http://localhost:8001/api/v1/paperclip/quota/overview`

---

## 4. 远程随时随地安全访问：Tailscale 零配置穿透

在上班路上、公司或度假时，通过手机随时查看家里的量化系统与战绩：

1. **Mac mini 安装 Tailscale**：
   ```bash
   brew install --cask tailscale
   ```
2. **手机端下载 Tailscale App**，登录同一账号；
3. **安全连接**：
   - Tailscale 会为你的 Mac mini 分配一个安全私网 IP（例如 `100.88.99.12`）；
   - 在手机浏览器中直接输入：
     * `http://100.88.99.12:3100`（查看 Paperclip 6 大员工与工单）
     * `http://100.88.99.12:3000`（查看 OKX-Dog 实时持仓与资产曲线）
   - **全程端到端加密，无需公网 IP，不开放任何公网危险端口**！

---

## 5. 7x24h 防断电与系统自愈配置

1. **设置断电自动重启**：
   - 打开 macOS `系统设置 -> 节能`；
   - 勾选 **「断电后自动重新启动」**。
2. **容器与后端保活**：
   - `docker-compose.paperclip.yml` 中已配置 `restart: always`，系统开机后容器将自动拉起；
   - 如需让宿主机 Python 脚本也在开机时全自动拉起，可将 `start_company_macmini.sh` 注册到用户登录项，或使用系统原生 `launchd` plist 守护。

---

## 6. 运维与资源监控

在终端中输入：
```bash
top -o mem
```
你将看到：
* `okx-dog-backend`: ~180MB
* `okx-dog-ai`: ~120MB
* `orbstack (包含 paperclip + postgres)`: ~350MB
* **整机总常驻内存仅 ~650MB，CPU 长期占用 < 3%，机身温凉，运行平稳！**
