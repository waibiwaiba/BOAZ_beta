# BOAZ Workflow Analysis

This document analyzes the execution flow of a specific BOAZ command to illustrate how the framework processes inputs and generates the final payload.

## Command Example

```bash
python3 Boaz.py -f /host_home/Boaz_beta/notepad.exe -o ./output/boaz_output.exe -t donut -l 16 -e uuid -c akira
```

## Step-by-Step Execution Breakdown

### 1. Initialization and Argument Parsing
*   **Source**: `Boaz.py` (lines 1399-1481)
*   **Action**: The script starts and parses the provided arguments.
    *   `input_file`: `/host_home/Boaz_beta/notepad.exe`
    *   `output_file`: `./output/boaz_output.exe`
    *   `shellcode_type`: `donut`
    *   `loader`: `16`
    *   `encoding`: `uuid`
    *   `compiler`: `akira`

### 2. Shellcode Generation
*   **Function**: `generate_shellcode` (lines 113-230)
*   **Source**: `Boaz.py` calling `./PIC/donut`
*   **Action**:
    1.  Since `-t donut` is specified, the script constructs a command to run the Donut tool.
    2.  Command: `./PIC/donut -b1 -f1 -i /host_home/Boaz_beta/notepad.exe -o note_donut.bin`
    3.  **Result**: A raw shellcode file named `note_donut.bin` is created. This contains the position-independent code capable of loading `notepad.exe` from memory.

### 3. Shellcode Encoding
*   **Function**: `generate_shellcode` (lines 191-222)
*   **Source**: `Boaz.py` calling `encoders/bin2uuid.py`
*   **Action**:
    1.  The script identifies `-e uuid`.
    2.  It executes: `python3 ./encoders/bin2uuid.py note_donut.bin > note_donut`
    3.  **Logic**: The `bin2uuid.py` script reads the binary shellcode and converts every 16 bytes into a UUID string format (e.g., `xxxx-xx-xx-xx-xxxxxx`).
    4.  **Result**: A text file `note_donut` containing a C-array style list of UUID strings.

### 4. Loader Preparation
*   **Function**: `write_loader` (lines 420-537)
*   **Source**: `Boaz.py` reading `loaders/loader_template_16.c`
*   **Action**:
    1.  **Template Selection**: Since `-l 16` is used, the script reads `loaders/loader_template_16.c`. This template implements "Classic userland API calls".
    2.  **Injection**:
        *   The script reads the content of the encoded shellcode file (`note_donut`).
        *   It looks for specific placeholders or variable declarations in the C template (e.g., `####SHELLCODE####` or `const char* UUIDs[]`).
        *   It injects the list of UUID strings into the `UUIDs` array.
    3.  **Conversion Logic**:
        *   Since `uuid` encoding is used, it injects the corresponding conversion logic (C code) that will run at runtime to convert the UUID strings back to raw binary shellcode.
        *   It adds `#include "uuid_converter.h"` to the top of the file.
    4.  **Output**: A modified source file `loaders/loader16_modified.c` is written to disk.

### 5. Compilation
*   **Function**: `compile_output` (lines 870-1064)
*   **Source**: `Boaz.py` calling `./akira_built/bin/clang++`
*   **Action**:
    1.  **Compiler Selection**: Since `-c akira` is specified, the script configures the build command for the Akira compiler (a customized Clang/LLVM).
    2.  **Obfuscation Passes**: It adds LLVM obfuscation flags: `-mllvm -irobf-indbr -mllvm -irobf-icall -mllvm -irobf-indgv ...` (Indirect Branch, Indirect Call, Indirect Global Variable, etc.).
    3.  **Command Construction**:
        ```bash
        ./akira_built/bin/clang++ -I. -I./converter -I./evader \
        -target x86_64-w64-mingw32 \
        loaders/loader16_modified.c \
        ./converter/uuid_converter.c \
        -o ./output/boaz_output.exe \
        -v -L<mingw_dir> ...
        ```
    4.  **Execution**: The compiler compiles the main loader and the UUID converter, links them against standard Windows libraries, and applies the obfuscation passes.
    5.  **Result**: The final executable `./output/boaz_output.exe`.

### 6. Post-Processing
*   **Action**:
    *   **Watermarking**: By default, `add_watermark` is called to stamp the binary.
    *   **Stripping**: If `strip_binary` is enabled (depends on flags), it strips debug symbols.
    *   **Hash Calculation**: The script calculates and prints the MD5 hash of the final output.

## Summary
The process effectively transforms a standard `notepad.exe` into a highly obfuscated loader. The payload is hidden as UUID strings, and the loader code itself is obfuscated by the Akira compiler to resist static analysis. At runtime, the loader will reconstruct the shellcode from the UUIDs and execute it using the technique defined in Loader 16.
