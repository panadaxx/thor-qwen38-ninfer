# Scope and notices

This folder is a status and usage package for a custom Thor build. It is not a full redistribution of the NInfer source tree, model weights, or third-party SDKs.

- The upstream NInfer project used as the base is Apache-2.0; follow its own license and notice files when redistributing code.
- The patches here only document the custom changes needed to reach the tested Thor configuration.
- The binary in `release/` is an experimental ARM64 build. It does not include model weights or generated sidecars.
- Model weights, visual weights, N-gram tables and generated sidecars are not redistributed here.
- Some experimental kernels or generated artifacts may have separate notices; keep the original notice files from the source tree when redistributing a full build.
