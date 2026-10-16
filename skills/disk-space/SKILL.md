---
name: disk-space
description: "Find what is using disk space on this Mac and what can actually be reclaimed."
---

# Disk space audit (macOS / APFS)

Rule zero: **quote one number, once, after every check below.** Never give a
running estimate that gets revised down prompt by prompt. If something is not
measured, label it "unmeasured" — do not guess.

## Why naive `du` is wrong here

Each of these has produced a wrong headline number before:

| Trap | What happens | Correct measurement |
|---|---|---|
| `/System/Volumes/Update/mnt1` | It is the **live system volume mounted a second time** (`/dev/disk3s1`). `du` reports the whole OS (~12 GB) as "staged update". | Ignore it. A staged update is `AssetsV2/com_apple_MobileAsset_MacSoftwareUpdate` + `Preboot/Cryptexes/Incoming` + `Update/SFR` + `Update/softwareupdate.*`. |
| cryptexd / dmg mounts | Simulator runtimes, Metal toolchain, Rosetta mount as separate APFS containers. `diskutil apfs list` shows "Capacity Consumed" of the *mounted image*, not the file. | Size the backing file: `du -sh` on the `.asset` dir under `/System/Library/AssetsV2/…`. Get the mapping from `hdiutil info` (`image-path`). |
| `Preboot/<Data-UUID>/` | Hardlink/clone tree; `du` shows 45 GB on a 21 GB volume. | Use the volume's Capacity Consumed, not `du`. |
| APFS clones (Chrome `code_sign_clone`, DerivedData, `simctl runtime add`) | `du` counts shared blocks at full size. | Treat as "≤ N GB, likely clones" unless verified. |
| Sparse files (`Docker.raw`) | `ls -l` shows logical size (245 GB); real is `du` (12 GB). | Always `du`, never `ls`, for sizes. |
| Firmlinks (`/Applications`, `/Users`, `/Library` → Data) | `du /` without `-x` double counts. | Always `du -x`. |
| Snapshots (`com.apple.os.update-*`) | Hold space invisible to `du`. Sizes are not exposed. | Report "N snapshots, size unmeasurable"; a restart clears MSUPrepareUpdate. |
| Swap | Lives on the `VM` volume, not in `/private/var/vm`. | `sysctl vm.swapusage`. Only a restart reclaims it. |

## Procedure

1. **Ground truth first.** `df -h /` and `diskutil apfs list` for the internal
   container (`disk3`). Volumes: Macintosh HD, Preboot, Recovery, Data, VM.
   These sum to the disk; everything else must reconcile against Data.
2. **Top-down, `-x` only.** `du -xsh /Users /Applications /Library /private /opt`
   then descend into the big ones. Stop descending at mount points
   (`mount | grep <path>`).
3. **For every candidate ≥ 1 GB, before it goes in the table, verify:**
   - *Backing path*: is it a mount? (`mount | grep`) → size the image file instead.
   - *Real size*: `du -sh` on the backing path (handles sparse + clones as well
     as possible; say "≤" if clones are plausible).
   - *Deletable by whom*: `ls -lO` for `restricted`/`sunlnk` flags. Anything
     under `/System/Library/AssetsV2` is SIP/MobileAsset-owned — `rm` fails
     even as root. Simulator runtimes: `xcrun simctl runtime delete <uuid>`
     (run `xcrun simctl runtime scan-and-mount` first if it's orphaned and not
     listed). OS updates: no supported purge.
   - *In use*: booted simulators (`xcrun simctl list devices | grep Booted`),
     running containers, open tmux sessions driving them.
4. **Then report** one table: item · measured size · backing path · how to
   delete · in-use? · confidence. Give **one** reclaimable total and name the
   single biggest lever (on a 16 GB Mac it is usually swap → restart).

## Known layout on this Mac

- Internal SSD 228 GB; external `/Volumes/offload` (1.9 TB) for anything big.
- Simulator runtimes: `/System/Library/AssetsV2/com_apple_MobileAsset_{iOS,watchOS}SimulatorRuntime/*.asset` (~7.5 GB each). Delete via simctl only.
- Simulator devices: `~/Library/Developer/CoreSimulator/Devices` — `xcrun simctl delete all` after checking nothing is booted.
- Docker VM disk: `~/Library/Containers/com.docker.docker/…/Docker.raw` (sparse). Media stack + agent-memory postgres run in it — not junk.
- Safe junk when seen: `~/Library/Developer/Xcode/DerivedData`, `iOS DeviceSupport/*`, `*ShipIt` update caches, `/Library/Application Support/Logi/LogiOptionsPlus/{cache,depots}`, old `~/.local/share/claude/versions/*`.
