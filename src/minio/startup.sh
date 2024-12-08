
chown -R svc-minio:svc-minio /etc/minio
systemctl daemon-reload

systemctl enable minio 
systemctl start minio
