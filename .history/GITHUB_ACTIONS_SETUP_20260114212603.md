# Настройка GitHub Actions для использования R2 в качестве бэкенда Terraform

## Подготовка

1. Убедитесь, что у вас есть аккаунт CloudFlare и R2 Bucket
2. Создайте API токены и учетные данные для R2

## Настройка GitHub Secrets

В настройках репозитория добавьте следующие секреты:

- `CLOUDFLARE_API_TOKEN` - API токен CloudFlare с правами на управление DNS
- `CLOUDFLARE_ACCOUNT_ID` - ID аккаунта CloudFlare для доступа к R2
- `R2_ACCESS_KEY_ID` - Access Key ID для R2
- `R2_SECRET_ACCESS_KEY` - Secret Access Key для R2
- `TIMEWEB_TOKEN` - API токен Timeweb Cloud

## Файл конфигурации GitHub Actions

Создайте файл `.github/workflows/terraform.yml`:

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.12.1
        
    - name: Configure AWS credentials for R2
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.R2_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.R2_SECRET_ACCESS_KEY }}
        aws-region: auto
        
    - name: Set up AWS CLI for R2
      run: |
        aws configure set aws_access_key_id ${{ secrets.R2_ACCESS_KEY_ID }}
        aws configure set aws_secret_access_key ${{ secrets.R2_SECRET_ACCESS_KEY }}
        aws configure set region auto
        aws configure set output json
        
    - name: Terraform Init
      run: |
        export AWS_ACCESS_KEY_ID="${{ secrets.R2_ACCESS_KEY_ID }}"
        export AWS_SECRET_ACCESS_KEY="${{ secrets.R2_SECRET_ACCESS_KEY }}"
        export AWS_DEFAULT_REGION="auto"
        terraform init \
          -backend-config="bucket=${{ vars.R2_BUCKET || 'terraform-state' }}" \
          -backend-config="key=kubernetes-cluster/terraform.tfstate" \
          -backend-config="endpoints.s3=https://${{ secrets.CLOUDFLARE_ACCOUNT_ID }}.r2.cloudflarestorage.com" \
          -backend-config="skip_credentials_validation=true" \
          -backend-config="skip_region_validation=true" \
          -backend-config="skip_metadata_api_check=true" \
          -backend-config="force_path_style=true"
      
    - name: Terraform Validate
      run: terraform validate
      
    - name: Terraform Validate
      run: |
        export AWS_ACCESS_KEY_ID="${{ secrets.R2_ACCESS_KEY_ID }}"
        export AWS_SECRET_ACCESS_KEY="${{ secrets.R2_SECRET_ACCESS_KEY }}"
        terraform validate
      
    - name: Terraform Plan
      run: |
        export AWS_ACCESS_KEY_ID="${{ secrets.R2_ACCESS_KEY_ID }}"
        export AWS_SECRET_ACCESS_KEY="${{ secrets.R2_SECRET_ACCESS_KEY }}"
        terraform plan
      env:
        CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        TF_VAR_cloudflare_account_id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
        
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: |
        export AWS_ACCESS_KEY_ID="${{ secrets.R2_ACCESS_KEY_ID }}"
        export AWS_SECRET_ACCESS_KEY="${{ secrets.R2_SECRET_ACCESS_KEY }}"
        terraform apply -auto-approve
      env:
        CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        TF_VAR_cloudflare_account_id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
        TIMEWEB_TOKEN: ${{ secrets.TIMEWEB_TOKEN }}
```

## Локальная настройка (для тестирования)

Если вы хотите протестировать конфигурацию локально, создайте файл `r2-backend.conf`:

```hcl
endpoint = "https://<your-account-id>.r2.cloudflarestorage.com"
access_key = "<your-r2-access-key-id>"
secret_key = "<your-r2-secret-access-key>"
bucket = "terraform-state"
key = "kubernetes/terraform.tfstate"
region = "auto"
skip_credentials_validation = true
skip_region_validation      = true
skip_metadata_api_check     = true
use_path_style              = true
```

Затем инициализируйте Terraform с этим бэкендом:

```bash
terraform init -backend-config=r2-backend.conf
```

## Важные замечания

1. Убедитесь, что R2 bucket существует до начала работы
2. Учетные данные R2 должны иметь права на запись и чтение в указанный bucket
3. При первом запуске локально, возможно, придется сначала инициализировать с локальным бэкендом, а затем мигрировать на R2
4. Не забудьте обновить переменные в GitHub Actions в соответствии с вашими настройками

## Миграция существующего состояния

Если у вас уже есть локальный tfstate файл, и вы хотите перенести его в R2, выполните следующие шаги:

1. Временно закомментируйте текущую конфигурацию бэкенда в `backend.tf`
2. Добавьте временную локальную конфигурацию:
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```
3. Выполните `terraform init` для загрузки локального состояния
4. Раскомментируйте конфигурацию R2 и закомментируйте локальную
5. Снова выполните `terraform init` и подтвердите миграцию состояния

После этого ваше состояние будет храниться в R2.