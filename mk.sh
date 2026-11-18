#!/bin/sh
# 给小米 17 Pro（pandora）出一版：外壳与 device.toml 用参考镜像里的，
# 只换 system/bin/recovery 成本版。用法：./mk_pandora.sh <版本> <名字>
set -e
REL="$1"
NAME="$2"
REL=${REL#v}
case "$REL" in
    *.*0[0-9]*|*.*0[0-9]) echo "版本号 $REL 里有前导零，semver 不接受；请用 0.0.NN" >&2; exit 1 ;;
esac
export TZ=Asia/Shanghai
W=/workspace/项目/第三方REC-pudding/工作
SRC=/workspace/项目/第三方REC-pudding/构建/skyward-0.3.1
T=/workspace/tools/rustup/toolchains/stable-aarch64-unknown-linux-gnu/bin

cd "$SRC"
export CARGO_HOME=/workspace/tools/cargo
export SKYWARD_RELEASE="$REL"
export CC_aarch64_linux_android=/workspace/tools/ndk/clang-android.sh
export AR_aarch64_linux_android=ar
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=/workspace/tools/ndk/clang-android.sh
export RUSTC="$T/rustc"
export RUSTDOC="$T/rustdoc"
export PATH="$T:$PATH"
touch crates/skyward-info/src/lib.rs
if cargo build --release -p skyward --target aarch64-linux-android --offline > build.log 2>&1; then
    tail -3 build.log
else
    tail -40 build.log
    echo "构建失败，未打包" >&2
    exit 1
fi

cd "$W"
# 外壳树：从参考镜像解出来的一份（rd_pandora），device.toml 原样保留。
cp "$SRC/target/aarch64-linux-android/release/skyward" rd_pandora/system/bin/recovery
chmod 755 rd_pandora/system/bin/recovery
(cd rd_pandora && find . -print0 | cpio --null -o -H newc --owner=0:0 --reproducible 2>../cpio_pan.err > ../d_pan.cpio)
lz4 -l -12 -f d_pan.cpio rd_pan.lz4 >/dev/null 2>&1
python3 avbwrap.py rd_pan.lz4 new_pan_avb.img
OUT="/storage/emulated/0/MT2/mcp/产物/测试版/$NAME"
cp new_pan_avb.img "$OUT"
touch "$OUT"
ls -l "$OUT"
sha256sum "$OUT"
md5sum "$OUT"
python3 - <<'PY'
import struct
d=open('new_pan_avb.img','rb').read()
ks,rs,_,_=struct.unpack_from('<IIII',d,8)
L=((4096+rs)+4095)//4096*4096
print('ramdisk',rs,'L',L,"AVB0",d[L:L+4],"foot",d[-64:-60])
PY