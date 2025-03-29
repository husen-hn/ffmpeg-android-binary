#!/bin/bash

# Set NDK path
ANDROID_NDK_HOME="/opt/android-ndk"

# Update FFmpeg version
FFMPEG_VERSION="7.1"

# Use current directory
WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"
echo "FFmpeg version: $FFMPEG_VERSION"

# Clean old build if exists
if [ -d "ffmpeg-${FFMPEG_VERSION}" ]; then
    echo "Cleaning old FFmpeg build directory..."
    rm -rf "ffmpeg-${FFMPEG_VERSION}"
fi

# Extract FFmpeg
echo "Extracting FFmpeg..."
if [ -f "ffmpeg-${FFMPEG_VERSION}.tar.bz2" ]; then
    tar xjf "ffmpeg-${FFMPEG_VERSION}.tar.bz2" || {
        echo "Failed to extract FFmpeg"
        exit 1
    }
else
    echo "Error: ffmpeg-${FFMPEG_VERSION}.tar.bz2 not found!"
    echo "Please download FFmpeg ${FFMPEG_VERSION} from:"
    echo "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    echo ""
    echo "You can download it using:"
    echo "wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    exit 1
fi

cd "ffmpeg-${FFMPEG_VERSION}"

# Verify NDK path
echo "Checking NDK path: $ANDROID_NDK_HOME"
if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: NDK path not found: $ANDROID_NDK_HOME"
    exit 1
fi

TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

if [ ! -d "$TOOLCHAIN" ]; then
    echo "Error: Toolchain not found: $TOOLCHAIN"
    exit 1
fi

function build_ffmpeg
{
    ABI=$1
    ANDROID_API=21

    echo "Building FFmpeg for $ABI"
    
    case ${ABI} in
        armeabi-v7a)
            ARCH=arm
            CPU=armv7-a
            CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
            CC=$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API}-clang++
            ;;
        arm64-v8a)
            ARCH=aarch64
            CPU=armv8-a
            CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
            CC=$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API}-clang++
            ;;
        x86_64)
            ARCH=x86_64
            CPU=x86-64
            CROSS_PREFIX=$TOOLCHAIN/bin/x86_64-linux-android-
            CC=$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API}-clang++
            ;;
    esac

    PREFIX=$WORK_DIR/android/$ABI
    mkdir -p $PREFIX
    
    echo "Configuring FFmpeg for $ABI"
    ./configure \
        --prefix=$PREFIX \
        --enable-shared \
        --enable-pic \
        --enable-jni \
        --enable-mediacodec \
        --enable-neon \
        --enable-hwaccels \
        --enable-gpl \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --enable-nonfree \
        --enable-protocols \
        --enable-cross-compile \
        --enable-encoders \
        --enable-decoders \
        --enable-demuxers \
        --enable-muxers \
        --enable-filters \
        --enable-bsfs \
        --enable-indevs \
        --enable-outdevs \
        --enable-network \
        --enable-ffmpeg \
        --enable-ffprobe \
        --disable-ffplay \
        --disable-static \
        --disable-debug \
        --disable-doc \
        --cross-prefix=$CROSS_PREFIX \
        --target-os=android \
        --arch=$ARCH \
        --cpu=$CPU \
        --cc=$CC \
        --cxx=$CXX \
        --sysroot=$TOOLCHAIN/sysroot \
        --extra-cflags="-O3 -fPIC" \
        --extra-ldflags="-L$PREFIX/lib" || {
            echo "Configure failed for $ABI"
            return 1
        }

    echo "Building FFmpeg for $ABI"
    make clean
    make -j$(nproc) || {
        echo "Make failed for $ABI"
        return 1
    }
    make install || {
        echo "Make install failed for $ABI"
        return 1
    }
    echo "Successfully built FFmpeg for $ABI"
}

# Build only for specified architectures
for ABI in armeabi-v7a arm64-v8a x86_64
do
    echo "Starting build for $ABI..."
    build_ffmpeg $ABI
    if [ $? -ne 0 ]; then
        echo "Build failed for $ABI"
        exit 1
    fi
done

# Copy binaries and libraries
PROJECT_OUTPUT="$WORK_DIR/android/project_output"
mkdir -p $PROJECT_OUTPUT

# Copy for each architecture
for ABI in armeabi-v7a arm64-v8a x86_64
do
    ABI_DIR="$PROJECT_OUTPUT/$ABI"
    mkdir -p $ABI_DIR/{lib,bin}
    
    # Copy shared libraries
    echo "Copying shared libraries for $ABI..."
    cp $WORK_DIR/android/$ABI/lib/*.so $ABI_DIR/lib/ || {
        echo "Failed to copy .so files for $ABI"
        exit 1
    }
    
    # Copy ffmpeg binary
    echo "Copying ffmpeg binary for $ABI..."
    if [ -f "$WORK_DIR/android/$ABI/bin/ffmpeg" ]; then
        cp $WORK_DIR/android/$ABI/bin/ffmpeg $ABI_DIR/bin/ && chmod +x $ABI_DIR/bin/ffmpeg
    else
        echo "Warning: ffmpeg binary not found for $ABI"
    fi
    
    # Copy ffprobe binary
    echo "Copying ffprobe binary for $ABI..."
    if [ -f "$WORK_DIR/android/$ABI/bin/ffprobe" ]; then
        cp $WORK_DIR/android/$ABI/bin/ffprobe $ABI_DIR/bin/ && chmod +x $ABI_DIR/bin/ffprobe
    else
        echo "Warning: ffprobe binary not found for $ABI"
    fi
done

echo "Build completed! Output is in $PROJECT_OUTPUT"
echo "Built architectures: armeabi-v7a arm64-v8a x86_64"
echo "FFmpeg version: $FFMPEG_VERSION"

# Create version info file
cat > "$PROJECT_OUTPUT/build_info.txt" << EOF
FFmpeg Android Build Information
Github: https://github.com/husen-hn/ffmpeg-android-binary
==============================
Version: $FFMPEG_VERSION

Architectures:
- armeabi-v7a
- arm64-v8a
- x86_64

Features:
- All encoders and decoders
- All muxers and demuxers
- All protocols
- Hardware acceleration
- Network support
- FFmpeg and FFprobe included
- MediaCodec support
- NEON optimization

Components:
1. Shared Libraries (.so files):
   - libavcodec
   - libavdevice
   - libavfilter
   - libavformat
   - libavutil
   - libpostproc
   - libswresample
   - libswscale

2. Executables:
   - ffmpeg
   - ffprobe
EOF

# Create directory structure info
echo -e "\nDirectory Structure:" >> "$PROJECT_OUTPUT/build_info.txt"
if command -v tree > /dev/null; then
    tree $PROJECT_OUTPUT >> "$PROJECT_OUTPUT/build_info.txt"
else
    find $PROJECT_OUTPUT -type f >> "$PROJECT_OUTPUT/build_info.txt"
fi

echo "Build information has been saved to $PROJECT_OUTPUT/build_info.txt"