# Docker Compose file for Wazuh with Open Distro for Elasticsearch and Kibana
services:
  wazuh:
    image: wazuh/wazuh-odfe:4.1.2
    hostname: wazuh-manager
    restart: always
    ports:
      - "1514:1514"
      - "1515:1515"
      - "514:514/udp"
      - "55000:55000"
    environment:
      - ELASTICSEARCH_URL=https://elasticsearch:9200
      - ELASTIC_USERNAME=admin
      - ELASTIC_PASSWORD=admin
      - FILEBEAT_SSL_VERIFICATION_MODE=none
    volumes:
      - ossec_api_configuration:/var/ossec/api/configuration
      - ossec_etc:/var/ossec/etc
      - ossec_logs:/var/ossec/logs
      - ossec_queue:/var/ossec/queue
      - ossec_var_multigroups:/var/ossec/var/multigroups
      - ossec_integrations:/var/ossec/integrations
      - ossec_active_response:/var/ossec/active-response/bin
      - ossec_agentless:/var/ossec/agentless
      - ossec_wodles:/var/ossec/wodles
      - filebeat_etc:/etc/filebeat
      - filebeat_var:/var/lib/filebeat

  elasticsearch:
    image: amazon/opendistro-for-elasticsearch:1.12.0
    hostname: elasticsearch
    restart: always
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - cluster.name=wazuh-cluster
      - network.host=0.0.0.0
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - bootstrap.memory_lock=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536

  kibana:
    image: wazuh/wazuh-kibana-odfe:4.1.2
    hostname: kibana
    restart: always
    ports:
      - 80:5601
    environment:
      - ELASTICSEARCH_USERNAME=admin
      - ELASTICSEARCH_PASSWORD=admin
      - SERVER_SSL_ENABLED=false
      - SERVER_SSL_CERTIFICATE=/usr/share/kibana/config/opendistroforelasticsearch.example.org.cert
      - SERVER_SSL_KEY=/usr/share/kibana/config/opendistroforelasticsearch.example.org.key

    depends_on:
      - elasticsearch
    links:
      - elasticsearch:elasticsearch
      - wazuh:wazuh

volumes:
  ossec_api_configuration:
  ossec_etc:
  ossec_logs:
  ossec_queue:
  ossec_var_multigroups:
  ossec_integrations:
  ossec_active_response:
  ossec_agentless:
  ossec_wodles:
  filebeat_etc:
  filebeat_var: