# BOAZ 工作流程分析

本文档分析了特定 BOAZ 命令的执行流程，以说明框架如何处理输入并生成最终的 Payload。

## 命令示例

```bash
python3 Boaz.py -f /host_home/Boaz_beta/notepad.exe -o ./output/boaz_output.exe -t donut -l 16 -e uuid -c akira
```

## 逐步执行细分

### 1. 初始化和参数解析
*   **源文件**: `Boaz.py` (第 1399-1481 行)
*   **动作**: 脚本启动并解析提供的参数。
    *   `input_file`: `/host_home/Boaz_beta/notepad.exe`
    *   `output_file`: `./output/boaz_output.exe`
    *   `shellcode_type`: `donut`
    *   `loader`: `16`
    *   `encoding`: `uuid`
    *   `compiler`: `akira`

### 2. Shellcode 生成
*   **函数**: `generate_shellcode` (第 113-230 行)
*   **源文件**: `Boaz.py` 调用 `./PIC/donut`
*   **动作**:
    1.  由于指定了 `-t donut`，脚本构建运行 Donut 工具的命令。
    2.  命令: `./PIC/donut -b1 -f1 -i /host_home/Boaz_beta/notepad.exe -o note_donut.bin`
    3.  **结果**: 创建名为 `note_donut.bin` 的原始 Shellcode 文件。这包含能够从内存加载 `notepad.exe` 的位置无关代码。

### 3. Shellcode 编码
*   **函数**: `generate_shellcode` (第 191-222 行)
*   **源文件**: `Boaz.py` 调用 `encoders/bin2uuid.py`
*   **动作**:
    1.  脚本识别出 `-e uuid`。
    2.  它执行: `python3 ./encoders/bin2uuid.py note_donut.bin > note_donut`
    3.  **逻辑**: `bin2uuid.py` 脚本读取二进制 Shellcode，并将每 16 个字节转换为 UUID 字符串格式 (例如 `xxxx-xx-xx-xx-xxxxxx`)。
    4.  **结果**: 一个名为 `note_donut` 的文本文件，包含 UUID 字符串的 C 数组列表。

### 4. 加载器准备
*   **函数**: `write_loader` (第 420-537 行)
*   **源文件**: `Boaz.py` 读取 `loaders/loader_template_16.c`
*   **动作**:
    1.  **模板选择**: 由于使用了 `-l 16`，脚本读取 `loaders/loader_template_16.c`。该模板实现了“经典用户层 API 调用”。
    2.  **注入**:
        *   脚本读取编码后的 Shellcode 文件 (`note_donut`) 的内容。
        *   它在 C 模板中查找特定的占位符或变量声明（例如 `####SHELLCODE####` 或 `const char* UUIDs[]`）。
        *   它将 UUID 字符串列表注入到 `UUIDs` 数组中。
    3.  **转换逻辑**:
        *   由于使用了 `uuid` 编码，它注入相应的转换逻辑（C 代码），该逻辑将在运行时将 UUID 字符串还原回原始二进制 Shellcode。
        *   它将 `#include "uuid_converter.h"` 添加到文件顶部。
    4.  **输出**: 修改后的源文件 `loaders/loader16_modified.c` 被写入磁盘。

### 5. 编译
*   **函数**: `compile_output` (第 870-1064 行)
*   **源文件**: `Boaz.py` 调用 `./akira_built/bin/clang++`
*   **动作**:
    1.  **编译器选择**: 由于指定了 `-c akira`，脚本配置 Akira 编译器（定制的 Clang/LLVM）的构建命令。
    2.  **混淆 Pass**: 它添加 LLVM 混淆标志：`-mllvm -irobf-indbr -mllvm -irobf-icall -mllvm -irobf-indgv ...` (间接分支、间接调用、间接全局变量等)。
    3.  **命令构建**:
        ```bash
        ./akira_built/bin/clang++ -I. -I./converter -I./evader \
        -target x86_64-w64-mingw32 \
        loaders/loader16_modified.c \
        ./converter/uuid_converter.c \
        -o ./output/boaz_output.exe \
        -v -L<mingw_dir> ...
        ```
    4.  **执行**: 编译器编译主加载器和 UUID 转换器，将它们与标准 Windows 库链接，并应用混淆 Pass。
    5.  **结果**: 最终可执行文件 `./output/boaz_output.exe`。

### 6. 后处理
*   **动作**:
    *   **水印**: 默认情况下，调用 `add_watermark` 给二进制文件添加标记。
    *   **剥离**: 如果启用了 `strip_binary`（取决于标志），它会剥离调试符号。
    *   **哈希计算**: 脚本计算并打印最终输出的 MD5 哈希值。

## 总结
该过程有效地将标准 `notepad.exe` 转换为高度混淆的加载器。Payload 被隐藏为 UUID 字符串，加载器代码本身由 Akira 编译器混淆以抵抗静态分析。在运行时，加载器将从 UUID 重构 Shellcode，并使用加载器 16 中定义的技术执行它。
