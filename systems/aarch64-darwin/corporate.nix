# Corporate Mac overrides — vendor-agnostic skeleton for a managed work
# machine. Add employer-specific machinery (VPN root CA, cloud SSO, endpoint
# tooling) inside the home-manager.sharedModules block below once the stack is
# known.
{ lib, ... }:

{
  # Determinate (or another external installer) owns the Nix daemon on many
  # corporate machines, so force-disable the nix.* options common/ and systems/
  # set unconditionally. Drop this if nix-darwin manages Nix on the work host.
  nix.enable = false;
  nix.optimise.automatic = lib.mkForce false;

  # MDM (Jamf etc.) commonly blocks sudo on /Applications/, which breaks the
  # brew upgrade/cleanup steps that need it — disable them and run `brewup`
  # manually instead.
  homebrew.onActivation.upgrade = lib.mkForce false;
  homebrew.onActivation.cleanup = lib.mkForce "none";

  # Employer-specific home-manager config goes here. Typical additions:
  #   - VPN/proxy root CA (NODE_EXTRA_CA_CERTS, AWS_CA_BUNDLE) + a refresh fn
  #   - cloud SSO seed (~/.aws/config) and login tooling
  #   - region / observability env vars (AWS region, DD_SITE, ...)
  # home-manager.sharedModules = [
  #   ({ pkgs, lib, ... }: {
  #     home.sessionVariables = { };
  #     home.packages = with pkgs; [ ];
  #   })
  # ];
}
