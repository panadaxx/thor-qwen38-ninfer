# 补丁目录

这里放的是当前 Thor SM110a NInfer 工作树中已保留或用于实验开关的补丁。它们不是全部上游代码，而是相对上游 `63428ac249da8a6c5d891b508d7e483d8c7def6c` 的自定义工作。

当前状态不是所有补丁都默认启用。具体开关见 `scripts/start-thor-3.8fl-512k.sh`。

核心补丁大致对应：

| 补丁 | 说明 |
|---|---|
| `0001-sm110a-compat-build.patch` | SM110a 兼容构建入口 |
| `0002-ninfer-bench-safe-profile-and-timing.patch` | benchmark 安全 profile 与计时 |
| `0003-thor-qualification-bundle.patch` | 算子验收测试 |
| `0004-bench-ngram-options.patch` | benchmark N-gram 参数 |
| `0005-thor-fast-build-unused-dense.patch` | 构建速度实验，不是推理优化 |
| `0007-thor-qsa-aot-integration.patch` | QSA AOT |
| `0008-thor-qsa-triton-mit-notice.patch` | Triton 许可通知 |
| `0001-hc-bf16-preserve.patch` | HC BF16 保留 |
| `hc_q8_overlay.patch` | HC Q8 sidecar |
| `production_optin.patch` | IQ4NL T1 slot parallel |
| `candidate.patch` | IQ2S BF16 pair |
| `q6k-cooperative-integration.patch` | Q6K cooperative |
| `q6k-padded-t1.patch` | Q6K padded T1 实验开关 |
| `qwen4-prefill-8192.patch` | 8K prefill |
| `ninfer-optin.patch` | Edge NVFP4 QKV sidecar |
| `0001-occ2-dispatch.patch` | SM110 occupancy-2 |
| `0001-fa2-prefix-dispatch.patch` | FA2 prefix |
| `0001-fa2-sparse-qsa-dispatch.patch` | FA2 sparse |

其余补丁是历史实验、诊断或否决项，不代表当前默认启用。
