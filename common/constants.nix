# Centralized constants for Nix configuration
# Single source of truth for tuning values and magic numbers
{
  # Performance tuning - Nix downloads and builds
  performance = {
    downloadBufferSize = 256 * 1024 * 1024; # 256MB in bytes
    httpConnections = 50;
    maxSubstitutionJobs = 32;
    stalledDownloadTimeout = 90; # seconds
    connectTimeout = 30; # seconds
  };

  # History management - shared across shell, terminal, tmux
  history = {
    shellHistorySize = 50000; # ZSH history
    scrollbackLines = 50000; # Terminal scrollback (Ghostty, Tmux)
  };

  # Cleanup and maintenance
  cleanup = {
    generationRetentionDays = 30; # Keep generations for 30 days
  };
}
