# MSM8937 Kernel Builder with OriginSU

[![Build](https://img.shields.io/badge/build-GitHub%20Actions-blue?logo=github-actions&logoColor=white)](https://github.com/1992Ade/msm8937-origin-builder/actions/workflows/build-kernel.yml)
[![Latest release](https://img.shields.io/github/v/release/1992Ade/msm8937-origin-builder?label=latest&logo=github)](https://github.com/1992Ade/msm8937-origin-builder/releases/latest)

> **Your warranty is now void.** Flashing a custom kernel can brick your device. You are responsible for what you flash. Always keep a backup of your stock `boot` partition.

## 📱 About This Repository

This repository automates the compilation of a custom **Linux 4.19** kernel for **MSM8937** (Snapdragon 430/435) Xiaomi devices, based on the [Mi-Thorium](https://github.com/Mi-Thorium) kernel tree. Check out **[riarumoda](https://github.com/riarumoda/perf_neon-builder)** for the original work with BakaSU implementation, other devices and Custom ROM suggestions.

Every build integrates the **[OriginSU](https://github.com/samakshkambxj/OriginSU)** kernel-based root solution and is packaged as a recovery-flashable `.zip` (TWRP / OrangeFox) with AnyKernel3.

**Fully automated:** a GitHub Actions workflow checks every week (Sunday) for a new OriginSU release. When one appears, the kernel is rebuilt and a new GitHub Release is published automatically — no manual action needed.

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
6. Install the **OriginSU manager** APK from the [OriginSU releases](https://github.com/samakshkambxj/OriginSU/releases) (use the same version as the kernel).

### ↩️ Restore the stock kernel

```sh
su -c rm -rf /data/adb/*        # remove root data first
adb reboot bootloader
fastboot flash boot stock_boot.img
fastboot reboot
```

---

## ⚙️ How the Build Works

The workflow lives in [`.github/workflows/build-kernel.yml`](.github/workflows/build-kernel.yml) and runs three jobs:

```
check  ──►  build (susfs)  ──┐
       └─►  build (manual) ──┴──►  release
```

1. **check** — reads the latest OriginSU release tag and looks for a release named `originsu-<tag>` in this repo. If it already exists, the run stops there.
2. **build** (×2, in parallel)
   - Clones the Mi-Thorium kernel (`mithorium/a13/master`) plus its device trees, techpacks (xiaomi, audio, camera) and the **prima** Wi-Fi driver.
   - Downloads the latest **Neutron Clang** toolchain.
   - Generates the config from `vendor/msm8937-perf_defconfig` + the Mi-Thorium fragments (`msm8937-legacy`, `xiaomi/msm8937/mi8937`, `kprobes`, …).
   - Reverts the KernelSU commit already present in the Mi-Thorium tree, then integrates OriginSU at the exact release tag.
   - Applies the non-GKI hook patches (SuSFS inline hook or manual hook) and the 4.19 fixups from perf_neon-builder.
   - Compiles `Image.gz-dtb` and packages it with AnyKernel3.
3. **release** — publishes a GitHub Release `originsu-<tag>` with both zips, the configs and release notes (OriginSU version, kernel commit, kernel version, build date).

### Schedule

| Trigger | Behaviour |
|---|---|
| Every Sunday at 05:17 UTC | Builds **only** if a new OriginSU release is out |
| Manual (`Run workflow`) | Always builds; you can pick an OriginSU tag, toggle KPM and choose whether to publish a release |

A manual run for a version that is already released **replaces** that release (useful to pick up kernel updates).

---

## 🚀 Using This Repository (forks)

1. Fork the repository.
2. Go to **Settings → Actions → General** and make sure Actions are enabled and **Workflow permissions** allow *Read and write* (needed to publish releases).
3. In the **Actions** tab, enable scheduled workflows on the fork.
4. Run **Build MSM8937 Kernel (Mi-Thorium) with OriginSU** once manually to create the first release.

> GitHub disables scheduled workflows after **60 days without repository activity**. If automatic releases stop, re-enable the workflow in the Actions tab or push a commit.

### Manual run options

| Input | Default | Description |
|---|---|---|
| `originsu_ref` | *(latest release)* | OriginSU tag to build |
| `kpm` | `true` | Enable `CONFIG_KPM` (disable if the build fails on KPM) |
| `publish` | `true` | Publish a GitHub Release (otherwise only build artifacts) |

---

## 🛠️ Troubleshooting

| Problem | What to do |
|---|---|
| Build fails in *Integrate OriginSU* | A hook patch no longer matches OriginSU — check `build-<mode>.log` in the run artifacts |
| Build fails with KPM errors | Re-run manually with `kpm` disabled |
| Device stuck on boot logo | Flash the `-manual` variant, or restore the stock `boot.img` |
| Boots, but no Wi-Fi / mobile network / camera | Almost always a module conflict — see [Coming from another root solution?](#️-coming-from-another-root-solution) below |
| Wi-Fi not working (no modules installed) | Make sure your ROM is built for the Mi-Thorium 4.19 kernel |
| No new release after an OriginSU update | Check that the scheduled workflow is still enabled (60-day rule above) |

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
* **[OriginSU](https://github.com/samakshkambxj/OriginSU)** — For the kernel-based root solution.
* **[riarumoda](https://github.com/riarumoda/perf_neon-builder)** — For perf_neon-builder, whose MSM8937 workflow this build is based on, and for the [AnyKernel3 fork](https://github.com/riarumoda/AnyKernel3) used for packaging.
* **[osm0sis](https://github.com/osm0sis/AnyKernel3)** — For the original AnyKernel3.
* **[JackA1ltman](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd)** — For the non-GKI KernelSU hook scripts and SuSFS patches.
* **[simonpunk](https://gitlab.com/simonpunk/susfs4ksu)** — For SuSFS.
* **[Neutron Toolchains](https://github.com/Neutron-Toolchains)** — For the Clang toolchain.
* **[tiann/KernelSU](https://github.com/tiann/KernelSU)** — The project OriginSU is built upon.

## 📄 License

Kernel sources are licensed under **GPL-2.0**. See each upstream project for its own license.
