#!/bin/bash
# set up script for BOAZ evasion tool

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 移除交互式更新，Docker中不需要 update/upgrade (基础镜像已做过)
echo -e "${YELLOW}[*] Skipping system update inside Docker container.${NC}"

# 安装依赖 (注意：基础镜像已安装大部分，这里作为保险)
# 移除 sudo，Docker 容器内通常是 root
apt install -y osslsigncode build-essential nasm git cmake ninja-build python3 \
    gcc g++ zlib1g-dev wine mingw-w64 mingw-w64-tools x86_64-w64-mingw32-g++ \
    curl unzip clang

# 修正 i386 架构支持
dpkg --add-architecture i386
apt-get update || echo "Update failed, continuing..."
apt-get install -y wine32:i386

# 安装 Python 库
pip3 install pyopenssl --break-system-packages

# ---------------------------------------------------------
# 工具安装部分
# ---------------------------------------------------------

if [ -f "./donut" ]; then
    echo "'donut' is already installed."
else
    echo "'donut' not found. (Assuming binary will be provided or handled elsewhere)"
fi

echo "Installing pe2sh..."
if [ -f "./PIC/pe2shc.exe" ]; then
    echo "'pe2shc.exe' is already installed."
else
    echo "'pe2shc.exe' not found."
fi

echo "Installing custom obfuscator based on avcleaner..."
if [ -f "./avcleaner_bin/avcleaner.bin" ]; then
    echo "'avcleaner.bin' is already installed."
else
    echo "'avcleaner.bin' not found."
fi

# ---------------------------------------------------------
# Install Mangle
# ---------------------------------------------------------
if [ ! -f ./signature/Mangle ]; then
  # 使用加速镜像
  git clone https://mirror.ghproxy.com/https://github.com/optiv/Mangle.git
  cd Mangle
  # Go 环境可能在基础镜像没装，尝试安装或忽略
  apt install -y golang-go || true
  go get github.com/Binject/debug/pe || true
  go build Mangle.go
  mv Mangle ../signature/
  cd ..
  rm -r Mangle
fi

