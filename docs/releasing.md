# Android release signing

Official releases from v1.3.1 use the permanent Lockout PKCS12 signing key.
The private keystore and a self-contained Markdown recovery document are saved
in the owner-requested OneDrive Documents folder, outside this repository.
The recovery document contains private material and must never be published.

Public certificate SHA-256:
`5580479C76233D86FD10A50B557F3585127A16C0AF807CF7E2622420F3858C24`.

## Configure an official release build

Restore the existing permanent key; do not generate a replacement for updates.
Copy `android/key.properties.example` to ignored `android/key.properties`, then
fill its four fields from the private recovery notes. `storeFile` is the absolute
keystore path. Forward slashes work on Windows. Use the PKCS12 store and alias
`lockout-release`. Alternatively set `LOCKOUT_KEYSTORE_PROPERTIES` to a private
properties file's absolute path.

Build with `C:\src\flutter\bin\flutter.bat build apk --release` on the project
owner's Windows setup. Check the APK using `apksigner verify --print-certs` and
compare its certificate fingerprint with the value above before publication.
Attach the APK and its SHA-256 checksum to the matching source tag.

Missing configuration fails local release-signing validation; local official
release builds do not fall back to a debug key. Credentials are read only from the local properties
file, never from committed values. Keystore formats and `android/key.properties`
are ignored by Git. Do not place recovery notes inside this checkout.

## CI and local development

Development builds use `flutter build apk --debug`. The unchanged GitHub Actions
workflow compiles release-mode test APKs without the private key. In that explicit
`GITHUB_ACTIONS=true` environment only, absent release credentials select a debug
certificate and emit a prominent test-artifact warning. Its `lockout-apk-*`
artifacts are disposable test packages, not official release updates, and cannot
update permanently signed installations. If permanent credentials are supplied,
they always take precedence. Forks can use their own signing identity,
but cannot update an installation signed by the official key.

## Migration from older builds

The original v1.1.0 release key is unavailable. Previous local debug builds also
have different identities. Before removing any older installation, export its
JSON backup, save it outside the app and verify the file exists. Uninstalling
removes local data. Then install the new permanent-key release and import the
backup. Future releases must retain the permanent key to update in place.

## Logo regeneration

The approved icon is The last rep, the center choice in
`docs/design/icon-preview/concept-03.png`. Production paths are reconstructed as
flat vector geometry in `tools/generate_brand_assets.py`. Run that script using
the existing local Python/Pillow tooling to regenerate 95 PNG exports, five SVGs,
legacy Android density resources, adaptive layers and the Android 13 monochrome
layer. The release logo ZIP contains only `assets/branding`, never signing files.
