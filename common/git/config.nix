# Shared Git configuration
{ config, lib, pkgs, username, ... }:

let
  # Define shared git configuration that will be used by both platforms
  gitConfig = {
    enable = true;

    # User details - Using placeholder that will be overridden by local config
    userName = "Your Name";
    userEmail = "user@example.com";

    # Git configuration
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore";
        autocrlf = "input";
        quotepath = false;
        compression = 9;
        preloadindex = true;
        pager = "diff-so-fancy | less --tabs=2 -RFX";
      };
      merge = {
        tool = "vscode";
        conflictstyle = "diff3";
      };
      mergetool.vscode = { cmd = "code --wait $MERGED"; };
      diff = {
        tool = "vscode";
        colorMoved = "default";
      };
      difftool.vscode = { cmd = "code --wait --diff $LOCAL $REMOTE"; };
      commit = {
        gpgsign = false; # Set to true if you use GPG signing
      };
      rerere = { enabled = true; };
      help = { autocorrect = 10; };
      color = {
        ui = "always";
        diff = {
          meta = "yellow";
          frag = "magenta bold";
          commit = "yellow bold";
          old = "red bold";
          new = "green bold";
          whitespace = "red reverse";
        };
        "diff-highlight" = {
          oldNormal = "red bold";
          oldHighlight = "red bold 52";
          newNormal = "green bold";
          newHighlight = "green bold 22";
        };
      };
    };

    # Common aliases
    aliases = {
      st = "status -sb";
      co = "checkout";
      cb = "checkout -b";
      ci = "commit";
      cm = "commit -m";
      ca = "commit --amend";
      br = "branch";
      df = "diff";
      dfc = "diff --cached";
      lol =
        "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      lga =
        "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
    };

    # Include local Git configuration file for private settings
    includes = [{ path = "~/.gitconfig.local"; }];
  };

  # Test for which platform we're on
  isHomeManager = lib.hasAttr "home" config;
  isDarwin = lib.hasAttr "darwinConfig" config || lib.hasAttr "security" config
    || lib.hasAttr "system" config;
  # Return different configurations based on the platform
in {
  # Common config exports to be used by both platforms as needed
  _module.args.gitShared = { inherit gitConfig; };
}
