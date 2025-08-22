#!/bin/bash
# Boundless Nexus 快速部署脚本

set -e

echo "🌟 Boundless Nexus - 50 GPU分布式零知识证明集群"
echo "=================================================="
echo ""

# 检查是否为主机部署
if [ "$1" = "master" ]; then
    echo "🚀 部署主机服务..."
    
    # 检查配置文件
    if [ ! -f "bento.env" ]; then
        echo "❌ 缺少主机配置文件 bento.env"
        exit 1
    fi
    
    # 读取主机IP
    MASTER_IP=$(grep "MASTER_HOST_IP=" bento.env | cut -d'=' -f2)
    echo "📍 主机IP: $MASTER_IP"
    
    # 验证环境
    echo "🔍 验证环境..."
    docker --version || (echo "❌ Docker未安装"; exit 1)
    docker compose version || (echo "❌ Docker Compose未安装"; exit 1)
    
    # 启动主机服务
    echo "🚀 启动主机服务..."
    docker compose -f master-compose.yml --env-file bento.env up -d
    
    echo ""
    echo "✅ 主机部署完成！"
    echo "🔗 访问地址:"
    echo "  - REST API: http://$MASTER_IP:8081"
    echo "  - MinIO Console: http://$MASTER_IP:9001 (admin/password)"
    echo ""
    echo "📋 下一步: 在僚机上运行 './quick-deploy.sh worker'"

elif [ "$1" = "worker" ]; then
    echo "🤖 部署僚机服务..."
    
    # 检查配置文件
    if [ ! -f "worker.env" ]; then
        echo "❌ 缺少僚机配置文件 worker.env"
        exit 1
    fi
    
    # 读取主机IP
    MASTER_IP=$(grep "MASTER_HOST_IP=" worker.env | cut -d'=' -f2)
    echo "📍 连接主机: $MASTER_IP"
    
    # 测试主机连通性
    echo "🔍 测试主机连通性..."
    ping -c 1 $MASTER_IP > /dev/null || (echo "❌ 无法连接主机 $MASTER_IP"; exit 1)
    
    # 验证环境
    echo "🔍 验证环境..."
    docker --version || (echo "❌ Docker未安装"; exit 1)
    docker compose version || (echo "❌ Docker Compose未安装"; exit 1)
    nvidia-smi > /dev/null 2>&1 && echo "✅ NVIDIA GPU可用" || echo "⚠️  NVIDIA GPU不可用"
    
    # 启动僚机服务
    echo "🚀 启动僚机服务..."
    docker compose -f worker-compose.yml --env-file worker.env up -d
    
    echo ""
    echo "✅ 僚机部署完成！"
    echo "🔗 本地服务:"
    echo "  - MinIO Console: http://localhost:9001"
    echo ""
    echo "📊 运行 'just status' 查看集群状态"

else
    echo "📋 用法:"
    echo "  主机部署: ./quick-deploy.sh master"
    echo "  僚机部署: ./quick-deploy.sh worker"
    echo ""
    echo "📚 详细说明请查看 README.md 和 DEPLOYMENT.md"
    echo ""
    echo "🔧 手动管理 (推荐):"
    echo "  just master-up    # 启动主机"
    echo "  just worker-up    # 启动僚机"
    echo "  just status       # 查看状态"
    echo "  just help         # 更多命令"
fi
