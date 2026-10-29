# Thor 上的 Qwen3.8 Flash Next / NInfer 公开状态包

这是一个面向 GitHub 的独立状态包，和本项目内部的 `records/` 诊断记录分开。

## 这是什么

本包整理了在一块拆车 NVIDIA DRIVE Thor 上运行 Qwen3.8 Flash Next Coder、NInfer 0.12.0、MTP3、512K 上下文和思考模式的当前可用状态。

当前已经可用：

- Qwen3.8 Flash Next Coder IQ1_M
- NInfer 0.12.0 SM110a 兼容工作树
- 512K 上下文
- MTP3
- xhigh thinking
- OpenAI/Anthropic 兼容 API
- Claude Code 兼容模板
- 设备端前缀缓存

当前不可用或未完成：

- NInfer Vision 还没有接入
- 512K 配置还没有做长期稳定性测试
- 当前服务不是 systemd 常驻服务
- 不能直接使用 artifact 内嵌旧模板；必须用新版 `qwen3_8.jinja`

## 硬件与运行环境

| 项目 | 当前值 |
|---|---|
| 设备 | 智己 LS9 拆车 NVIDIA DRIVE Thor |
| GPU | Thor，SM110，14 SM |
| CPU | 12 核 ARM64 |
| 统一内存 | 约 58.7 GiB 可见 |
| 驱动 | 原 CUDA 12.8 驱动，未替换 |
| CUDA 工具链 | 13.0.88 |
| CUDA 用户态 compat | 13.4 |
| 推理引擎 | NInfer 0.12.0，`63428ac249da8a6c5d891b508d7e483d8c7def6c` |
| 主模型 | `Qwen3.8-Flash-Next-GSQ-RCO-Coder-IQ1_M` |
| 模型组件 | `text + ngram + mtp` |
| KV | rk8v4，512K 全量设备驻留 |
| 推测解码 | MTP3 |

## 当前实测

最近一次干净 A/B 中，MTP OFF、HC Q8 + IQ4NL T1 slot parallel 的有效基线：

| 语言 | decode | ms/token |
|---|---:|---:|
| English | 28.850351 tok/s | 34.661623 |
| Chinese | 28.831174 tok/s | 34.684679 |

干净 prefill 中，IQ2S BF16 pair 打开后：

| 输入长度 | prefill | TTFT |
|---|---:|---:|
| 4K | 897.57 tok/s | 4.56s |
| 8K | 984.42 tok/s | 8.32s |

较早的 256K 运行实例累计到最近一次统计：

| 项目 | 数值 |
|---|---:|
| 平均 prefill | 712.0 tok/s |
| 平均 decode | 27.54 tok/s |
| 实际 prefill 计算 | 323,993 tokens |
| 缓存复用 prompt | 2,590,432 tokens |
| 缓存命中率 | 约 88.9% |
| MTP 接受率 | 约 52.5% |

这些数字不是 Jetson 或 RTX 上的成绩，也不能直接外推。

### 512K 启动验证

2026-10-29 对 512K 配置做了启动和短请求验证：

| 配置 | 启动结果 | 运行时 | 启动后 GPU 余量 | 结论 |
|---|---|---:|---:|---|
| 512K BF16 | PASS | 19.9 GiB | 838 MiB | 能启动，但余量过低，不设为默认 |
| 512K rk8v4 + YaRN | PASS | 12.1 GiB | 8.64 GiB | 当前默认，推荐 |

512K rk8v4 的模型接口返回 `context_length=524288`，日志显示 `YaRN at factor 2 past the native 262144 positions`。短请求也成功完成，输入 `58` tokens，输出 `32` tokens。

当前验证边界是“512K 容量可以启动并处理请求”；还没有做真正 512K-token 长文本的完整质量和速度测试。

## 快速启动

`scripts/start-thor-3.8fl-512k.sh` 是 Thor 本机启动脚本。它会读取当前 Thor 上的 NInfer artifact、N-gram 表、HC Q8 sidecar 和新版 Qwen 模板，然后前台启动服务。

```bash
THOR_API_KEY='sk-thor-local-change-me' bash scripts/start-thor-3.8fl-512k.sh
```

如果你想使用自己的 API key，请在启动前显式设置 `THOR_API_KEY`。脚本不会把默认 key 当作安全密钥。

电脑侧连接：

```text
Base URL: http://10.0.0.2:18778/v1
Model ID: qwen3.8-flash-next-coder-mtp-512k
```

历史上 TensorFold 0.6.3 也在同一 Thor 上跑通过同一 IQ1_M 模型和图片问答，但当前主线已经转到 NInfer，因为它更快、上下文和 agent API 兼容性更好。

