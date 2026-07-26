{ username, ... }:

let
  constants = import ./constants.nix;
in
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];

      max-jobs = "auto";
      cores = 0;
      build-cores = 0;

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

    extraOptions = ''
      narinfo-cache-negative-ttl = 0
    '';
  };

  nixpkgs.config.allowUnfree = true;
}
