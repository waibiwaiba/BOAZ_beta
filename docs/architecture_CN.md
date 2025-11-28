# BOAZ 架构与设计

BOAZ 被设计为一个模块化且可扩展的框架，用于生成规避性 Shellcode 加载器。它遵循流水线架构，输入二进制文件在成为最终可执行文件之前会经历多个转换阶段。

## 系统概览

该系统由以下关键组件组成：

1.  **编排器 (Orchestrator - `Boaz.py`)**: 中央 Python 脚本，负责解析参数、管理流水线并调用其他组件。
2.  **Shellcode 生成器 (Shellcode Generators)**: 将可执行文件 (PE 文件) 转换为位置无关 Shellcode 的工具。
3.  **编码器 (Encoders)**: 将原始 Shellcode 转换为各种格式（如 UUID、IPv4、MAC）以规避基于特征码检测的模块。
4.  **加载器 (Loaders)**: 基于 C 语言的模板，定义了 Shellcode 如何在内存中注入和执行。
5.  **规避器 (Evaders)**: 实现规避技术的 C 模块（反模拟、解钩等）。
6.  **编译器 (Compilers)**: 用于将最终 C 代码编译为可执行文件的工具链 (MinGW, Clang/LLVM)。

## 流水线

### 1. 输入处理
框架接受原始 Shellcode 文件 (`.bin`) 或 Windows 可执行文件 (`.exe`)。如果提供的是可执行文件，它必须被转换为 Shellcode。

### 2. Shellcode 生成
BOAZ 集成了多个外部工具来生成 Shellcode：
*   **Donut**: 将 .NET 程序集、PE 文件等转换为 Shellcode。
*   **PE2SHC**: 将 PE 转换为 Shellcode。
*   **Amber / Shoggoth**: 其他具有反射加载功能的 Shellcode 生成器。
*   **Augmented Loader**: 用于生成 Shellcode 的自定义 Python 脚本。

### 3. 编码 (混淆)
为了将 Shellcode 隐藏在加载器的数据段中，BOAZ 支持多种编码方案。这会将恶意字节流转换为看起来无害的数据类型：
*   **UUID**: Shellcode 被转换为 UUID 字符串列表。
*   **IPv4 / MAC**: Shellcode 被伪装成 IP 或 MAC 地址。
*   **加密**: AES, ChaCha20, RC4 等。

### 4. 加载器构建
这是框架的核心。BOAZ 使用基于模板的方法。
*   **模板**: 位于 `loaders/loader_template_*.c`。这些包含像 `####SHELLCODE####` 或 `####MAGICSPELL####` 这样的占位符。
*   **注入**: `Boaz.py` 读取选定的模板并注入编码后的 Shellcode 和必要的头文件。
*   **功能注入**: 额外的功能如反模拟、API 解钩 (`unhooking`) 和 SweetSleep (`sleep_encrypt`) 通过字符串操作 (RegEx) 注入到源代码中。

### 5. 编译
修改后的 C 代码使用支持的编译器之一进行编译：
*   **MinGW**: 标准的 Windows GCC 交叉编译器。
*   **Pluto / Akira**: 基于 LLVM 的编译器 (Clang)，带有自定义混淆 Pass（例如，控制流平坦化、虚假控制流、指令替换）。这些提供二进制级别的混淆。

### 6. 后处理
*   **剥离 (Stripping)**: 移除符号以减小体积并去除分析信息。
*   **水印**: 添加水印签名。
*   **签名**: 欺骗数字证书。
*   **熵减**: 修改二进制文件以降低其熵值。

## 关键设计原则

*   **模块化**: 通过添加新文件并更新主脚本，可以相对容易地添加新的加载器、编码器和 Shellcode 生成器。
*   **源码级规避**: 大部分规避逻辑（解钩、反模拟）是在编译前注入到源代码级别的。
*   **编译器级混淆**: 利用 LLVM Pass (Akira/Pluto) 确保最终的二进制结构复杂且难以逆向工程。
*   **多态性**: 通过支持随机睡眠时间、多种编码和动态注入垃圾代码，生成的二进制文件在一定程度上是唯一的（多态的）。
