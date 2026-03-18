# AWS CLI / saml2aws Corporate Integration — Design Spec

**Date:** 2026-03-18
**Scope:** Corporate Mac (`MSGMAC-MV69Q140FD`) only
**File changed:** `systems/aarch64-darwin/corporate.nix`

---

## Context

AWS access at msg uses raw SAML federation via CyberArk Identity. There is no IAM Identity Center. CyberArk posts a SAML assertion directly to the AWS SAML ACS endpoint. Native `aws sso login` / `sso-session` blocks do not apply.

The correct toolchain is:
- `saml2aws` — exchanges a CyberArk SAML assertion for temporary STS credentials
- `saml2aws-multi` (`awslogin`) — wrapper that handles multiple accounts/roles in one shot, installed via `pipx`

Two environments:
- **TEST** — `msg-dop-test.cyberark.cloud`, username `sven.hummelsberger@tst.do.msg.group`
- **PROD** — `msg-dop.cyberark.cloud`, username `sven.hummelsberger@do.msg.group` (suffix TBC)

---

## Constraints

Files that remain writable — Nix may seed them once but must not symlink or own them:

| File | Seeded by Nix? | Runtime writer |
|------|---------------|----------------|
| `~/.aws/config` | Yes — activation, `[ ! -f ]` guard | Manual / `saml2aws` |
| `~/.saml2aws` | Yes — activation, `[ ! -f ]` guard | `saml2aws configure` |
| `~/.aws/credentials` | No | `saml2aws login` |
| `~/.saml2awsmulti/aws_login_roles.csv` | No | `awslogin` |

---

## Approach: Extend `corporate.nix` (Option A)

All changes go into `home-manager.sharedModules` in `systems/aarch64-darwin/corporate.nix`. No new files or modules.

The existing `sharedModules` entry is a bare attrset. Rewrite it as a function to bring `pkgs` into scope. HM modules always receive `pkgs` as a module argument; `useGlobalPkgs = true` (set in `flake.nix`) ensures it is the system nixpkgs.

```nix
home-manager.sharedModules = [
  ({ pkgs, lib, ... }: {
    # all corporate HM config consolidated here
  })
];
```

### 1. Packages

```nix
home.packages = with pkgs; [
  saml2aws   # SAML → STS credential exchange; must be on PATH for saml2aws-multi
  awscli2    # AWS CLI v2
];
```

`pipx` is already present in shared `devPackages`. `saml2aws-multi` is not in nixpkgs — installed via activation (see section 3b).

### 2. Environment Variables

Add `AWS_CA_BUNDLE` alongside the existing `NODE_EXTRA_CA_CERTS` in the same attrset:

```nix
home.sessionVariables = {
  NODE_EXTRA_CA_CERTS = "$HOME/.zscaler.pem";  # existing
  AWS_CA_BUNDLE       = "$HOME/.zscaler.pem";  # new: Zscaler TLS for saml2aws + aws CLI
};
```

### 3. Activation Scripts

Three activation entries, all `entryAfter ["writeBoundary"]`.

**3a. `~/.aws/config`** — seeds base profiles on first run only:

```nix
home.activation.awsConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if [ ! -f "$HOME/.aws/config" ]; then
    mkdir -p "$HOME/.aws"
    cat > "$HOME/.aws/config" << EOF
[profile test-landing-zone]
region = eu-central-1
output = json

[profile prod-landing-zone]
region = eu-central-1
output = json
EOF
  fi
'';
```

**3b. `~/.saml2aws`** — seeds IdP profiles on first run only. `[default]` = TEST; `[prod]` = PROD named profile:

```nix
home.activation.saml2awsConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if [ ! -f "$HOME/.saml2aws" ]; then
    cat > "$HOME/.saml2aws" << EOF
[default]
url                  = https://msg-dop-test.cyberark.cloud
username             = sven.hummelsberger@tst.do.msg.group
provider             = CyberArk
mfa                  = Auto
skip_verify          = false
timeout              = 0
aws_urn              = urn:amazon:webservices
aws_session_duration = 3600
aws_profile          = test-landing-zone
region               = eu-central-1

[prod]
url                  = https://msg-dop.cyberark.cloud
username             = sven.hummelsberger@do.msg.group
provider             = CyberArk
mfa                  = Auto
skip_verify          = false
timeout              = 0
aws_urn              = urn:amazon:webservices
aws_session_duration = 3600
aws_profile          = prod-landing-zone
region               = eu-central-1
EOF
  fi
'';
```

