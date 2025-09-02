# 使用官方Python 3.10镜像作为基础镜像
FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    wget \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY . /app/

# 安装Python依赖
RUN pip install --no-cache-dir --upgrade pip

# 安装PyTorch (CPU版本，如需GPU版本请修改)
RUN pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu

# 安装项目依赖
RUN pip install --no-cache-dir -r requirements.txt

# 安装IndexTTS包
RUN pip install --no-cache-dir -e .

# 创建checkpoints目录
RUN mkdir -p /app/checkpoints

# 创建test_data目录
RUN mkdir -p /app/test_data

# 暴露端口（用于Web UI）
EXPOSE 7860

# 设置默认命令
CMD ["python", "webui.py", "--host", "0.0.0.0", "--port", "7860"]

# 可选：添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1