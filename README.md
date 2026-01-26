# Terraform + GitHub Actions + Cloudflare R2 для развертывания Kubernetes в Timeweb Cloud

## 📋 О проекте

Этот проект содержит Terraform-конфигурацию для создания кластера Kubernetes в Timeweb Cloud с интеграцией CloudFlare для управления DNS и R2 для хранения состояния Terraform.

## 🏗️ Архитектура

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   GitHub        │     │   Cloudflare    │     │   Timeweb Cloud │
│   Repository    │────▶│   R2 + DNS      │────▶│   Kubernetes    │
│                 │     │                 │     │   Cluster       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
       │                                                │
       └───── CI/CD Pipeline (GitHub Actions) ─────────┘
```

## 📁 Структура проекта

```
.
├── .github/workflows/          # GitHub Actions workflow
│   ├── terraform-apply.yml     # Workflow для деплоя
│   └── terraform-destroy.yml   # Workflow для удаления инфраструктуры
├── backend.tf                  # Конфигурация удаленного бэкенда
├── k8s-cluster.tf             # Ресурсы Kubernetes кластера
├── main.tf                    # Основная конфигурация Terraform
├── variables.tf               # Переменные Terraform
├── .gitignore                 # Игнорируемые файлы
└── README.md                  # Эта документация
```

## Архитектура кластера

- **1 мастер-нода**: Используется первый доступный пресет типа "master"
- **2 воркер-ноды**: Используется первый доступный пресет типа "worker"
- **VPC сеть**: 192.168.0.0/16 для изоляции
- **R2 хранилище**: S3-совместимое хранилище CloudFlare для хранения tfstate

## 🚀 Быстрый старт

### 1. Предварительные требования

- Учетная запись [Timeweb Cloud](https://timeweb.cloud/) с API токеном
- Учетная запись [Cloudflare](https://dash.cloudflare.com/) с:
  - Зарегистрированным доменом
  - API токеном
  - Account ID
  - R2 bucket "terraform-state"
- [GitHub](https://github.com/) репозиторий
- Установленный Terraform (>= 0.13)
- **kubectl** для управления кластером

### 2. Клонирование и настройка

```bash
# Клонировать репозиторий
git clone <your-repo-url>
cd infra
```

### 3. Настройка переменных

Создайте файл `terraform.tfvars` (не добавляйте в Git):

```hcl
# terraform.tfvars
timeweb_token = "ваш_timeweb_api_токен"
cloudflare_api_token = "ваш_cloudflare_api_токен"
cloudflare_account_id = "ваш_cloudflare_account_id"
domain_name = "ваш-домен.рф"
cluster_name = "production-k8s"
worker_count = 2
```

## 🔧 Настройка окружения

### GitHub Secrets

Добавьте в настройках репозитория (Settings → Secrets and variables → Actions):

| Secret Name | Описание |
|-------------|----------|
| `TIMEWEB_TOKEN` | API токен Timeweb Cloud |
| `CLOUDFLARE_API_TOKEN` | API токен Cloudflare (с правами на DNS и R2) |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID Cloudflare |
| `R2_ACCESS_KEY_ID` | Access Key для R2 |
| `R2_SECRET_ACCESS_KEY` | Secret Key для R2 |
| `AWS_ENDPOINT_URL_S3` | Endpoint URL для R2 |

### Cloudflare R2 Bucket

1. Перейдите в [Cloudflare R2](https://dash.cloudflare.com/?to=/:account/r2)
2. Создайте bucket с именем `terraform-state`
3. Создайте API токен с правами на чтение/запись:
   - Включите "Object Read & Write"
   - Укажите нужный bucket

### Timeweb Cloud API токен

1. Перейдите в [Timeweb Cloud](https://timeweb.cloud/)
2. Создайте API токен с правами:
   - Управление VPC
   - Управление Kubernetes
   - Управление Floating IP

### Настройка переменных для CloudFlare

**Вариант 1: Через переменные окружения (рекомендуется для production)**

```bash
export CLOUDFLARE_API_TOKEN="ваш_cloudflare_api_token"
export CLOUDFLARE_EMAIL="ваш_email@domain.com"
```

**Вариант 2: Через файл (для локального тестирования)**

Создайте файл `cloudflare.auto.tfvars`:

```hcl
cloudflare_api_token = "ваш_cloudflare_api_token"
cloudflare_email    = "ваш_email@domain.com"
```

⚠️ **Важно**: Добавьте `cloudflare.auto.tfvars` в `.gitignore`, чтобы не.commitить токены в репозиторий:

```bash
echo "cloudflare.auto.tfvars" >> .gitignore
```

### Получение CloudFlare API Token

1. Зайдите в [CloudFlare Dashboard](https://dash.cloudflare.com/)
2. Перейдите в **My Profile** → **API Tokens**
3. Создайте новый токен с правами:
   - Zone.Zone: Read
   - Zone.DNS: Edit
4. Скопируйте токен и используйте в переменных окружения или файле `cloudflare.auto.tfvars`

### Настройка R2 для хранения tfstate

Для хранения состояния Terraform используется CloudFlare R2 - S3-совместимое хранилище.

#### Создание R2 Bucket

1. Зайдите в [CloudFlare Dashboard](https://dash.cloudflare.com/)
2. Перейдите в раздел **R2**
3. Создайте новый Bucket с именем `terraform-state` (или другим, соответствующим вашей конфигурации)
4. Запомните имя вашего Bucket

#### Получение учетных данных R2

1. В CloudFlare Dashboard перейдите в раздел **R2**
2. Нажмите "Manage R2 API Tokens"
3. Создайте или используйте существующие Access Key ID и Secret Access Key

#### Настройка локальной конфигурации

Конфигурация R2 бэкенда находится в файле `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "kubernetes-cluster/terraform.tfstate"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    use_path_style              = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
```

## 📊 Переменные Terraform

Основные переменные (полный список в `variables.tf`):

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `cluster_name` | `"my-k8s-cluster"` | Имя Kubernetes кластера |
| `k8s_version` | `"v1.34.3+k0s.0"` | Версия Kubernetes |
| `worker_count` | `2` | Количество worker-нод |
| `location` | `"ru-1"` | Локация дата-центра |
| `availability_zone` | `"spb-3"` | Зона доступности серверов и Floating IP |
| `vpc_subnet` | `"192.168.0.0/16"` | CIDR подсети VPC |
| `domain_name` | `"vovanbl411.qzz.io"` | Ваш домен |
| `timeweb_token` | `""` | API токен Timeweb Cloud |
| `cloudflare_api_token` | `""` | API токен CloudFlare |

## 🔄 Рабочие процессы

### GitHub Actions Workflow

Workflow автоматически выполняется при:
- Push в ветку `main` → `terraform apply`
- Pull request → `terraform plan`

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    # Общие переменные для всех шагов
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: "auto"
      TF_VAR_timeweb_token: ${{ secrets.TIMEWEB_TOKEN }}
      TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      TF_VAR_cloudflare_account_id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
      R2_ENDPOINT: ${{ secrets.AWS_ENDPOINT_URL_S3 }}

    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.12.1
        
    - name: Terraform Init
      run: |
        terraform init \
          -backend-config="bucket=${{ vars.R2_BUCKET || 'terraform-state' }}" \
          -backend-config="key=kubernetes-cluster/terraform.tfstate" \
          -backend-config="endpoint=${{ env.R2_ENDPOINT }}" \
          -backend-config="access_key=${{ env.AWS_ACCESS_KEY_ID }}" \
          -backend-config="secret_key=${{ env.AWS_SECRET_ACCESS_KEY }}" \
          -backend-config="skip_credentials_validation=true" \
          -backend-config="skip_region_validation=true" \
          -backend-config="skip_metadata_api_check=true" \
          -backend-config="use_path_style=true" \
          -backend-config="skip_requesting_account_id=true" \
          -reconfigure
    
    - name: Terraform Validate
      run: terraform validate
      
    - name: Terraform Plan
      run: terraform plan
        
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve

    - name: Upload Inventory
      uses: actions/upload-artifact@v4
      with:
        name: ansible-inventory
        path: inventory.ini
```

