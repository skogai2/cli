---
type: module
name: config
description: layered key-value settings
command: argc.sh
tools: [yq, argc]
config.system.dir: config
config.system.file: config.system.md
config.global.dir: config
config.global.file: config.global.md
config.local.dir: config
config.local.file: config.local.md
---

# config

The config module: where each scope's files live. Every other setting is
declared in a scope's default file under `base/` and overridden at the
same path outside it.
