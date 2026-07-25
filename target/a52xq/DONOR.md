# Android 17 donor

## Selected firmware

- Device: Samsung Galaxy Z Fold8
- Model: `SM-F971B`
- Product/codename family: `h8q` (`h8qxxx`; framework device `qssi_64`)
- Platform: `sm8850`
- CSC: `EUX`
- Build: `F971BXXU1AZFW`
- Android: 17
- SDK: 37
- One UI: 9 (`ro.build.version.oneui=90000`)
- Security patch: 2026-06-05
- Build ID: `CP2A.260605.016`
- Fingerprint: `samsung/h8qxxx/qssi_64:17/CP2A.260605.016/F971BXXU1AZFW:user/release-keys`

The framework is Android 17 / SDK 37. The Fold8 vendor and ODM baseline is
Android 16 / SDK 36, so both source shipping and board API levels are 36.

## Package provenance

- Archive: `F971BXXU1AZFW_F971BOXM1AZFW_F971BXXU1AZFW_EUX.zip`
- Size: 24,015,540,826 bytes
- SHA-256: `A9D0D2C3D8C5896B43C31D50494F8B2FABB5C7008F181EF4BA0A4F6765487BAA`
- AP: `AP_F971BXXU1AZFW_F971BXXU1AZFW_MQB111318164_REV00_user_low_ship_MULTI_CERT_meta_OS17.tar.md5`
- AP size: 13,832,601,723 bytes
- `super.img.lz4` size: 12,537,841,524 bytes

This is a full Samsung firmware package. No incremental OTA or base firmware
is required.

## Verified framework images

| Partition | Size | SHA-256 |
| --- | ---: | --- |
| `system.img` | 8,362,614,784 | `5F1FD15067725378F6180DC4B80320E44978E86E6F9022C861CFD8B01BD48BC9` |
| `product.img` | 1,686,491,136 | `836278C2A238BCCA7018034D18103B65CBF7C141D362B68CA3AAB2BF9D2E222F` |
| `system_ext.img` | 205,262,848 | `BF66B3E301A8CCB64BF3DBAF57323A6CD96727241B55E3415E05DB8FEDB1A147` |

All three images have valid EROFS superblock magic.

## Local staging

The inspected artifacts currently live on the Windows G: SSD:

```text
G:\CodexScratch\f971b-azfw
```

From WSL, the AP is available at:

```text
/mnt/g/CodexScratch/f971b-azfw/ap/AP_F971BXXU1AZFW_F971BXXU1AZFW_MQB111318164_REV00_user_low_ship_MULTI_CERT_meta_OS17.tar.md5
```

UN1CA expects locally downloaded Odin files under:

```text
out/odin/SM-F971B_EUX/
```

Stage the AP and BL there and set `.downloaded` to:

```text
F971BXXU1AZFW/F971BOXM1AZFW/F971BXXU1AZFW
```

Do not commit firmware archives or partition images to Git.

## Porting boundary

Use the Fold8 `system`, `product`, and `system_ext` trees as framework donor
content. Do not carry Fold8 `vendor`, `odm`, `vendor_dlkm`, `system_dlkm`,
boot images, DTBO, vbmeta, or pvmfw into the SM-A526B package.

The target remains `a52xq` / SM7225 with its Android 11 vendor and target
kernel. Foldable display, hinge, subdisplay, camera, fingerprint, radio and
Wi-Fi product features must be rebased before any build or flash test.

The global `unica/patches/product_feature` module is intentionally disabled
on this development branch until its source constants are audited against
One UI 9. The values below the donor identity block in `unica/configs/qssi.sh`
are therefore marked as inherited and must not be treated as verified Fold8
values.
