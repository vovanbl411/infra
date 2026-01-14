# Диаграмма архитектуры

```mermaid
graph TB
    subgraph "Облачные провайдеры"
        TC[Timeweb Cloud]
        CF[CloudFlare]
    end
    
    subgraph "Компоненты инфраструктуры"
        VPC[VPC сеть<br/>10.100.0.0/16]
        
        subgraph "Kubernetes кластер"
            MK8S[Kubernetes кластер]
            MN[Мастер-нода]
            WN[Воркер-ноды]
        end
        
        FIP[Floating IP]
        DNS[DNS-записи в CloudFlare]
    end
    
    subgraph "Хранилище состояния"
        R2[CloudFlare R2]
        TFSTATE[Terraform State]
    end
    
    subgraph "Локальная среда"
        TF[Terraform]
        KCTL[kubectl]
    end
    
    subgraph "Пользовательские приложения"
        IC[Ingress Controller]
        TA[Тестовое приложение]
    end
    
    TC --> VPC
    VPC --> MK8S
    MK8S --> MN
    MK8S --> WN
    MK8S --> IC
    WN --> TA
    
    FIP <--> MK8S
    FIP --> DNS
    DNS --> CF
    
    R2 --> TFSTATE
    TF --> TFSTATE
    TF --> MK8S
    
    KCTL --> MK8S
    IC --> TA
    
    style TC fill:#e1f5fe
    style CF fill:#f3e5f5
    style R2 fill:#e8f5e8
    style TF fill:#fff3e0
    style KCTL fill:#fff3e0
</graph>
```

## Описание диаграммы

Диаграмма показывает архитектуру проекта, включающую:

1. **Облачные провайдеры**: Timeweb Cloud (где размещается кластер) и CloudFlare (для DNS и R2)
2. **Инфраструктурные компоненты**: VPC сеть, Kubernetes кластер с мастер- и воркер-нодами
3. **Сетевые компоненты**: Floating IP и DNS-записи для доступа к кластеру
4. **Хранилище состояния**: R2 используется для хранения состояния Terraform
5. **Локальные инструменты**: Terraform и kubectl для управления кластером
6. **Пользовательские приложения**: Ingress Controller и тестовое приложение

Связи между компонентами показывают взаимодействие и зависимости между различными частями системы.