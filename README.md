# Exynos 9820 Kernel Builder with OriginSU

[![Build](https://img.shields.io/badge/build-GitHub%20Actions-blue?logo=github-actions&logoColor=white)](https://github.com/1992Ade/exynos9820-origin-builder/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/1992Ade/exynos9820-origin-builder?label=latest&logo=github)](https://github.com/1992Ade/exynos9820-origin-builder/releases/latest)

> **Your warranty is now void.** Flashing a custom kernel can brick your device. You are responsible for what you flash. Always keep a backup of your stock `boot` (and `vbmeta`) partitions.

## 📱 About This Repository

This repository automates the compilation of a custom **Linux 4.14** kernel for the **Samsung Galaxy S10 / Note10 / F62** family (**Exynos 9820 / 9825**). It is built from the **real FreeRunner kernel source, [Project-Matrixx-New/android_kernel_samsung_exynos9820](https://github.com/Project-Matrixx-New/android_kernel_samsung_exynos9820)** (branch `lineage-24.0`, FreeRunner v3.9) — the source that **[LeDrew2017's FreeRunnerKernel](https://github.com/LeDrew2017/FreeRunnerKernel)** releases are built from.

> `LeDrew2017/android_kernel_samsung_exynos9820`, used by earlier versions of this builder, is a December 2024 snapshot of hiratazx's Yuki v3.0 tree — **not** FreeRunner. Its kernels did not boot on current ROMs.

The upstream kernel ships with **KernelSU-Next**. This builder **replaces it with [OriginSU](https://github.com/samakshkambxj/OriginSU)** upgrades **SuSFS to v2.4.0** (FreeRunner ships v2.3.0), enables **TCP BBR**, and can add **Baseband Guard**, **NoMount** and **Droidspaces** (see [Included features](#-included-features)). Each build is packaged as a recovery-flashable `.zip` (TWRP) with LeDrew's AnyKernel, **one per device**.

**Fully automated:** a GitHub Actions workflow checks every week (Sunday) for a new OriginSU release and, when one is out **with its manager APK**, rebuilds every device and publishes a release automatically.

---

## 💙 Prefer the original? Use LeDrew2017's FreeRunnerKernel

This project is **only an OriginSU rebuild**. All the real kernel work is **[LeDrew2017](https://github.com/LeDrew2017)'s**. If you'd rather run the original kernel with its own root solution (**KernelSU-Next / SukiSU**), get it directly from the developer — it is the reference build and is actively maintained:

- **Kernel source:** [Project-Matrixx-New/android_kernel_samsung_exynos9820](https://github.com/Project-Matrixx-New/android_kernel_samsung_exynos9820)
- **Build scripts:** [LeDrew2017/FreeRunnerKernel](https://github.com/LeDrew2017/FreeRunnerKernel)
- **A ROM that ships it (Galaxy S10+):** [Project Infinity-X — beyond2lte](https://projectinfinity-x.com/downloads/beyond2lte)

Please support the original developer first. 🙏

### Versions at a glance

| | FreeRunner (original) | This builder |
|---|---|---|
| **Root** | KernelSU-Next / SukiSU | **OriginSU** `v4.3.0` |
| **SuSFS** | `v2.3.0` (in-tree) | **`v2.4.0`** (upgraded; `v2.3.0` in-tree still selectable) |
| **TCP congestion control** | BIC (default), CUBIC, Westwood, HTCP | **BBR (default)** + the same |
| **Kernel base** | `lineage-24.0` (v3.9) | same |
| **Toolchain** | clang 21, `make LLVM=1` | LLVM 21.1.8, `make LLVM=1` |
| **Extra features** | — | **Baseband Guard · NoMount · Droidspaces** (optional) |
| **Kernel** | Linux 4.14 (Exynos 9820/9825) | same |

The point of this rebuild is **OriginSU** (+ the optional extra features). For KernelSU-Next, FreeRunner already does that — use it directly.

---

## 🧩 Included Features

Always included on top of OriginSU: **SuSFS** and **TCP BBR**. Optional (`extra_features` input): Baseband Guard, NoMount, Droidspaces.

| Feature | Upstream | What it does | Kernel config |
|---|---|---|---|
| **SuSFS `v2.4.0`** | [simonpunk](https://gitlab.com/simonpunk/susfs4ksu), 4.14 port by [JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd) | Root/mount hiding (`susfs` hook mode). Replaces FreeRunner's in-tree v2.3.0 (`susfs_version = intree` to keep it) | `CONFIG_KSU_SUSFS_*` |
| **TCP BBR** | Google (upstream Linux) | Built in and **default** TCP congestion control (FreeRunner: BIC). Mostly helps uploads, video calls and hotspot. Back to CUBIC: `sysctl -w net.ipv4.tcp_congestion_control=cubic` | `CONFIG_TCP_CONG_BBR=y`, `CONFIG_DEFAULT_TCP_CONG="bbr"` |
| **Baseband Guard** | [vc-teahouse](https://github.com/vc-teahouse/Baseband-guard) | LSM that blocks writes to the modem/baseband partitions | `CONFIG_BBG=y` |
| **NoMount** | [maxsteeel](https://github.com/maxsteeel/nomount) | Prevents unwanted mounts used for root detection | `CONFIG_NOMOUNT=y` |
| **Droidspaces** | [ravindu644](https://github.com/ravindu644/Droidspaces-OSS) | Namespace/cgroup isolation to run isolated Android/Linux spaces | `CONFIG_NAMESPACES`, `CONFIG_USER_NS`, cgroups, netfilter… |

> On the Exynos 9820 defconfig, `CONFIG_MEMCG`, `CONFIG_CFS_BANDWIDTH` and `CONFIG_CGROUP_PIDS` are already enabled, so Droidspaces gets the **full** feature set here (memory, CPU and pids limits all available) — the builder just adds `CONFIG_USER_NS`. If you use it with a systemd-based Linux space, mask the `NetworkManager` and `wpa_supplicant` services inside it (as noted upstream).

---

## ✅ Supported Devices

LeDrew2017's kernel supports the whole Exynos 9820/9825 line-up. This builder produces one zip per device — **flash only the one matching your codename**:

| Device | Codename | Model | Status |
|---|---|---|---|
| Galaxy S10+ | `beyond2lte` | SM-G975F | ✅ **Tested**: boots (v3.9, OriginSU + SuSFS v2.3.0 + extras) — SuSFS v2.4.0 build: 🧪 testing |
| Galaxy S10e | `beyond0lte` | SM-G970F | 🧪 Please test |
| Galaxy S10 | `beyond1lte` | SM-G973F | 🧪 Please test |
| Galaxy S10 5G | `beyondx` | SM-G977B | 🧪 Please test |
| Galaxy Note10 | `d1` | SM-N970F | 🧪 Please test |
| Galaxy Note10 5G | `d1x` | SM-N971 | 🧪 Please test |
| Galaxy Note10+ | `d2s` | SM-N975F | 🧪 Please test |
| Galaxy Note10+ 5G | `d2x` | SM-N976B | 🧪 Please test |
| Galaxy F62 | `f62` | SM-E625F | 🧪 Please test |

> ### 🧪 Community rebuild
> **Galaxy S10+ (`beyond2lte`) is tested and boots** on FreeRunner v3.9 with OriginSU + SuSFS v2.3.0 + extras (Project Infinity-X). The SuSFS v2.4.0 + BBR build is being tested; if it doesn't boot, rebuild with `susfs_version = intree`. The other devices are built from the same source but not yet verified: please report. Test in this order on one device: **1)** `root = ksunext` (FreeRunner as-is: must boot, validates the CI) → **2)** `root = originsu`, `hook_mode = manual` → **3)** `hook_mode = susfs` → **4)** `extra_features = true`. The first step that bootloops tells you where the problem is. Back up your stock `boot` first.

### 🧬 ROM compatibility

This is a **LineageOS kernel**: the FreeRunner source is the LineageOS kernel for the Exynos 9820 devices (default branch `lineage-24.0`, i.e. the LineageOS 24 / Android 17 device tree), with FreeRunner's tweaks on top.

- ✅ **LineageOS and LineageOS-based ROMs** for these devices — tested on **Project Infinity-X** (S10+).
- ⚠️ ROMs on an older LineageOS base (e.g. 23.x / Android 16) should also work, but are untested: if one bootloops, rebuild with `kernel_branch = ksunext-qpr2` (FreeRunner v3.8-R2, Android 16 QPR2) and report it.
- ❌ **Stock One UI and One UI-based ROMs are not supported** (different kernel and device tree).

---

## 📦 Which zip should I download?

Each release ships **one zip per device**, named:

```
exynos9820-<codename>-OriginSU-<version>-<hook>-<date>.zip
```

- **`-susfs-v2.4.0`** — SuSFS inline hook: root + SuSFS hiding (**recommended**). `-susfs-v2.3.0` = FreeRunner's in-tree SuSFS.
- **`-manual-`** — manual hook only, no SuSFS: fallback if the SuSFS build doesn't boot.
- **`-KSUNext-control-`** — FreeRunner unchanged (KernelSU-Next), only to validate the build chain.
- **`-extras`** suffix — Baseband Guard + NoMount + Droidspaces included.

A SHA-256 sum and the full kernel `.config` of each device are attached to the release.

---

## 🔧 Installation

1. Back up your stock `boot` and `vbmeta` partitions.
2. Download the zip **matching your device codename** from the [latest release](https://github.com/1992Ade/exynos9820-origin-builder/releases/latest).
3. Flash it in TWRP (or `adb sideload <file>.zip`).
4. Reboot, then install the **OriginSU manager** APK from the OriginSU release linked in the notes (same version as the kernel).

> **Updating the ROM?** An OTA replaces `boot`, so re-flash the zip after each ROM update.

### ↩️ Restore the stock kernel

```sh
su -c rm -rf /data/adb/*        # remove root data first
adb reboot bootloader
fastboot flash boot stock_boot.img
fastboot reboot
```

---

## ⚙️ How the Build Works

The workflow lives in [`.github/workflows/build.yml`](.github/workflows/build.yml) and runs three jobs:

```
check  ──►  build (matrix: 9 devices)  ──►  release
```

1. **check** — reads the latest stable OriginSU release (scheduled runs require its **manager APK**). Builds only if there's a new `originsu-<tag>`; manual runs always build.
2. **build** (one job per device, `fail-fast: false`)
   - Clones the FreeRunner branch (default `lineage-24.0` = v3.9) **with its submodules** and downloads the official **LLVM 21.1.8** release (FreeRunner is built with clang 21; the previous "Neutron latest" was a clang 24 dev snapshot).
   - `root = originsu`: removes KernelSU-Next, runs OriginSU's `setup.sh`, then [`scripts/originsu_compat_4.14.sh`](scripts/originsu_compat_4.14.sh) (4.14 compat for OriginSU) and [`scripts/originsu_hooks_4.14.sh`](scripts/originsu_hooks_4.14.sh), which converts the tree's KSU-Next hooks to what OriginSU expects (see the header of that script: the faccessat/stat argument type mismatch crashed init in SuSFS mode).
   - SuSFS v2.4.0 ([`scripts/susfs_v2.4.sh`](scripts/susfs_v2.4.sh)): removes FreeRunner's in-tree v2.3.0 ([`strip_susfs.py`](scripts/strip_susfs.py), every `#if CONFIG_KSU_SUSFS*` block), applies JackA1ltman's 4.14 v2.4.0 patch hunk by hunk only where all the context matches ([`strict_apply.py`](scripts/strict_apply.py) — `patch --fuzz` put hunks in wrong places on this Samsung tree), then hand-ports the 20 hunks that don't match ([`susfs_v2.4_samsung_fixups.py`](scripts/susfs_v2.4_samsung_fixups.py): Samsung includes, `ida_alloc*` API, smaps). If the set of unmatched hunks ever changes, the build stops instead of guessing.
   - TCP BBR enabled as default congestion control.
   - Optional **extra features** ([`scripts/extra_features.sh`](scripts/extra_features.sh)).
   - Configures like FreeRunner's `build.sh`: `exynos9820-<device>_defconfig` + a config fragment merged with `merge_config.sh`, then checks that every requested option really stuck.
   - Builds with `make LLVM=1` and packages `Image` with LeDrew's AnyKernel, locked to that device.
3. **release** — publishes `originsu-<tag>` with every device zip, their SHA-256 sums, configs and a per-device table.

### Manual run options

| Input | Default | Description |
|---|---|---|
| `originsu_ref` | *(latest release)* | OriginSU tag to build |
| `kernel_branch` | `lineage-24.0` | Branch of the FreeRunner source (Project-Matrixx-New) |
| `device` | `all` | One device or all of them |
| `root` | `originsu` | `originsu`, or `ksunext` = FreeRunner unchanged (control build) |
| `hook_mode` | `susfs` | `susfs` = root + SuSFS; `manual` = root only |
| `susfs_version` | `v2.4.0` | `v2.4.0` = upgraded SuSFS; `intree` = FreeRunner's v2.3.0 (susfs mode only) |
| `extra_features` | `false` | Baseband Guard + NoMount + Droidspaces |
| `kpm` | `false` | Enable `CONFIG_KPM` |
| `publish` | `false` | Publish a GitHub Release (scheduled runs always publish) |

> Scheduled workflows are disabled by GitHub after **60 days without repo activity** — re-enable in the Actions tab or push a commit if auto-releases stop.

---

## 🙏 Credits & Acknowledgments

* **[LeDrew2017](https://github.com/LeDrew2017)** & **[Project-Matrixx-New](https://github.com/Project-Matrixx-New)** — For the **FreeRunner** Exynos 9820 kernel source, device support and AnyKernel. **This project is just a rebuild of their work.**
* **[OriginSU](https://github.com/samakshkambxj/OriginSU)** — For the kernel-based root solution used here.
* **[KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)** — The root solution the original FreeRunner kernel ships with.
* **[simonpunk](https://gitlab.com/simonpunk/susfs4ksu)** — For SuSFS.
* **[JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd)** — For the SuSFS v2.4.0 port to 4.14 and the non-GKI hook layout.
* **[vc-teahouse](https://github.com/vc-teahouse/Baseband-guard)** — For Baseband Guard.
* **[maxsteeel](https://github.com/maxsteeel/nomount)** — For NoMount.
* **[ravindu644](https://github.com/ravindu644/Droidspaces-OSS)** — For Droidspaces.
* **[LLVM](https://github.com/llvm/llvm-project)** — For the Clang toolchain.
* **[tiann/KernelSU](https://github.com/tiann/KernelSU)** — The project OriginSU is built upon.

## 📄 License

Kernel sources are licensed under **GPL-2.0**. See each upstream project for its own license.
