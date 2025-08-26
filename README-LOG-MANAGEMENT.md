# Filebeat Log Management - Eski Log Sorunu Çözümü

## Problem
MSSQL Docker container'ının 2024 tarihli eski logları Filebeat tarafından sürekli Elasticsearch'e gönderiliyor ve yeni log gibi görünüyor.

## Çözüm

### 1. Filebeat Konfigürasyonu Güncellemeleri

`filebeat-ubuntu.yml` dosyasında yapılan değişiklikler:

- **`ignore_older: 168h`**: Sadece son 7 günlük logları oku
- **Timestamp parsing**: Log içindeki tarihleri doğru parse et
- **Event filtering**: 2025 Temmuz'dan önceki logları otomatik atla
- **File information**: Log kaydının hangi dosyadan geldiğini göster
- **Index Lifecycle Management**: 14 gün sonra Elasticsearch'teki logları otomatik sil

### 2. Log Temizlik Scripti

`cleanup-old-logs.sh` scripti:
- 14 günden eski Docker container log dosyalarını siler
- Journald loglarını temizler
- Docker system prune yapar
- Disk kullanımını gösterir

### 3. Basitleştirilmiş Yapı

Registry yönetimi kaldırıldı:
- Filebeat her restart'ta logları yeniden okur
- Daha basit ve temiz yapı
- Registry dosyası yönetimi gerekmez

## Kullanım

### İlk Kurulum
```bash
# 1. Eski logları temizle
./cleanup-old-logs.sh

# 2. Filebeat'i başlat
./run-ubuntu.sh
```

### Günlük Bakım
```bash
# Eski logları temizle (crontab'a ekleyin)
0 2 * * * /path/to/cleanup-old-logs.sh
```

### Sorun Giderme
```bash
# Container'ı yeniden başlat
docker restart filebeat

# Container loglarını kontrol et
docker logs filebeat

# Filebeat konfigürasyon testi
docker exec filebeat filebeat test config
```

## Konfigürasyon Detayları

### Log Retention Ayarları
- **Filebeat**: 7 gün (`ignore_older: 168h`)
- **Elasticsearch**: 14 gün (ILM policy)
- **Docker**: 14 gün (cleanup script)

### Timestamp Parsing
Desteklenen formatlar:
- `2006-01-02T15:04:05.000000000Z`
- `2006-01-02T15:04:05Z`
- `2006-01-02 15:04:05`
- `Mon Jan 02 15:04:05 UTC 2006`
- `Tue Aug 26 06:02:39 UTC 2025`

### Filtreleme Kuralları
1. **Global**: 2025 Temmuz'dan önceki tüm loglar atlanır
2. **Dosya yaşı**: 7 günden eski dosyalar okunmaz

## Monitoring

### Kibana'da Kontrol
- URL: https://kibana.emm-cyber.de
- Index pattern: `docker-logs-*`
- Kullanıcı: `kibana_user`
- Şifre: `KibanaPass123!`

### Log Türleri
- `docker_container`: Container logları
- `system`: Sistem logları
- `application`: Uygulama logları

### Dosya Bilgileri
Her log kaydında şu dosya bilgileri bulunur:
- `log.file.path`: Tam dosya yolu
- `log.file.name`: Dosya adı
- `source_file_path`: Kaynak dosya yolu
- `source_file_name`: Kaynak dosya adı
- `container_log_source`: Container log dosyası yolu
- `log_file_path`: Log dosyası yolu
- `log_file_name`: Log dosyası adı

## Önemli Notlar

⚠️ **Dikkat**: 
- Cleanup script'i çalıştırmadan önce backup alın
- ILM policy Elasticsearch'te otomatik oluşturulur
- Filebeat her restart'ta logları yeniden okur

✅ **Avantajlar**:
- 2025 Temmuz'dan önceki loglar artık Elasticsearch'e gönderilmez
- Disk alanı otomatik temizlenir
- Timestamp'ler doğru parse edilir
- 14 günlük retention policy uygulanır
- Basitleştirilmiş yapı, registry yönetimi gerekmez
