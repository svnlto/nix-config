# CI/CD Integration

## ADO Pipelines — Variable Groups with Key Vault

```yaml
variables:
  - group: myapp-production-secrets   # linked to Key Vault

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'myapp-azure-connection'
      KeyVaultName: 'myapp-kv-prod'
      SecretsFilter: 'DatabasePassword,ApiKey'
      RunAsPreJob: true
    displayName: 'Fetch secrets from Key Vault'

  - script: |
      echo "Connecting as $(DatabasePassword)"
    displayName: 'Use secrets'
```

**ADO Library setup:**

1. Project Settings -> Pipelines -> Library -> + Variable group
2. Toggle "Link secrets from an Azure key vault as variables"
3. Select service connection and Key Vault
4. Authorize specific secrets (never authorize all)
5. Restrict pipeline permissions to specific pipelines

## ADO — Workload Identity Federation

Prefer workload identity over service principal secrets:

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'myapp-workload-identity'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az keyvault secret show \
        --vault-name myapp-kv-prod \
        --name DatabasePassword \
        --query value -o tsv
```

**Setup:**

1. Create app registration in Entra ID
2. Add federated credential:
   issuer = `https://vstoken.dev.azure.com/<org-id>`,
   subject = `sc://<org>/<project>/<service-connection>`
3. Assign Key Vault RBAC to the app registration
4. Create ADO service connection with workload identity federation type

## ADO — Vault Integration

```yaml
steps:
  - script: |
      export VAULT_ADDR=https://vault.example.com:8200
      export VAULT_TOKEN=$(VaultToken)
      DB_PASSWORD=$(vault kv get -field=password secret/database/config)
      echo "##vso[task.setvariable variable=DB_PASSWORD;issecret=true]$DB_PASSWORD"
    displayName: 'Fetch secrets from Vault'
    env:
      VaultToken: $(VAULT_TOKEN)
```

## ADO Secret Hygiene

- **Variable groups**: Key Vault-linked, not manual secret variables
- **issecret=true**: `echo "##vso[task.setvariable variable=MY_SECRET;issecret=true]$value"`
- **SecretsFilter**: list specific secrets, never `*` in production
- **Pipeline permissions**: restrict variable group access per pipeline
- **Approval gates**: require approval on environments accessing production secrets
- **Audit**: ADO audit log tracks variable group access

## GitHub Actions

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/deploy
    aws-region: us-west-2

- name: Get secret
  run: |
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id production/database/password \
      --query SecretString --output text)
    echo "::add-mask::$SECRET"
    echo "DB_PASSWORD=$SECRET" >> $GITHUB_ENV
```

```yaml
- name: Import from Vault
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.example.com:8200
    token: ${{ secrets.VAULT_TOKEN }}
    secrets: |
      secret/data/database username | DB_USERNAME ;
      secret/data/database password | DB_PASSWORD
```
