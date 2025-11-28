# BOAZ 使用指南

BOAZ 是一个旨在生成规避性 Shellcode 加载器的迷你规避框架。它可以自动将可执行文件转换为 Shellcode，对其进行编码，并将其注入到各种基于 C 语言的加载器模板中。它还支持高级功能，如反模拟（Anti-Emulation）、API 解钩（API Unhooking）、系统调用（直接/间接）和混淆。

## 安装

请确保已安装必要的依赖项。该项目包含一个 `requirements.sh` 脚本，用于在 Kali Linux 上设置环境。

```bash
chmod +x requirements.sh
./requirements.sh
```

Python 依赖项：
```bash
pip3 install -r requirements.txt
```

## 基本用法

主要的入口点是 `Boaz.py`。

```bash
python3 Boaz.py [选项]
```

### 常用参数

| 参数 | 描述 |
|---|---|
| `-f`, `--input-file` | 输入二进制文件的路径（`.exe` 或 `.bin`）。 |
| `-o`, `--output-file` | 指定输出文件的路径和名称。 |
| `-t`, `--shellcode-type` | Shellcode 生成工具 (`donut`, `pe2sh`, `rc4`, `amber`, `shoggoth`, `augment`)。默认值：`donut`。 |
| `-l`, `--loader` | 加载器技术编号（参见下方的加载器列表）。默认值：`1`。 |
| `-e`, `--encoding` | Shellcode 编码方式 (`uuid`, `xor`, `mac`, `ipv4`, `base45`, `base64`, `base58`, `aes`, `chacha` 等)。 |
| `-c`, `--compiler` | 使用的编译器 (`mingw`, `pluto`, `akira`)。默认值：`mingw`。 |
| `-a`, `--anti-emulation` | 启用反模拟检查。 |
| `-u`, `--api-unhooking` | 启用 API 解钩。 |
| `-sleep` | 启用随机睡眠混淆。 |
| `-dream` | 启用带加密堆栈的睡眠 (SweetSleep)。 |

### 加载器列表（部分）

*   **1**: 代理系统调用 (Proxy syscall) -> 自定义调用栈 + 带有无线程执行的间接系统调用。
*   **15**: Syswhispers2 经典原生 API 调用。
*   **16**: 经典用户层 API 调用。
*   **29**: 经典间接系统调用。
*   **30**: 经典直接系统调用。
*   (还有更多，请使用 `python3 Boaz.py -h` 查看完整列表)

## 示例

### 1. 使用 Donut 和 UUID 编码的基本生成
使用 Donut 将 `notepad.exe` 转换为 Shellcode，将其编码为 UUID，并使用加载器 16。

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload.exe -t donut -l 16 -e uuid
```

### 2. 使用高级编译 (Akira)
使用 Akira 编译器（基于 Clang 并带有混淆 Pass）以获得更好的规避效果。

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload_akira.exe -t donut -l 16 -e uuid -c akira
```

### 3. 添加规避功能
添加反模拟、API 解钩和加密睡眠。

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/evasive.exe -t donut -l 1 -e aes -a -u -dream 3000
```

### 4. 使用原始 Shellcode 输入
如果你已经有一个 `.bin` Shellcode 文件。

```bash
python3 Boaz.py -f ./shellcode.bin -o ./output/loader.exe -l 30 -e xor
```

### 5. 生成 DLL
将输出编译为 DLL 而不是 EXE。

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload.dll -t donut -l 16 -dll
```

## 高级功能

*   **SysWhispers**: 使用 `-w` 或 `-w 2` 集成 SysWhispers 进行直接系统调用。
*   **混淆 (Obfuscation)**: 使用 `-obf` 在编译前混淆生成的 C 源代码。
*   **水印 (Watermarking)**: 水印默认开启。使用 `-wm 0` 禁用。
*   **签名 (Signing)**: 使用 `-s` 对二进制文件进行签名。你可以提供一个网站来克隆其证书。

## 故障排除

*   **编译错误**: 确保 MinGW 和其他编译器已正确安装并设置了路径。
*   **运行时失败**: 某些加载器可能无法在所有 Windows 版本上运行，或者可能被 EDR 捕获。尝试不同的加载器和编码组合。
