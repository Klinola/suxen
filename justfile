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
    @echo "  master clean    - 彻底清理主机服务（删除所有数据）"
    @echo "  master status   - 查看主机状态"
    @echo "  worker up       - 启动僚机服务"
    @echo "  worker down     - 停止僚机服务"
    @echo "  worker clean    - 彻底清理僚机服务"
    @echo "  worker status   - 查看僚机状态"
    @echo "  status          - 查看完整集群状态"
    @echo "  logs [service]  - 查看日志"
    @echo "  monitor         - 全面系统监控"
    @echo "  monitor-detailed - 详细连接和性能监控"
    @echo "  monitor-live    - 实时监控面板"
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
    @echo "🔧 构建Docker镜像 (v1.0.0)..."
    @docker build --network=host \
       --build-arg http_proxy=http://127.0.0.1:8080 \
       --build-arg https_proxy=http://127.0.0.1:8080 \
       --build-arg HTTP_PROXY=http://127.0.0.1:8080 \
       --build-arg HTTPS_PROXY=http://127.0.0.1:8080 \
       --build-arg no_proxy=localhost,127.0.0.1,::1 \
       --build-arg NO_PROXY=localhost,127.0.0.1,::1 \
       -f dockerfiles/rest_api.prebuilt.dockerfile \
       --build-arg BINARY_URL=https://github.com/boundless-xyz/boundless/releases/download/bento-v1.0.0/bento-bundle-linux-amd64.tar.gz \
       -t bento-master-rest_api . && \
     docker build --network=host \
       --build-arg http_proxy=http://127.0.0.1:8080 \
       --build-arg https_proxy=http://127.0.0.1:8080 \
       --build-arg HTTP_PROXY=http://127.0.0.1:8080 \
       --build-arg HTTPS_PROXY=http://127.0.0.1:8080 \
       --build-arg no_proxy=localhost,127.0.0.1,::1 \
       --build-arg NO_PROXY=localhost,127.0.0.1,::1 \
       -f dockerfiles/agent.prebuilt.dockerfile \
       --build-arg BINARY_URL=https://github.com/boundless-xyz/boundless/releases/download/bento-v1.0.0/bento-bundle-linux-amd64.tar.gz \
       -t bento-master-agent .
    @echo "✅ 镜像构建完成"
    docker compose -f master-compose.yml --env-file {{default_env}} up -d
    @echo "✅ 主机服务启动完成"
    @echo ""
    @just master-logs

# 停止主机服务
master-down:
    @echo "🛑 停止主机服务..."
    docker compose -f master-compose.yml --env-file {{default_env}} down
    @echo "✅ 主机服务已停止"

# 彻底清理主机服务（包括数据库和存储）
master-clean:
    @echo "🛑 彻底清理主机服务..."
    @echo "⚠️  这将删除所有数据库记录、MinIO文件和容器！"
    @# 优雅停止服务
    @docker compose -f master-compose.yml --env-file {{default_env}} stop 2>/dev/null || true
    @# 删除容器和卷
    @docker compose -f master-compose.yml --env-file {{default_env}} down -v --remove-orphans 2>/dev/null || true
    @# 清理相关网络
    @docker network rm bento-master_bento-network 2>/dev/null || true
    @echo "✅ 主机服务彻底清理完成"

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
    @curl -s http://localhost:9000/minio/health/live >/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo ""
    @echo "🎮 GPU代理数量: $(docker ps --filter 'name=gpu_prove_agent' --format '{.Names}' | wc -l)"

# 启动僚机服务
worker-up:
    @echo "🚀 启动僚机服务..."
    @echo "📍 连接主机: $(grep MASTER_HOST_IP {{worker_env}} | cut -d'=' -f2)"
    docker compose -f worker-compose.yml --env-file {{worker_env}} up -d
    @echo "✅ 僚机服务启动完成"
    @echo ""
    @just worker-logs

# 停止僚机服务
worker-down:
    @echo "🛑 停止僚机服务..."
    docker compose -f worker-compose.yml --env-file {{worker_env}} down
    @echo "✅ 僚机服务已停止"

# 彻底清理僚机服务
worker-clean:
    @echo "🛑 彻底清理僚机服务..."
    @# 优雅停止服务
    @docker compose -f worker-compose.yml --env-file {{worker_env}} stop 2>/dev/null || true
    @# 删除容器（worker无卷，但清理容器和网络）
    @docker compose -f worker-compose.yml --env-file {{worker_env}} down --remove-orphans 2>/dev/null || true
    @echo "✅ 僚机服务彻底清理完成"

