# Using BOAZ with Docker

BOAZ includes a Dockerfile to simplify dependency management and ensure a consistent build environment.

## 1. Building the Docker Image

First, build the Docker image from the root of the repository.

```bash
docker build -t boaz .
```

This process will:
*   Install Kali Linux base packages.
*   Install cross-compilation tools (MinGW, Clang, NASM).
*   Install Python dependencies.
*   Set up the `boaz` user and environment.

## 2. Running BOAZ in Docker

Since `Boaz.py` is the entrypoint, you can pass arguments directly to the `docker run` command.

**Important**: You need to mount a volume to pass input files and retrieve output files.

### Basic Structure

```bash
docker run --rm -it -v $(pwd):/data boaz [arguments]
```

*   `-v $(pwd):/data`: Mounts your current directory to `/data` inside the container.
*   **Note**: When referencing files, use the path inside the container (e.g., `/data/notepad.exe`).

### Example Command

Generate a payload from a local `notepad.exe` using Docker:

```bash
docker run --rm -it -v $(pwd):/data boaz \
    -f /data/notepad.exe \
    -o /data/output/payload.exe \
    -t donut \
    -l 16 \
    -e uuid
```

### Explanation
1.  **Mount**: The current directory (`$(pwd)`) is mounted to `/data`.
2.  **Input**: The script looks for `notepad.exe` in `/data` (which corresponds to your local folder).
3.  **Output**: The script writes `payload.exe` to `/data/output/`. You will find this file in your local `./output/` directory after execution.

## 3. Interactive Mode (Alternative)

If you prefer to have a shell inside the container:

```bash
docker run --rm -it --entrypoint /bin/bash -v $(pwd):/data boaz
```

Once inside, you can run commands manually:

```bash
python3 Boaz.py -f /data/notepad.exe -o /data/output/test.exe ...
```
