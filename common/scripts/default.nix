_:

{
  # Export worktree manager content for ZSH integration
  _module.args.worktreeManager = builtins.readFile ./worktree-manager.zsh;
}
