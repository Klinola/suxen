# Nexus Cluster - Distributed Computing Infrastructure

## 📖 Overview

**Nexus** is a high-performance distributed computing cluster deployment solution designed for large-scale GPU environments, optimized for computational workloads requiring mathematical proof generation.

### 🏗️ Architecture Design

```
Master Node + Multiple Worker Nodes
├── Master-Worker Database Synchronization (Redis + PostgreSQL + MinIO)
├── Localized Data Access (Reduced Network Latency)
├── Horizontal Scaling Support (Unlimited Worker Addition)
└── High Availability & Fault Tolerance (Master-Replica Backup)
```

### ⚡ Performance Advantages

- **Ultra-Low Latency**: Internal network connectivity with local database access
- **High Concurrency**: Support for 50+ GPU parallel computational processing
- **Load Balancing**: Intelligent distribution of database connection pressure
- **Fault Tolerance**: Master-replica synchronization ensures data integrity

## 🚀 Quick Start

### 1. Configure Master IP
```bash
# Edit configuration files
vim bento.env
vim worker.env

# Set your master node internal IP
MASTER_HOST_IP=192.168.1.100
```

### 2. Deploy Master Node
```bash
just master-up
```

### 3. Deploy Worker Nodes
```bash
# Copy files to worker machines, then execute:
just worker-up
```

### 4. Verify Cluster Status
```bash
just status
```

## 📁 File Structure

| File | Purpose |
|------|---------|
| `master-compose.yml` | Master node Docker Compose configuration |
| `worker-compose.yml` | Worker node Docker Compose configuration |
| `bento.env` | Master node environment variables |
| `worker.env` | Worker node environment variables |
| `justfile` | Deployment management scripts |
| `DEPLOYMENT.md` | Detailed deployment guide |

## 🔧 Management Commands

```bash
just help          # Show help
just config        # Configuration wizard
just master-up      # Start master node
just worker-up      # Start worker node
just status         # Check cluster status
just monitor        # Performance monitoring
just logs [service] # View service logs
just clean          # Clean data
```

## ⚠️ Important Notes

1. **Internal IP Required** - Ensures optimal performance
2. **Network Requirements** - 10GbE recommended for best results
3. **Resource Requirements** - Adjust configuration based on actual hardware
4. **Port Configuration** - 6379(Redis), 5432(PostgreSQL), 9000/9001(MinIO)

## 📚 Documentation

For detailed deployment instructions, see `DEPLOYMENT.md`