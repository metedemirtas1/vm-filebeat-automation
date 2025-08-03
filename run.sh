#!/bin/bash

# Mevcut filebeat container'ını durdur ve sil (eğer varsa)
docker stop filebeat 2>/dev/null || true
docker rm filebeat 2>/dev/null || true

# Filebeat container'ını başlat (Ubuntu için optimize edilmiş)
docker run -d \
  --name filebeat \
  --user=root \
  -e ELASTIC_USERNAME=elastic \
  -e ELASTIC_PASSWORD=ElasticPass123! \
  --volume="$(pwd)/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro" \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --volume="/var/log:/var/log:ro" \
  --volume="/var/log/containers:/var/log/containers:ro" \
  --volume="/proc:/host/proc:ro" \
  --volume="/sys:/host/sys:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --network="host" \
  docker.elastic.co/beats/filebeat:8.11.0

echo "Filebeat container başlatıldı!"
echo "Logları kontrol etmek için: docker logs filebeat"
echo "Elasticsearch bağlantısını test etmek için: docker exec filebeat filebeat test output"
echo "Container durumunu kontrol etmek için: docker ps | grep filebeat"