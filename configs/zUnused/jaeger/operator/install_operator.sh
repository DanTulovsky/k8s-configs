kubectl create namespace observability
kubectl create -f jaegertracing.io_jaegers_crd.yaml
kubectl create -n observability -f service_account.yaml
kubectl create -n observability -f role.yaml
kubectl create -n observability -f role_binding.yaml
kubectl create -n observability -f operator.yaml
kubectl create -f cluster_role.yaml
kubectl create -f cluster_role_binding.yaml