**3c. `saml2aws-multi` via pipx** — installs `awslogin` if not already present. Uses the store path of `pipx` to avoid PATH ordering issues during activation. Fails gracefully so `nixswitch` is not blocked by network errors:

```nix
home.activation.saml2awsMulti = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if ! command -v awslogin >/dev/null 2>&1; then
    echo "Installing saml2aws-multi..."
    ${pkgs.pipx}/bin/pipx install git+https://github.com/kyhau/saml2aws-multi.git \
      || echo "WARNING: saml2aws-multi install failed — run manually: pipx install git+https://github.com/kyhau/saml2aws-multi.git"
  fi
'';
```

Note: `${pkgs.pipx}/bin/pipx` is a Nix store path interpolated at build time — it is available regardless of `$PATH` during activation.

Note on heredocs: all heredoc delimiters are unquoted (`<< EOF`, not `<< 'EOF'`) — single-quotes inside a Nix `''` string terminate the Nix string, causing a parse error.

### 4. Shell Aliases

```nix
programs.zsh.shellAliases = {
  # existing
  refresh-zscaler = "...";
  # new
  awswho   = "aws sts get-caller-identity";
  awstest  = "awslogin -s test";               # saml2aws-multi, uses [default] (TEST)
  awsprod  = "saml2aws login --idp-account prod";  # direct saml2aws, uses [prod] profile
};
```

`awstest` drives `saml2aws-multi` (`awslogin`), which reads only `[default]` from `~/.saml2aws` — multi-role bulk refresh for TEST.

`awsprod` drives `saml2aws` directly with `--idp-account prod`, which reads the `[prod]` section — interactive single-role picker for PROD. `saml2aws-multi` does not support named profile selection so PROD uses the underlying binary.

`-s test` is a substring filter on role names in the cache — it pre-selects roles whose names contain "test". This is provisional: confirm actual role names after first `awslogin --refresh-cached-roles` run and update the alias if needed. For an unfiltered full refresh, use bare `awslogin`.

---

## Not Managed by Nix

| Path | Reason |
|------|--------|
| `~/.aws/credentials` | Written by `saml2aws login` |
| `~/.saml2awsmulti/` | Runtime cache written by `awslogin` |

---

## Bootstrap Workflow (new machine)

After `darwin-rebuild switch`:
- `saml2aws` and `awscli2` are installed
- `~/.aws/config` and `~/.saml2aws` are seeded (if not already present)
- `saml2aws-multi` (`awslogin`) is installed via the pipx activation script (requires network)

```bash
# 1. TEST: first auth + role enumeration (triggers CyberArk browser/MFA flow)
awslogin --refresh-cached-roles

# 2. Verify TEST
aws sts get-caller-identity --profile AdministratorAccess-msg-dop-test

# 3. Confirm awstest keyword matches actual role names
#    Update awstest alias in corporate.nix if needed, then nixswitch

# 4. PROD: confirm do.msg.group suffix, then first login (interactive role picker)
saml2aws login --idp-account prod

# 5. Verify PROD
aws sts get-caller-identity --profile prod-landing-zone

# Daily login
awstest   # TEST bulk refresh via awslogin (saml2aws-multi)
awsprod   # PROD single-role login via saml2aws directly
```

---

## Notes

- **Credential expiry:** STS credentials expire after 1h (max 12h if IAM role trust policy allows). No persistent token cache — re-login required.
- **Zscaler:** `AWS_CA_BUNDLE` ensures `saml2aws login` and `aws` CLI calls succeed behind Zscaler TLS inspection.
- **PROD username suffix:** `do.msg.group` is inferred from the TEST suffix `tst.do.msg.group`. Confirm before first PROD login and update `~/.saml2aws` manually if wrong.
- **`saml2aws-multi` install:** Activation gracefully degrades on network failure — `awslogin` will be absent but `nixswitch` completes. Run `pipx install` manually if it failed.
- **`~/.aws/sso/cache/`:** Irrelevant — no SSO session exists in this setup.
