#!/bin/bash

# Eski Docker container loglarını temizle
# Bu script 14 günden eski log dosyalarını siler

echo "🧹 Eski Docker container logları temizleniyor..."

# Docker container log dizinlerini kontrol et
LOG_DIRS=(
    "/var/lib/docker/containers"
    "/mnt/data-storage/docker/containers"
)

for dir in "${LOG_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "📁 $dir dizini kontrol ediliyor..."
        
        # 14 günden eski log dosyalarını bul ve sil
        find "$dir" -name "*-json.log" -type f -mtime +14 -exec ls -la {} \; | head -10
        
        # Eski log dosyalarını sil (güvenlik için önce listele)
        echo "🗑️  14 günden eski log dosyaları siliniyor..."
        find "$dir" -name "*-json.log" -type f -mtime +14 -delete
        
        # Silinen dosya sayısını göster
        remaining=$(find "$dir" -name "*-json.log" -type f | wc -l)
        echo "✅ $dir dizininde $remaining adet log dosyası kaldı"
    else
        echo "⚠️  $dir dizini bulunamadı"
    fi
done

# Sistem loglarını da temizle (logrotate zaten yapıyor ama ekstra güvenlik)
echo "🧹 Sistem logları kontrol ediliyor..."

# journald loglarını temizle (14 günden eski)
if command -v journalctl &> /dev/null; then
    echo "📋 Journald logları temizleniyor..."
    sudo journalctl --vacuum-time=14d
fi

# Docker system prune - kullanılmayan container, image, network'leri temizle
echo "🐳 Docker sistem temizliği yapılıyor..."
docker system prune -f

# Disk kullanımını göster
echo "💾 Disk kullanımı:"
df -h /var/lib/docker 2>/dev/null || echo "Docker dizini bulunamadı"
df -h /mnt/data-storage 2>/dev/null || echo "Data storage dizini bulunamadı"

echo "✅ Log temizlik işlemi tamamlandı!"
echo "📅 Bu scripti günlük olarak çalıştırmak için crontab'a ekleyin:"
echo "   0 2 * * * /path/to/cleanup-old-logs.sh"
