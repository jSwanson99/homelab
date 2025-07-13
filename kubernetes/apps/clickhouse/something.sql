-- Query 1: Nodes Data
-- This query creates nodes for cluster -> namespace -> workload -> pod hierarchy
WITH 
	-- Extract attributes from ResourceAttributes map
	cluster_data AS (
		SELECT 
			ResourceAttributes['k8s.cluster.uid'] as cluster_id,
			ResourceAttributes['k8s.namespace.name'] as namespace,
			ResourceAttributes['k8s.pod.name'] as pod_name,
			-- Workload identification (prioritize in order: deployment, statefulset, daemonset, replicaset)
			COALESCE(
				ResourceAttributes['k8s.deployment.name'],
				ResourceAttributes['k8s.statefulset.name'],
				ResourceAttributes['k8s.daemonset.name'],
				ResourceAttributes['k8s.replicaset.name']
			) as workload_name,
			CASE
				WHEN ResourceAttributes['k8s.deployment.name'] != '' THEN 'deployment'
				WHEN ResourceAttributes['k8s.statefulset.name'] != '' THEN 'statefulset'
				WHEN ResourceAttributes['k8s.daemonset.name'] != '' THEN 'daemonset'
				WHEN ResourceAttributes['k8s.replicaset.name'] != '' THEN 'replicaset'
				ELSE 'unknown'
			END as workload_type,
			Timestamp
		FROM otel_logs
		WHERE $__timeFilter(Timestamp)
	),
	-- Calculate metrics for each level
	metrics AS (
		SELECT 
			cluster_id,
			namespace,
			workload_name,
			workload_type,
			pod_name,
			COUNT(*) as log_count,
			COUNT(*) / ( ($__toTime - $__fromTime) / 60 ) as logs_per_minute
		FROM cluster_data
		GROUP BY cluster_id, namespace, workload_name, pod_name
	)
-- Generate nodes for each level
SELECT 
	id,
	title,
	subtitle,
	logs_per_minute as "Transactions per second",
	0.5 as "Average duration", -- Placeholder
	0.95 as "Success", -- Placeholder
	0.05 as "Errors", -- Placeholder
	icon,
	noderadius,
	false as highlighted,
	logs_per_minute * 100 as "Test value"
FROM (
	-- Cluster level (root)
	SELECT 
		'cluster' as id,
		'Cluster' as title,
		'' as subtitle,
		SUM(logs_per_minute) as logs_per_minute,
		'database' as icon,
		40 as noderadius
	FROM metrics
	GROUP BY cluster_id
	
	UNION ALL
	
	-- Namespace level
	SELECT 
		'namespace:' || namespace as id,
		namespace as title,
		'namespace' as subtitle,
		SUM(logs_per_minute) as logs_per_minute,
		'folder' as icon,
		35 as noderadius
	FROM metrics
	GROUP BY namespace
	
	UNION ALL
	
	-- Workload level
	SELECT 
		'workload:' || namespace || ':' || workload_name as id,
		workload_name as title,
		workload_type as subtitle,
		SUM(logs_per_minute) as logs_per_minute,
		'layers' as icon,
		30 as noderadius
	FROM metrics
	WHERE workload_name IS NOT NULL
	GROUP BY namespace, workload_name
	
	UNION ALL
	
	-- Pod level
	SELECT 
		'pod:' || pod_name as id,
		pod_name as title,
		'pod' as subtitle,
		logs_per_minute,
		'box' as icon,
		25 as noderadius
	FROM metrics
)
ORDER BY id;


-- Query 2: Edges Data
-- This query creates edges between the hierarchical levels
WITH 
	cluster_data AS (
		SELECT 
			ResourceAttributes['k8s.cluster.uid'] as cluster_id,
			ResourceAttributes['k8s.namespace.name'] as namespace,
			ResourceAttributes['k8s.pod.name'] as pod_name,
			COALESCE(
				ResourceAttributes['k8s.deployment.name'],
				ResourceAttributes['k8s.statefulset.name'],
				ResourceAttributes['k8s.daemonset.name'],
				ResourceAttributes['k8s.replicaset.name']
			) as workload_name,
			Timestamp
		FROM otel_logs
		WHERE Timestamp >= now() - INTERVAL 5 MINUTE
	),
	edge_metrics AS (
		SELECT 
			cluster_id,
			namespace,
			workload_name,
			pod_name,
			COUNT(*) as log_count,
			COUNT(*) / 300.0 as logs_per_second
		FROM cluster_data
		GROUP BY cluster_id, namespace, workload_name, workload_type, pod_name
	)
-- Generate edges
SELECT 
	id,
	source,
	target,
	mainstat,
	false as highlighted,
	thickness,
	'' as color,
	'' as strokedasharray
FROM (
	-- Cluster to Namespace edges
	SELECT 
		'cluster:' || cluster_id || '--namespace:' || namespace as id,
		'cluster:' || cluster_id as source,
		'namespace:' || namespace as target,
		ROUND(SUM(logs_per_second), 2) as mainstat,
		GREATEST(1, LEAST(10, ROUND(SUM(logs_per_second) / 10))) as thickness
	FROM edge_metrics
	GROUP BY cluster_id, namespace
	
	UNION ALL
	
	-- Namespace to Workload edges
	SELECT 
		'namespace:' || namespace || '--workload:' || namespace || ':' || workload_name as id,
		'namespace:' || namespace as source,
		'workload:' || namespace || ':' || workload_name as target,
		ROUND(SUM(logs_per_second), 2) as mainstat,
		GREATEST(1, LEAST(10, ROUND(SUM(logs_per_second) / 10))) as thickness
	FROM edge_metrics
	WHERE workload_name IS NOT NULL
	GROUP BY namespace, workload_name
	
	UNION ALL
	
	-- Workload to Pod edges
	SELECT 
		'workload:' || namespace || ':' || workload_name || '--pod:' || pod_name as id,
		'workload:' || namespace || ':' || workload_name as source,
		'pod:' || pod_name as target,
		ROUND(logs_per_second, 2) as mainstat,
		GREATEST(1, LEAST(10, ROUND(logs_per_second / 10))) as thickness
	FROM edge_metrics
	WHERE workload_name IS NOT NULL
)
ORDER BY id;