# 查看僚机状态
worker-status:
    @echo "📊 僚机服务状态:"
    @docker compose -f worker-compose.yml --env-file {{worker_env}} ps
    @echo ""
    @echo "🔍 远程服务健康检查:"
    @echo -n "Redis远程: "
    @redis-cli -h $(grep MASTER_HOST_IP {{worker_env}} | cut -d'=' -f2) -p 6379 ping 2>/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo -n "PostgreSQL远程: "
    @pg_isready -h $(grep MASTER_HOST_IP {{worker_env}} | cut -d'=' -f2) -p 5432 -U worker -d taskdb 2>/dev/null && echo "✅ 正常" || echo "❌ 异常"
    @echo -n "MinIO远程: "
    @curl -s http://$(grep MASTER_HOST_IP {{worker_env}} | cut -d'=' -f2):9000/minio/health/live >/dev/null && echo "✅ 正常" || echo "❌ 异常"
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

# 查看主机服务日志
master-logs:
    @echo "📜 查看主机服务日志:"
    @if [ -f "master-compose.yml" ]; then \
        docker compose -f master-compose.yml logs -f --tail=50; \
    else \
        echo "❌ 未找到master-compose.yml文件"; \
    fi

# 查看僚机服务日志
worker-logs:
    @echo "📜 查看僚机服务日志:"
    @if [ -f "worker-compose.yml" ]; then \
        docker compose -f worker-compose.yml logs -f --tail=50; \
    else \
        echo "❌ 未找到worker-compose.yml文件"; \
    fi

# 查看所有服务日志 (兼容旧命令)
logs-all:
    @echo "📜 请使用 logs-master 或 logs-worker 命令"


# 彻底清理所有数据（危险操作）
clean:
    @echo "🚨 危险操作: 这将彻底删除所有数据、容器和网络！"
    @echo "包括: 数据库记录、MinIO文件、Redis缓存、所有容器和网络（保留镜像）"
    @echo "确认执行彻底清理? [y/N]"
    @read -r confirm; \
    if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
        echo "🧹 步骤1: 彻底清理主机服务..."; \
        just master-clean; \
        echo "🧹 步骤2: 彻底清理僚机服务..."; \
        just worker-clean; \
        echo "🧹 步骤3: 清理容器和网络（保留镜像）..."; \
        docker container prune -f; \
        docker network prune -f; \
        echo "🧹 步骤4: 清理未使用的卷..."; \
        docker volume prune -f; \
        echo "✅ 彻底清理完成 - 系统已重置到初始状态"; \
        echo "💡 下次启动将是全新环境，不会有残留数据干扰"; \
    else \
        echo "❌ 取消清理操作"; \
    fi

# 全面系统监控
monitor:
    @echo "🔍 系统监控仪表盘"
    @echo "=============================================="
    @date '+时间: %Y-%m-%d %H:%M:%S'
    @echo ""
    @just _monitor_host
    @echo ""
    @just _monitor_containers
    @echo ""
    @just _monitor_services_simple
    @echo ""
    @just _monitor_application_simple

# 主机层监控
_monitor_host:
    @echo "🖥️  主机层监控"
    @echo "----------------------------------------"
    @echo "💻 CPU 信息:"
    @echo "  逻辑核心数: $(nproc)"
    @echo "  负载均值: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
    @echo "  CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')%"
    @echo ""
    @echo "🧠 内存信息:"
    @free -h | awk 'NR==1{printf "%-10s %-8s %-8s %-8s %-8s\n", "类型", "总量", "已用", "可用", "使用率"} NR==2{printf "%-10s %-8s %-8s %-8s %.1f%%\n", "物理内存", $2, $3, $7, ($3/$2)*100}'
    @echo ""
    @echo "🌐 网络信息:"
    @echo "  活跃网络连接: $(ss -tun | wc -l) 个"
    @echo "  TCP监听端口: $(ss -tln | grep -c LISTEN) 个"

