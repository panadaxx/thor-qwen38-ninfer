# Release 包说明

当前 Release 页面：[v2026.10.29-thor-sm110a](https://github.com/panadaxx/thor-qwen38-ninfer/releases/tag/v2026.10.29-thor-sm110a)。

当前编译产物：[`ninfer-multicall-thor-sm110a-stripped-20261029.tar.zst`](https://github.com/panadaxx/thor-qwen38-ninfer/releases/download/v2026.10.29-thor-sm110a/ninfer-multicall-thor-sm110a-stripped-20261029.tar.zst)。

`ninfer-multicall-thor-sm110a-stripped-20261029.tar.zst` 是当前 Thor 上编译好的 NInfer 可执行文件。压缩后约 319 MB，适合作为 GitHub Release 资产上传；这个体积不适合直接放进普通 Git 历史。

Release 资产的 SHA-256 在 [`ASSET_SHA256.txt`](ASSET_SHA256.txt)。

## 架构

```text
ELF 64-bit LSB pie executable
ARM aarch64
Linux 3.7.0+
stripped
```

## 校验和还原

下载后先校验：

```bash
sha256sum -c ASSET_SHA256.txt
```

然后解压：

```bash
mkdir -p extracted
tar --zstd -xf ninfer-multicall-thor-sm110a-stripped-20261029.tar.zst -C extracted
```

## 注意

- 这个包只包含编译好的 NInfer 可执行文件。
- 不包含大模型权重、N-gram 表、HC Q8 sidecar、视觉权重。
- 不包含 API key。
- 这是实验构建，不是正式发布。
- 目标平台是 NVIDIA DRIVE Thor，SM110，ARM64。
- 如果你需要在另一台 Thor 上运行，最好使用同一架构和同一 NVIDIA 驱动兼容层。

## 大文件放在哪里

大模型和 sidecar 体积太大，不建议放进普通 Git。推荐做法：

1. 模型和 sidecar 放在本机数据盘。
2. 编译产物作为 GitHub Release 资产上传。
3. 若一定要放入 Git，使用这里的分片包或 Git LFS。
