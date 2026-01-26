# Документація проєкту - ФІНАЛЬНИЙ ПРОЕКТ AWS DevOps Infrastructure

## Структура інфраструктурного проєкту

Цей репозиторій містить повну Terraform-конфігурацію для розгортання комплексної інфраструктури в AWS. Проєкт поділений на окремі модулі для управління, розвитку та масштабування:

- **s3-backend** — інфраструктура для зберігання Terraform state та блокування
- **vpc** — створення мережевого оточення (VPC, приватні та публічні підмережі, маршрути)
- **ecr** — репозиторій контейнерів у AWS ECR
- **eks** — керований Kubernetes кластер на AWS з автоматичним масштабуванням
- **rds** — реляційна база даних з підтримкою Aurora та стандартного RDS
- **jenkins** — CI/CD сервер для автоматизації будування та розгортання
- **argo_cd** — GitOps інструмент для безперервного розгортання

### Модуль s3-backend

Модуль створює S3-бакет для Terraform-стану з увімкненим versioning і коректними правилами власності.
Також піднімається DynamoDB-таблиця (terraform_locks), що використовується для блокування state під час виконання terraform apply або plan.

### Модуль vpc

Модуль формує окрему VPC, яка містить:

- Публічні підмережі — доступні напряму з інтернету (кількість визначається змінною public_subnets).
- Приватні підмережі — працюють через NAT Gateway і не мають прямого доступу ззовні (залежно від private_subnets).

Реалізовано таблиці маршрутів:

- Публічні підмережі виходять в інтернет через Internet Gateway (IGW).
- Приватні підмережі використовують NAT Gateway для outbound-трафіку.

### Модуль ecr

Окремий модуль створює репозиторій контейнерів у ECR з автоматичним скануванням (scan_on_push).
Також додається IAM-політика, яка дозволяє читати та завантажувати образи в репозиторій.

### Модуль eks

Модуль розгортає керований Kubernetes кластер (Amazon EKS) з наступними компонентами:

- **EKS Cluster** — контрольна площина Kubernetes, керована AWS
- **Node Group** — група робочих вузлів з автоматичним масштабуванням
  - `desired_size` — поточна кількість вузлів
  - `min_size` — мінімальна кількість вузлів
  - `max_size` — максимальна кількість вузлів
- **EBS CSI Driver** — плагін для управління постійними томами
- **OIDC Provider** — для інтеграції з IAM для pod-ів

Також модуль налаштовує автоматичну інфраструктуру масштабування та збір логів у CloudWatch.

### Модуль jenkins

Модуль розгортає Jenkins у Kubernetes кластері з використанням Helm:

- **Jenkins Server** — головний сервер для CI/CD конвеєрів
- **Service Account** — налаштування IRSA (IAM Roles for Service Accounts)
- **Persistent Volume** — для збереження конфігурацій та історії збірок
- **Helm Chart** — з налаштованим values.yaml для автоматизації deployment

Jenkins налаштований на:

- Роботу з Git репозиторіями
- Інтеграцію з ECR для завантаження образів
- Взаємодію з EKS для розгортання контейнерів

### Модуль argo_cd

Модуль розгортає ArgoCD — GitOps інструмент для безперервного розгортання:

- **ArgoCD Server** — веб-інтерфейс для управління deployment'ами
- **ArgoCD Repo Server** — синхронізація з Git репозиторіями
- **ArgoCD Application Controller** — управління застосуваннями у Kubernetes
- **Custom Helm Chart** — для управління Application та Repository ресурсами

ArgoCD автоматично синхронізує стан кластера зі стану Git репозиторію і забезпечує:

- Декларативне управління конфігураціями
- Автоматичне розгортання при оновленнях
- Моніторинг та historiu deployment'ів

### Модуль rds

Модуль розгортає реляційну базу даних на AWS RDS з підтримкою двох режимів:

**Режим 1: Стандартний RDS (use_aurora = false)**

- Один екземпляр RDS (однозональний або Multi-AZ)
- Підходить для невеликих проектів та розробки
- Менш витратний, але менша масштабованість

**Режим 2: Aurora Cluster (use_aurora = true)**

- Повнофункціональний кластер з writer та reader інстансами
- Автоматична репліка та failover
- Масштабована читання через reader endpoint
- Рекомендується для production

#### Спільні ресурси

- DB Subnet Group — для розміщення БД в приватних підмережах
- Security Group — обмежена CIDR блоком VPC для безпеки
- Parameter Group — налаштування для обраного режиму (Aurora або стандартний RDS)

