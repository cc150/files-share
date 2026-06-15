# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a deployment utility bundle for **Windows 10 Enterprise LTSC 2021**. It contains:

- **[Fix-LTSC2021.cmd](Fix-LTSC2021.cmd)** — Batch script that installs Microsoft.VCLibs (Universal CRT) AppX packages (x64 and x86) required by UWP/WinRT apps on Windows. Runs with elevation check and skips if already installed.
- **[Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx](Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.Appx)** — Visual C++ 2015-2022 Universal CRT (x64) AppX package.
- **[Microsoft.VCLibs.140.00_14.0.30704.0_x86__8wekyb3d8bbwe.Appx](Microsoft.VCLibs.140.00_14.0.30704.0_x86__8wekyb3d8bbwe.Appx)** — Visual C++ 2015-2022 Universal CRT (x86) AppX package.
- **[win10-lstc2021.txt](win10-lstc2021.txt)** — Contains KMS activation commands (`slmgr /skms` and `slmgr /ato`) for Windows licensing.

## Key Details

- **Remote:** `https://github.com/cc150/win10-lstc-2021.git`
- **Branch:** `main`
- **No source code, tests, or build system** — this is a static asset/utility bundle.
- **No CI/CD, linting, or testing infrastructure** exists.
- The `.Appx` files are pre-packaged binaries; they should not be modified.
- The batch script ([Fix-LTSC2021.cmd](Fix-LTSC2021.cmd)) must be run as Administrator to install VCLibs packages.
