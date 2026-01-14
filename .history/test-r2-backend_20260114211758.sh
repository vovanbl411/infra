#!/bin/bash

# Скрипт для локального тестирования конфигурации R2 бэкенда

echo "=== Тестирование конфигурации R2 бэкенда ==="

# Проверяем, установлен ли terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform не установлен. Пожалуйста, установите Terraform."
    exit 1
fi

# Проверяем, установлен ли jq (для парсинга JSON)
if ! command -v jq &> /dev/null; then
    echo "⚠️ JQ не установлен. Установите jq для лучшей валидации (не обязательно)."
fi

# Проверяем наличие необходимых переменных окружения
echo "Введите ваши учетные данные R2 (оставьте пустым для пропуска тестирования):"
read -p "CloudFlare Account ID: " CF_ACCOUNT_ID
if [ -z "$CF_ACCOUNT_ID" ]; then
    echo "❌ CloudFlare Account ID обязателен для тестирования."
    exit 1
fi

read -s -p "R2 Access Key ID: " R2_ACCESS_KEY_ID
echo
if [ -z "$R2_ACCESS_KEY_ID" ]; then
    echo "❌ R2 Access Key ID обязателен для тестирования."
    exit 1
fi

read -s -p "R2 Secret Access Key: " R2_SECRET_ACCESS_KEY
echo

read -p "R2 Bucket Name (по умолчанию terraform-state): " R2_BUCKET
R2_BUCKET=${R2_BUCKET:-terraform-state}

read -p "Ключ для состояния (по умолчанию kubernetes-cluster/terraform.tfstate): " R2_STATE_KEY
R2_STATE_KEY=${R2_STATE_KEY:-kubernetes-cluster/terraform.tfstate}

# Сохраняем временные значения в переменные окружения
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

# Создаем временный файл конфигурации бэкенда
cat > temp-backend-config.conf << EOF
endpoint = "https://$CF_ACCOUNT_ID.r2.cloudflarestorage.com"
bucket = "$R2_BUCKET"
key = "$R2_STATE_KEY"
region = "auto"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
EOF

echo "🔧 Временная конфигурация бэкенда создана..."

# Создаем временную конфигурацию terraform для тестирования
cat > temp-main.tf << EOF
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  description = "CloudFlare API token"
  type        = string
  sensitive   = true
}

output "test" {
  value = "Configuration is valid"
}
EOF

# Инициализируем Terraform с временной конфигурацией
echo "🔍 Инициализация Terraform с R2 бэкендом..."
terraform init -backend-config=temp-backend-config.conf -reconfigure || {
    echo "❌ Ошибка инициализации с R2 бэкендом"
    # Удаляем временные файлы
    rm -f temp-backend-config.conf temp-main.tf
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    exit 1
}

# Проверяем конфигурацию
echo "✅ Проверка конфигурации..."
terraform validate || {
    echo "❌ Ошибка валидации конфигурации"
    # Удаляем временные файлы
    rm -f temp-backend-config.conf temp-main.tf
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    exit 1
}

# Планируем изменения (без применения)
echo "📋 Планирование изменений..."
terraform plan || {
    echo "❌ Ошибка планирования изменений"
    # Удаляем временные файлы
    rm -f temp-backend-config.conf temp-main.tf
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    exit 1
}

echo "🎉 Тестирование конфигурации R2 бэкенда прошло успешно!"

# Удаляем временные файлы
rm -f temp-backend-config.conf temp-main.tf
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

echo "💡 Вы можете использовать эту конфигурацию в GitHub Actions"
echo "   Убедитесь, что ваши секреты правильно настроены в репозитории."