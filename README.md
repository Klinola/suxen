# Boundless Nexus - 50 GPU分布式零知识证明集群

## 📖 概述

**Boundless Nexus** 是一个为50+个GPU设计的高性能分布式零知识证明计算集群部署方案。

### 🏗️ 架构设计

```
主机 (Master) + 多个僚机 (Workers)
├── 主从数据库同步 (Redis + PostgreSQL + MinIO)
├── 本地化数据访问 (减少网络延迟)
├── 水平扩展支持 (无限制添加僚机)
└── 高可用容错 (主从备份机制)
```

### ⚡ 性能优势

- **超低延迟**: 内网连接 + 本地数据库访问
- **高并发**: 支持50+ GPU并行证明计算  
- **负载均衡**: 智能分散数据库连接压力
- **容错保障**: 主从同步确保数据安全

## 🚀 快速开始

### 1. 配置主机IP
```bash
# 编辑配置文件
vim bento.env
vim worker.env

# 修改为你的主机内网IP
MASTER_HOST_IP=192.168.1.100
```

### 2. 部署主机
```bash
just master-up
```

### 3. 部署僚机
```bash
# 将文件复制到僚机，然后执行:
just worker-up
```

### 4. 验证集群
```bash
just status
```

## 📁 文件说明

| 文件 | 用途 |
|------|------|
| `master-compose.yml` | 主机Docker Compose配置 |
| `worker-compose.yml` | 僚机Docker Compose配置 |
| `bento.env` | 主机环境变量配置 |
| `worker.env` | 僚机环境变量配置 |
| `justfile` | 部署管理脚本 |
| `DEPLOYMENT.md` | 详细部署指南 |

## 🔧 管理命令

```bash
just help          # 显示帮助
just config        # 配置向导
just master-up      # 启动主机
just worker-up      # 启动僚机
just status         # 查看状态
just monitor        # 性能监控
just logs [service] # 查看日志
just clean          # 清理数据
```

## ⚠️ 重要提醒

1. **必须使用内网IP** - 确保最佳性能
2. **网络要求** - 推荐万兆以太网
3. **资源要求** - 根据实际硬件调整配置
4. **端口开放** - 6379(Redis), 5432(PostgreSQL), 9000/9001(MinIO)

## 📚 更多文档

详细部署指南请查看 `DEPLOYMENT.md`

---

🌟 **Nexus** - 拉丁语"连接"，象征着将分布式计算节点智能连接为统一的高性能集群。