### Удаление инфраструктуры

Для удаления инфраструктуры можно использовать workflow `terraform-destroy.yml`, который запускается вручную:

```yaml
name: Terraform Destroy

on:
  workflow_dispatch: # Позволяет запустить удаление вручную кнопкой в интерфейсе

jobs:
  terraform-destroy:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: "auto"
      TF_VAR_timeweb_token: ${{ secrets.TIMEWEB_TOKEN }}
      TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      TF_VAR_cloudflare_account_id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
      R2_ENDPOINT: ${{ secrets.AWS_ENDPOINT_URL_S3 }}

    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.12.1
        
    - name: Terraform Init
      run: |
        terraform init \
          -backend-config="bucket=${{ vars.R2_BUCKET || 'terraform-state' }}" \
          -backend-config="key=kubernetes-cluster/terraform.tfstate" \
          -backend-config="endpoint=${{ env.R2_ENDPOINT }}" \
          -backend-config="access_key=${{ env.AWS_ACCESS_KEY_ID }}" \
          -backend-config="secret_key=${{ env.AWS_SECRET_ACCESS_KEY }}" \
          -backend-config="skip_credentials_validation=true" \
          -backend-config="skip_region_validation=true" \
          -backend-config="skip_metadata_api_check=true" \
          -backend-config="use_path_style=true" \
          -backend-config="skip_requesting_account_id=true" \
          -reconfigure
    
    - name: Terraform Destroy
      run: terraform destroy -auto-approve
```

