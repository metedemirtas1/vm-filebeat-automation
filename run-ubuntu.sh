#!/bin/bash

# Ubuntu için Filebeat container'ını başlat
echo "Ubuntu için Filebeat container'ı başlatılıyor..."

# Mevcut filebeat container'ını durdur ve sil (eğer varsa)
docker stop filebeat 2>/dev/null || true
docker rm filebeat 2>/dev/null || true

# Dosya izinlerini düzelt (Jenkins için)
echo "Dosya izinlerini düzeltiliyor..."
sudo chown root:root filebeat-ubuntu.yml 2>/dev/null || true
sudo chmod 644 filebeat-ubuntu.yml 2>/dev/null || true

# Container logs dizinini oluştur
mkdir -p "$(pwd)/container-logs"

# Docker daemon log dizinlerini kontrol et ve oluştur
echo "Docker log dizinlerini kontrol ediliyor..."
sudo mkdir -p /var/log/docker 2>/dev/null || true
sudo chmod 755 /var/log/docker 2>/dev/null || true

# Docker container log dizinlerini kontrol et
echo "Docker container log dizinleri kontrol ediliyor..."
if [ -d "/var/lib/docker/containers" ]; then
    echo "✅ /var/lib/docker/containers dizini mevcut"
    echo "📁 Container log dosyaları:"
    find /var/lib/docker/containers -name "*-json.log" -type f | head -10
else
    echo "❌ /var/lib/docker/containers dizini bulunamadı!"
fi

if [ -d "/mnt/data-storage/docker/containers" ]; then
    echo "✅ /mnt/data-storage/docker/containers dizini mevcut"
    echo "📁 Container log dosyaları:"
    find /mnt/data-storage/docker/containers -name "*-json.log" -type f | head -10
else
    echo "⚠️  /mnt/data-storage/docker/containers dizini bulunamadı (opsiyonel)"
fi

# Ubuntu için optimize edilmiş Filebeat container'ını başlat
echo "🚀 Filebeat container başlatılıyor..."
docker run -d \
  --name filebeat \
  --user=root \
  -e ELASTIC_USERNAME=elastic \
  -e ELASTIC_PASSWORD=ElasticPass123! \
  --volume="$(pwd)/filebeat-ubuntu.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/mnt/data-storage/docker/containers:/mnt/data-storage/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --volume="/var/log:/var/log:ro" \
  --volume="/var/log/containers:/var/log/containers:ro" \
  --volume="/var/log/docker:/var/log/docker:ro" \
  --volume="/proc:/host/proc:ro" \
  --volume="/sys:/host/sys:ro" \
  --volume="/var/log/journal:/var/log/journal:ro" \
  --network="host" \
  --restart=unless-stopped \
  docker.elastic.co/beats/filebeat:8.11.0

# Container'ın başlatılmasını bekle
sleep 5

# Container durumunu kontrol et
if docker ps | grep -q filebeat; then
    echo "✅ Filebeat container başarıyla başlatıldı!"
    
    # Container loglarını kontrol et
    echo "📋 Container logları kontrol ediliyor..."
    docker logs filebeat --tail 20
    
    # Filebeat konfigürasyon testi
    echo "🔧 Filebeat konfigürasyon testi yapılıyor..."
    docker exec filebeat filebeat test config -c /usr/share/filebeat/filebeat.yml
    
else
    echo "❌ Filebeat container başlatılamadı!"
    exit 1
fi

echo ""
echo "📋 Kontrol komutları:"
echo "  • Container durumu: docker ps | grep filebeat"
echo "  • Container logları: docker logs filebeat"
echo "  • Elasticsearch test: docker exec filebeat filebeat test output"
echo "  • Filebeat logları: docker exec filebeat tail -f /usr/share/filebeat/logs/filebeat-$(date +%Y%m%d).ndjson"
echo ""
echo "🔍 Docker container logları kontrol:"
echo "  • Container log dizini: ls -la /var/lib/docker/containers/"
echo "  • Belirli container logları: docker logs <container_id>"
echo "  • Filebeat test: docker exec filebeat filebeat test config"
echo "  • JSON log dosyaları: find /var/lib/docker/containers -name '*-json.log'"
echo ""
echo "🌐 Kibana'da logları görüntülemek için:"
echo "  • https://kibana.emm-cyber.de"
echo "  • Kullanıcı: kibana_user"
echo "  • Şifre: KibanaPass123!"
echo "  • Index pattern: docker-logs-*"
echo ""
echo "📊 Log türleri:"
echo "  • docker_container: Container logları"
echo "  • docker_container_json: JSON format container logları"
echo "  • docker_daemon: Docker daemon logları"
echo "  • docker_systemd: Docker systemd logları"
echo "  • docker_events: Real-time container events"
echo "  • system: Sistem logları"
echo "  • application: Uygulama logları" 