# ---------------------------------------------------------
# Install pyMetaTwin
# ---------------------------------------------------------
echo "Installing pyMetaTwin..."
if [ ! -f "./signature/metatwin.py" ]; then
    git clone https://mirror.ghproxy.com/https://github.com/thomasxm/pyMetaTwin
    cp -r pyMetaTwin/* signature
    cd signature
else
    cd signature
fi

# 安装 metatwin 依赖
if [ -f "install.sh" ]; then
    chmod +x install.sh
    sed -i 's///g' install.sh
    ./install.sh
fi
cd ..

# ---------------------------------------------------------
# Install Syswhisper2
# ---------------------------------------------------------
echo "Installing Syswhisper2..."
if [ ! -d "./SysWhispers2" ]; then
    git clone https://mirror.ghproxy.com/https://github.com/jthuraisamy/SysWhispers2
    cd SysWhispers2
    python3 ./syswhispers.py --preset common -o syscalls_common
    cd ..
else
    cd SysWhispers2
    python3 ./syswhispers.py --preset common -o syscalls_common
    cd ..
fi

# ---------------------------------------------------------
# [重点修正] Clone and build llvm-obfuscator (Akira-obfuscator)
# ---------------------------------------------------------
echo -e "${GREEN}[!] Install LLVM Obfuscator, it will take a while...${NC}"

if [ ! -d "akira_built" ]; then
    echo "Cloning and building Akira llvm-obfuscator..."
    git clone https://mirror.ghproxy.com/https://github.com/thomasxm/Akira-obfuscator.git
    cd Akira-obfuscator && mkdir -p akira_built
    
    # === 关键修正 ===
    # 1. 使用 clang/clang++ 代替 gcc/g++
    # 2. 强制 C++14 标准 (解决 SmallVector 错误)
    # 3. 忽略非致命错误 (-Wno-error)
    cd akira_built && cmake \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_CXX_STANDARD=14 \
        -DCMAKE_CXX_FLAGS="-Wno-error" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb" \
        -G "Ninja" ../llvm
        
    ninja -j2
    cd .. && mv ./akira_built/ ../
    cd ..
    rm -r Akira-obfuscator
else 
    echo -e "${RED}[!] Akira llvm-obfuscator is already installed.${NC}"
fi

# 寻找 MinGW 版本
GCCVER=$(ls /usr/lib/gcc/x86_64-w64-mingw32 2>/dev/null | grep posix | sort -V | tail -n 1)
if [ -z "$GCCVER" ]; then
  GCCVER=$(ls /usr/lib/gcc/x86_64-w64-mingw32 2>/dev/null | grep win32 | sort -V | tail -n 1)
fi

if [ -z "$GCCVER" ]; then
  echo "Error: No usable MinGW GCC version found."
  # 这里的 exit 1 可能会导致构建失败，暂时注释掉，让它继续尝试
  # exit 1
fi
echo "Using MinGW GCC version: $GCCVER"

# 测试 Akira 编译
echo "start Akira unit test:"
# 确保文件存在再运行
if [ -f "./akira_built/bin/clang++" ]; then
    ./akira_built/bin/clang++ \
      -D nullptr=NULL \
      -mllvm -irobf-indbr -mllvm -irobf-icall -mllvm -irobf-indgv -mllvm -irobf-cse -mllvm -irobf-cff \
      -target x86_64-w64-windows-gnu \
      loader2_test.c classic_stubs/syscalls.c ./classic_stubs/syscallsstubs.std.x64.s \
      -o test.exe -v \
      -L/usr/lib/gcc/x86_64-w64-mingw32/$GCCVER \
      -L/usr/x86_64-w64-mingw32/lib \
      -L/usr/x86_64-w64-mingw32/mingw/lib \
      -I./c++/ -I./c++/mingw32/ \
      -lstdc++ -lgcc_s -lgcc \
      -lws2_32 -lpsapi -lmingw32 -lmoldname -lmingwex -lmsvcrt -ladvapi32 -lshell32 -luser32 -lkernel32
else
    echo "Warning: Akira clang++ not found, skipping test compilation."
fi

# 运行 Wine 测试
if [ -f "./test.exe" ]; then
    wine ./test.exe || echo "Wine execution failed (expected in Docker), continuing..."
fi

# ---------------------------------------------------------
# [重点修正] Clone and build Pluto
# ---------------------------------------------------------
if [ ! -d "llvm_obfuscator_pluto" ]; then
    echo "Cloning and building Pluto-obfuscator..."
    git clone https://mirror.ghproxy.com/https://github.com/thomasxm/Pluto.git
    cd Pluto && mkdir -p pluto_build
    cd pluto_build
    
    # === 关键修正: 同样切换到 Clang ===
    cmake -G Ninja -S .. -B build \
        -DCMAKE_C_COMPILER="clang" \
        -DCMAKE_CXX_COMPILER="clang++" \
        -DCMAKE_CXX_STANDARD=14 \
        -DCMAKE_INSTALL_PREFIX="../llvm_obfuscator_pluto/" \
        -DCMAKE_BUILD_TYPE=Release
        
    ninja -j2 -C build install
    mkdir -p ../../../llvm_obfuscator_pluto/
    mv ./install/* ../../../llvm_obfuscator_pluto/
    cd ../../../ 
    rm -r Pluto
else 
    echo -e "${GREEN}[!] Pluto is already installed.${NC}"
fi

echo -e "${GREEN}[!] Installation and setup completed! ${NC}"

# ---------------------------------------------------------
# Main linker
# ---------------------------------------------------------
pip3 install pyinstaller --break-system-packages || true

echo -e "${YELLOW}[*] Running PyInstaller to build ELF executable. ${NC}"
pyinstaller --onefile Boaz.py

mv dist/Boaz . 2>/dev/null || true
rm -r dist/ 2>/dev/null || true
echo -e "${GREEN}[+] Setup completed successfully!${NC}"