### Локальная разработка

#### Вариант 1: Локальный бэкенд (рекомендуется для тестирования)

```bash
# Закомментируйте блок backend в backend.tf
terraform init
terraform plan -var-file=secrets.tfvars
```

#### Вариант 2: Удаленный бэкенд (R2)

```bash
# Настройте переменные окружения
export AWS_ACCESS_KEY_ID="ваш_r2_key"
export AWS_SECRET_ACCESS_KEY="ваш_r2_secret"
export AWS_ENDPOINT="https://ваш_account_id.r2.cloudflarestorage.com"
export AWS_REGION="auto"

# Инициализируйте с конфигурацией R2
terraform init -reconfigure \
  -backend-config="bucket=terraform-state" \
  -backend-config="key=kubernetes-cluster/terraform.tfstate" \
  -backend-config="endpoint=https://ваш_account_id.r2.cloudflarestorage.com" \
  -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
  -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="skip_requesting_account_id=true"
```

## 🛠️ Полезные команды

```bash
# Форматирование кода
terraform fmt -recursive

# Валидация конфигурации
terraform validate


# План с локальными переменными
terraform plan -var-file=secrets.tfvars

# Применение изменений
terraform apply -auto-approve

# Уничтожение инфраструктуры
terraform destroy -var-file=secrets.tfvars

# Вывод информации о кластере
terraform output

# Обновить провайдеры
terraform init -upgrade
```

## 🔍 Что создается

При применении конфигурации создается:

1. **VPC** для изоляции сети кластера
2. **Kubernetes кластер** с master-нодой
3. **Worker node group** с заданным количеством нод
4. **Inventory файл** для Ansible (локально)

## Развертывание кластера

### 1. Инициализация Terraform с R2 бэкендом

Перед первой инициализацией убедитесь, что у вас есть учетные данные R2:

```bash
# Установите переменные окружения
export AWS_ACCESS_KEY_ID="ваш_r2_access_key_id"
export AWS_SECRET_ACCESS_KEY="ваш_r2_secret_access_key"
export AWS_DEFAULT_REGION="auto"
export AWS_ENDPOINT_URL_S3="https://ваш_account_id.r2.cloudflarestorage.com"

# Инициализируйте Terraform с конфигурацией R2 бэкенда
terraform init -reconfigure \
  -backend-config="bucket=terraform-state" \
  -backend-config="key=kubernetes-cluster/terraform.tfstate" \
  -backend-config="endpoint=$AWS_ENDPOINT_URL_S3" \
  -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
  -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="use_path_style=true" \
  -backend-config="skip_requesting_account_id=true"
```

