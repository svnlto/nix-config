{
  lib,
  username,
  ...
}:

# morty does no signed commits (no 1Password in the VM); the committed global
# signByDefault + op-ssh-sign program would fail every git op here. Force off.
{
  home-manager.users.${username}.programs.git.signing.signByDefault = lib.mkForce false;
}
