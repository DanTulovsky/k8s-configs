kubectl delete -f jaegertracing.io_jaegers_crd.yaml
kubectl delete -n observability -f service_account.yaml
kubectl delete -n observability -f role.yaml
kubectl delete -n observability -f role_binding.yaml
kubectl delete -n observability -f operator.yaml
kubectl delete -f cluster_role.yaml
kubectl delete -f cluster_role_binding.yaml
