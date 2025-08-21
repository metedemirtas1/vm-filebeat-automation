#!/bin/bash

echo "🐳 Docker Container Logları Monitoring Script'i"
echo "=============================================="
echo ""

# Filebeat container durumunu kontrol et
echo "📊 Filebeat Container Durumu:"
if docker ps | grep -q filebeat; then
    echo "✅ Filebeat container çalışıyor"
    echo "   Container ID: $(docker ps --filter name=filebeat --format '{{.ID}}')"
    echo "   Status: $(docker ps --filter name=filebeat --format '{{.Status}}')"
else
    echo "❌ Filebeat container çalışmıyor!"
    exit 1
fi

echo ""

# Docker container log dizinlerini kontrol et
echo "📁 Docker Container Log Dizinleri:"
if [ -d "/var/lib/docker/containers" ]; then
    container_count=$(find /var/lib/docker/containers -maxdepth 1 -type d | wc -l)
    log_count=$(find /var/lib/docker/containers -name "*-json.log" -type f | wc -l)
    echo "✅ /var/lib/docker/containers: $container_count container, $log_count log dosyası"
    
    # Son 5 container log dosyasını listele
    echo "   Son log dosyaları:"
    find /var/lib/docker/containers -name "*-json.log" -type f -printf "%T@ %p\n" | sort -n | tail -5 | while read timestamp path; do
        date_str=$(date -d "@${timestamp%.*}" '+%Y-%m-%d %H:%M:%S')
        echo "     $date_str - $(basename "$path")"
    done
else
    echo "❌ /var/lib/docker/containers dizini bulunamadı!"
fi

if [ -d "/mnt/data-storage/docker/containers" ]; then
    container_count=$(find /mnt/data-storage/docker/containers -maxdepth 1 -type d | wc -l)
    log_count=$(find /mnt/data-storage/docker/containers -name "*-json.log" -type f | wc -l)
    echo "✅ /mnt/data-storage/docker/containers: $container_count container, $log_count log dosyası"
else
    echo "⚠️  /mnt/data-storage/docker/containers dizini bulunamadı (opsiyonel)"
fi

echo ""

# Filebeat loglarını kontrol et
echo "📋 Filebeat Logları:"
echo "   Son 10 log satırı:"
docker logs filebeat --tail 10 2>/dev/null | grep -E "(ERROR|WARN|INFO|docker|container)" || echo "   Log bulunamadı"

echo ""

# Filebeat konfigürasyon testi
echo "🔧 Filebeat Konfigürasyon Testi:"
if docker exec filebeat filebeat test config -c /usr/share/filebeat/filebeat.yml 2>/dev/null; then
    echo "✅ Konfigürasyon geçerli"
else
    echo "❌ Konfigürasyon hatası!"
fi

echo ""

# Elasticsearch bağlantı testi
echo "🌐 Elasticsearch Bağlantı Testi:"
if docker exec filebeat filebeat test output 2>/dev/null | grep -q "Connection to"; then
    echo "✅ Elasticsearch bağlantısı başarılı"
else
    echo "❌ Elasticsearch bağlantı hatası!"
fi

echo ""

# Container log örnekleri
echo "📝 Container Log Örnekleri:"
echo "   JSON log dosyası içeriği örneği:"
if [ -f "/var/lib/docker/containers/$(ls /var/lib/docker/containers | head -1)/$(ls /var/lib/docker/containers/$(ls /var/lib/docker/containers | head -1) | grep '\.log$' | head -1)" ]; then
    log_file=$(find /var/lib/docker/containers -name "*-json.log" -type f | head -1)
    echo "   Dosya: $log_file"
    echo "   İlk 3 satır:"
    head -3 "$log_file" | sed 's/^/     /'
else
    echo "   Log dosyası bulunamadı"
fi

echo ""
echo "🔄 Monitoring tamamlandı!"
echo ""
echo "💡 Yardımcı komutlar:"
echo "   • Filebeat logları: docker logs filebeat -f"
echo "   • Container logları: docker logs <container_id>"
echo "   • Log dosyaları: find /var/lib/docker/containers -name '*-json.log'"
echo "   • Filebeat restart: docker restart filebeat"
