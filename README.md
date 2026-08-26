# WatchPlayer — video player for Apple Watch (watchOS 8, Series 3+)

A watchOS app that plays videos directly on your Apple Watch using the native
`WKInterfaceMovie` player, plus a small iPhone companion app to send your own
videos to the watch over Bluetooth/Wi-Fi via `WCSession`.

## What it does

**On the watch**
- List of playable videos:
  - a bundled sample clip (`Extension/Resources/sample.mp4`)
  - several streaming presets (small progressive MP4s)
  - any videos sent from the iPhone app (stored in the app's Documents folder)
- Tap a row -> fullscreen player with play/pause/scrub controls.
- Refresh button rescans for new files.

**On the iPhone**
- Pick video files with the document picker; they are queued and transferred
  to the watch automatically (transfer completes even if the watch is offline
  at pick time — it sends when the devices connect).

## Requirements

- macOS with Xcode 13+ (project targets watchOS 8.0 / iOS 14.0)
- Apple Watch Series 3 or newer running watchOS 8+
- A free (or paid) Apple Developer account for on-device signing

## Build & run

1. Open `WatchPlayer.xcodeproj` in Xcode.
2. Select each of the 3 targets ("WatchPlayer", "WatchPlayer WatchKit App",
   "WatchPlayer WatchKit Extension") -> Signing & Capabilities -> set your Team.
3. Choose the **WatchPlayer** scheme, pick your paired iPhone + Apple Watch,
   and Run. Both apps install together.
4. Launch "WatchPlayer" on the watch.

If Xcode complains about the hand-written project file, regenerate it:

```bash
brew install xcodegen
xcodegen generate   # uses project.yml in this folder
```

## Build an IPA with GitHub Actions

The repository includes a workflow at `.github/workflows/build.yml`. Open the repository’s **Actions** tab, select **Build WatchPlayer IPA**, choose **Run workflow**, and select `unsigned` to produce `WatchPlayer-unsigned.ipa` as a downloadable workflow artifact. This package is useful for inspecting the app bundle, but an unsigned IPA cannot be installed on an iPhone or Apple Watch.

To create an installable IPA, configure the following repository secrets in **Settings → Secrets and variables → Actions** and run the workflow with `signed` selected:

| Secret | Value |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Apple distribution `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` certificate |
| `APPLE_KEYCHAIN_PASSWORD` | Any temporary password for the CI keychain |
| `APPLE_TEAM_ID` | Your 10-character Apple Developer Team ID |
| `APPLE_IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded profile for `com.watchplayer.WatchPlayer` |
| `APPLE_WATCH_APP_PROVISIONING_PROFILE_BASE64` | Base64-encoded profile for `com.watchplayer.WatchPlayer.watchkitapp` |
| `APPLE_WATCH_EXTENSION_PROVISIONING_PROFILE_BASE64` | Base64-encoded profile for `com.watchplayer.WatchPlayer.watchkitapp.extension` |

The three provisioning profiles must belong to the same App ID family and team, and the selected export method must match their type. For example, use `ad-hoc` for an Ad Hoc profile or `app-store` for an App Store profile. The workflow uploads the resulting `WatchPlayer.ipa` under the **Actions** run’s artifacts. Apple Developer signing is required for a device-installable package; GitHub Actions can build the file, but it cannot create Apple certificates or profiles for you.

For local base64 encoding, run `base64 -i MyProfile.mobileprovision | pbcopy` on macOS, or `base64 -w 0 MyProfile.mobileprovision` on Linux. Treat the certificate, password, and profiles as private credentials.

## Adding your own videos

- Easiest: open the iPhone app, tap **Choose Videos**, pick MP4/MOV/M4V files.
  They appear on the watch after transfer (a few seconds per MB over
  Bluetooth).
- Or add URLs programmatically in `Extension/VideoLibrary.swift`
  (`remotePresets`) — progressive MP4 over HTTPS works best.

## Notes / limits

- The player uses `WKInterfaceMovie`, which supports local files and
  remote progressive MP4/MOV. HLS (.m3u8) is not guaranteed to work.
- Series 3 has ~8 GB storage shared with watchOS and a slow CPU — keep
  transferred clips small (a few minutes of 480p H.264 is comfortable).
- Streaming requires the watch to be on Wi-Fi (or near its iPhone).
- Battery drain is high during playback; expect roughly an hour of video
  from a full charge on Series 3.

## Layout

```
WatchPlayer/
├── iOS/                  companion app (send videos)
├── WatchApp/             watch app shell + Interface.storyboard
├── Extension/            all watch logic (list, player, library, WCSession)
└── WatchPlayer.xcodeproj
```

## Troubleshooting

- **Storyboard errors about the `<movie>` element**: open
  `WatchApp/Interface.storyboard`, delete the movie item in the
  "moviePlayer" scene, drag a new *Movie* object from the Object library
  onto it, and reconnect the `moviePlayer` outlet.
- **"No profiles" signing error**: set your team on all three targets.
- **Video won't stream**: confirm the URL is direct HTTPS MP4; try the
  bundled sample first.
