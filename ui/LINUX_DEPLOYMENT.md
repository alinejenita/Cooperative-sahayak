# Linux Deployment Guide: Jetson Orin Nano 8 Developer Kit

This guide covers building, configuring, and deploying the **SarVani** Flutter application on a Linux device—specifically the **NVIDIA Jetson Orin Nano 8 Developer Kit** running JetPack Linux (Ubuntu 20.04 or 22.04 LTS, ARM64 / aarch64).

---

## 1. System Requirements & Dependencies

Before building or running the Flutter app on Jetson Orin Nano, install the required GTK, GStreamer, audio, and build system packages:

```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-alsa \
  gstreamer1.0-pulseaudio \
  libpulse-dev \
  libasound2-dev \
  libfontconfig1
```

---

## 2. Offline Typography & Font Support

The application includes bundled, offline Open Font License (OFL) TTF files in `assets/fonts/` to ensure full rendering capability across all 6 supported languages without relying on pre-installed Linux desktop font packages or active internet access:

- **English / Latin**: `Roboto` & `NotoSerif`
- **Hindi (`हिन्दी`)**: `NotoSansDevanagari`
- **Tamil (`தமிழ்`)**: `NotoSansTamil`
- **Telugu (`తెలుగు`)**: `NotoSansTelugu`
- **Malayalam (`മലയാളം`)**: `NotoSansMalayalam`
- **Kannada (`ಕನ್ನಡ`)**: `NotoSansKannada`

Font fallback chains are configured automatically in `lib/theme/kiosk_theme.dart` via Flutter's `fontFamilyFallback`.

---

## 3. Building the Application on Jetson Orin Nano

1. **Enable Linux desktop support in Flutter SDK**:
   ```bash
   flutter config --enable-linux-desktop
   ```

2. **Fetch Dart/Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Build the production release bundle for ARM64 Linux**:
   ```bash
   flutter build linux --release
   ```

The compiled standalone executable and bundle will be generated in:
`build/linux/arm64/release/bundle/`

---

## 4. Running in Fullscreen Kiosk Mode

To run the binary directly on your touchscreen connected to the Jetson Orin Nano:

```bash
./build/linux/arm64/release/bundle/sarvani
```

To auto-start the application on boot as a systemd service in kiosk mode:

1. Create a service unit file at `/etc/systemd/system/pacs-kiosk.service`:
   ```ini
   [Unit]
   Description=SarVani PACS Kiosk Service
   After=graphical.target

   [Service]
   Environment=DISPLAY=:0
   Environment=XAUTHORITY=/home/jetson/.Xauthority
   ExecStart=/path/to/sarvani/build/linux/arm64/release/bundle/sarvani
   Restart=always
   User=jetson

   [Install]
   WantedBy=graphical.target
   ```

2. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable pacs-kiosk.service
   sudo systemctl start pacs-kiosk.service
   ```
