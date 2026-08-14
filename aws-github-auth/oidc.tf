# 1. Provedor OIDC: Ensina a AWS a confiar no GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"] # Thumbprint oficial e público do GitHub
}

# 2. A Role (Crachá) que o GitHub vai assumir
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole-Lab"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            # Repositórios autorizados a assumir essa role
            "token.actions.githubusercontent.com:sub" = [
              "repo:andriocampos/meu-lab-terraform:*",
              "repo:andriocampos/github-actions-curso:*"
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 3. Permissões da Role (Para laboratório, damos acesso total de Admin)
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 4. Output para copiar o ARN (Precisaremos dele no GitHub)
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
