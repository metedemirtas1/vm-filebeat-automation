#!/bin/bash

# Ubuntu için Filebeat container'ını başlat
echo "Ubuntu için Filebeat container'ı başlatılıyor..."

# Mevcut filebeat container'ını durdur ve sil (eğer varsa)
docker stop filebeat 2>/dev/null || true
docker rm filebeat 2>/dev/null || true

# Dosya izinlerini düzelt (Jenkins için)
echo "Dosya izinleri düzeltiliyor..."
sudo chown root:root filebeat-ubuntu.yml 2>/dev/null || true
sudo chmod 644 filebeat-ubuntu.yml 2>/dev/null || true

# Ubuntu için optimize edilmiş Filebeat container'ını başlat
docker run -d \
  --name filebeat \
  --user=root \
  -e ELASTIC_USERNAME=elastic \
  -e ELASTIC_PASSWORD=ElasticPass123! \
  --volume="$(pwd)/filebeat-ubuntu.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/mnt/data-storage/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --volume="/var/log:/var/log:ro" \
  --volume="/var/log/containers:/var/log/containers:ro" \
  --volume="/proc:/host/proc:ro" \
  --volume="/sys:/host/sys:ro" \
  --network="host" \
  docker.elastic.co/beats/filebeat:8.11.0

echo "✅ Filebeat container başlatıldı!"
echo ""
echo "📋 Kontrol komutları:"
echo "  • Container durumu: docker ps | grep filebeat"
echo "  • Container logları: docker logs filebeat"
echo "  • Elasticsearch test: docker exec filebeat filebeat test output"
echo "  • Filebeat logları: docker exec filebeat tail -f /usr/share/filebeat/logs/filebeat-$(date +%Y%m%d).ndjson"
echo ""
echo "🌐 Kibana'da logları görüntülemek için:"
echo "  • https://kibana.emm-cyber.de"
echo "  • Kullanıcı: kibana_user"
echo "  • Şifre: KibanaPass123!"
echo "  • Index pattern: docker-logs-*" 