#### Основні змінні

- `use_aurora` — вибір між Aurora (true) та стандартним RDS (false)
- `vpc_cidr_block` — CIDR блок VPC для обмеження ingress правила
- `db_name` — ім'я бази даних
- `username` / `password` — облікові дані адміністратора
- `instance_class` — розмір інстанса (напр. db.t3.micro)
- `aurora_replica_count` — кількість reader реплік для Aurora
- `parameters` — custom параметри для Parameter Group
- `publicly_accessible` — чи доступна БД з публічної мережі

#### Приклад використання Aurora

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora        = true
  aurora_replica_count = 2
  name              = "app-db"
  db_name           = "production"
  username          = "admin"
  password          = var.db_password
  instance_class    = "db.t3.medium"
  engine_version_cluster = "15.3"

  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = module.vpc.vpc_cidr_block
  subnet_private_ids = module.vpc.private_subnet_ids

  tags = local.tags
}
```

#### Приклад використання стандартного RDS

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora     = false
  name           = "dev-db"
  db_name        = "development"
  username       = "admin"
  password       = var.db_password
  instance_class = "db.t3.micro"
  multi_az       = false

  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = module.vpc.vpc_cidr_block
  subnet_private_ids = module.vpc.private_subnet_ids

  tags = local.tags
}
```

#### Outputs

- `aurora_cluster_endpoint` — write endpoint для Aurora
- `aurora_reader_endpoint` — read-only endpoint для Aurora
- `rds_endpoint` — endpoint для стандартного RDS
- `database_port` — порт БД (5432 для PostgreSQL)
- `aurora_connection_url` — connection string для Aurora
- `rds_connection_url` — connection string для RDS
- `database_name` — ім'я БД
- `database_username` — ім'я користувача адміністратора

## Команди для ініціалізації та запуску

```
# Ініціалізація бекенду та плагінів
terraform init

# Перегляд плану змін
terraform plan

# Створення всієї інфраструктури
terraform apply

# Повне видалення ресурсів
terraform destroy
```

##

## Архітектура фінального проєкту

Проєкт формує повний stack для управління AWS інфраструктурою та контейнеризованими застосуваннями:

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Account                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                   │  │
│  │                                                      │  │
│  │  ┌─────────────────┐  ┌──────────────────┐          │  │
│  │  │  Public Subnets │  │ Private Subnets  │          │  │
│  │  │  (IGW Routing)  │  │ (NAT Routing)    │          │  │
│  │  └─────────────────┘  └──────────────────┘          │  │
│  │                                                      │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │         EKS Cluster                         │    │  │
│  │  │  ┌────────────────────────────────────┐    │    │  │
│  │  │  │ Jenkins (CI/CD Pipeline)           │    │    │  │
│  │  │  │ ArgoCD (GitOps Deployment)         │    │    │  │
│  │  │  │ Applications (Django etc.)         │    │    │  │
│  │  │  └────────────────────────────────────┘    │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                      │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ RDS Database (Aurora/PostgreSQL)             │   │  │
│  │  │ (Private Subnets)                           │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ ECR Registry (Container Images)                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│           S3 Backend + DynamoDB (State Management)           │
└──────────────────────────────────────────────────────────────┘
```

## Нотатки щодо запуску проєкту

Перед запуском усієї інфраструктури необхідно створити S3-бекенд і DynamoDB-таблицю, де Terraform зберігатиме свій стан.

Для цього:

1. Тимчасово закоментуйте всі модулі в main.tf, окрім s3-backend.
2. Закоментуйте увесь backend.tf.
3. Виконайте:

```
terraform init -reconfigure
terraform apply
```

Після цього:

- поверніть backend.tf,
- розкоментуйте всі інші модулі у main.tf,
- знову запустіть:

```
terraform init -reconfigure
```

## Перевірка Jenkins

У веб-інтерфейсі Jenkins після розгортання з’явиться джоба seed-job (взята з values Jenkins). Натискаю Build Now, після чого можна подивитись:

1. логи збірки
2. що було закомічено в інфра-репозиторій
3. чи з’явився новий образ у ECR

## Перегляд змін в Argo CD

У UI Argo CD можна відстежити оновлення Deployment’у. Після синхронізації з’являється новий pod

Якщо потрібно перевірити вручну:

```
kubectl get pods
kubectl logs <pod-name>
```
