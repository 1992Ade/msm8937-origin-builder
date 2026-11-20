# MSM8937 Kernel Builder with OriginSU

[![Build](https://img.shields.io/github/actions/workflow/status/1992Ade/msm8937-origin-builder/build.yml?label=build&logo=github-actions&logoColor=white)](https://github.com/1992Ade/msm8937-origin-builder/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/1992Ade/msm8937-origin-builder?label=latest&logo=github)](https://github.com/1992Ade/msm8937-origin-builder/releases/latest)

> [!IMPORTANT]
> **This is the recommended kernel for MSM8937 — OriginSU `v4.3.0`, the final OriginSU release.**
> OriginSU has been renamed and rebuilt as **[KazeSU](https://github.com/KazeSU/KazeSU)**, which targets modern (GKI 5.10+) kernels and dropped the compatibility code this 4.19 kernel needs. OriginSU `v4.3.0` still supports it fully (non-GKI hooks, SuSFS, built-in module mounting), so this builder stays on it: the root solution is frozen, but the builder is still maintained by hand for kernel updates and optimizations.
>
> KazeSU support for MSM8937 is **on hold**: its separate repository, [msm8937-KazeSU-builder](https://github.com/1992Ade/msm8937-KazeSU-builder), will get a proper update later, depending on how KazeSU development evolves (in particular whether older kernels are supported again).
>
> The OriginSU `v4.3.0` code and manager remain available in the KazeSU repository ([tag `v4.3.0`, release "legacy-v4.3.0"](https://github.com/KazeSU/KazeSU/releases/tag/v4.3.0)); the matching manager APK is also attached to every release here. Note that KazeSU `v1.0.0` works with this kernel too but new root hiding method is not implemented.

> **Your warranty is now void.** Flashing a custom kernel can brick your device. You are responsible for what you flash. Always keep a backup of your stock `boot` partition.

## 📱 About This Repository

This repository automates the compilation of a custom **Linux 4.19** kernel for **MSM8937** (Snapdragon 430/435) Xiaomi devices, based on the [Mi-Thorium](https://github.com/Mi-Thorium) kernel tree. Check out **[riarumoda](https://github.com/riarumoda/perf_neon-builder)** for the original work with BakaSU implementation, other devices and Custom ROM suggestions.

Every build integrates the **[OriginSU v4.3.0](https://github.com/KazeSU/KazeSU/releases/tag/v4.3.0)** kernel-based root solution — together with **SuSFS**, **Baseband Guard**, **NoMount**, **Droidspaces**, **TCP BBR** and a set of low-risk [kernel optimizations](#-optimizations) (see [Included features](#-included-features)) — and is packaged as a recovery-flashable `.zip` (TWRP / OrangeFox) with AnyKernel3. The matching **OriginSU manager APK** is attached to each release.

**Manual builds only:** OriginSU will not get new releases, so the weekly check was removed. Running the workflow by hand rebuilds OriginSU `v4.3.0` on the latest Mi-Thorium kernel, with the current optimizations, and replaces the release.

---

## 🧩 Included Features

On top of OriginSU, every build enables the same hardening/usability modules as the base [perf_neon-builder](https://github.com/riarumoda/perf_neon-builder) for the `mi89x7` target:

| Feature | Upstream | What it does | Kernel config |
|---|---|---|---|
| **SuSFS** | [simonpunk](https://gitlab.com/simonpunk/susfs4ksu) | Hides root/mounts from detection (`-susfs` variant only) | `CONFIG_KSU_SUSFS_*` |
| **Baseband Guard** | [vc-teahouse](https://github.com/vc-teahouse/Baseband-guard) | LSM that blocks writes to the modem/baseband partitions | `CONFIG_BBG=y` |
| **NoMount** | [maxsteeel](https://github.com/maxsteeel/nomount) | Mounts modules without real mounts (VFS path redirection, nothing in `/proc/mounts`) — driven by OriginSU's *OriginMount* screen, see [Modules](#-modules) | `CONFIG_NOMOUNT=y` |
| **Droidspaces** | [ravindu644](https://github.com/ravindu644/Droidspaces-OSS) | Namespace/cgroup isolation to run isolated Android/Linux spaces | `CONFIG_NAMESPACES`, `CONFIG_*_NS`, cgroups, netfilter… |
| **TCP BBR + fq** | Linux / Mi-Thorium | BBR is the default TCP congestion control, paired with the `fq` qdisc for packet pacing | `CONFIG_DEFAULT_BBR=y`, `CONFIG_DEFAULT_FQ=y` |
| **Optimizations** | this repo ([`scripts/optimizations.sh`](scripts/optimizations.sh)) | Power-efficient workqueues, zstd for ZRAM, TTL/HL targets, `vm.swappiness` up to 200, Cortex-A53 tuning | see [Optimizations](#-optimizations) |

> **Droidspaces note:** it enables `CONFIG_CFS_BANDWIDTH=y`, which can conflict with Qualcomm's WALT scheduler on some trees. It is enabled for `mi89x7` the same way the base project does; if a build or boot ever breaks, this is the first config to suspect.
>
> If you use Droidspaces with a systemd-based Linux space, mask the `NetworkManager` and `wpa_supplicant` services inside that space (as noted upstream).

### 🌐 TCP BBR

The Mi-Thorium base config already builds BBR and makes it the default; the workflow enforces it and adds the **`fq`** queue discipline as default qdisc. BBR sets the sending rate from measured bandwidth and RTT instead of reacting to packet loss, which helps on lossy Wi-Fi and mobile links; `fq` paces packets at the rate BBR computes, which costs less CPU on the Cortex-A53 than TCP's built-in pacing fallback. The build fails if the final `.config` does not have `CONFIG_DEFAULT_TCP_CONG="bbr"` and `CONFIG_DEFAULT_NET_SCH="fq"`.

Check on the phone (root shell):

```sh
cat /proc/sys/net/ipv4/tcp_congestion_control        # bbr
cat /proc/sys/net/ipv4/tcp_available_congestion_control
cat /proc/sys/net/core/default_qdisc                 # fq
```

### ⚡ Optimizations

Applied by [`scripts/optimizations.sh`](scripts/optimizations.sh), which is shared with [msm8937-KazeSU-builder](https://github.com/1992Ade/msm8937-KazeSU-builder) (it does not depend on the root solution). Only low-risk changes: each one either saves power or only takes effect if you change a setting. The build fails if one of the configs below is missing from the final `.config`.

| Change | Effect | How to use / check |
|---|---|---|
| `CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y` | Background kernel work runs on CPUs that are already awake instead of waking an idle core | `cat /sys/module/workqueue/parameters/power_efficient` → `Y` |
| `CONFIG_CRYPTO_ZSTD=y` | zstd becomes available for ZRAM (better compression than lz4, a bit more CPU). **lz4 stays the default** | `cat /sys/block/zram0/comp_algorithm` lists `zstd` |
| `CONFIG_IP6_NF_TARGET_HL=y` (+ IPv4 `TTL`) | iptables `TTL` / `HL` targets, e.g. to hide tethering from the carrier | `iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64` and `ip6tables -t mangle -A POSTROUTING -j HL --hl-set 64` |
| `vm.swappiness` max 100 → 200 | Lets you make the kernel prefer swapping to ZRAM over dropping app caches. The default value set by the ROM is unchanged | `echo 160 > /proc/sys/vm/swappiness` (values up to 200 accepted) |
| `-mcpu=cortex-a53` | Code tuned for the Cortex-A53 cores used by all supported devices (ThinLTO keeps it at link time) | — |

Not included on purpose: MGLRU (its authors advise against it on CPUs without hardware access-flag management, which the Cortex-A53 lacks) and BBRv3 (only maintained for 6.x kernels; the 4.19 BBRv1 already has the Wi-Fi/cellular ACK-aggregation fixes).

---

## ✅ Supported Devices

Same device family as the Mi-Thorium `mi89x7` target:

| Device | Codename |
|---|---|
| Redmi 3S / 3X | `land` |
| Redmi 4 | `prada` |
| Redmi 4X | `santoni` |
| Redmi 4A | `rolex` |
| Redmi 5A | `riva` |
| Redmi Note 5A Lite / Y1 Lite | `ugglite` |
| Redmi Note 5A Prime / Y1 Prime | `ugg` |

**Requirement:** a ROM that runs on the Mi-Thorium **4.19** kernel (Android 11 and newer). I suggest  **[/e/OS for Redmi 3S/Mi8937](https://doc.e.foundation/devices/Mi8937/)** on Android 15.

---

## 📦 Which zip should I download?

Each release ships two variants:

| File | Hook mode | Recommended for |
|---|---|---|
| `MSM8937-OriginSU-<version>-susfs-<date>.zip` | SuSFS inline hook | Most users — root + SuSFS root hiding |
| `MSM8937-OriginSU-<version>-manual-<date>.zip` | Manual hook | Fallback if the SuSFS build doesn't boot |

The full kernel `.config` of each variant is attached to the release for reference.

---

## 🔧 Installation

0. **Coming from Magisk, APatch, BakaSU or another KernelSU?** Read [this warning](#️-coming-from-another-root-solution) first.
1. Back up your stock `boot` partition (from TWRP/OrangeFox, or keep the `boot.img` of your ROM).
2. Download the zip from the [latest release](https://github.com/1992Ade/msm8937-origin-builder/releases/latest).
3. Reboot to recovery and flash it (or `adb sideload <file>.zip`).
4. If you use the bootloader bypass exploit on MSM8937, flash the **appender** after the kernel.
5. Reboot to system.
6. Install the **OriginSU manager** APK attached to the same release (`OriginSU_v4.3.0_…-arm64-v8a-release.apk`, also on the [legacy-v4.3.0 page](https://github.com/KazeSU/KazeSU/releases/tag/v4.3.0)). It must match the kernel: do **not** install the KazeSU v1.x manager with this kernel.

### 🧱 Modules

OriginSU mounts modules itself. Choose how in the manager's **OriginMount** screen (the choice applies from the next boot):

| Mode | What it does |
|---|---|
| `auto` (default) | Uses a metamodule if one is installed, otherwise Magic Mount if you enabled it, otherwise **no mounting** |
| `nomount` | Uses the **NoMount** driver built into this kernel: module files are injected without real mounts, so nothing shows in `/proc/mounts` |
| `builtin` | OriginSU's built-in Magic Mount |
| `metamodule` | Delegates to an installed metamodule (e.g. meta-overlayfs) |
| `off` | No module mounting (scripts, `sepolicy.rule` and `system.prop` still work) |

NoMount is already in the kernel and OriginSU talks to it directly: **do not install the separate NoMount module zip** on top.

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
check  ──►  build (susfs)  ──┐
       └─►  build (manual) ──┴──►  release
```

1. **check** — selects the OriginSU tag (`v4.3.0` by default; only `v4.x` OriginSU tags are accepted).
2. **build** (×2, in parallel)
   - Clones the Mi-Thorium kernel (`mithorium/a13/master`) plus its device trees, techpacks (xiaomi, audio, camera) and the **prima** Wi-Fi driver.
   - Downloads the latest **Neutron Clang** toolchain.
   - Generates the config from `vendor/msm8937-perf_defconfig` + the Mi-Thorium fragments (`msm8937-legacy`, `xiaomi/msm8937/mi8937`, `kprobes`, …).
   - Enables TCP BBR + `fq` (see [TCP BBR](#-tcp-bbr)) and applies the shared [optimizations](#-optimizations).
   - Reverts the KernelSU commit already present in the Mi-Thorium tree, then integrates OriginSU at the exact tag, from the KazeSU repository (the build stops if that tag cannot be checked out).
   - Applies the non-GKI hook patches (SuSFS inline hook or manual hook) and the 4.19 fixups from perf_neon-builder.
   - Enables the extra features — **Baseband Guard**, **NoMount** and **Droidspaces** (see [Included features](#-included-features)). The build stops if the NoMount driver speaks an API older than the one OriginSU requires (22).
   - Compiles `Image.gz-dtb` (after checking BBR/fq and the optimization configs) and packages it with AnyKernel3.
3. **release** — downloads the matching OriginSU manager APK (arm64-v8a) from the KazeSU repository and publishes a GitHub Release `originsu-<tag>` with both zips, the manager, the configs and release notes (OriginSU version, kernel commit, kernel version, build date).

### Schedule

| Trigger | Behaviour |
|---|---|
| Manual (`Run workflow`) | Builds OriginSU `v4.3.0` (or another `v4.x` tag), optional KPM, optional release |

There is no scheduled build any more (OriginSU is discontinued).

A manual run for a version that is already released **replaces** that release (useful to pick up kernel updates).

---

## 🚀 Using This Repository (forks)

1. Fork the repository.
2. Go to **Settings → Actions → General** and make sure Actions are enabled and **Workflow permissions** allow *Read and write* (needed to publish releases).
3. Run **Build MSM8937 Kernel (Mi-Thorium) with OriginSU** once manually to create the first release.

### Manual run options

| Input | Default | Description |
|---|---|---|
| `originsu_ref` | `v4.3.0` | OriginSU tag to build (`v4.x` only) |
| `kpm` | `false` | Enable `CONFIG_KPM` (disable if the build fails on KPM) |
| `publish` | `true` | Publish a GitHub Release (otherwise only build artifacts) |

---

## 🛠️ Troubleshooting

| Problem | What to do |
|---|---|
| Build fails in *Integrate OriginSU* | A hook patch no longer matches OriginSU — check `build-<mode>.log` in the run artifacts |
| Build fails with KPM errors | Re-run manually with `kpm` disabled |
| Build fails with a BBR / fq error | The kernel config no longer selects BBR or `fq` by default — check the *TCP congestion control* lines in the compile log |
| Build fails with `optimizations:` errors | A config from [`scripts/optimizations.sh`](scripts/optimizations.sh) was dropped by Kconfig — check the *Optimizations in the final .config* lines in the compile log |
| Release fails at *Fetch the OriginSU manager APK* | The APK is no longer on the KazeSU `v4.3.0` release — re-run with `publish` off, or attach the APK by hand |
| Modules installed but their files don't show up | Pick a mode in **OriginMount** (`auto` mounts nothing without a metamodule or Magic Mount) — see [Modules](#-modules) |
| Device stuck on boot logo | Flash the `-manual` variant, or restore the stock `boot.img` |
| Boots, but no Wi-Fi / mobile network / camera | Almost always a module conflict — see [Coming from another root solution?](#️-coming-from-another-root-solution) below |
| Wi-Fi not working (no modules installed) | Make sure your ROM is built for the Mi-Thorium 4.19 kernel |

### ⚠️ Coming from another root solution?

If you previously used **Magisk, APatch, BakaSU (perf_neon), KernelSU or SukiSU**, your old modules are still in `/data/adb/modules` and will be loaded by OriginSU.

OriginSU ships its **own Zygisk (OriginZygisk)**. Old modules — especially another Zygisk implementation (ReZygisk, NeoZygisk, Zygisk Next) or Zygisk-based modules such as LSPosed — can conflict with it. The typical symptom is a phone that **boots fine but has no Wi-Fi, no mobile network and/or no camera**.

**Fix: uninstall all modules, then reinstall them one by one.**

From a PC (use the interactive shell — it also works in Windows PowerShell):

```sh
adb shell
su
for m in /data/adb/modules/*/; do touch "$m/remove"; done
rm -rf /data/adb/modules_update/*
reboot
```

Each module's `uninstall.sh` runs on the next boot. If some folders remain afterwards:

```sh
adb shell
su
rm -rf /data/adb/modules/*
reboot
```

Then:

- Reinstall your modules **one at a time**, checking Wi-Fi, network and camera after each reboot.
- Use **only one Zygisk**: keep OriginZygisk and don't install another Zygisk module.
- Reinstall Zygisk-based modules (e.g. LSPosed) last.
- Optional cleanup of leftovers from other root solutions, e.g. APatch: `rm -rf /data/adb/ap /data/adb/apd`.

---

## 🙏 Credits & Acknowledgments

This project relies on the incredible work of the following open-source projects and developers:

* **[Mi-Thorium](https://github.com/Mi-Thorium)** — For the MSM8937 4.19 kernel source tree ([kernel_msm-4.19](https://github.com/Mi-Thorium/kernel_msm-4.19), branch `mithorium/a13/master`), device trees, techpacks and the prima Wi-Fi driver.
* **[OriginSU](https://github.com/KazeSU/KazeSU/releases/tag/v4.3.0)** (now [KazeSU](https://github.com/KazeSU/KazeSU)) — For the kernel-based root solution.
* **[riarumoda](https://github.com/riarumoda/perf_neon-builder)** — For perf_neon-builder, whose MSM8937 workflow this build is based on, and for the [AnyKernel3 fork](https://github.com/riarumoda/AnyKernel3) used for packaging.
* **[osm0sis](https://github.com/osm0sis/AnyKernel3)** — For the original AnyKernel3.
* **[JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd)** — For the non-GKI KernelSU hook scripts and SuSFS patches.
* **[simonpunk](https://gitlab.com/simonpunk/susfs4ksu)** — For SuSFS.
* **[vc-teahouse](https://github.com/vc-teahouse/Baseband-guard)** — For Baseband Guard.
* **[maxsteeel](https://github.com/maxsteeel/nomount)** — For NoMount.
* **[ravindu644](https://github.com/ravindu644/Droidspaces-OSS)** — For Droidspaces.
* **[Neutron Toolchains](https://github.com/Neutron-Toolchains)** — For the Clang toolchain.
* **[tiann/KernelSU](https://github.com/tiann/KernelSU)** — The project OriginSU is built upon.

## 📄 License

Kernel sources are licensed under **GPL-2.0**. See each upstream project for its own license.
