# BOAZ Usage Guide

BOAZ is a mini-evasion framework designed to generate evasive shellcode loaders. It automates the process of converting executables into shellcode, encoding them, and injecting them into various C-based loader templates. It also supports advanced features like anti-emulation, API unhooking, syscalls (direct/indirect), and obfuscation.

## Installation

Ensure you have the necessary dependencies installed. The project includes a `requirements.sh` script for setting up the environment on Kali Linux.

```bash
chmod +x requirements.sh
./requirements.sh
```

Python dependencies:
```bash
pip3 install -r requirements.txt
```

## Basic Usage

The main entry point is `Boaz.py`.

```bash
python3 Boaz.py [options]
```

### Common Arguments

| Argument | Description |
|---|---|
| `-f`, `--input-file` | Path to the input binary (`.exe` or `.bin`). |
| `-o`, `--output-file` | Specify the output file path and name. |
| `-t`, `--shellcode-type` | Shellcode generation tool (`donut`, `pe2sh`, `rc4`, `amber`, `shoggoth`, `augment`). Default: `donut`. |
| `-l`, `--loader` | Loader technique number (see Loader List below). Default: `1`. |
| `-e`, `--encoding` | Shellcode encoding (`uuid`, `xor`, `mac`, `ipv4`, `base45`, `base64`, `base58`, `aes`, `chacha`, etc.). |
| `-c`, `--compiler` | Compiler to use (`mingw`, `pluto`, `akira`). Default: `mingw`. |
| `-a`, `--anti-emulation` | Enable anti-emulation checks. |
| `-u`, `--api-unhooking` | Enable API unhooking. |
| `-sleep` | Enable random sleep obfuscation. |
| `-dream` | Enable sleep with encrypted stacks (SweetSleep). |

### Loader List (Partial)

*   **1**: Proxy syscall -> Custom call Stack + indirect syscall with threadless execution.
*   **15**: Syswhispers2 classic native API calls.
*   **16**: Classic userland API calls.
*   **29**: Classic indirect syscall.
*   **30**: Classic direct syscall.
*   (And many more, check `python3 Boaz.py -h` for the full list)

## Examples

### 1. Basic Generation with Donut and UUID Encoding
Convert `notepad.exe` to shellcode using Donut, encode it as UUIDs, and use Loader 16.

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload.exe -t donut -l 16 -e uuid
```

### 2. Using Advanced Compilation (Akira)
Use the Akira compiler (Clang-based with obfuscation passes) for better evasion.

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload_akira.exe -t donut -l 16 -e uuid -c akira
```

### 3. Adding Evasion Features
Add anti-emulation, API unhooking, and encrypted sleep.

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/evasive.exe -t donut -l 1 -e aes -a -u -dream 3000
```

### 4. Using Raw Shellcode Input
If you already have a `.bin` shellcode file.

```bash
python3 Boaz.py -f ./shellcode.bin -o ./output/loader.exe -l 30 -e xor
```

### 5. Generating a DLL
Compile the output as a DLL instead of an EXE.

```bash
python3 Boaz.py -f ./notepad.exe -o ./output/payload.dll -t donut -l 16 -dll
```

## Advanced Features

*   **SysWhispers**: Use `-w` or `-w 2` to integrate SysWhispers for direct syscalls.
*   **Obfuscation**: Use `-obf` to obfuscate the generated C source code before compilation.
*   **Watermarking**: Watermarking is enabled by default. Use `-wm 0` to disable.
*   **Signing**: Use `-s` to sign the binary. You can provide a website to clone the certificate from.

## Troubleshooting

*   **Compilation Errors**: Ensure MinGW and other compilers are correctly installed and paths are set.
*   **Runtime Failures**: Some loaders may not work on all Windows versions or may be caught by EDRs. Try different combinations of loaders and encodings.