### 2. Проверка плана

```bash
terraform plan
```

### 3. Применение конфигурации

```bash
terraform apply
```

Применение может занять 10-15 минут. Terraform будет создавать:
- VPC сеть
- Kubernetes кластер с мастер-нодой
- Группу воркер-нод (2 ноды)
- Состояние будет сохранено в R2
- Инвентарь Ansible будет создан локально

### 4. Получение kubeconfig

После успешного применения получите kubeconfig:

```bash
terraform output -raw raw_cluster_data.kubeconfig > kubeconfig.yaml
```

Или воспользуйтесь официальным клиентом Timeweb Cloud для получения kubeconfig.

### 5. Настройка kubectl

```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
```

### 6. Проверка состояния кластера

```bash
kubectl get nodes
kubectl get pods -A
```

## DNS Настройка

DNS-записи не создаются автоматически в текущей конфигурации, так как соответствующие ресурсы в k8s-cluster.tf закомментированы.


## SSL-сертификаты

### Вариант 1: CloudFlare Origin Certificate

1. В CloudFlare Dashboard перейдите в **SSL/TLS** → **Origin Server**
2. Создайте сертификат
3. Создайте секрет в Kubernetes:

```bash
kubectl create secret tls cloudflare-cert --cert=path/to/cert.pem --key=path/to/private.key
```

### Вариант 2: Let's Encrypt с cert-manager

Установите cert-manager:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```

Создайте ClusterIssuer для Let's Encrypt.

## Мониторинг

Установите Prometheus и Grafana:

```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

## Управление кластером

### Масштабирование воркер-нод

В файле `k8s-cluster.tf` измените `node_count`:

```hcl
resource "twc_k8s_node_group" "worker_nodes" {
  # ...
  node_count = 3  # Измените количество нод
}
```

Примените изменения:

```bash
terraform apply
```

### Обновление версии Kubernetes

Измените версию в `variables.tf`:

```hcl
variable "k8s_version" {
  description = "Kubernetes version"
 type        = string
 default     = "v1.34.3+k0s.0"  # Новая версия
}
```

### Автомасштабирование

Включите автомасштабирование:

```hcl
resource "twc_k8s_node_group" "worker_nodes" {
  # ...
  is_autoscaling = true
  min_size = 2
  max_size = 5
}
```

## Удаление кластера

```bash
terraform destroy
```

## Работа с R2 бэкендом

### Миграция с локального бэкенда

Если у вас уже есть локальный tfstate файл, и вы хотите перенести его в R2, выполните следующие шаги:

1. Временно измените конфигурацию бэкенда в `backend.tf` на локальную:
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

2. Выполните `terraform init` для загрузки локального состояния

3. Верните конфигурацию R2 в `backend.tf`

4. Снова выполните `terraform init` и подтвердите миграцию состояния


Убедитесь, что перед запуском команды заданы переменные окружения AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY с вашими учетными данными R2.

### Синхронизация состояния

Если вы работаете в команде, всегда синхронизируйте состояние перед применением изменений:

```bash
terraform refresh
```

### Резервное копирование состояния

Состояние автоматически сохраняется в R2, но вы можете экспортировать его вручную:

```bash
terraform state pull > terraform.tfstate.backup
```

## 📈 Мониторинг и логи

### Просмотр логов GitHub Actions
- Перейдите в репозитории на GitHub
- `Actions` → Выберите workflow → Выберите job

### Просмотр состояния R2
1. Перейдите в Cloudflare R2
2. Выберите bucket `terraform-state`
3. Файл состояния: `kubernetes-cluster/terraform.tfstate`