如果要改成其他监听地址或端口，使用：

```bash
THOR_HOST=0.0.0.0 THOR_PORT=18778 THOR_API_KEY='sk-thor-local-change-me' \
  bash scripts/start-thor-3.8fl-512k.sh
```

## 启动脚本默认做的事

1. 确认 `/home/data` 挂载 UUID 正确。
2. 确认 artifact、N-gram 表、HC Q8 sidecar 和新版模板存在。
3. 检查 `18778` 端口是否空闲。
4. 加载 CUDA 13.0.88 与 SM110a 兼容运行环境。
5. 打开 HC Q8、IQ4NL T1 slot parallel、QSA AOT、Q6K cooperative、FA2 prefix/sparse、BF16 dense prefill 和 IQ2S BF16 pair 等已验证开关。
6. 用 512K、rk8v4 KV、YaRN factor 2、设备驻留 experts、MTP3 和新版 Qwen 模板启动服务。

## 当前优化状态

### 已保留优化

| 方向 | 状态 |
|---|---|
| SM110a 兼容构建 | 已完成 |
| HC BF16 到 Q8 sidecar | 已保留 |
| IQ4NL T1 slot parallel | 已保留 |
| IQ2S BF16 pair prefill | 已保留 |
| Q6K cooperative | 已保留 |
| QSA AOT | 已保留 |
| FA2 prefix/sparse | 已保留 |
| Edge NVFP4 QKV sidecar | 已保留，默认关闭 |
| GDN output NVFP4 sidecar | 单算子已过，未整模接入 |

### 已否决或收益不足

| 方向 | 结论 |
|---|---|
| HC WMMA 融合 | 明显慢，否决 |
| IQ4NL weighted epilogue | 冷缓存慢约 18%，否决 |
| IQ2S signed4 重编码 | 冷缓存慢约 6-10%，否决 |
| Q6 K2560 half-warp | 数值未过，否决 |
| CUDA 13.0 与 13.4 编译器 A/B | 差异低于 1%，否决 |
| A16 route-tile | 明显慢，否决 |
| MTP3 普通文本 | 早测慢于 MTP OFF，需要按 workload 分档 |

## 下一步优化方向

优先级从高到低：

1. **Q6_K/Dense decode**：当前占比最大，是冲击 30-40 tok/s 的第一方向。
2. **MoE Gate/Up/Down**：继续减少实际读字节和调度开销。
3. **Hyper-Connection**：已有 Q8 sidecar，仍有剩余空间。
4. **Edge NVFP4 QKV**：有正收益但质量风险未完全收口，保持默认关闭。
5. **GDN output sidecar**：单算子已过，需要整模验证。
6. **MTP 分档**：普通聊天、代码生成和 agent 场景应该分开测。
7. **Vision**：需要重新生成 `text + mtp + vision` artifact。
8. **正式服务化**：后续可以加受控的前台/守护两种方式，但当前没有自启。

## Vision 当前状态

当前 artifact 只有 `text + ngram + mtp`，没有 Vision。车上已有：

```text
/home/data/models/llm/qwen3.8-flash-next-coder/mmproj-Qwen3.8-Flash-Next-BF16.gguf
```

但 NInfer 不能直接在现有 artifact 上加 `--vision`。需要重新生成 `text + mtp + vision` 的完整 artifact，同时补齐：

```text
preprocessor_config.json
video_preprocessor_config.json
```

数据盘目前剩约 27 GiB，而新完整 artifact 预计约 33.3 GiB，所以还需要腾空间或外部备份后再转。

## 本包包含什么

```text
public/thor-qwen38-ninfer/
├── README.md
├── LICENSE
├── NOTICE.md
├── scripts/
│   └── start-thor-3.8fl-512k.sh
├── patches/
│   ├── README.md
│   └── *.patch
└── release/
    ├── README.md
    ├── ASSET_SHA256.txt
    └── 编译产物作为 GitHub Release 资产上传
```

`release/` 里的编译产物适合作为 GitHub Release 资产上传，不适合直接塞进普通 Git。大模型、N-gram 表、Sidecar 等大体积文件不会放进这个包。

## 注意

- 这个包不是生产部署。
- 当前服务是前台进程，不是 systemd 常驻服务。
- 请不要把 API key 写进 Git。
- 大模型权重和 sidecar 体积巨大，应放在本机数据盘或单独 release 资产。
- 512K + rk8v4 + YaRN + MTP3 当前只做了启动和短请求验证，没有做长上下文质量或长期稳定性认证。
- BF16 也能启动 512K，但启动后只剩约 838 MiB GPU 余量，不适合作为默认配置。
- 改 SSH、网络、启动链、内核、系统 GPU 驱动都不在本包范围内。
