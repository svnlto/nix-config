# AWS Secrets Manager

## CLI Reference

```bash
aws secretsmanager create-secret \
  --name production/database/password \
  --secret-string "super-secret-password"

aws secretsmanager get-secret-value \
  --secret-id production/database/password \
  --query SecretString --output text
```
