# MSM8937 Kernel Builder with OriginSU

## 📱 About This Repository
This repository automates the compilation of a custom Linux 4.19 kernel for **MSM8937** (Snapdragon 430/435) devices. Powered by GitHub Actions, every build automatically integrates the **OriginSU** root solution and packages a recovery-flashable `.zip` file (compatible with TWRP / OrangeFox).

---

## 🙏 Credits & Acknowledgments

This project relies on the incredible work of the following open-source projects and developers:

* **[Mi-Thorium](https://github.com/Mi-Thorium/kernel_msm-4.19)** — For providing the MSM8937 kernel source tree (GKI A13 branch).
* **[OriginSU](https://github.com/samakshkambxj/OriginSU)** — For the kernel-based root solution.
* **[osm0sis](https://github.com/osm0sis/AnyKernel3)** — For the AnyKernel3 tool used to package the compiled kernel into a flashable zip.
* **[riarumoda](https://github.com/riarumoda/perf_neon-builder)** — For the inspiration and workflow automation structure.
