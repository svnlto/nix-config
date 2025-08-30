{ ... }:

{
  home.file."Library/Application Support/lazygit/config.yml".text = ''
    gui:
      theme:
        lightTheme: false
        activeBorderColor:
          - '#89b4fa'
          - bold
        inactiveBorderColor:
          - '#45475a'
        optionsTextColor:
          - '#cdd6f4'
        selectedLineBgColor:
          - '#313244'
        selectedRangeBgColor:
          - '#313244'
        cherryPickedCommitBgColor:
          - '#94e2d5'
        cherryPickedCommitFgColor:
          - '#1e1e2e'
        unstagedChangesColor:
          - '#f38ba8'
        defaultFgColor:
          - '#cdd6f4'

      scrollHeight: 2
      scrollPastBottom: true
      sidePanelWidth: 0.3333
      expandFocusedSidePanel: false
      mainPanelSplitMode: 'flexible'
      language: 'en'
      timeFormat: '02 Jan 06 15:04 MST'
      commitLength:
        show: true
      mouseEvents: true
      skipDiscardChangeWarning: false
      skipStashWarning: false
      showFileTree: true
      showListFooter: true
      showRandomTip: false
      showCommandLog: false
      commandLogSize: 8

    git:
      paging:
        colorArg: always
        pager: diff-so-fancy
      commit:
        signOff: false
      merging:
        manualCommit: false
        args: ""
      log:
        order: "topo-order"
        showGraph: 'when-maximised'
      skipHookPrefix: WIP
      autoFetch: true
      autoRefresh: true
      branchLogCmd: 'git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --'
      allBranchesLogCmds:
        - 'git log --graph --all --color=always --abbrev-commit --decorate --date=relative --pretty=medium'
      overrideGpg: false
      disableForcePushing: false
      parseEmoji: false

    update:
      method: prompt
      days: 14

    confirmOnQuit: false
    customCommands:
      - key: 'P'
        command: 'git push --force-with-lease'
        description: 'Force push with lease'
        context: 'global'
      - key: 'a'
        command: 'git add .'
        description: 'Add all files'
        context: 'files'

    keybinding:
      universal:
        quit: 'q'
        quit-alt1: '<c-c>'
        return: '<esc>'
        quitWithoutChangingDirectory: 'Q'
        togglePanel: '<tab>'
        prevItem: '<up>'
        nextItem: '<down>'
        prevItem-alt: 'k'
        nextItem-alt: 'j'
        prevPage: ','
        nextPage: '.'
        gotoTop: '<'
        gotoBottom: '>'
        scrollLeft: 'H'
        scrollRight: 'L'
        prevBlock: '<left>'
        nextBlock: '<right>'
        prevBlock-alt: 'h'
        nextBlock-alt: 'l'
        jumpToBlock: ['1', '2', '3', '4', '5']
        nextMatch: 'n'
        prevMatch: 'N'
        optionMenu: '<disabled>'
        optionMenu-alt1: '?'
        select: '<space>'
        goInto: '<enter>'
        openRecentRepos: '<c-r>'
        confirm: '<enter>'
        remove: 'd'
        new: 'n'
        edit: 'e'
        openFile: 'o'
        scrollUpMain: '<pgup>'
        scrollDownMain: '<pgdown>'
        scrollUpMain-alt1: 'K'
        scrollDownMain-alt1: 'J'
        scrollUpMain-alt2: '<c-u>'
        scrollDownMain-alt2: '<c-d>'
        executeShellCommand: ':'
        createRebaseOptionsMenu: 'm'
        pushFiles: 'P'
        pullFiles: 'p'
        refresh: 'R'
        createPatchOptionsMenu: '<c-p>'
        nextTab: ']'
        prevTab: '['
        nextScreenMode: '+'
        prevScreenMode: '_'
        undo: 'z'
        redo: '<c-z>'
        filteringMenu: '<c-s>'
        diffingMenu: 'W'
        diffingMenu-alt: '<c-e>'
        copyToClipboard: '<c-o>'
  '';
}
