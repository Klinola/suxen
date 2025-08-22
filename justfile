# 50 GPU分布式Bento部署管理
# 使用方法: just <command>

# 默认配置
default_env := "bento.env"
worker_env := "worker.env"

# 显示帮助信息
help:
    @echo "🚀 50 GPU分布式Bento部署管理"
    @echo ""
    @echo "📋 可用命令:"
    @echo "  config          - 配置主机IP和资源参数"
    @echo "  master up       - 启动主机服务"
    @echo "  master down     - 停止主机服务"
    @echo "  master status   - 查看主机状态"
    @echo "  worker up       - 启动僚机服务"
    @echo "  worker down     - 停止僚机服务"
    @echo "  worker status   - 查看僚机状态"
    @echo "  status          - 查看完整集群状态"
    @echo "  logs [service]  - 查看日志"
    @echo "  clean           - 清理所有数据"
    @echo ""
    @echo "🔧 配置文件:"
    @echo "  bento.env       - 主机配置"
    @echo "  worker.env      - 僚机配置"
    @echo ""
    @echo "⚠️  重要: 请先运行 'just config' 配置主机IP！"

# 配置主机IP和资源参数
config:
    @echo "🔧 配置50 GPU分布式部署参数"
    @echo ""
    @echo "当前主机IP配置:"
    @grep "MASTER_HOST_IP" {{default_env}} || echo "未找到配置"
    @echo ""
    @echo "请编辑以下配置文件:"
    @echo "1. 主机配置: {{default_env}}"
    @echo "2. 僚机配置: {{worker_env}}"
    @echo ""
    @echo "💡 建议使用内网IP以获得最佳性能！"
    @echo "💡 内网IP延迟更低、带宽更高、更安全"

# 启动主机服务
master-up:
    @echo "🚀 启动主机服务..."
    @echo "📍 主机IP: $(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2)"
    docker compose -f master-compose.yml --env-file {{default_env}} up -d
    @echo "✅ 主机服务启动完成"
    @echo ""
    @echo "🔍 验证服务状态:"
    @sleep 5
    @just master-status

# 停止主机服务
master-down:
    @echo "🛑 停止主机服务..."
    docker compose -f master-compose.yml --env-file {{default_env}} down
    @echo "✅ 主机服务已停止"

# 查看主机状态
master-status:
    @echo "📊 主机服务状态:"
    @docker compose -f master-compose.yml --env-file {{default_env}} ps
    @echo ""
    @echo "🔍 核心服务健康检查:"
    @echo -n "Redis: "
    @docker exec $(docker ps -q -f name=redis) redis-cli ping 2>/dev/null || echo "❌ 异常"
    @echo -n "PostgreSQL: "
    @docker exec $(docker ps -q -f name=postgres) pg_isready -U worker -d taskdb 2>/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo -n "MinIO: "
    @curl -s http://$(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2):9000/minio/health/live >/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo ""
    @echo "🎮 GPU代理数量: $(docker ps --filter 'name=gpu_prove_agent' --format '{.Names}' | wc -l)"

# 启动僚机服务
worker-up:
    @echo "🚀 启动僚机服务..."
    @echo "📍 连接主机: $(grep MASTER_HOST_IP {{worker_env}} | cut -d'=' -f2)"
    docker compose -f worker-compose.yml --env-file {{worker_env}} up -d
    @echo "✅ 僚机服务启动完成"
    @echo ""
    @echo "🔍 验证服务状态:"
    @sleep 10
    @just worker-status

# 停止僚机服务
worker-down:
    @echo "🛑 停止僚机服务..."
    docker compose -f worker-compose.yml --env-file {{worker_env}} down
    @echo "✅ 僚机服务已停止"

# 查看僚机状态
worker-status:
    @echo "📊 僚机服务状态:"
    @docker compose -f worker-compose.yml --env-file {{worker_env}} ps
    @echo ""
    @echo "🔍 本地服务健康检查:"
    @echo -n "Redis本地: "
    @docker exec $(docker ps -q -f name=redis-local) redis-cli ping 2>/dev/null || echo "❌ 异常"
    @echo -n "PostgreSQL本地: "
    @docker exec $(docker ps -q -f name=postgres-local) pg_isready -U worker -d taskdb 2>/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo -n "MinIO本地: "
    @curl -s http://localhost:9000/minio/health/live >/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo ""
    @echo "🔄 同步状态检查:"
    @echo -n "Redis主从同步: "
    @docker exec $(docker ps -q -f name=redis-local) redis-cli info replication | grep "master_host:" || echo "❌ 未同步"
    @echo ""
    @echo "🎮 GPU代理数量: $(docker ps --filter 'name=gpu_prove_agent' --format '{.Names}' | wc -l)"

