# Локальное тестирование GitHub Actions Workflow

Для локального тестирования GitHub Actions workflow можно использовать инструмент `act`, который позволяет запускать GitHub Actions на локальной машине.

## Установка act

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install act
```

### macOS:
```bash
brew install act
```

### Установка через GitHub Releases:
```bash
# Последнюю версию смотрите на https://github.com/nektos/act/releases
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

## Подготовка к локальному тестированию

1. Убедитесь, что у вас есть доступ к секретам, которые используются в workflow:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `TIMEWEB_TOKEN`

2. Создайте файл `.secrets` в корне проекта с необходимыми переменными:
```bash
CLOUDFLARE_API_TOKEN=ваш_токен
CLOUDFLARE_ACCOUNT_ID=ваш_account_id
R2_ACCESS_KEY_ID=ваш_access_key
R2_SECRET_ACCESS_KEY=ваш_secret_key
TIMEWEB_TOKEN=ваш_timeweb_token
```

## Запуск workflow локально

### Запуск всего workflow:
```bash
act -s CLOUDFLARE_API_TOKEN -s CLOUDFLARE_ACCOUNT_ID -s R2_ACCESS_KEY_ID -s R2_SECRET_ACCESS_KEY -s TIMEWEB_TOKEN
```

### Запуск конкретного job:
```bash
act terraform -s CLOUDFLARE_API_TOKEN -s CLOUDFLARE_ACCOUNT_ID -s R2_ACCESS_KEY_ID -s R2_SECRET_ACCESS_KEY -s TIMEWEB_TOKEN
```

### Запуск с конкретным event'ом (например, push в main):
```bash
act push -s CLOUDFLARE_API_TOKEN -s CLOUDFLARE_ACCOUNT_ID -s R2_ACCESS_KEY_ID -s R2_SECRET_ACCESS_KEY -s TIMEWEB_TOKEN
```

## Альтернативный способ - тестирование команд вручную

Вы можете протестировать команды из workflow по отдельности:

1. Установите AWS CLI и настройте его для работы с R2:
```bash
aws configure set aws_access_key_id ваш_r2_access_key_id
aws configure set aws_secret_access_key ваш_r2_secret_access_key
aws configure set region auto
aws configure set output json
```

2. Установите переменные окружения:
```bash
export AWS_ACCESS_KEY_ID="ваш_r2_access_key_id"
export AWS_SECRET_ACCESS_KEY="ваш_r2_secret_access_key"
export CLOUDFLARE_API_TOKEN="ваш_cloudflare_api_token"
export TIMEWEB_TOKEN="$(cat token.txt)"
```

3. Выполните инициализацию Terraform с конфигурацией R2 бэкенда:
```bash
terraform init \
  -backend-config="bucket=terraform-state" \
  -backend-config="key=kubernetes-cluster/terraform.tfstate" \
  -backend-config="endpoints.s3=https://ваш_account_id.r2.cloudflarestorage.com" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="force_path_style=true"
```

4. Проверьте конфигурацию:
```bash
terraform validate
```

5. Запустите планирование:
```bash
terraform plan
```

## Важные замечания

- При локальном тестировании убедитесь, что вы не случайно примените изменения (terraform apply), так как это создаст реальные ресурсы
- Для тестирования workflow рекомендуется использовать отдельную ветку и тестовый R2 bucket
- Убедитесь, что у ваших учетных данных достаточно прав для выполнения необходимых операций
- При использовании `act` могут возникнуть проблемы с доступом к локальным файлам, поэтому убедитесь, что контейнеры имеют доступ к рабочей директории

## Проверка конфигурации без запуска

Вы можете проверить синтаксис workflow файла:
```bash
# Проверка YAML синтаксиса
yamllint .github/workflows/terraform.yml

# Или используйте онлайн-валидатор YAML
```

Также можно проверить саму конфигурацию Terraform без инициализации бэкенда:
```bash
terraform validate
terraform fmt -check