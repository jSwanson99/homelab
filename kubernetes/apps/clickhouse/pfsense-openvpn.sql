
CREATE MATERIALIZED VIEW connected_clients_timeseries
ENGINE = MergeTree()
PRIMARY KEY (server, user, address, timestamp)
ORDER BY (server, user, address, timestamp)
AS SELECT
  Timestamp as timestamp,
  extractAll(Body, 'server \'([^\']+)\'')[1] as server,
  extractAll(Body, 'user \'([^\']+)\'')[1] as user,
  extractAll(Body, 'address \'([^\']+)\'')[1] as address,
  CASE 
    WHEN Body LIKE '% - connected' THEN 1
    WHEN Body LIKE '% - disconnected' THEN -1
  END as connection_change
FROM otel_logs
WHERE ServiceName = 'pfsense'
  AND LogAttributes['process'] = 'openvpn'
  AND Body LIKE '%openvpn server%' 
  AND (Body LIKE '% - connected' OR Body LIKE '% - disconnected');
