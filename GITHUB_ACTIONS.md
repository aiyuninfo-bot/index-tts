# GitHub Actions Docker 构建指南

本文档介绍如何使用 GitHub Actions 自动构建和推送 IndexTTS 的 Docker 镜像到 Docker Hub。

## 文件说明

- `.github/workflows/docker-build.yml`: 完整的多平台构建workflow
- `.github/workflows/docker-build-cpu.yml`: CPU版本专用workflow
- `.github/workflows/docker-build-gpu.yml`: GPU版本专用workflow
- `Dockerfile`: CPU版本的Docker配置
- `Dockerfile.gpu`: GPU版本的Docker配置

## 配置步骤

### 1. 设置 Docker Hub 凭据

在 GitHub 仓库中设置以下 Secrets：

1. 进入仓库的 **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret** 添加以下密钥：

| Secret 名称 | 描述 | 示例值 |
|------------|------|--------|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 | `your-dockerhub-username` |
| `DOCKERHUB_TOKEN` | Docker Hub 访问令牌 | `dckr_pat_xxxxxxxxxxxxx` |

### 2. 获取 Docker Hub 访问令牌

1. 登录 [Docker Hub](https://hub.docker.com/)
2. 点击右上角头像 → **Account Settings**
3. 选择 **Security** 标签
4. 点击 **New Access Token**
5. 输入描述（如：`GitHub Actions`）
6. 选择权限：**Read, Write, Delete**
7. 点击 **Generate** 并复制生成的令牌

## Workflow 说明

### 主要 Workflow (`docker-build.yml`)

**触发条件：**
- 推送到 `main` 或 `master` 分支
- 创建标签（如 `v1.0.0`）
- Pull Request
- 手动触发

**功能特性：**
- 多平台构建（linux/amd64, linux/arm64）
- 自动标签管理
- 构建缓存优化
- 安全证明生成

### CPU 专用 Workflow (`docker-build-cpu.yml`)

**触发条件：**
- 相关文件变更时推送
- 发布新版本
- 手动触发

**特点：**
- 仅构建 CPU 版本
- 更快的构建速度
- 适合轻量级部署

### GPU 专用 Workflow (`docker-build-gpu.yml`)

**触发条件：**
- GPU相关文件变更时推送
- 发布新版本
- 手动触发

**特点：**
- 基于 NVIDIA CUDA 镜像
- 支持 GPU 加速
- 适合高性能推理

## 镜像标签策略

### 自动标签

| 触发事件 | 生成的标签 |
|----------|------------|
| 推送到主分支 | `latest` |
| 推送标签 `v1.2.3` | `v1.2.3`, `1.2`, `1`, `latest` |
| 推送到其他分支 | `branch-name` |
| Pull Request | `pr-123` |

### 手动标签

可以通过以下方式手动触发构建：

1. 在 GitHub 仓库页面点击 **Actions**
2. 选择对应的 workflow
3. 点击 **Run workflow**
4. 选择分支并点击 **Run workflow**

## 使用构建的镜像

### CPU 版本

```bash
# 拉取最新版本
docker pull your-username/indextts-cpu:latest

# 运行容器
docker run -d \
  --name indextts-cpu \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/test_data:/app/test_data \
  -v $(pwd)/outputs:/app/outputs \
  your-username/indextts-cpu:latest
```

### GPU 版本

```bash
# 拉取最新版本
docker pull your-username/indextts-gpu:latest

# 运行容器（需要 nvidia-docker）
docker run -d \
  --name indextts-gpu \
  --gpus all \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/test_data:/app/test_data \
  -v $(pwd)/outputs:/app/outputs \
  your-username/indextts-gpu:latest
```

### 多平台版本

```bash
# 拉取主workflow构建的镜像
docker pull your-username/indextts:latest

# 运行容器
docker run -d \
  --name indextts \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/test_data:/app/test_data \
  -v $(pwd)/outputs:/app/outputs \
  your-username/indextts:latest
```

## 自定义配置

### 修改镜像名称

在 workflow 文件中修改 `IMAGE_NAME` 环境变量：

```yaml
env:
  IMAGE_NAME: your-custom-name
```

### 修改触发条件

可以根据需要修改 `on` 部分：

```yaml
on:
  push:
    branches: [ main, develop ]  # 添加更多分支
    paths:
      - 'src/**'                 # 仅在特定路径变更时触发
  schedule:
    - cron: '0 2 * * 0'          # 每周日凌晨2点自动构建
```

### 添加构建参数

在 `docker/build-push-action` 步骤中添加构建参数：

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    build-args: |
      PYTHON_VERSION=3.10
      PYTORCH_VERSION=2.1.0
```

## 监控和调试

### 查看构建状态

1. 在仓库页面点击 **Actions**
2. 选择对应的 workflow run
3. 查看各个步骤的日志

### 常见问题

**1. 认证失败**
```
Error: buildx failed with: ERROR: failed to solve: failed to authorize
```
解决方案：检查 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN` 是否正确设置

**2. 构建超时**
```
Error: The operation was canceled.
```
解决方案：
- 启用构建缓存
- 减少构建平台数量
- 优化 Dockerfile

**3. 磁盘空间不足**
```
Error: No space left on device
```
解决方案：
- 清理不必要的文件
- 使用多阶段构建
- 添加清理步骤

### 构建优化建议

1. **使用构建缓存**：已在 workflow 中配置
2. **多阶段构建**：分离构建和运行环境
3. **最小化镜像层**：合并 RUN 命令
4. **使用 .dockerignore**：排除不必要的文件

## 安全最佳实践

1. **使用访问令牌**：不要使用密码，使用 Docker Hub 访问令牌
2. **最小权限原则**：令牌只授予必要的权限
3. **定期轮换**：定期更新访问令牌
4. **监控使用**：定期检查 Docker Hub 的使用情况

## 扩展功能

### 添加镜像扫描

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.REGISTRY }}/${{ secrets.DOCKERHUB_USERNAME }}/${{ env.IMAGE_NAME }}:latest
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### 添加通知

```yaml
- name: Notify on success
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: success
    text: 'Docker image built and pushed successfully!'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

通过这些 GitHub Actions workflow，您可以实现 IndexTTS 项目的自动化 Docker 镜像构建和发布流程。