# Android FFmpeg Builder
A robust shell script to build FFmpeg libraries for Android. This script automatically builds FFmpeg shared libraries (.so files) for multiple Android architectures.

## Current Features
- Builds FFmpeg version 7.1 for Android
- Supports multiple architectures (armeabi-v7a, arm64-v8a, x86_64)
- Minimal configuration focusing on core video/audio functionality
- Optimized for size and performance
- Automated build process
- Pre-built binaries available in releases

## Prerequisites

### Required Tools
- Android NDK
- Build essentials (gcc, make)
- YASM/NASM assembler
- wget
- pkg-config

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install build-essential gcc make yasm nasm pkg-config wget
```

On macOS:
```bash
brew install automake yasm nasm pkg-config wget
```

Android NDK Setup
1. Download Android NDK from [Android's NDK page](https://developer.android.com/ndk/downloads)
2. Extract it to a location (default: `/opt/android-ndk`)
3. Update the `ANDROID_NDK_HOME` variable in the script if your NDK is installed elsewhere

## Usage
1. Clone this repository:
```bash
git clone https://github.com/husen-hn/android-ffmpeg-builder.git
cd android-ffmpeg-builder
```

2. Make the script executable:
```bash
chmod +x build_ffmpeg.sh
```

3. Run the script:
```bash
./build_ffmpeg.sh
```

The built libraries will be in `android/project_libs/`:
```
android/project_libs/
├── arm64-v8a/
│   ├── libavcodec.so
│   ├── libavformat.so
│   ├── libavutil.so
│   ├── libswresample.so
│   └── libswscale.so
├── armeabi-v7a/
└── x86_64/
```

## Configurations
The script builds FFmpeg with these configurations:
- Shared libraries enabled
- Static libraries disabled
- Documentation disabled
- Programs (ffmpeg, ffplay, ffprobe) disabled
- Hardware acceleration disabled
- Minimal codec support (h264, aac, mp3)
- File protocol support
- MP4 and MKV container support

## License
This project is licensed under the GNU Lesser General Public Version 3 License - see the [LICENSE](./LICENSE) file for details.