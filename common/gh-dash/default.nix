_:

{
  # gh-dash configuration with Catppuccin Mocha theme.
  # v4.25+ reads the global config from XDG config, not ~/.gh-dash.yml
  # (that name is only honoured as a repo-local file inside a git checkout).
  xdg.configFile."gh-dash/config.yml".text = ''
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
      refetchIntervalMinutes: 5
      preview:
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
          name: open in browser
          command: >
            gh pr view {{.PrNumber}} --repo {{.RepoName}} --web
        - key: C
          name: create pr
          command: >
            gh pr create --repo {{.RepoName}} --web
      issues:
        - key: O
          name: open in browser
          command: >
            gh issue view {{.IssueNumber}} --repo {{.RepoName}} --web
        - key: C
          name: create issue
          command: >
            gh issue create --repo {{.RepoName}} --web
  '';
}
