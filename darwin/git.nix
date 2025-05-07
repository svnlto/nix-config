# macOS-specific Git configuration
{ config, lib, pkgs, username, gitShared ? { }, ... }:

let
  # Template for local Git configuration with private information
  localGitConfigTemplate = ''
    # Local Git configuration - NOT tracked in Git
    # This file contains your personal Git configuration, including email

    [user]
        name = Your Name
        email = your.email@example.com
  '';

  # Common .gitignore content
  sharedGitignore = ''
    # OS files
    .DS_Store
    .DS_Store?
    ._*
    .Spotlight-V100
    .Trashes
    ehthumbs.db
    Thumbs.db

    # Editor files
    .vscode/
    .idea/
    *.swp
    *.swo
    *~

    # Environment files
    .env
    .env.local

    # Build artifacts
    node_modules/
    dist/
    build/
    target/

    # Logs
    *.log
    npm-debug.log*

    # Dependency lock files
    package-lock.json
    yarn.lock
    pnpm-lock.yaml

    # Nix
    result
    result-*
  '';

  # Create a gitconfig string from the standard structure
  gitConfig = {
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
    commit = { gpgsign = false; };
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
    alias = {
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
    include = { path = "~/.gitconfig.local"; };
  };

  # Function to convert Nix attrset to gitconfig content
  mkGitConfig = attrs:
    let
      # Function to convert a value to a string
      mkValueString = v:
        if builtins.isBool v then
          (if v then "true" else "false")
        else if builtins.isInt v then
          builtins.toString v
        else if builtins.isString v then
          v
        else if builtins.isList v then
          builtins.concatStringsSep "," (map mkValueString v)
        else
          builtins.abort "unsupported type for ${v}";

      # Function to convert a section to string
      mkSection = name: values:
        let
          # For simple key/value pairs
          mkEntry = k: v: "    ${k} = ${mkValueString v}";

          # For sections that contain subsections
          mkSubsection = k: v:
            if builtins.isAttrs v then
              if k == "alias" then
                lib.mapAttrsToList (sk: sv: mkEntry sk sv) v
              else
              # Nested section
                [ ''[${name} "${k}"]'' ]
                ++ (lib.mapAttrsToList (sk: sv: mkEntry sk sv) v)
            else [
              mkEntry
              k
              v
            ];

          # Process all entries in a section
          entries = lib.flatten (lib.mapAttrsToList mkSubsection values);
        in [ "[${name}]" ] ++ entries;

      # Process all sections
      sections = lib.flatten (lib.mapAttrsToList mkSection attrs);
    in lib.concatStringsSep "\n" sections;

  # Generate the gitconfig content
  gitConfigContent = mkGitConfig gitConfig;

in {
  # For nix-darwin, we use environment.etc instead of programs.git
  environment.etc."gitconfig".text = gitConfigContent;

  # Create .gitignore file
  system.activationScripts.gitignore = {
    text = ''
      echo "Setting up .gitignore..."
      echo '${sharedGitignore}' > /Users/${username}/.gitignore
      chown ${username}: /Users/${username}/.gitignore
    '';
  };

  # Create local git config template
  system.activationScripts.gitLocalConfig = {
    text = ''
            echo "Checking local git configuration..."
            if [ ! -f /Users/${username}/.gitconfig.local ]; then
              echo "Creating template for local git configuration..."
              cat > /Users/${username}/.gitconfig.local << EOF
      ${localGitConfigTemplate}
      EOF
              echo "⚠️  IMPORTANT: Please edit ~/.gitconfig.local to set your email address ⚠️"
            fi
            chown ${username}: /Users/${username}/.gitconfig.local 2>/dev/null || true
    '';
  };

  # Install diff-so-fancy and git
  environment.systemPackages = with pkgs; [ diff-so-fancy git ];
}
