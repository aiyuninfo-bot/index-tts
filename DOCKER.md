# IndexTTS Docker 部署指南

本文档介绍如何使用 Docker 部署 IndexTTS 项目。

## 文件说明

- `Dockerfile`: 用于构建 IndexTTS 镜像的配置文件
- `docker-compose.yml`: 用于简化容器部署和管理的编排文件
- `.dockerignore`: 指定构建镜像时忽略的文件和目录
- `DOCKER.md`: 本使用说明文档

## 快速开始

### 方法一：使用 Docker Compose（推荐）

1. **构建并启动服务**
   ```bash
   docker-compose up -d
   ```

2. **下载模型文件**（首次运行需要）
   ```bash
   docker-compose --profile tools run --rm model-downloader
   ```

3. **访问 Web UI**
   打开浏览器访问：http://localhost:7860

### 方法二：使用 Docker 命令

1. **构建镜像**
   ```bash
   docker build -t indextts:latest .
   ```

2. **创建必要的目录**
   ```bash
   mkdir -p checkpoints test_data outputs
   ```

3. **下载模型文件**
   ```bash
   # 方式1：使用容器下载
   docker run --rm -v $(pwd)/checkpoints:/app/checkpoints indextts:latest \
     huggingface-cli download IndexTeam/IndexTTS-1.5 \
     config.yaml bigvgan_discriminator.pth bigvgan_generator.pth \
     bpe.model dvae.pth gpt.pth unigram_12000.vocab \
     --local-dir /app/checkpoints
   
   # 方式2：在宿主机下载（需要安装 huggingface-hub）
   pip install huggingface-hub
   huggingface-cli download IndexTeam/IndexTTS-1.5 \
     config.yaml bigvgan_discriminator.pth bigvgan_generator.pth \
     bpe.model dvae.pth gpt.pth unigram_12000.vocab \
     --local-dir checkpoints
   ```

4. **运行容器**
   ```bash
   docker run -d \
     --name indextts-app \
     -p 7860:7860 \
     -v $(pwd)/checkpoints:/app/checkpoints \
     -v $(pwd)/test_data:/app/test_data \
     -v $(pwd)/outputs:/app/outputs \
     indextts:latest
   ```

## 使用说明

### Web UI 使用

1. 将参考音频文件放入 `test_data` 目录
2. 访问 http://localhost:7860
3. 在 Web 界面中上传音频文件并输入要合成的文本
4. 生成的音频将保存在 `outputs` 目录中

### 命令行使用

```bash
# 进入容器
docker exec -it indextts-app bash

# 使用命令行工具
indextts "你好，这是一个测试文本" \
  --voice /app/test_data/reference.wav \
  --model_dir /app/checkpoints \
  --config /app/checkpoints/config.yaml \
  --output /app/outputs/output.wav
```

### Python API 使用

```bash
# 进入容器
docker exec -it indextts-app python
```

```python
from indextts.infer import IndexTTS

tts = IndexTTS(model_dir="/app/checkpoints", cfg_path="/app/checkpoints/config.yaml")
voice = "/app/test_data/reference.wav"
text = "你好，这是一个测试文本"
output_path = "/app/outputs/output.wav"

tts.infer(voice, text, output_path)
```

## GPU 支持

如果需要 GPU 加速，请：

1. **安装 NVIDIA Docker 支持**
   ```bash
   # Ubuntu/Debian
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   sudo apt-get update && sudo apt-get install -y nvidia-docker2
   sudo systemctl restart docker
   ```

2. **修改 Dockerfile**
   将 PyTorch 安装命令改为 GPU 版本：
   ```dockerfile
   RUN pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

3. **使用 GPU 运行**
   ```bash
   # Docker Compose 方式：取消注释 docker-compose.yml 中的 GPU 配置
   
   # Docker 命令方式：
   docker run -d --gpus all \
     --name indextts-app \
     -p 7860:7860 \
     -v $(pwd)/checkpoints:/app/checkpoints \
     -v $(pwd)/test_data:/app/test_data \
     -v $(pwd)/outputs:/app/outputs \
     indextts:latest
   ```

## 常见问题

### 1. 模型下载失败

如果在中国大陆，可以设置 HuggingFace 镜像：
```bash
export HF_ENDPOINT="https://hf-mirror.com"
```

### 2. 内存不足

模型文件较大，确保有足够的磁盘空间和内存：
- 磁盘空间：至少 10GB
- 内存：至少 8GB RAM

### 3. 权限问题

如果遇到文件权限问题，可以调整目录权限：
```bash
sudo chown -R $(id -u):$(id -g) checkpoints test_data outputs
```

### 4. 端口冲突

如果 7860 端口被占用，可以修改端口映射：
```bash
# 使用 8080 端口
docker run -p 8080:7860 ...
```

## 清理

```bash
# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi indextts:latest

# 清理未使用的 Docker 资源
docker system prune -a
```

## 技术支持

如有问题，请参考：
- [项目主页](https://github.com/index-tts/index-tts)
- [Issues](https://github.com/index-tts/index-tts/issues)
- QQ群：1048202584
- Discord：https://discord.gg/uT32E7KDmy