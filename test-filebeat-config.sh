#!/bin/bash

# Filebeat konfigürasyon test scripti

echo "🧪 Filebeat konfigürasyon testi başlatılıyor..."

# Filebeat container'ının çalışıp çalışmadığını kontrol et
if ! docker ps | grep -q filebeat; then
    echo "❌ Filebeat container çalışmıyor!"
    echo "   Önce ./run-ubuntu.sh ile container'ı başlatın"
    exit 1
fi

echo "✅ Filebeat container çalışıyor"

# Konfigürasyon testi
echo "🔧 Konfigürasyon testi yapılıyor..."
docker exec filebeat filebeat test config -c /usr/share/filebeat/filebeat.yml

if [ $? -eq 0 ]; then
    echo "✅ Konfigürasyon geçerli"
else
    echo "❌ Konfigürasyon hatası!"
    exit 1
fi

# Output testi
echo "📤 Elasticsearch output testi yapılıyor..."
docker exec filebeat filebeat test output -c /usr/share/filebeat/filebeat.yml

if [ $? -eq 0 ]; then
    echo "✅ Elasticsearch bağlantısı başarılı"
else
    echo "❌ Elasticsearch bağlantı hatası!"
    exit 1
fi

# Registry yönetimi kaldırıldı - basitleştirilmiş yapı
echo "📋 Registry yönetimi kaldırıldı - basitleştirilmiş yapı kullanılıyor"

# Container loglarını kontrol et
echo "📋 Son container logları:"
docker logs filebeat --tail 10

# Disk kullanımını göster
echo "💾 Disk kullanımı:"
df -h /var/lib/docker 2>/dev/null || echo "Docker dizini bulunamadı"

echo ""
echo "🎉 Tüm testler tamamlandı!"
echo ""
echo "📊 Monitoring için:"
echo "  • Kibana: https://kibana.emm-cyber.de"
echo "  • Index pattern: docker-logs-*"
echo "  • Container logları: docker logs filebeat -f"
