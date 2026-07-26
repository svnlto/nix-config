{
  config,
  pkgs,
  lib,
  ...
}:

let
  gitCfg = config.programs.git;
in
{
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        inherit (gitCfg.settings.user) name email;
      };

      ui = {
        editor = "nvim";
        default-command = [ "log" ];
        show-cryptographic-signatures = true;
        diff-formatter = [
          (lib.getExe pkgs.difftastic)
          "--color=always"
          "--display=inline"
          "$left"
          "$right"
        ];
      };

      git = {
        # Refuse to push anything still marked as work in progress.
        private-commits = "description(glob:'wip:*')";
        sign-on-push = true;
      };

      # "drop" + sign-on-push means one 1Password prompt per push instead of
      # one per commit rewrite.
      signing = {
        behavior = "drop";
        backend = "ssh";
        key = gitCfg.signing.key;
        backends.ssh = {
          program = gitCfg.settings.gpg.ssh.program;
          allowed-signers = "~/.ssh/allowed_signers";
        };
      };

      snapshot.max-new-file-size = "20MiB";

      # jj does not run git hooks, so `jj fix` stands in for the nixfmt
      # pre-commit hook.
      fix.tools.nixfmt = {
        command = [
          (lib.getExe pkgs.nixfmt)
          "--filename=$path"
        ];
        patterns = [ "glob:'**/*.nix'" ];
      };

      templates.git_push_bookmark = ''"svenlito/push-" ++ change_id.short()'';

      revset-aliases = {
        # Also protect commits on trunk's descendants that are not mine.
        "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine())";
        "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
        "stack()" = "stack(@)";
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };

      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@-)"
          "--to"
          "@-"
        ];
        l = [
          "log"
          "-r"
          "stack()"
        ];
        retrunk = [
          "rebase"
          "-d"
          "trunk()"
        ];
        sync = [
          "git"
          "fetch"
          "--all-remotes"
        ];
      };
    };
  };

  # config.toml is a read-only store symlink; this dir is where `jj config set`
  # replacements and throwaway experiments go (jj layers conf.d over config.toml).
  xdg.configFile."jj/conf.d/.keep".text = "";
}
