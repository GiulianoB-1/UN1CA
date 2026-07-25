# Galaxy A52 5G Android 17 porting status

## Device identity

This target is only for:

- Samsung Galaxy A52 5G
- Model family: SM-A526
- Codename: `a52xq`
- SoC: Snapdragon 750G / SM7225
- Qualcomm platform: lito

It is not the Galaxy A52s 5G (`a52sxq`, SM-A528, SM7325).

## Source of this target

The device directory was restored from the historical official UN1CA commit:

`b482000753db7f888179fa1c3362ac73233d797f`

The original target included camera adaptation, stock blobs, overlays,
Samsung Product Feature patches, device properties and installer data.

## Current status

### Migrated

- Current-format `config.sh`
- Exact super-partition sizes
- Exact SM7225 identifiers
- Android 11 target vendor API levels
- Conservative current-format `sff.sh`
- Historical overlays
- Historical debloat list
- Historical patch files retained for reference
- Verified Fold8 Android 17 / One UI 9 framework donor and image hashes

### Disabled pending rebase

The following historical patch groups contain valuable device knowledge, but
they were written for an older Samsung framework and must not be applied
blindly:

- `patches/camera`
- `patches/miscs`
- `patches/spf`
- `patches/stock_blobs`
- `patches/adb`
- `unica/patches/product_feature`

Each group contains a `disable` marker during the first stage.

### Required before any flashable build

1. Stage the verified `F971BXXU1AZFW` donor described in `DONOR.md`.
2. Import its `system`, `product` and `system_ext` framework trees.
3. Verify the imported framework identity and Android 17 / SDK 37 metadata.
4. Audit and re-enable the global Product Feature module for One UI 9.
5. Compare the FCM level 5 framework matrix with the captured A52XQ manifests.
6. Rebase stock-blob adaptation first.
7. Rebase camera adaptation.
8. Recreate SPF substitutions against the new framework files.
9. Remove Fold8-specific display, hinge and subdisplay behavior.
10. Validate logical partition sizes.
11. Build and inspect images without flashing.
12. Only then prepare the first recovery test package.

## Known working baseline

The physical phone currently boots:

- Android 16 / SDK 36
- One UI 8
- Galaxy S22 system identity
- A52XQ Android 11 vendor / SDK 30
- Kernel 4.19.152 touchGrassKernel
- SELinux enforcing
- Active netd and tethering BPF programs
- EROFS dynamic partitions

That working ROM is the behavioral baseline for Android 17.
