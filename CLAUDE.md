# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BOAZ (Bypass, Obfuscate, Adapt, Zero-trace) is an evasion research tool for educational purposes that implements multi-layered evasion techniques to bypass antivirus and EDR detection. The tool supports x64 binary (PE) or raw payload (.bin) as input and has been tested on Windows environments with various AV and EDR solutions.

**Note**: This is a security research tool designed for educational purposes and authorized security testing only.

## Architecture

BOAZ follows a modular design centered around several key components:

### Core Components

- **Boaz.py**: Main Python script that orchestrates the entire evasion process
- **Loaders** (`loaders/`): 70+ process injection and code execution techniques (loader numbers 1-79)
- **PIC Generators** (`PIC/`): Position-independent shellcode generators (donut, pe2sh, rc4, amber, shoggoth)
- **Encoders** (`encoders/`): Various payload encoding schemes (UUID, XOR, MAC, IPv4, base64/45/58, AES, DES, ChaCha, RC4)
- **Converters** (`converter/`): Header files for decoding encoded payloads at runtime
- **Evaders** (`evader/`): Anti-emulation, API unhooking, ETW patching, and other evasion techniques
- **Signature** (`signature/`): Code signing and metadata manipulation tools

### Build System

The project uses multiple compilation approaches:
- **MinGW**: Standard cross-compilation for Windows
- **LLVM Obfuscators**: Pluto and Akira for advanced binary obfuscation
- **Wine**: For running Windows-specific tools in Linux environment

## Installation and Setup

### Prerequisites
- Linux environment (Kali/Debian preferred)
- Wine configured for Windows binary execution
- CMake, Git, GCC, G++, MinGW, LLVM, nasm

### Quick Setup
```bash
git clone <repository-url>
cd boaz_code
bash requirements.sh
```

### Docker Setup (Recommended)
```bash
sudo docker pull mmttxx20/boaz-builder:latest
sudo docker run --rm -it --entrypoint /bin/bash \
  -v "$HOME:/host_home" -v "$PWD:/boaz/output" \
  --shm-size=1024M --name boaz_built \
  mmttxx20/boaz-builder
```

## Common Development Commands

### Basic Usage Examples
```bash
# Basic packing with donut shellcode and loader 1
python3 Boaz.py -f ~/testing_payloads/notepad_64.exe -o ./output.exe -t donut -l 1

# With LLVM obfuscation and UUID encoding
python3 Boaz.py -f input.exe -o output.exe -t donut -l 16 -e uuid -c akira

# Advanced example with multiple evasion techniques
python3 Boaz.py -f input.exe -o output.exe -t donut -obf -l 1 -c pluto -e aes -a -u -etw

# Compile as DLL
python3 Boaz.py -f input.exe -o output.dll -t donut -l 1 -dll

# Using Docker
python3 Boaz.py -f /host_home/input.exe -o ./output.exe -t donut -l 16 -e uuid -c akira
```

### Build Commands
```bash
# Build ELF executable (after requirements.sh)
./Boaz [options]

# Or use Python directly
python3 Boaz.py [options]

# Check for hooks detection tool
python3 Boaz.py -dh
```

### Testing
No automated test suite is provided. Testing is done by:
1. Running the tool against sample payloads
2. Verifying output binaries execute correctly
3. Testing against target AV/EDR solutions in controlled environments

## Key File Locations

- **Main Script**: `Boaz.py`
- **Loader Templates**: `loaders/loader_template_[N].c` (N = loader number)
- **PIC Tools**: `PIC/` directory contains donut, pe2sh, amber, etc.
- **Encoding Scripts**: `encoders/bin2*.py` for various encoding schemes
- **Evasion Headers**: `evader/*.h` and `evader/*.c`
- **Output Directory**: `./output/` (auto-created if not specified)

## Loader System

The tool uses a numbered loader system (1-79) where each number represents a different process injection or execution technique:

- **1**: Proxy syscall with custom call stack + indirect syscall (threadless)
- **15**: SysWhispers2 classic native API calls
- **16**: Classic userland API calls (VirtualAllocEx → WriteProcessMemory → CreateRemoteThread)
- **22**: Advanced indirect custom call stack syscall with VEH→VCH logic
- **37**: Stealth loader with memory scan evasion
- **50**: Woodpecker process injection (classification evasion)
- **65**: Advanced VMT hooking with custom module loader
- **73-77**: VT pointer threadless process injection variants

