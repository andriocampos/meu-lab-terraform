# 🚀 Lab Terraform — CI/CD, GitOps & AWS

Repositório de portfólio que demonstra práticas reais de **CI/CD**, **GitOps** e **Infrastructure as Code (IaC)** no ecossistema AWS. Cada módulo é um laboratório funcional que pode ser provisionado e destruído com um clique via GitHub Actions.

---

## 🎯 O que este repositório demonstra

| Competência | Implementação |
|---|---|
| **CI/CD** | Pipelines automatizadas com GitHub Actions (plan em PR, apply na main) |
| **GitOps** | Infraestrutura versionada no Git — toda mudança passa por workflow |
| **IaC** | Terraform modular (VPC, EC2, IAM, S3) com state management |
| **Configuração** | Ansible com roles idempotentes (Docker, Deploy, Validate) |
| **Segurança** | Autenticação sem credenciais estáticas via OIDC (keyless) |
| **Observabilidade** | Stack de monitoramento (Prometheus + Grafana) provisionada automaticamente |
| **FinOps** | Estimativa de custo/hora exibida ao final de cada deploy |

---

## 📐 Arquitetura — Pipeline One-Click

```
┌──────────────────────────────────────────────────────────────────┐
│                        GitHub Actions                              │
│                                                                    │
│   ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐  │
│   │  Terraform  │───▶│    Ansible   │───▶│ Validação + Custo  │  │
│   │  (Infra)    │    │  (Config)    │    │ (Job Summary)      │  │
│   └─────────────┘    └──────────────┘    └────────────────────┘  │
│         │                    │                                     │
└─────────┼────────────────────┼────────────────────────────────────┘
          │                    │
          ▼                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                     AWS — us-east-1                                │
│                                                                    │
│   ┌────────────────── VPC 10.70.0.0/16 ──────────────────────┐   │
│   │                                                            │   │
│   │   Subnet Pública (10.70.1.0/24) ─── Internet Gateway      │   │
│   │   │                                                        │   │
│   │   └── EC2 (t3.micro)                                      │   │
│   │       ├── Nginx (Reverse Proxy :80)                        │   │
│   │       ├── Go API (/api-info)                               │   │
│   │       ├── Prometheus (/prometheus)                         │   │
│   │       └── Grafana (/grafana)                               │   │
│   │                                                            │   │
│   └────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura do Repositório

```
.
├── .github/workflows/
│   ├── deploy-sre-demo.yml     # 🚀 Pipeline principal (apply/destroy one-click)
│   ├── lab-s3.yml              # Lab S3 com dispatch manual
│   ├── test-oidc.yml           # Teste de autenticação OIDC
│   └── desagio-labs3.yml       # Primeiro workflow didático
│
├── infra-demo/                  # Módulo principal — VPC + EC2 + Ansible
│   ├── versions.tf             # Terraform >= 1.5.7, backend S3 dinâmico
│   ├── provider.tf             # AWS provider (us-east-1)
│   ├── variables.tf            # Variáveis parametrizáveis
│   ├── vpc.tf                  # VPC + Subnet + IGW + Route Table
│   ├── ec2.tf                  # Security Group + Key Pair + EC2
│   ├── outputs.tf              # IP público, instance ID, chave SSH
│   └── ansible/                # Automação de configuração
│       ├── playbook.yml
│       └── roles/
│           ├── docker/         # Instalação Docker (Debian/RedHat)
│           ├── deploy/         # Build + Docker Compose (App + Monitoramento)
│           └── validate/       # Testa endpoints + rollback automático
│
├── aws-github-auth/             # OIDC Provider + IAM Role (GitHub → AWS)
│   └── oidc.tf
│
├── infra/                       # Módulo VPC avançado (multi-AZ, for_each)
│   ├── vpc.tf
│   └── variables.tf
│
├── desafios-lab/                # Labs isolados
│   └── lab-s3/                  # Bucket S3 com random suffix
│
└── docs/                        # Documentação técnica
    ├── ec2-iam-role-instance-profile.md
    └── guia-github-actions.md
```

---

## ⚡ Como usar

### Deploy completo (one-click)

1. Acesse **Actions** → **🚀 SRE Demo - Deploy/Destroy**
2. Clique **Run workflow** → selecione `apply`
3. Aguarde ~5 minutos
4. Acesse os links no **Job Summary**

### Destruir tudo

1. Mesmo workflow → selecione `destroy`
2. Remove **toda** a infraestrutura + bucket de state

### Resultado esperado

Ao final do apply, o Job Summary exibe:

| Serviço | URL |
|---------|-----|
| Aplicação | `http://<IP>/api-info` |
| Grafana | `http://<IP>/grafana/` (admin/admin) |
| Prometheus | `http://<IP>/prometheus/` |

E a estimativa de custo:

| Recurso | Custo/hora |
|---------|-----------|
| EC2 t3.micro | $0.0104 |
| EBS 20GB gp3 | $0.0022 |
| **TOTAL** | **$0.0126/hr (~R$ 0.07/hr)** |

---

## 🔐 Segurança

- **Zero credenciais estáticas** — Autenticação via OIDC (GitHub ↔ AWS)
- **Least privilege no scope** — Role assume restrita ao repositório específico
- **Chave SSH efêmera** — Gerada pelo Terraform a cada deploy, nunca persiste
- **State isolado** — Bucket S3 criado e destruído junto com a infra

---

## 🛠️ Tecnologias

| Categoria | Ferramenta |
|-----------|-----------|
| IaC | Terraform 1.5.7 |
| Config Management | Ansible |
| CI/CD | GitHub Actions |
| Cloud | AWS (VPC, EC2, IAM, S3) |
| Containers | Docker + Docker Compose |
| Aplicação | Go (HTTP server com métricas) |
| Monitoramento | Prometheus + Grafana |
| Reverse Proxy | Nginx |
| Autenticação | OpenID Connect (OIDC) |

---

## 📊 Workflows disponíveis

| Workflow | Trigger | Descrição |
|----------|---------|-----------|
| `deploy-sre-demo.yml` | Manual (apply/destroy) | Pipeline completa: Infra + Config + Validação |
| `lab-s3.yml` | Manual (apply/destroy) | Cria/destrói bucket S3 |
| `test-oidc.yml` | Manual | Valida autenticação OIDC com `sts get-caller-identity` |

---

## 🧠 Decisões técnicas

| Decisão | Justificativa |
|---------|---------------|
| Backend S3 efêmero | Lab descartável — state criado e destruído junto com a infra |
| `t3.micro` | Suficiente para demo, custo mínimo ($0.012/hr) |
| Ansible via SSH (não SSM) | Demonstra configuração clássica + key management |
| Validação com rollback | Se algum serviço não responde, o Ansible desfaz o deploy |
| `terraform_wrapper: false` | Permite capturar outputs diretamente no workflow |
| `tls_private_key` no Terraform | Chave efêmera — não precisa de secrets management para lab |

---

## 📚 Documentação adicional

- [EC2 IAM Roles & Instance Profiles](docs/ec2-iam-role-instance-profile.md)
- [Guia GitHub Actions](docs/guia-github-actions.md)

---

## 👤 Autor

**Andrio Campos**
SRE | DevOps | AWS

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://linkedin.com/in/andriocampos)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat&logo=github)](https://github.com/andriocampos)
