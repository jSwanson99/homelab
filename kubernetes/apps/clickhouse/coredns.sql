CREATE DATABASE IF NOT EXISTS ip;

CREATE OR REPLACE TABLE ip.dns_mv_target (
  Time DateTime64(3, 'America/New_York'),
  level LowCardinality(String),
  client_ip IPv4,
  client_port UInt16,
  query_id UInt32,
  type LowCardinality(String),
  class LowCardinality(String),
  name String CODEC(ZSTD(3)),
  proto LowCardinality(String),
  req_size UInt32,
  dnssec_ok Bool,
  bufsize UInt32,
  rcode LowCardinality(String),
  flags Array(Tuple(String, UInt8)),
  rsize UInt16,
  duration_secs Float64,
  priority UInt16,
  hostname LowCardinality(String),
  pid UInt32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(Time)
ORDER BY (Time, type, hostname, client_ip)
SETTINGS index_granularity=8192;

DROP VIEW IF EXISTS ip.dns;


CREATE MATERIALIZED VIEW ip.dns
TO ip.dns_mv_target
AS
SELECT
  toDateTime64(Timestamp, 3, 'America/New_York') as Time,
  toLowCardinality(message[1]) as level,
  toIPv4OrNull(message[2]) as client_ip,
  toUInt16(message[3]) as client_port,
  toUInt32(message[4]) as query_id,
  toLowCardinality(message[5]) as type,
  toLowCardinality(message[6]) as class,
  toString(message[7]) as name,
  toLowCardinality(message[8]) as proto,
  toUInt32(message[9]) as req_size,
  toBool(message[10]) as dnssec_ok,
  toUInt32(message[11]) as bufsize,
  toLowCardinality(message[12]) as rcode,
  arrayMap(x -> (x, 1), splitByChar(',', message[13])) as flags,
  toUInt16(message[14]) as rsize,
  toFloat64(message[15]) as duration_secs,
  toUInt16(priority) as priority,
  toLowCardinality(hostname) as hostname,
  toUInt32(pid) as pid
FROM (
  SELECT
    Timestamp,
    extractAllGroups(JSONExtract(Body, 'MESSAGE', 'String'), '(\S+) (\S+):(\S+) - (\S+) \"(\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+)\" (\S+) (\S+) (\S+) ([0-9\.]+)')[1] as message,
    JSONExtract(Body, 'PRIORITY', 'Int16') as priority,
    JSONExtract(Body, '_HOSTNAME', 'String') as hostname,
    JSONExtract(Body, '_PID', 'Int32') as pid
  FROM otel_logs
	WHERE ServiceName = 'coredns'
)
WHERE message[1] = '[INFO]'

CREATE TABLE ip.arp_mv_target (
    Timestamp DateTime,
    ip IPv4,
    iface LowCardinality(String),
    macAddr FixedString(17),
    state LowCardinality(String)
) ENGINE = MergeTree()
ORDER BY (Timestamp, ip)
PARTITION BY toYYYYMMDD(Timestamp)
TTL Timestamp + INTERVAL 30 DAY;

CREATE MATERIALIZED VIEW ip.arp TO ip.arp_mv_target AS
SELECT 
    toStartOfMinute(Timestamp) as Timestamp,
    toIPv4(logParts[1][1]) as ip,
    toLowCardinality(logParts[2][1]) as iface,
    toFixedString(logParts[3][1], 17) as macAddr,
    toLowCardinality(logParts[4][1]) as state
FROM (
    SELECT 
        Timestamp, 
        extractAllGroups(Body, '(\S+)') as logParts
    FROM otel_logs
    WHERE ServiceName = 'vyos'
    AND LogAttributes['appname'] = 'ARP-TABLE'
)
WHERE isIPv4String(logParts[1][1]);