# 查看完整集群状态
status:
    @echo "🌐 50 GPU分布式集群状态总览"
    @echo "================================"
    @echo ""
    @if [ -f "{{default_env}}" ]; then \
        echo "📍 主机IP: $(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2)"; \
        echo "🎮 主机GPU数量: $(docker ps --filter 'name=gpu_prove_agent' --format '{.Names}' | wc -l)"; \
        echo ""; \
        echo "🔗 访问地址:"; \
        echo "  - REST API: http://$(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2):8081"; \
        echo "  - MinIO Console: http://$(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2):9001"; \
        echo "  - Redis主节点: $(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2):6379"; \
        echo "  - PostgreSQL主节点: $(grep MASTER_HOST_IP {{default_env}} | cut -d'=' -f2):5432"; \
    else \
        echo "❌ 配置文件未找到，请先运行 'just config'"; \
    fi

# 查看日志
logs service="":
    @if [ "{{service}}" = "" ]; then \
        echo "📋 可用服务日志:"; \
        echo "  主机: redis, postgres, minio, gpu_prove_agent0, rest_api"; \
        echo "  僚机: redis-local, postgres-local, minio-local, gpu_prove_agent0"; \
        echo ""; \
        echo "使用方法: just logs <service>"; \
    else \
        echo "📜 查看 {{service}} 日志:"; \
        if docker ps --format '{.Names}' | grep -q "{{service}}"; then \
            docker logs -f --tail 50 $(docker ps -q -f name={{service}}); \
        else \
            echo "❌ 服务 {{service}} 未运行"; \
        fi; \
    fi

# 查看所有服务日志
logs-all:
    @echo "📜 查看所有服务日志:"
    @if [ -f "master-compose.yml" ]; then \
        echo "🔍 主机服务日志:"; \
        docker compose -f master-compose.yml logs -f --tail=50; \
    elif [ -f "worker-compose.yml" ]; then \
        echo "🔍 僚机服务日志:"; \
        docker compose -f worker-compose.yml logs -f --tail=50; \
    else \
        echo "❌ 未找到compose文件"; \
    fi


# 清理所有数据（危险操作）
clean:
    @echo "⚠️  警告: 这将删除所有数据和容器！"
    @echo "是否确认清理? [y/N]"
    @read -r confirm; \
    if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
        echo "🧹 清理主机服务..."; \
        docker compose -f master-compose.yml --env-file {{default_env}} down -v 2>/dev/null || true; \
        echo "🧹 清理僚机服务..."; \
        docker compose -f worker-compose.yml --env-file {{worker_env}} down -v 2>/dev/null || true; \
        echo "🧹 清理Docker资源..."; \
        docker system prune -f; \
        echo "✅ 清理完成"; \
    else \
        echo "❌ 取消清理操作"; \
    fi

# 性能监控
monitor:
    @echo "📈 性能监控面板"
    @echo "==============="
    @echo ""
    @echo "🔧 系统资源使用:"
    @docker stats --no-stream --format "table {.Name}\t{.CPUPerc}\t{.MemUsage}\t{.MemPerc}" | head -20
    @echo ""
    @echo "💾 磁盘使用:"
    @docker system df
    @echo ""
    @echo "🌐 网络连接:"
    @echo "Redis连接数: $(docker exec $(docker ps -q -f name=redis) redis-cli info clients | grep connected_clients || echo '无法获取')"

# 快速重启
restart:
    @echo "🔄 快速重启集群..."
    @just master-down
    @just worker-down
    @sleep 5
    @just master-up
    @sleep 10
    @just worker-up

# 验证部署
verify:
    @echo "🔍 验证50 GPU部署..."
    @echo ""
    @echo "1. 检查配置文件..."
    @if [ ! -f "{{default_env}}" ]; then echo "❌ 缺少主机配置文件"; exit 1; fi
    @if [ ! -f "{{worker_env}}" ]; then echo "❌ 缺少僚机配置文件"; exit 1; fi
    @echo "✅ 配置文件检查通过"
    @echo ""
    @echo "2. 检查Docker环境..."
    @docker --version || (echo "❌ Docker未安装"; exit 1)
    @docker compose version || (echo "❌ Docker Compose未安装"; exit 1)
    @echo "✅ Docker环境检查通过"
    @echo ""
    @echo "3. 检查GPU环境..."
    @nvidia-smi > /dev/null 2>&1 && echo "✅ NVIDIA GPU检查通过" || echo "⚠️  NVIDIA GPU不可用"
    @echo ""
    @echo "🎉 环境验证完成！可以开始部署。"
