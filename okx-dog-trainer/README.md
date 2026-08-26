# 🐶 OKX-Dog 欧易量化专精专家模型训练套件 (OKX-Dog Trainer)

本工程是 **OKX-Dog** 的独立离线模型训练与知识蒸馏套件，专为基于 **Google Colab (免费/Pro T4/A100/L4 GPU)** 极速微调量化专精开源小模型（如 `DeepSeek-R1-Distill-Qwen-7B/14B` 或 `Qwen2.5-7B/14B-Instruct`）而设计。

---

## 🌟 整体工作流速览 (Workflow Overview)

```
[1. 本地系统收集并导出数据] ──► [2. 上传至 Google Colab 微调] ──► [3. 导出 GGUF 并在 Ollama 部署] ──► [4. 接入系统实习生插槽以老带新]
```

---

## 🛠️ Step 1: 导出训练数据 (前端可视化 / 命令行双通道)

### 方式一：前端页面可视化一键导出 (强烈推荐，零门槛)
1. 打开系统前端页面，点击顶部 **「👥 AI 员工团队 & 演进看板」**；
2. 切换至 **「🐣 实习生微调与数据中心」** Tab；
3. 勾选 `[✔] 先调用大模型进行高密度思考链精简提炼 (--refine-first)`；
4. 点击 **「🚀 一键生成并导出训练集」**；
5. 导出成功后，直接在页面点击 **「📥 下载」** 获取 `sft_train_alpaca.jsonl` 与 `dpo_pairs.jsonl` 文件。

### 方式二：终端命令行导出
在主工程根目录执行一键导出命令：

```bash
# 1. 快速导出当前积累的 SFT 与 DPO 数据集 (零 API 开销)
python3 -m okx-dog-ai.dataset.exporter --output-dir ./exports

# 2. (推荐黄金模式) 先调用本地 Antigravity CLI 或 DeepSeek 批量精简提炼思考链后再导出
python3 -m okx-dog-ai.dataset.exporter --output-dir ./exports --refine-first --batch-size 20
```

导出生成的文件：
- `sft_train_alpaca.jsonl`: 注入量化特征认知、6 专家博弈逻辑与标准 JSON 契约的监督微调数据集；
- `dpo_pairs.jsonl`: 基于盘口真实盈亏构建的正负偏好对齐数据集（强化精准避坑，惩罚追高被套）。

---

## 🚀 Step 2: 在 Google Colab 开启极速微调

1. 打开 [Google Colab](https://colab.research.google.com/)；
2. 点击 **文件 (File) -> 上传笔记本 (Upload notebook)**，选择本项目中的 [`colab_train_unsloth.ipynb`](./colab_train_unsloth.ipynb)；
3. 将 Colab 运行时类型切换为 **GPU (T4 或 A100 / L4)**；
4. 将 Step 1 导出的 `sft_train_alpaca.jsonl` 上传到 Colab（或挂载的 Google Drive）；
5. 顺次运行 Notebook 中的代码单元：
   - 自动安装 **Unsloth (比标准微调快 2~5 倍，显存降低 70%)**；
   - 自动加载 4-bit 量化基座模型 (`unsloth/DeepSeek-R1-Distill-Qwen-7B` 或 `unsloth/Qwen2.5-7B-Instruct`)；
   - 启动 LoRA / QLoRA 训练（1 个 Epoch 约 15~25 分钟）；
   - 执行 DPO 真实盘口盈亏强化对齐；
   - 一键合并权重并导出为 `okx-dog-intern-q4_k_m.gguf`。

---

## 📦 Step 3: 将训练好的模型导入本地 Ollama

微调完成后，从 Colab 下载导出的 `.gguf` 文件和 `Modelfile` 到本地，执行：

```bash
# 1. 使用 Ollama 一键创建专有模型
ollama create okx-dog-intern -f Modelfile

# 2. 测试本地推理
ollama run okx-dog-intern "当前市场 BTC-USDT-SWAP 触及 EMA25 支撑，MACD 金叉，请输出分析决策。"
```

---

## 🐣 Step 4: 激活 OKX-Dog 实习生插槽（以老带新）

打开主系统配置文件 `okx-dog-ai/config.py` 或根目录 `.env`，开启实习生插槽：

```ini
# 开启实习生影子推演模式
INTERN_ENABLED=true
INTERN_PROVIDER=ollama
INTERN_BASE_URL=http://127.0.0.1:11434/v1
INTERN_MODEL_NAME=okx-dog-intern
```

系统重启后：
1. 实盘决策发单仍由资深老模型/硬风控严格把关；
2. 实习生模型在后台**异步并发影子推演**，实时沉淀虚拟战绩；
3. 系统自动比对二者决策分歧与真实收益，在演进看板展示转正进度清单；
4. 当考核指标全绿达标（胜率 $\ge 65\%$、一致率 $\ge 70\%$）后，即可放心一键晋升为主力决策模型！