Use `python3 Boaz.py -h` to see the complete list with descriptions.

## Compilation Options

### Compilers
- **mingw**: Standard MinGW cross-compilation (default)
- **pluto**: Pluto LLVM obfuscator with various passes (bcf, fla, mba, sub, etc.)
- **akira**: Akira LLVM obfuscator with indirect calls/globals and string encryption

### LLVM Passes (for Pluto/Akira)
```bash
# Pluto example
-mllvm "bcf,fla,mba,sub,idc,gle"

# Akira example
-mllvm "irobf-indbr,irobf-icall,irobf-indgv,irobf-cse,irobf-cff"
```

### Output Formats
- **EXE**: Standard executable (default)
- **DLL**: Dynamic-link library (-dll flag)
- **CPL**: Control Panel applet (-cpl flag)

## Evasion Techniques

### Pre-Execution (Signature Evasion)
- Function/string obfuscation
- SGN (Shikata Ga Nai) encoding
- Payload encoding (UUID, XOR, MAC, IPv4, base64/45/58, AES/DES/ChaCha/RC4)
- LLVM IR-level obfuscation
- Entropy reduction
- Code signing and metadata copying

### During Execution (Heuristic/Behavioral Evasion)
- Anti-emulation checks
- API unhooking (direct ntdll rewrite, Peruns' Fart, Halo's gate)
- ETW patching
- Junk API calls
- Sleep obfuscation (Ekko-style)
- Memory guard techniques
- Process injection with various call stacks
- Threadless execution primitives

### Post-Execution
- Self-deletion
- Anti-forensic trace cleanup
- Registry timestamp modification

## Working with Loaders

When modifying or adding loaders:

1. **Template Structure**: Each loader follows a pattern with placeholders:
   - `####SHELLCODE####`: Shellcode insertion point
   - `####END####`: Post-execution function insertion point
   - Standard function signatures for DLL/CPL variants

2. **DLL/CPL Variants**: Templates exist for different output formats:
   - `loader[N].c`: Standard EXE
   - `loader[N].dll.c`: DLL with `ExecuteMagiccode` entry point
   - `loader[N].cpl.c`: CPL with `CPlApplet` entry point

3. **Assembly Dependencies**: Some loaders require NASM compilation:
   - Loaders 1, 29, 30, 34, 36, 39, 40, 41, 50, 66, 79 need assembly files
   - Check `compile_output()` in Boaz.py for specific assembly files

## Security Considerations

This tool is designed for:
- Educational purposes and security research
- Authorized penetration testing
- AV/EDR evaluation in controlled environments
- Understanding evasion techniques

**IMPORTANT**: Only use on systems you own or have explicit permission to test against.

## Troubleshooting

### Common Issues
- **LLVM Build Failures**: Use provided Docker image with pre-built obfuscators
- **Wine Issues**: Ensure proper 32/64-bit architecture support
- **Missing Tools**: Run `requirements.sh` to install dependencies
- **Permission Issues**: Some obfuscation steps require sudo (handled automatically)

### Debug Mode
The tool provides verbose output by default. Key debug information:
- Selected options and their arguments
- Shellcode generation details
- Compilation commands and paths
- Success/failure status at each step

## Development Notes

- **Modular Design**: Each technique is implemented as a separate module for easy customization
- **Template-Based**: Loaders use templates with placeholder replacement for shellcode insertion
- **Multi-Compiler Support**: Supports both traditional and LLVM-based obfuscation
- **Cross-Platform**: Built in Linux but targets Windows executables
- **Docker-Friendly**: Full Docker support for dependency management

When making changes:
1. Test with simple payloads first
2. Verify compilation with different compiler options
3. Check that DLL/CPL variants work correctly
4. Test evasion techniques in safe environments
5. Maintain backward compatibility with existing loader numbers


python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_37_hard.exe -t donut -l 37 -e aes
奇怪，-l放前面就能跑
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_advanced.exe -t donut -l 37 -e uuid -a -u -etw
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_advanced.exe -t donut -l 37 -e uuid -a