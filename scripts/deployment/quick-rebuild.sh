#!/bin/bash
# 快速重建和测试脚本

echo "🔄 Pulling latest code..."
git pull origin DEV

echo "🛑 Stopping containers..."
docker compose down

echo "🏗️  Building (with cache)..."
docker compose up -d --build

echo "⏳ Waiting for service to start..."
sleep 3

echo "📊 Checking logs..."
docker logs -f $(docker ps -q --filter "name=checksum-api") &
LOG_PID=$!

echo ""
echo "🧪 Testing API in 3 seconds..."
sleep 3

echo ""
echo "📡 Sending test request..."
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Test123","method":"text"}' | jq .

echo ""
echo "✅ Done! Check logs above for Telegram notification status"
echo "❌ To stop log stream: kill $LOG_PID"
