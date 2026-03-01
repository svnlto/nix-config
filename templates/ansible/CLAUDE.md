# Ansible Project

## Commands

```bash
nix develop              # enter dev shell with ansible, ansible-lint, yamllint, yq
ansible-playbook -i inventory/hosts site.yml   # run playbook
ansible-lint .           # lint playbooks and roles
yamllint .               # lint YAML files
ansible-vault encrypt group_vars/prod/vault.yml  # encrypt secrets
pre-commit run --all-files  # run all pre-commit hooks
```

## Project Structure

```
inventory/
  hosts.yml              # inventory file
group_vars/
  all/
    vars.yml             # shared variables
    vault.yml            # encrypted secrets (ansible-vault)
roles/
  <role-name>/
    tasks/main.yml
    handlers/main.yml
    templates/
    files/
    defaults/main.yml
    vars/main.yml
site.yml                 # main playbook
```

## Conventions

- Use YAML for all Ansible files (not INI for inventory)
- One task per `name` — descriptive names in imperative form
- Use `ansible-vault` for all secrets; never commit plaintext credentials
- Prefer `become: true` at task level, not playbook level
- Use `ansible-lint` before committing (automated via hooks)
- Roles should be self-contained with sensible defaults
- Use `block/rescue/always` for error handling

## Security Rules

- Never commit unencrypted vault files
- Use `--check` (dry-run) before applying to production
- Pin collection versions in `requirements.yml`

## Relevant Skills

This project benefits from globally installed Claude Code skills:
- **devsecops-expert** — secure automation patterns, secrets management
- **security-auditing** — infrastructure security review
