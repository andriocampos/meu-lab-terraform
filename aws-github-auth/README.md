# Configuração OIDC — GitHub Actions ↔ AWS

## O que é

Esta pasta contém o Terraform que configura a autenticação **keyless** entre o GitHub Actions e a AWS. Com isso, os workflows assumem uma IAM Role via OIDC sem precisar de access keys estáticas.

---

## Arquitetura

```
GitHub Actions                         AWS
┌──────────────┐                      ┌────────────────────────────┐
│  Workflow     │  1. Solicita JWT     │                            │
│  (run)       │ ─────────────────►   │  OIDC Provider             │
│              │                      │  (token.actions.github...) │
│              │  2. Valida token      │         │                  │
│              │ ◄─────────────────   │         ▼                  │
│              │                      │  IAM Role                  │
│              │  3. Credenciais temp  │  (GitHubActionsRole-Lab)   │
│              │ ◄─────────────────   │         │                  │
│              │                      │         ▼                  │
│  usa AWS API │                      │  AdministratorAccess       │
└──────────────┘                      └────────────────────────────┘
```

---

## Componentes criados pelo Terraform

| Recurso | Nome | Função |
|---------|------|--------|
| `aws_iam_openid_connect_provider` | GitHub OIDC | Registra GitHub como identity provider na AWS |
| `aws_iam_role` | `GitHubActionsRole-Lab` | Role que os workflows assumem |
| Trust Policy | (inline na role) | Define QUAIS repos podem assumir a role |
| Policy Attachment | `AdministratorAccess` | Permissões concedidas (lab = admin) |

---

## Repositórios autorizados

A trust policy permite que estes repos assumam a role:

```json
"token.actions.githubusercontent.com:sub": [
  "repo:andriocampos/meu-lab-terraform:*",
  "repo:andriocampos/github-actions-curso:*"
]
```

Para adicionar um novo repo, edite o array em `oidc.tf` e aplique.

---

## Como usar

### Pré-requisitos

- AWS CLI configurada com o profile `conta-hotmail`
- Terraform instalado (>= 1.5.7)

### Verificar profiles disponíveis

```bash
cat ~/.aws/credentials
# Mostra:
# [default]         ← conta padrão
# [conta-hotmail]   ← conta onde o OIDC está configurado (590183934378)
```

### Comandos

```bash
cd aws-github-auth/

# Inicializar (só na primeira vez ou após mudanças no provider)
AWS_PROFILE=conta-hotmail terraform init

# Ver o que será alterado (sem aplicar)
AWS_PROFILE=conta-hotmail terraform plan

# Aplicar mudanças
AWS_PROFILE=conta-hotmail terraform apply

# Aplicar sem confirmação manual
AWS_PROFILE=conta-hotmail terraform apply -auto-approve

# Destruir tudo (remove OIDC + Role)
AWS_PROFILE=conta-hotmail terraform destroy
```

### Por que `AWS_PROFILE=conta-hotmail`?

Porque o profile `default` aponta para outra conta AWS (`129373676377`), mas o OIDC foi criado na conta `590183934378` (profile `conta-hotmail`). Sem especificar o profile, o Terraform tenta acessar a conta errada e dá erro 403.

**Alternativa:** Exportar antes de rodar vários comandos:

```bash
export AWS_PROFILE=conta-hotmail
terraform plan
terraform apply
# Todos usam conta-hotmail até fechar o terminal
```

---

## Configurar o Secret nos repositórios

Após criar/atualizar a role, configure o ARN como secret em cada repo que precisa de acesso:

```bash
# Para o repo meu-lab-terraform
cd /path/to/meu-lab-terraform
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::590183934378:role/GitHubActionsRole-Lab"

# Para o repo github-actions-curso
cd /path/to/github-actions-curso
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::590183934378:role/GitHubActionsRole-Lab"
```

O ARN da role é exibido como output do Terraform:

```bash
AWS_PROFILE=conta-hotmail terraform output github_actions_role_arn
# → arn:aws:iam::590183934378:role/GitHubActionsRole-Lab
```

---

## Como adicionar um novo repositório

1. Edite `oidc.tf` e adicione o repo no array:

```hcl
"token.actions.githubusercontent.com:sub" = [
  "repo:andriocampos/meu-lab-terraform:*",
  "repo:andriocampos/github-actions-curso:*",
  "repo:andriocampos/NOVO-REPO:*"           # ← adicionar aqui
]
```

2. Aplique:

```bash
AWS_PROFILE=conta-hotmail terraform apply
```

3. Configure o secret no novo repo:

```bash
cd /path/to/NOVO-REPO
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::590183934378:role/GitHubActionsRole-Lab"
```

---

## Como usar no workflow (lado do GitHub)

```yaml
permissions:
  id-token: write      # ← OBRIGATÓRIO para OIDC
  contents: read

jobs:
  meu-job:
    runs-on: ubuntu-latest
    steps:
      - name: Autenticação AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Testar acesso
        run: aws sts get-caller-identity
```

---

## Troubleshooting

| Erro | Causa | Solução |
|------|-------|---------|
| `AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity` | Repo não está na trust policy | Adicionar repo no array e `terraform apply` |
| `Error: configuring Terraform AWS Provider: no valid credential sources` | Profile errado ou não configurado | Usar `AWS_PROFILE=conta-hotmail` |
| `403 Forbidden` no `terraform plan` | CLI usando profile default (conta errada) | Verificar `AWS_PROFILE` |
| Secret `AWS_ROLE_ARN` não funciona | ARN errado ou secret não configurado | `gh secret list` para verificar |
| `id-token: write` não reconhecido | Falta campo `permissions` no workflow | Adicionar bloco `permissions` |

---

## Contas AWS

| Profile | Account ID | Uso |
|---------|-----------|-----|
| `default` | `129373676377` | Conta pessoal (não usada para labs) |
| `conta-hotmail` | `590183934378` | Conta dos labs (OIDC + infra) |

---

## Arquivos nesta pasta

| Arquivo | Commitar? | Descrição |
|---------|:---------:|-----------|
| `oidc.tf` | ✅ | Código Terraform (OIDC + Role) |
| `.terraform.lock.hcl` | ✅ | Lock de providers |
| `terraform.tfstate` | ❌ | State local (tem ARNs e IDs) |
| `terraform.tfstate.backup` | ❌ | Backup do state |
| `*.tfplan` | ❌ | Plans binários |
| `.terraform/` | ❌ | Providers instalados |
