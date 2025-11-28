# BOAZ Architecture and Design

BOAZ is designed as a modular and extensible framework for generating evasive shellcode loaders. It follows a pipeline architecture where an input binary goes through several stages of transformation before becoming a final executable.

## System Overview

The system is composed of the following key components:

1.  **Orchestrator (`Boaz.py`)**: The central Python script that parses arguments, manages the pipeline, and invokes other components.
2.  **Shellcode Generators**: Tools that convert executables (PE files) into position-independent shellcode.
3.  **Encoders**: Modules that transform raw shellcode into various formats (e.g., UUID, IPv4, MAC) to evade signature-based detection.
4.  **Loaders**: C-based templates that define how the shellcode is injected and executed in memory.
5.  **Evaders**: C modules that implement evasion techniques (anti-emulation, unhooking, etc.).
6.  **Compilers**: Toolchains (MinGW, Clang/LLVM) used to compile the final C code into an executable.

## The Pipeline

### 1. Input Handling
The framework accepts either a raw shellcode file (`.bin`) or a Windows executable (`.exe`). If an executable is provided, it must be converted to shellcode.

### 2. Shellcode Generation
BOAZ integrates several external tools to generate shellcode:
*   **Donut**: Converts .NET Assemblies, PE files, etc., to shellcode.
*   **PE2SHC**: Converts PE to shellcode.
*   **Amber / Shoggoth**: Other shellcode generators with reflective loading capabilities.
*   **Augmented Loader**: A custom Python script for generating shellcode.

### 3. Encoding (Obfuscation)
To hide the shellcode within the loader's data section, BOAZ supports various encoding schemes. This transforms the malicious byte stream into innocuous-looking data types:
*   **UUID**: Shellcode is converted into a list of UUID strings.
*   **IPv4 / MAC**: Shellcode is masqueraded as IP or MAC addresses.
*   **Encryption**: AES, ChaCha20, RC4, etc.

### 4. Loader Construction
This is the core of the framework. BOAZ uses a template-based approach.
*   **Templates**: Located in `loaders/loader_template_*.c`. These contain placeholders like `####SHELLCODE####` or `####MAGICSPELL####`.
*   **Injection**: `Boaz.py` reads the selected template and injects the encoded shellcode and necessary headers.
*   **Feature Injection**: Additional features like Anti-Emulation, API Unhooking (`unhooking`), and SweetSleep (`sleep_encrypt`) are injected into the source code via string manipulation (RegEx).

### 5. Compilation
The modified C code is compiled using one of the supported compilers:
*   **MinGW**: Standard GCC cross-compiler for Windows.
*   **Pluto / Akira**: LLVM-based compilers (Clang) with custom obfuscation passes (e.g., Control Flow Flattening, Bogus Control Flow, Instruction Substitution). These provide binary-level obfuscation.

### 6. Post-Processing
*   **Stripping**: Removing symbols to reduce size and analysis information.
*   **Watermarking**: Adding a watermark signature.
*   **Signing**: Spoofing digital certificates.
*   **Entropy Reduction**: Modifying the binary to lower its entropy score.

## Key Design Principles

*   **Modularity**: New loaders, encoders, and shellcode generators can be added relatively easily by adding new files and updating the main script.
*   **Source-Level Evasion**: Much of the evasion logic (unhooking, anti-emulation) is injected at the source code level before compilation.
*   **Compiler-Level Obfuscation**: Leveraging LLVM passes (Akira/Pluto) ensures that the final binary structure is complex and harder to reverse engineer.
*   **Polymorphism**: By supporting random sleep times, multiple encodings, and dynamic injection of junk code, the generated binaries are unique (polymorphic) to some extent.
