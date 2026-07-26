{
  performance = {
    downloadBufferSize = 256 * 1024 * 1024; # bytes
    httpConnections = 50;
    maxSubstitutionJobs = 32;
    stalledDownloadTimeout = 90; # seconds
    connectTimeout = 30; # seconds
  };

  history = {
    shellHistorySize = 50000;
    scrollbackBytes = 10000000; # bytes
  };

  cleanup = {
    generationRetentionDays = 30;
  };
}
