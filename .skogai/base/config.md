---
type: module
name: config
description: layered key-value settings
command: config
tools: [mise, yq, argc]
---

# config

The config module: key-value settings, held by mise in its `skogai` env.
A project's defaults are its committed `mise.skogai.toml`; changes go
beside it. See `docs/config.md`.
