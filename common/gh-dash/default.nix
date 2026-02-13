_:

{
  # gh-dash configuration with Catppuccin Mocha theme
  home.file.".gh-dash.yml".text = ''
    prSections:
      - title: Mine
        filters: is:open author:@me sort:updated-desc
      - title: Review
        filters: -author:@me is:open review-requested:@me sort:updated-desc
      - title: All
        filters: is:open sort:updated-desc
    issuesSections:
      - title: My Issues
        filters: author:@me is:open sort:updated-desc
      - title: Assigned
        filters: assignee:@me is:open sort:updated-desc
      - title: All Issues
        filters: is:open sort:updated-desc

    defaults:
      view: prs
      refetchIntervalMinutes: 5
      prsLimit: 20
      issuesLimit: 20
      preview:
        open: true
        width: 84

    theme:
      colors:
        text:
          primary: "#cdd6f4"
          secondary: "#a6adc8"
          inverted: "#1e1e2e"
          faint: "#6c7086"
          warning: "#f9e2af"
          success: "#a6e3a1"
        background:
          selected: "#313244"
        border:
          primary: "#89b4fa"
          secondary: "#45475a"
          faint: "#585b70"

    keybindings:
      universal:
        - key: g
          name: lazygit
          command: >
            cd {{.RepoPath}} && lazygit
      prs:
        - key: c
          builtin: checkout
        - key: O
          builtin: view
        - key: C
          builtin: create
      issues:
        - key: O
          builtin: view
        - key: C
          builtin: create
  '';
}