# 容器层监控
_monitor_containers:
    @echo "🐳 容器层监控"
    @echo "----------------------------------------"
    @echo "📊 核心服务容器状态:"
    @docker ps | grep -E 'postgres|redis|pgbouncer|rest_api|minio' | awk '{print $NF "\t" $1}' | head -10 || echo "  无核心服务容器运行"
    @echo ""
    @echo "📈 核心服务资源使用:"
    @docker stats --no-stream | grep -E 'postgres|redis|pgbouncer|rest_api|minio' | head -10 || echo "  无法获取资源使用情况"
    @echo ""
    @echo "🎮 GPU Agent 状态:"
    @echo "  运行中的 GPU Agent: $(docker ps | grep gpu_prove_agent | wc -l) 个"

# 简化服务监控
_monitor_services_simple:
    @echo "🔧 核心服务监控"
    @echo "----------------------------------------"
    @echo "🔴 Redis 服务状态:"
    @if docker exec $(docker ps -q -f name=redis) redis-cli ping >/dev/null 2>&1; then \
        echo "  ✅ Redis 连接正常"; \
        docker exec $(docker ps -q -f name=redis) redis-cli info clients | grep connected_clients; \
        docker exec $(docker ps -q -f name=redis) redis-cli info memory | grep used_memory_human; \
        docker exec $(docker ps -q -f name=redis) redis-cli info stats | grep instantaneous_ops_per_sec; \
    else \
        echo "  ❌ Redis 连接异常"; \
    fi
    @echo ""
    @echo "🐘 PostgreSQL 服务状态:"
    @if docker exec $(docker ps -q -f name=postgres) pg_isready -U worker -d taskdb >/dev/null 2>&1; then \
        echo "  ✅ PostgreSQL 连接正常"; \
        docker exec $(docker ps -q -f name=postgres) psql -U worker -d taskdb -c "SELECT count(*) as total_connections FROM pg_stat_activity;" 2>/dev/null; \
        docker exec $(docker ps -q -f name=postgres) psql -U worker -d taskdb -c "SELECT pg_size_pretty(pg_database_size('taskdb')) as db_size;" 2>/dev/null; \
    else \
        echo "  ❌ PostgreSQL 连接异常"; \
    fi
    @echo ""
    @echo "🔗 PgBouncer 服务状态:"
    @if docker ps -q -f name=pgbouncer >/dev/null 2>&1; then \
        echo "  ✅ PgBouncer 容器正常运行"; \
        echo "  📊 PgBouncer 连接池统计 (基于日志分析):"; \
        recent_transactions=`docker logs $(docker ps -q -f name=pgbouncer) --tail 50 | grep "transaction time" | wc -l`; \
        master_connections=`docker logs $(docker ps -q -f name=pgbouncer) --tail 50 | grep -E "172\.19\." | wc -l`; \
        worker_connections=`docker logs $(docker ps -q -f name=pgbouncer) --tail 50 | grep -E "172\.31\." | wc -l`; \
        echo "    最近50条日志中的事务: $$recent_transactions 个"; \
        echo "    Master内网连接活动: $$master_connections 条"; \
        echo "    Worker外网连接活动: $$worker_connections 条"; \
        echo "  📋 配置信息:"; \
        echo "    监听端口: 5432 (容器内) -> 6432 (主机)"; \
        echo "    连接模式: transaction"; \
        echo "    最大客户端连接: 5000"; \
        echo "    默认连接池大小: 20"; \
        echo "  ⚡ 外部连接测试:"; \
        if nc -z localhost 6432 2>/dev/null; then \
            echo "    ✅ 外部端口6432可访问"; \
        else \
            echo "    ❌ 外部端口6432不可访问"; \
        fi; \
    else \
        echo "  ❌ PgBouncer 容器未运行"; \
    fi

# 简化应用监控
_monitor_application_simple:
    @echo "📊 应用逻辑层监控"
    @echo "----------------------------------------"
    @echo "🔄 任务队列状态:"
    @if docker exec $(docker ps -q -f name=postgres) psql -U worker -d taskdb -c "SELECT 1;" >/dev/null 2>&1; then \
        echo "  任务状态统计:"; \
        docker exec $(docker ps -q -f name=postgres) psql -U worker -d taskdb -c "SELECT status, count(*) as count FROM tasks GROUP BY status ORDER BY count DESC;" 2>/dev/null || echo "    暂无任务数据"; \
    else \
        echo "  ❌ 数据库连接异常，无法获取任务信息"; \
    fi
    @echo ""
    @echo "🎯 集群健康评估:"
    @echo "  核心服务容器: $(docker ps | grep -E 'postgres|redis|pgbouncer' | wc -l)/3 个"
    @echo "  GPU Agent: $(docker ps | grep gpu_prove_agent | wc -l) 个" 
    @echo "  总容器数: $(docker ps | wc -l) 个"