### Доступ к Kubernetes кластеру
```bash
# Получить kubeconfig
terraform output -raw raw_cluster_data.kubeconfig > kubeconfig.yaml

# Использовать с kubectl
kubectl --kubeconfig kubeconfig.yaml get nodes
```

## 🔐 Безопасность

### Что не должно попадать в Git
- Файлы `*.tfvars` с секретами
- Файлы состояния Terraform (`*.tfstate`)
- Конфигурационные файлы с credentials

### Управление секретами
- Используйте GitHub Secrets для CI/CD
- Используйте `.envrc` с `direnv` для локальной разработки
- Никогда не коммитьте секреты в репозиторий

## 🔄 Обновление

### Обновление версии Kubernetes
Измените переменную `k8s_version` в `terraform.tfvars`:
```hcl
k8s_version = "v1.35.0"  # Новая версия
```
Затем выполните `terraform apply`.

### Масштабирование кластера
Измените переменную `worker_count` и выполните `terraform apply`.

## 🚨 Устранение неполадок

### Проблемы с подключением

1. Проверьте kubeconfig:
   ```bash
   kubectl cluster-info
   ```

2. Проверьте статус нод:
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

### DNS проблемы

1. Проверьте DNS-записи в CloudFlare Dashboard
2. Используйте `nslookup` для проверки разрешения:
   ```bash
   nslookup k8s-api.vovanbl411.qzz.io
   ```

### Проблемы с API токенами

1. Убедитесь, что токены не истекли
2. Проверьте права доступа токенов
3. Пересоздайте токены при необходимости

### Проблемы с R2 бэкендом

1. Проверьте наличие учетных данных R2:
   ```bash
   echo $AWS_ACCESS_KEY_ID
   echo $AWS_SECRET_ACCESS_KEY
   ```
   
2. Убедитесь, что bucket существует и доступен
3. Проверьте права доступа к bucket


### Ошибка: "Missing region value"
**Решение:** Установите переменную окружения:
```bash
export AWS_REGION="auto"
```

### Ошибка: "Backend configuration changed"
**Решение:** Используйте миграцию состояния:
```bash
terraform init -migrate-state
```

### Ошибка: Invalid Attribute Combination
**Решение:** Убедитесь, что используется только один из `force_path_style` или `use_path_style`

## Стоимость

Примерная стоимость в месяц (на основе тарифов Timeweb Cloud):
- Мастер-нода: Зависит от выбранного пресета (первый доступный пресет типа "master")
- 2 воркер-ноды: Зависит от выбранного пресета (первый доступный пресет типа "worker")
- R2 Storage: Зависит от объема хранения и трафика (см. тарифы CloudFlare R2)
- Общий трафик: зависит от использования

## Поддержка

При возникновении проблем:
1. Проверьте логи Terraform: `terraform apply -debug`
2. Проверьте статус ресурсов в Timeweb Cloud панели
3. Проверьте логи Kubernetes: `kubectl logs -n kube-system`
4. Проверьте доступность R2 bucket и учетных данных

## 📚 Ресурсы

- [Документация Timeweb Cloud](https://timeweb.cloud/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте feature branch: `git checkout -b feature/amazing-feature`
3. Зафиксируйте изменения: `git commit -m 'Add amazing feature'`
4. Запушьте в ветку: `git push origin feature/amazing-feature`
5. Откройте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для деталей.

## 👥 Авторы

- Ваше имя/команда

---

**💡 Совет:** Регулярно выполняйте `terraform plan` для проверки изменений перед применением!

## Следующие шаги

1. Настройте CI/CD пайплайн с GitHub Actions
2. Добавьте мониторинг и алертинг
3. Настройте бэкапы кластера
4. Рассмотрите использование managed баз данных
5. Настройте логирование (ELK stack)

## Локальное тестирование

Вы можете протестировать конфигурацию локально перед пушем в репозиторий. Для этого:

1. Убедитесь, что у вас установлен Terraform
2. Настройте учетные данные для доступа к R2 и другим провайдерам
3. Для тестирования GitHub Actions workflow локально используйте инструмент `act`