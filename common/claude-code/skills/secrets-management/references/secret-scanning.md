# Secret Scanning

## Pre-commit

```bash
#!/bin/bash
docker run --rm -v "$(pwd):/repo" \
  trufflesecurity/trufflehog:3.88 \
  filesystem --directory=/repo

if [ $? -ne 0 ]; then
  echo "Secret detected! Commit blocked."
  exit 1
fi
```

## CI Integration

```yaml
# ADO
- script: |
    docker run --rm -v $(Build.SourcesDirectory):/repo \
      trufflesecurity/trufflehog:3.88 filesystem --directory=/repo
  displayName: 'Secret scan'
  failOnStderr: true
```

```yaml
# GitHub Actions
- name: Secret scan
  uses: trufflesecurity/trufflehog@v3.88
  with:
    path: .
    extra_args: --only-verified
```
