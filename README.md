# Qontext CLI

`qontext` is the command-line interface for [Qontext](https://qontext.ai).

## Status

This repository currently hosts **release binaries only**. The source will be
published here once it has been cleaned up and given the beauty treatment it
deserves.

## Features

- **Skills** — install and sync workspace Skills into your local agent
  (currently the only supported feature).

## Install

### Linux / macOS

```sh
curl -fsSL https://cli.qontext.ai | sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/qontext-ai/cli/main/install.ps1 | iex
```

### Manual

If you'd rather not pipe a script into a shell:

1. Download the archive for your platform from the
   [Releases](https://github.com/qontext-ai/cli/releases) page.
2. Verify it against `SHA256SUMS-<version>.txt` from the same release:
   - macOS/Linux: `shasum -a 256 -c SHA256SUMS-<version>.txt`
   - Windows: `Get-FileHash -Algorithm SHA256 <archive>`
3. Extract and move `qontext` (or `qontext.exe`) onto your `PATH`.
