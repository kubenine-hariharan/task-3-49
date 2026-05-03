---
name: ecs-fargate-oidc-cicd
description: >-
  Builds minimal GitHub Actions CI/CD that pushes a Docker image to Docker Hub and
  redeploys ECS Fargate using AWS IAM OIDC (no static AWS keys in GitHub). Covers
  Terraform patterns for one public subnet, security group on port 5000,
  assign_public_ip, least-privilege ecs:UpdateService/ecs:DescribeServices on one
  service ARN, and trust policy scoped to repo + refs/heads/main. Use when
  implementing ECS Fargate deploy from Actions, GitHub OIDC to AWS, task-3-49-style
  pipelines, or force-new-deployment after :latest pushes.
disable-model-invocation: true
---

# ECS Fargate CI/CD with GitHub OIDC

## Goal

End-to-end: push to `main` → build image → push `:latest` to Docker Hub → `aws ecs update-service --force-new-deployment`. AWS auth uses **OIDC** (`sts:AssumeRoleWithWebIdentity`), not `AWS_ACCESS_KEY_ID` secrets.

## GitHub Actions requirements

- Trigger: `on.push.branches: [main]` (must align with IAM trust `sub`, see [reference.md](reference.md)).
- Job permissions: `id-token: write`, `contents: read` (OIDC token issuance).
- AWS step: `aws-actions/configure-aws-credentials` with `role-to-assume` and `aws-region` **only** — do not use `aws-access-key-id`.
- Docker Hub: `docker/login-action` + secrets `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (access token, not password).
- After push: `aws ecs update-service --cluster <name> --service <name> --force-new-deployment`.

## Why `--force-new-deployment`

ECS does not redeploy solely because `:latest` changed on the registry; force triggers a new deployment so tasks **re-pull** the tag.

## AWS IAM (OIDC)

1. **OIDC identity provider** URL `https://token.actions.githubusercontent.com`, audience `sts.amazonaws.com`. Thumbprints: follow current [GitHub OIDC for AWS](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services); rotate if GitHub docs change.
2. **IAM role** trust: `Principal.Federated` = OIDC provider ARN; `Action` = `sts:AssumeRoleWithWebIdentity`; **conditions** on `token.actions.githubusercontent.com:aud` and `:sub` (exact repo + `ref:refs/heads/main` — no repo wildcards).
3. **Deploy policy** (inline name e.g. `task-3-49-deploy-policy`): **only** `ecs:UpdateService` and `ecs:DescribeServices`; **Resource** = that ECS **service** ARN (not `*`).

This repo’s Terraform encodes that pattern in `terraform/iam.tf`.

## Terraform / ECS shape (minimal)

- **VPC:** One AZ, one **public** subnet, Internet Gateway; **no** NAT, **no** private subnets for this pattern.
- **Security group:** Inbound TCP **5000** from `0.0.0.0/0`, egress all (image pull, logs).
- **ECS:** Fargate cluster + service; task definition points at Docker Hub image `:latest`; **network**: public subnets, **`assign_public_ip = true`**; desired count 1; **no ALB** for the learning path.

**Apply order:** Image exists on Docker Hub (or acceptable placeholder) before first `terraform apply` so tasks can start.

## Verification checklist

- [ ] Workflow succeeds on push to `main`.
- [ ] Repository has **no** AWS access key secrets.
- [ ] IAM trust shows specific `repo:OWNER/REPO:ref:refs/heads/main`.
- [ ] IAM policy allows only the two ECS actions on **one** service ARN.
- [ ] ECS shows a new deployment after the workflow; app reachable at task public IP (e.g. port 5000).

## Quick rubric answers (for demos)

| Topic | Answer |
|-------|--------|
| Fork PR | Trust `sub` / fork workflow context does not match upstream repo branch claim; assume role fails; fork jobs also lack upstream secrets. |
| `ecs:DeleteService` in workflow | **AccessDenied** — not in policy. |
| `:latest` in production | Ambiguous version, race on concurrent pushes, weak rollback story. |
| Docker Hub secret vs AWS key | Registry login has no AWS OIDC path in this setup; AWS supports OIDC to IAM — avoid long-lived AWS keys in CI. |
| Drain window | Single task / no ALB: brief connection errors possible while old task drains and new task starts. |

## Additional detail

- Policy/trust JSON templates and links: [reference.md](reference.md)
