{ username, ... }:

let constants = import ./constants.nix;
in {
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" username ];

      # Performance optimizations
      max-jobs = "auto";
      cores = 0;
      build-cores = 0;

      # Settings to improve lock handling and build performance
      use-case-hack = true;
      fallback = true;
      keep-going = true;
      log-lines = 25;
      download-buffer-size = constants.performance.downloadBufferSize;
      builders-use-substitutes = true;
      http-connections = constants.performance.httpConnections;
      max-substitution-jobs = constants.performance.maxSubstitutionJobs;
      stalled-download-timeout = constants.performance.stalledDownloadTimeout;
      connect-timeout = constants.performance.connectTimeout;
    };

    # Shared extra options
    extraOptions = ''
      narinfo-cache-negative-ttl = 0
    '';
  };

  # Allow unfree software across platforms
  nixpkgs.config.allowUnfree = true;
}
