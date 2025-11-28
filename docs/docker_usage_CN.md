# 使用 Docker 运行 BOAZ

BOAZ 包含一个 Dockerfile，用于简化依赖管理并确保一致的构建环境。

## 1. 构建 Docker 镜像

首先，从仓库根目录构建 Docker 镜像。

```bash
docker build -t boaz .
```

此过程将：
*   安装 Kali Linux 基础包。
*   安装交叉编译工具 (MinGW, Clang, NASM)。
*   安装 Python 依赖项。
*   设置 `boaz` 用户和环境。

## 2. 在 Docker 中运行 BOAZ

由于 `Boaz.py` 是入口点，你可以直接将参数传递给 `docker run` 命令。

**重要**: 你需要挂载一个卷来传递输入文件并获取输出文件。

### 基本结构

```bash
docker run --rm -it -v $(pwd):/data boaz [参数]
```

*   `-v $(pwd):/data`: 将当前目录挂载到容器内的 `/data`。
*   **注意**: 引用文件时，请使用容器内的路径（例如 `/data/notepad.exe`）。

### 示例命令

使用 Docker 从本地 `notepad.exe` 生成 Payload：

```bash
docker run --rm -it -v $(pwd):/data boaz \
    -f /data/notepad.exe \
    -o /data/output/payload.exe \
    -t donut \
    -l 16 \
    -e uuid
```

### 解释
1.  **挂载**: 当前目录 (`$(pwd)`) 被挂载到 `/data`。
2.  **输入**: 脚本在 `/data` 中查找 `notepad.exe`（对应于你的本地文件夹）。
3.  **输出**: 脚本将 `payload.exe` 写入 `/data/output/`。执行后，你可以在本地 `./output/` 目录中找到此文件。

## 3. 交互模式 (替代方案)

如果你更喜欢在容器内拥有一个 Shell：

```bash
docker run --rm -it --entrypoint /bin/bash -v $(pwd):/data boaz
```

进入容器后，你可以手动运行命令：

```bash
python3 Boaz.py -f /data/notepad.exe -o /data/output/test.exe ...
```
