# 50 GPU分布式Bento部署指南

## 📋 部署架构

```
主机 (Master Node):
├── Redis主节点 (64G内存, 16核)
├── PostgreSQL主节点 (32G内存, 8核)  
├── MinIO主节点 (16G内存, 4核)
├── 8个GPU Prove Agents
├── 4个Executor Agents
├── REST API
└── 监控服务

僚机 (Worker Nodes):
├── Redis从节点 (16G内存, 4核) ← 同步主机
├── PostgreSQL从节点 (16G内存, 4核) ← 同步主机
├── MinIO节点 (8G内存, 2核) ← 镜像主机
├── 8个GPU Prove Agents
└── 数据同步服务
```

## 🚀 快速部署

### 1. 配置IP地址

编辑 `bento.env`：
```bash
# 修改为你的主机内网IP
MASTER_HOST_IP=192.168.1.100
```

编辑 `worker.env`：
```bash
# 保持与主机IP一致
MASTER_HOST_IP=192.168.1.100
```

### 2. 主机部署

```bash
# 验证环境
just verify

# 启动主机服务
just master-up

# 检查状态
just master-status
```

### 3. 僚机部署

将以下文件复制到每台僚机：
- `worker-compose.yml`
- `worker.env`
- `justfile`

在每台僚机上执行：
```bash
# 启动僚机服务
just worker-up

# 检查状态
just worker-status
```

### 4. 验证部署

```bash
# 查看整体状态
just status

# 监控性能
just monitor

# 查看日志
just logs gpu_prove_agent0
```

## 🔧 常用命令

```bash
# 配置管理
just config          # 配置向导
just verify           # 验证环境

# 服务管理
just master-up        # 启动主机
just worker-up        # 启动僚机
just restart          # 重启集群
just clean            # 清理数据

# 状态监控  
just status           # 集群状态
just monitor          # 性能监控
just logs [service]   # 查看日志
```

## 📊 性能优势

| 指标 | 单机部署 | 主从架构 | 提升 |
|------|----------|----------|------|
| 网络延迟 | N/A | 大幅降低 | ⬇️ |
| 数据库压力 | 高 | 分散负载 | ⬇️ |
| 故障容错 | 无 | 主从备份 | ⬆️ |
| 扩展性 | 受限 | 水平扩展 | ⬆️ |

## ⚠️ 重要提醒

1. **使用内网IP**: 50个GPU的高频数据交换必须使用内网IP
2. **资源配置**: 根据实际硬件调整内存和CPU限制
3. **网络要求**: 推荐万兆以太网，最低千兆
4. **防火墙**: 确保端口6379(Redis)、5432(PostgreSQL)、9000/9001(MinIO)开放
5. **数据备份**: 定期备份PostgreSQL数据

## 🌐 访问地址

- **REST API**: `http://{主机IP}:8081`
- **MinIO Console**: `http://{主机IP}:9001` (admin/password)
- **Redis主节点**: `{主机IP}:6379`
- **PostgreSQL主节点**: `{主机IP}:5432`

## 🐛 故障排除

### 僚机连接失败
```bash
# 检查网络连通性
ping {主机IP}

# 检查端口开放
telnet {主机IP} 6379
telnet {主机IP} 5432
telnet {主机IP} 9000
```

### Redis同步异常
```bash
# 查看Redis复制状态
docker exec redis-local redis-cli info replication

# 手动重新连接
docker exec redis-local redis-cli SLAVEOF {主机IP} 6379
```

### PostgreSQL同步异常
```bash
# 查看复制状态
docker exec postgres-local psql -U worker -d taskdb -c "SELECT * FROM pg_stat_wal_receiver;"

# 重新初始化从节点
just worker-down
docker volume rm worker_postgres-local-data
just worker-up
```

### GPU代理无法启动
```bash
# 检查NVIDIA驱动
nvidia-smi

# 检查Docker GPU支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# 查看代理日志
just logs gpu_prove_agent0
```

## 📈 监控指标

定期检查以下指标：
- GPU利用率: `nvidia-smi`
- 容器资源: `just monitor`  
- Redis连接数: `docker exec redis redis-cli info clients`
- PostgreSQL连接数: `docker exec postgres psql -U worker -d taskdb -c "SELECT count(*) FROM pg_stat_activity;"`
- 网络延迟: `ping {其他节点IP}`

## 🔄 扩展指南

添加新僚机：
1. 复制配置文件到新机器
2. 确保网络连通性
3. 执行 `just worker-up`
4. 验证同步状态

升级版本：
1. 更新Docker镜像标签
2. 逐台重启: `just restart`
3. 验证功能正常
