# Distributed GPU Cluster Deployment Guide

## 📋 Deployment Architecture

```
Master Node:
├── Redis Primary (64G memory, 16 cores)
├── PostgreSQL Primary (32G memory, 8 cores)  
├── MinIO Primary (16G memory, 4 cores)
├── 8x GPU Processing Agents
├── 4x Executor Agents
├── REST API
└── Monitoring Services

Worker Nodes:
├── Redis Replica (16G memory, 4 cores) ← Syncs from Master
├── PostgreSQL Replica (16G memory, 4 cores) ← Syncs from Master
├── MinIO Node (8G memory, 2 cores) ← Mirrors Master
├── 8x GPU Processing Agents
└── Data Synchronization Services
```

## 🚀 Quick Deployment

### 1. Configure IP Addresses

Edit `bento.env`:
```bash
# Set your master node internal IP
MASTER_HOST_IP=192.168.1.100
```

Edit `worker.env`:
```bash
# Keep consistent with master IP
MASTER_HOST_IP=192.168.1.100
```

### 2. Master Node Deployment

```bash
# Verify environment
just verify

# Start master services
just master-up

# Check status
just master-status
```

### 3. Worker Node Deployment

Copy the following files to each worker machine:
- `worker-compose.yml`
- `worker.env`
- `justfile`

Execute on each worker machine:
```bash
# Start worker services
just worker-up

# Check status
just worker-status
```

### 4. Verify Deployment

```bash
# Check overall status
just status

# Monitor performance
just monitor

# View logs
just logs gpu_processing_agent0
```

## 🔧 Common Commands

```bash
# Configuration Management
just config          # Configuration wizard
just verify           # Verify environment

# Service Management
just master-up        # Start master node
just worker-up        # Start worker node
just restart          # Restart cluster
just clean            # Clean data

# Status Monitoring  
just status           # Cluster status
just monitor          # Performance monitoring
just logs [service]   # View logs
```

## 📊 Performance Advantages

| Metric | Single Node | Master-Replica | Improvement |
|--------|-------------|----------------|-------------|
| Network Latency | N/A | Significantly Reduced | ⬇️ |
| Database Load | High | Distributed Load | ⬇️ |
| Fault Tolerance | None | Master-Replica Backup | ⬆️ |
| Scalability | Limited | Horizontal Scaling | ⬆️ |

## ⚠️ Important Notes

1. **Use Internal IP**: High-frequency data exchange across 50 GPUs requires internal IP
2. **Resource Configuration**: Adjust memory and CPU limits based on actual hardware
3. **Network Requirements**: 10GbE recommended, 1GbE minimum
4. **Firewall**: Ensure ports 6379(Redis), 5432(PostgreSQL), 9000/9001(MinIO) are open
5. **Data Backup**: Regular PostgreSQL data backups recommended

## 🌐 Access Endpoints

- **REST API**: `http://{master_ip}:8081`
- **MinIO Console**: `http://{master_ip}:9001` (admin/password)
- **Redis Primary**: `{master_ip}:6379`
- **PostgreSQL Primary**: `{master_ip}:5432`

## 🐛 Troubleshooting

### Worker Connection Failure
```bash
# Check network connectivity
ping {master_ip}

# Check port accessibility
telnet {master_ip} 6379
telnet {master_ip} 5432
telnet {master_ip} 9000
```

### Redis Sync Issues
```bash
# Check Redis replication status
docker exec redis-local redis-cli info replication

# Manual reconnection
docker exec redis-local redis-cli SLAVEOF {master_ip} 6379
```

### PostgreSQL Sync Issues
```bash
# Check replication status
docker exec postgres-local psql -U worker -d taskdb -c "SELECT * FROM pg_stat_wal_receiver;"

# Reinitialize replica
just worker-down
docker volume rm worker_postgres-local-data
just worker-up
```

### GPU Agent Startup Issues
```bash
# Check NVIDIA drivers
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# View agent logs
just logs gpu_processing_agent0
```

## 📈 Monitoring Metrics

Regularly check the following metrics:
- GPU Utilization: `nvidia-smi`
- Container Resources: `just monitor`  
- Redis Connections: `docker exec redis redis-cli info clients`
- PostgreSQL Connections: `docker exec postgres psql -U worker -d taskdb -c "SELECT count(*) FROM pg_stat_activity;"`
- Network Latency: `ping {other_node_ip}`

## 🔄 Scaling Guide

Adding new worker nodes:
1. Copy configuration files to new machine
2. Ensure network connectivity
3. Execute `just worker-up`
4. Verify sync status

Version upgrades:
1. Update Docker image tags
2. Rolling restart: `just restart`
3. Verify functionality
