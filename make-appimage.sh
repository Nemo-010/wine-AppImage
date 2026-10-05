#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/bcf6aa9582f676e1c93d0022319e6055cd1f2de2/Papirus/64x64/apps/wine.svg
export DESKTOP=/usr/share/applications/wine.desktop
export APPNAME=wine
export DEPLOY_SDL=1
export DEPLOY_PIPEWIRE=1
export DEPLOY_GSTREAMER=1
export DEPLOY_VULKAN=1
export DEPLOY_OPENGL=1

# Deploy dependencies
mkdir -p /tmp/wine
WINEPREFIX=/tmp/wine quick-sharun \
	/usr/lib/wine/x86_64-unix/wine \
	/usr/bin/wine*             \
	/usr/lib/wine              \
	/usr/bin/msidb             \
	/usr/bin/msiexec           \
	/usr/bin/notepad           \
	/usr/bin/regedit           \
	/usr/bin/regsvr32          \
	/usr/bin/widl              \
	/usr/bin/wmc               \
	/usr/bin/wrc               \
	/usr/bin/function_grep.pl  \
	/usr/bin/cabextract        \
	/usr/lib/libfreetype.so*   \
	/usr/lib/libharfbuzz*      \
	/usr/lib/libgraphite*      \
	/usr/lib/libavcodec.so*	   \
	/usr/lib/libavdevice.so*   \
	/usr/lib/libavfilter.so*   \
	/usr/lib/libavformat.so*   \
	/usr/lib/libavutil.so*     \
	/usr/lib/libswresample.so* \
	/usr/lib/libswscale.so*    \
	/usr/bin/wget              \
	/usr/bin/zenity            \
	/usr/bin/unzip             \
	/usr/lib/7zip/7z           \
	/usr/lib/7zip/7z.so

# Install latest winetricks
wget --retry-connrefused --tries=30 https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O ./AppDir/bin/winetricks
chmod +x ./AppDir/bin/winetricks

# wine's preloader maps the wineloader and its PT_INTERP itself. Point that at
# the bundled loader through $APPDIR, which the preloader patch expands, and
# give the wineloader an rpath for the bundled libs and anylinux since the
# preloader runs outside sharun's --library-path/--preload.
rm -f ./AppDir/lib/wine/x86_64-unix/wine
cp /usr/lib/wine/x86_64-unix/wine ./AppDir/lib/wine/x86_64-unix/wine
patchelf --set-interpreter '$APPDIR/lib/ld-linux-x86-64.so.2' ./AppDir/lib/wine/x86_64-unix/wine
patchelf --set-rpath '$ORIGIN:$ORIGIN/../..:$ORIGIN/../../sharun-preload' ./AppDir/lib/wine/x86_64-unix/wine
patchelf --add-needed anylinux.so ./AppDir/lib/wine/x86_64-unix/wine

chmod +x ./AppDir/bin/*.hook

# strip windows libs, inspired by alpine linux: 
# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/community/wine/APKBUILD
if [ "$ARCH" = 'x86_64' ]; then
	x86_64-w64-mingw32-strip -R .comment --strip-unneeded ./AppDir/lib/wine/x86_64-windows/*.dll
	i686-w64-mingw32-strip   -R .comment --strip-unneeded ./AppDir/lib/wine/i386-windows/*.dll
fi

# Turn AppDir into AppImage
quick-sharun --make-appimage
