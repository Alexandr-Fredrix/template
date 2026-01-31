# Kubernetes Manifests - Руководство и Шаблоны

## 📖 Что такое Kubernetes Manifests?

Kubernetes манифесты - это YAML файлы, описывающие желаемое состояние ресурсов в Kubernetes кластере. Kubernetes работает по принципу декларативного управления конфигурацией.

## 🏗️ Основные типы ресурсов

### Pod
Базовая единица развертывания:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

### Deployment
Управление репликами подов:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
```

### Service
Сетевой доступ к подам:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### Ingress
HTTP/HTTPS роутинг:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
```

### ConfigMap
Конфигурационные данные:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: postgres.default.svc.cluster.local
  LOG_LEVEL: info
  config.yaml: |
    server:
      port: 8080
      timeout: 30s
```

### Secret
Чувствительные данные:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DATABASE_PASSWORD: secretpassword
  API_KEY: your-api-key
# или base64 encoded:
# data:
#   DATABASE_PASSWORD: c2VjcmV0cGFzc3dvcmQ=
```

### PersistentVolume & PersistentVolumeClaim
Хранилище данных:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

## 🎯 Основные команды kubectl

```bash
# Применить манифест
kubectl apply -f manifest.yaml
kubectl apply -f directory/

# Удалить ресурс
kubectl delete -f manifest.yaml
kubectl delete deployment nginx

# Посмотреть ресурсы
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all

# Подробная информация
kubectl describe pod nginx-pod
kubectl describe deployment nginx

# Логи
kubectl logs pod-name
kubectl logs -f pod-name
kubectl logs pod-name -c container-name

# Выполнить команду в поде
kubectl exec -it pod-name -- /bin/bash
kubectl exec pod-name -- ls /app

# Port forwarding
kubectl port-forward pod/nginx-pod 8080:80
kubectl port-forward service/nginx-service 8080:80

# Масштабирование
kubectl scale deployment nginx --replicas=5

# Обновление образа
kubectl set image deployment/nginx nginx=nginx:1.22

# Статус rollout
kubectl rollout status deployment/nginx
kubectl rollout history deployment/nginx
kubectl rollout undo deployment/nginx

# Редактирование ресурса
kubectl edit deployment nginx

# Просмотр YAML
kubectl get deployment nginx -o yaml
kubectl get pod nginx-pod -o json

# Namespace
kubectl get pods -n production
kubectl create namespace staging
kubectl config set-context --current --namespace=production

# Labels и selectors
kubectl get pods -l app=nginx
kubectl label pod nginx-pod env=production

# Top (нужен metrics-server)
kubectl top nodes
kubectl top pods

# Debug
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
```

## 💡 Best Practices

### 1. Используйте labels
```yaml
metadata:
  labels:
    app: myapp
    tier: frontend
    environment: production
    version: v1.0.0
    managed-by: helm
```

### 2. Задавайте resource limits
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### 3. Используйте probes
```yaml
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### 4. Не запускайте от root
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### 5. Используйте ConfigMap для конфигурации
```yaml
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: app-config
    # или
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DATABASE_HOST
```

### 6. Используйте Secrets для паролей
```yaml
spec:
  containers:
  - name: app
    env:
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: DATABASE_PASSWORD
```

### 7. PodDisruptionBudget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

### 8. NetworkPolicy для безопасности
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
```

## 🔧 Расширенные возможности

### HorizontalPodAutoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### StatefulSet (для stateful приложений)
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### Job и CronJob
```yaml
# Job - одноразовая задача
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:latest
        command: ["python", "manage.py", "migrate"]
      restartPolicy: Never
  backoffLimit: 4

---
# CronJob - периодические задачи
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 2 * * *"  # Каждый день в 2:00
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup:latest
            command: ["./backup.sh"]
          restartPolicy: OnFailure
```

## 🔒 Безопасность

### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## 📚 Полезные ссылки

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
