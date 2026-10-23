# Keel 第一次编解码

[English](getting-started.md) · **简体中文**

需要 Racket 9.0+。安装 catalog 包，不复制源码：

```sh
raco pkg install --auto keel
```

将以下代码保存为 roundtrip.rkt：

```racket
#lang racket/base
(require keel)
(define original (hash "task" "review" "done" #f))
(define encoded (encode-app-value original))
(unless (equal? original (decode-app-value encoded))
  (error 'roundtrip "round trip failed"))
(displayln "Keel round trip passed")
```

```sh
racket roundtrip.rkt
```

预期输出 `Keel round trip passed`。这验证一次本机 public API 编解码，不表示已验证其他语言、版本或网络传输。

本库不提供 RPC 信封、网络端点或 UI。使用 schema 时由框架映射至其传输；不要绕过权威拒绝规则、规范 map 排序或预算限制。

下一步阅读 [v1 契约](contract-v1.md)、[使用与支持](USING.zh-CN.md)及 [CONTRIBUTING](../CONTRIBUTING.md)。独立实现需运行 `tests/golden-v1.txt` 规范 corpus。
