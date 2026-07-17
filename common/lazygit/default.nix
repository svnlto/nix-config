_:

{
  # xdg.configFile resolves the lazygit config path per-platform (macOS Application Support vs Linux .config).
  xdg.configFile."lazygit/config.yml".text = ''
    gui:
      theme:
        activeBorderColor:
          - '#89b4fa'
          - bold
        inactiveBorderColor:
          - '#45475a'
        optionsTextColor:
          - '#cdd6f4'
        selectedLineBgColor:
          - '#313244'
        cherryPickedCommitBgColor:
          - '#94e2d5'
        cherryPickedCommitFgColor:
          - '#1e1e2e'
        unstagedChangesColor:
          - '#f38ba8'
        defaultFgColor:
          - '#cdd6f4'

      language: 'en'
      timeFormat: '02 Jan 06 15:04 MST'
      showRandomTip: false
      showCommandLog: false

    git:
      pagers:
        - colorArg: always
          pager: diff-so-fancy
      log:
        showGraph: 'when-maximised'

    customCommands:
      - key: 'P'
        command: 'git push --force-with-lease'
        description: 'Force push with lease'
        context: 'global'
      - key: 'a'
        command: 'git add .'
        description: 'Add all files'
        context: 'files'
  '';
}