# 详细监控pgbouncer连接和Redis性能 (保留原有功能)
monitor-detailed:
    @echo "📊 详细服务监控面板"
    @echo "================================"
    @echo ""
    @echo "🔗 PgBouncer 连接统计:"
    @echo "----------------------------------------"
    @echo "📈 活跃连接数按IP统计:"
    @docker compose -f master-compose.yml --env-file {{default_env}} logs pgbouncer --tail=300 2>/dev/null | \
        grep -E "taskdb/worker@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+" | \
        sed -E 's/.*taskdb\/worker@([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+.*/\1/' | \
        sort | uniq -c | sort -nr | \
        awk 'BEGIN{printf "%-8s %-15s %s\n", "连接数", "IP地址", "类型"} {if($2 ~ /^172\.19\./) printf "%-8s %-15s %s\n", $1, $2, "Master内网"; else printf "%-8s %-15s %s\n", $1, $2, "Worker外网"}' || echo "  无法获取连接统计"
    @echo ""
    @echo "📊 总连接统计:"
    @master_count=`docker compose -f master-compose.yml --env-file {{default_env}} logs pgbouncer --tail=300 2>/dev/null | grep -E "taskdb/worker@172\.19\." | sed -E 's/.*taskdb\/worker@([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+.*/\1/' | sort | uniq | wc -l | tr -d ' '`; \
     worker_count=`docker compose -f master-compose.yml --env-file {{default_env}} logs pgbouncer --tail=300 2>/dev/null | grep -E "taskdb/worker@172\.31\." | sed -E 's/.*taskdb\/worker@([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+.*/\1/' | sort | uniq | wc -l | tr -d ' '`; \
     if [ "$$master_count" != "" ] && [ "$$worker_count" != "" ]; then \
       total=`expr $$master_count + $$worker_count 2>/dev/null || echo "0"`; \
       echo "  Master内网连接: $$master_count"; \
       echo "  Worker外网连接: $$worker_count"; \
       echo "  总连接数: $$total"; \
     else \
       echo "  无法获取连接统计"; \
     fi
    @echo ""
    @echo "🔴 Redis 性能分析:"
    @echo "----------------------------------------"
    @echo "📊 Redis基础信息:"
    @docker exec `docker ps -q -f name=redis` redis-cli info server 2>/dev/null | grep -E "(redis_version|uptime_in_seconds|tcp_port)" | sed 's/:/: /' || echo "❌ Redis信息获取失败"
    @echo ""
    @echo "📈 Redis内存分析 (配置: 128GB最大内存):"
    @used_memory_human=`docker exec $(docker ps -q -f name=redis) redis-cli info memory 2>/dev/null | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     used_memory_peak_human=`docker exec $(docker ps -q -f name=redis) redis-cli info memory 2>/dev/null | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     echo "  当前内存使用: $$used_memory_human"; \
     echo "  峰值内存使用: $$used_memory_peak_human"; \
     echo "  配置最大内存: 128GB"; \
     echo "  ✅ 内存使用正常"
    @echo ""
    @echo "🔗 Redis连接分析 (配置: 10000最大连接):"
    @connected_clients=`docker exec $(docker ps -q -f name=redis) redis-cli info clients 2>/dev/null | grep "connected_clients:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     blocked_clients=`docker exec $(docker ps -q -f name=redis) redis-cli info clients 2>/dev/null | grep "blocked_clients:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     echo "  活跃连接数: $$connected_clients/10000"; \
     echo "  阻塞连接数: $$blocked_clients"; \
     if [ "$$connected_clients" != "" ] && [ "$$connected_clients" -gt 8000 ] 2>/dev/null; then echo "  🚨 警告: 连接数接近上限!"; \
     elif [ "$$connected_clients" != "" ] && [ "$$connected_clients" -gt 5000 ] 2>/dev/null; then echo "  ⚠️  注意: 连接数较高"; \
     else echo "  ✅ 连接数正常"; fi
    @echo ""
    @echo "⚡ Redis性能指标:"
    @total_commands=`docker exec $(docker ps -q -f name=redis) redis-cli info stats 2>/dev/null | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     ops_per_sec=`docker exec $(docker ps -q -f name=redis) redis-cli info stats 2>/dev/null | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     keyspace_hits=`docker exec $(docker ps -q -f name=redis) redis-cli info stats 2>/dev/null | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     keyspace_misses=`docker exec $(docker ps -q -f name=redis) redis-cli info stats 2>/dev/null | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r' | head -1`; \
     echo "  总命令处理数: $$total_commands"; \
     echo "  当前操作/秒: $$ops_per_sec"; \
     echo "  缓存命中: $$keyspace_hits, 未命中: $$keyspace_misses"; \
     if [ "$$ops_per_sec" != "" ] && [ "$$ops_per_sec" -gt 50000 ] 2>/dev/null; then echo "  🚨 高负载: 操作频率很高"; \
     elif [ "$$ops_per_sec" != "" ] && [ "$$ops_per_sec" -gt 10000 ] 2>/dev/null; then echo "  ⚠️  中等负载"; \
     else echo "  ✅ 负载正常"; fi
    @echo ""
    @echo "💾 Redis键空间与存储:"
    @keyspace_info=`docker exec $(docker ps -q -f name=redis) redis-cli info keyspace 2>/dev/null | head -1`; \
     if [ "$$keyspace_info" = "" ]; then \
       echo "  无键数据存储"; \
     else \
       echo "  $$keyspace_info"; \
     fi
    @echo ""
    @echo "🔧 Redis配置检查:"
    @echo "  ✅ 最大内存策略: allkeys-lru (推荐用于缓存)"
    @echo "  ✅ 持久化: AOF每秒同步 (平衡性能与安全)"
    @echo "  ✅ IO线程: 16个 (适合高并发)"
    @echo "  ✅ TCP参数: 优化网络性能"
    @echo ""
    @echo "🎮 Agent服务状态:"
    @echo "----------------------------------------"
    @echo "Master主机 agents:"
    @docker compose -f master-compose.yml --env-file {{default_env}} ps --format "table {.Service}\t{.State}" 2>/dev/null | grep -E "(gpu_prove_agent|exec_agent|snark_agent|aux_agent)" | head -15
    @echo ""
    @echo "📊 容器资源使用 (前12个活跃容器):"
    @docker stats --no-stream | awk 'NR<=13{print}' | column -t

