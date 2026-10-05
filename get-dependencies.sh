#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --needed --noconfirm \
	alsa-lib               \
	cabextract             \
	desktop-file-utils     \
	fontconfig             \
	freetype2              \
	gettext                \
	glib2                  \
	gnutls                 \
	gst-libav              \
	gst-plugins-bad        \
	gst-plugins-base       \
	gst-plugins-base-libs  \
	gst-plugins-good       \
	gst-plugins-ugly       \
	gstreamer              \
	harfbuzz               \
	libcups                \
	libgcc                 \
	libgphoto2             \
	libpcap                \
	libpulse               \
	libunwind              \
	libx11                 \
	libxcomposite          \
	libxcursor             \
	libxext                \
	libxinerama            \
	libxkbcommon           \
	libxi                  \
	libxrandr              \
	libxxf86vm             \
	ntsync-autoload        \
	opencl-headers         \
	opencl-icd-loader      \
	pcsclite               \
	perl                   \
	pipewire-audio         \
	pipewire-jack          \
	samba                  \
	sane                   \
	sdl2                   \
	systemd-libs           \
	unixodbc               \
	v4l-utils              \
	vulkan-headers         \
	vulkan-icd-loader      \
	wayland                \
	7zip                   \
	unzip

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

if [ "$ARCH" = 'x86_64' ]; then
	sudo pacman -S --noconfirm mingw-w64-gcc
fi

# Comment this out if you need an AUR package
make-aur-package zenity-rs-bin

# If the application needs to be manually built that has to be done down here
echo "Building wine..."
echo "---------------------------------------------------------------"
git clone https://gitlab.winehq.org/wine/wine.git ./wine
cd ./wine

# Build the latest stable release only, development releases are not used
git fetch --tags origin
TAG=$(git tag --sort=-v:refname | grep -E '^wine-[0-9]+\.0(\.[0-9]+)?$' | head -1)
git checkout "$TAG"
echo "${TAG#wine-}" > ~/version
git apply ../patches/wine-dlopen-ntdll.patch

mkdir ./build
cd ./build
# No debug info, it is not needed since the Windows libs get stripped later
export CFLAGS="-O2 -pipe"
export CXXFLAGS="-O2 -pipe"
export CROSSCFLAGS="-O2 -pipe"
export CROSSCXXFLAGS="-O2 -pipe"
export CROSSLDFLAGS="-Wl,-O1"
../configure                  \
	--prefix=/usr             \
	--libdir=/usr/lib         \
	--disable-tests           \
	--enable-archs=x86_64,i386 \
	--enable-build-id
make -j"$(nproc)"
sudo make prefix=/usr libdir=/usr/lib dlldir=/usr/lib/wine install
