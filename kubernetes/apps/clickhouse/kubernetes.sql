CREATE TABLE k8s.logs_mv_target
(
    timestamp DateTime64(9),
    body String,
    level UInt8,
    labels Map(String, String),
    image_name String,
    image_tag String,
    pod_name String,
    pod_start_time String,
    container_name String,
    container_restart_count String,
    workload_type String,
    workload String,
    workload_uid String,
    namespace String,
    node_name String,
    cluster_uid String,
    severity_text String
)
ENGINE = MergeTree()
ORDER BY (timestamp, namespace, workload)
PARTITION BY toYYYYMM(timestamp);

CREATE MATERIALIZED VIEW k8s.logs TO k8s.logs_mv_target AS
SELECT 
    Timestamp as timestamp,
    Body as body,
    SeverityNumber as level,
    map(
        'namespace', namespace,
        'workload_name', workload,
        'workload_type', workload_type,
        'container_name', container_name
    ) as labels,
		LogAttributes,
    -- Image
    ResourceAttributes['container.image.name'] as image_name,
    ResourceAttributes['container.image.tag'] as image_tag,
    -- Pod
    ResourceAttributes['k8s.pod.name'] as pod_name,
    ResourceAttributes['k8s.pod.start_time'] as pod_start_time,
    -- Container  
    ResourceAttributes['k8s.container.name'] as container_name,
    ResourceAttributes['k8s.container.restart_count'] as container_restart_count,
    -- Workload
    CASE 
        WHEN ResourceAttributes['k8s.deployment.name'] != '' THEN 'Deployment'
        WHEN ResourceAttributes['k8s.statefulset.name'] != '' THEN 'StatefulSet'  
        WHEN ResourceAttributes['k8s.daemonset.name'] != '' THEN 'DaemonSet'
        WHEN ResourceAttributes['k8s.replicaset.name'] != '' THEN 'ReplicaSet'
        ELSE 'Unknown'
    END as workload_type,
    CASE 
        WHEN ResourceAttributes['k8s.deployment.name'] != '' THEN ResourceAttributes['k8s.deployment.name']
        WHEN ResourceAttributes['k8s.statefulset.name'] != '' THEN ResourceAttributes['k8s.statefulset.name']
        WHEN ResourceAttributes['k8s.daemonset.name'] != '' THEN ResourceAttributes['k8s.daemonset.name']
        WHEN ResourceAttributes['k8s.replicaset.name'] != '' THEN ResourceAttributes['k8s.replicaset.name']
        ELSE 'Unknown'
    END as workload,
    coalesce(
        ResourceAttributes['k8s.replicaset.uid'],
        ResourceAttributes['k8s.statefulset.uid'],
        ResourceAttributes['k8s.daemonset.uid']
    ) as workload_uid,
    -- Misc
    ResourceAttributes['k8s.namespace.name'] as namespace,
    ResourceAttributes['k8s.node.name'] as node_name,
    ResourceAttributes['k8s.cluster.uid'] as cluster_uid,
    SeverityText as severity_text
FROM otel_logs
WHERE ResourceAttributes['k8s.namespace.name'] != '';

-- Query the processed data
SELECT * FROM k8s_logs_processed;



SELECT 
  *
FROM (
  SELECT 
    Timestamp as timestamp,
    Body as body,
    SeverityNumber as level,
    map(
      'namespace', namespace,
      'workload_name', workload,
      'workload_type', workload_type,
      'container_name', container_name
    ) as labels,

		LogAttributes,

	 -- Image
    ResourceAttributes['container.image.name'] as image_name,
    ResourceAttributes['container.image.tag'] as image_tag,
    -- Pod
    ResourceAttributes['k8s.pod.name'] as pod_name,
    ResourceAttributes['k8s.pod.start_time'] as pod_start_time,
    -- Container  
    ResourceAttributes['k8s.container.name'] as container_name,
    ResourceAttributes['k8s.container.restart_count'] as container_restart_count,

    -- Workload
    CASE 
      WHEN ResourceAttributes['k8s.deployment.name'] != '' THEN 'Deployment'
      WHEN ResourceAttributes['k8s.statefulset.name'] != '' THEN 'StatefulSet'  
      WHEN ResourceAttributes['k8s.daemonset.name'] != '' THEN 'DaemonSet'
      WHEN ResourceAttributes['k8s.replicaset.name'] != '' THEN 'ReplicaSet'
      ELSE 'Unknown'
    END as workload_type,
    CASE 
      WHEN ResourceAttributes['k8s.deployment.name'] != '' THEN ResourceAttributes['k8s.deployment.name']
      WHEN ResourceAttributes['k8s.statefulset.name'] != '' THEN ResourceAttributes['k8s.statefulset.name']
      WHEN ResourceAttributes['k8s.daemonset.name'] != '' THEN ResourceAttributes['k8s.daemonset.name']
      WHEN ResourceAttributes['k8s.replicaset.name'] != '' THEN ResourceAttributes['k8s.replicaset.name']
      ELSE 'Unknown'
    END as workload,
     Coalesce(
      ResourceAttributes['k8s.replicaset.uid'] as replicaset_uid,
      ResourceAttributes['k8s.statefulset.uid'] as statefulset_uid,
      ResourceAttributes['k8s.daemonset.uid'] as daemonset_uid
    ) as workload_uid,

     -- Misc
    ResourceAttributes['k8s.namespace.name'] as namespace,
    ResourceAttributes['k8s.node.name'] as node_name,
    ResourceAttributes['k8s.cluster.uid'] as cluster_uid,
    SeverityText
    -- ResourceAttributes['k8s.app.instance'] as app_instance,
    -- ResourceAttributes['k8s.app.component'] as app_component

  FROM otel_logs
  WHERE ResourceAttributes['k8s.namespace.name'] != ''
)'