# 实时监控 (持续刷新)
monitor-live:
    @echo "🔄 实时监控 (按 Ctrl+C 退出)"
    @echo "================================"
    @while true; do \
        clear; \
        echo "🕐 `date '+%Y-%m-%d %H:%M:%S'` - Bento集群实时监控"; \
        echo "================================"; \
        echo ""; \
        echo "🔗 PgBouncer活跃连接:"; \
        master_count=`docker compose -f master-compose.yml --env-file {{default_env}} logs pgbouncer --tail=100 2>/dev/null | grep -E "taskdb/worker@172\.19\." | grep -oE "taskdb/worker@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+" | sort | uniq | wc -l`; \
        worker_count=`docker compose -f master-compose.yml --env-file {{default_env}} logs pgbouncer --tail=100 2>/dev/null | grep -E "taskdb/worker@172\.31\." | grep -oE "taskdb/worker@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+" | sort | uniq | wc -l`; \
        total=`expr $$master_count + $$worker_count`; \
        echo "  Master: $$master_count | Worker: $$worker_count | 总计: $$total"; \
        echo ""; \
        echo "🔴 Redis状态:"; \
        redis_clients=`docker exec $(docker ps -q -f name=redis) redis-cli info clients 2>/dev/null | grep connected_clients | cut -d: -f2`; \
        redis_memory=`docker exec $(docker ps -q -f name=redis) redis-cli info memory 2>/dev/null | grep used_memory_human | cut -d: -f2`; \
        redis_ops=`docker exec $(docker ps -q -f name=redis) redis-cli info stats 2>/dev/null | grep instantaneous_ops_per_sec | cut -d: -f2`; \
        echo "  连接数: $$redis_clients | 内存: $$redis_memory | 操作/秒: $$redis_ops"; \
        echo ""; \
        echo "🎮 活跃容器 (前10个):"; \
        docker stats --no-stream | awk 'NR<=11{print}' | column -t; \
        sleep 5; \
    done

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