# ---------------- Stage 1: Builder ----------------
# 直接使用我们做好的基础镜像
FROM boaz-base AS builder

WORKDIR /boaz

# 把当前目录的代码复制进去
COPY . .

# 运行业务逻辑（这里是你容易出错、需要反复调试的部分）
# 记得先按上一条回复的建议，修改 requirements.sh 里的 github 地址
RUN chmod +x requirements.sh && \
    sed -i 's/sudo //g' requirements.sh && \
    python3 -m venv venv && \
    . ./venv/bin/activate && \
    pip install --upgrade pip && \
    bash requirements.sh && \
    ./venv/bin/pip install pyinstaller && \
    ./venv/bin/pyinstaller --onefile Boaz.py

# ---------------- Stage 2: Runtime ----------------
# Runtime 也直接用基础镜像，省去了再次安装的时间
FROM boaz-base

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=
ENV WINEDEBUG=-all

WORKDIR /boaz

# 从 Builder 阶段复制生成的文件
COPY --from=builder /boaz /boaz

# 安装 Python 依赖
RUN [ -f requirements.txt ] || pip3 freeze > requirements.txt
RUN pip3 install --break-system-packages -r requirements.txt || true

ENTRYPOINT ["python3", "/boaz/Boaz.py"]