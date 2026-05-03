# Reference: OIDC trust and ECS policy

## Trust policy shape (GitHub → AWS)

Use the official GitHub documentation for the exact JSON. Conceptually:

- **Principal**: `Federated` = ARN of `aws_iam_openid_connect_provider` for `token.actions.githubusercontent.com`.
- **Action**: `sts:AssumeRoleWithWebIdentity`.
- **Conditions**:
  - `token.actions.githubusercontent.com:aud` = `sts.amazonaws.com`
  - `token.actions.githubusercontent.com:sub` = `repo:OWNER/REPO:ref:refs/heads/main` (replace with your repository; must match the branch you deploy from).

For **tag-based** deploys, the `sub` claim uses a tag ref (e.g. `ref:refs/tags/v1.0.0`); align IAM with your workflow `on:` triggers.

## Deploy policy shape (least privilege)

Allow **only**:

- `ecs:UpdateService`
- `ecs:DescribeServices`

**Resource**: full ECS service ARN:

`arn:aws:ecs:REGION:ACCOUNT_ID:service/CLUSTER_NAME/SERVICE_NAME`

Do not use `*` for Resource in this learning constraint.

## ECS service ARN in Terraform

Prefer referencing the live service resource so the ARN stays correct:

- Build from `aws_ecs_cluster` name + `aws_ecs_service` name, or use attributes your provider exposes for the service ARN.

## Links

- [Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
