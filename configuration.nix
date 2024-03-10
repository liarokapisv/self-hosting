{ self, modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    self.inputs.agenix.nixosModules.default
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrfs2dvR3gQxhvtdU6ERB9ZY6Lo+6KN4p4d0Iy676Bm veritas@veritas-m1-pro"
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.vim
    pkgs.curl
    pkgs.gitMinimal
  ];

  age.secrets = {
    "adminpassFile.txt" = {
      file = "/secrets/adminpassFile.txt.age";
      mode = "770";
      owner = "nextcloud";
      group = "nextcloud";
    };
    "cloudflareCreds.txt" = {
      file = "/secrets/cloudflareCreds.txt.age";
      mode = "770";
      group = "acme";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "liarokapis.v@gmail.com";

    certs."demoninajar.com" = {
      extraDomainNames = [ "*.demoninajar.com" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialsFile = config.age.secrets."cloudflareCreds.txt".path;
    };
  };

  services = {

    openssh = {
      enable = true;
      hostKeys = [
        { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
      ];
    };

    nginx = {
      group = "acme";
      virtualHosts = {
        "nextcloud.demoninajar.com" = {
          forceSSL = true;
          useACMEHost = "demoninajar.com";
        };
      };
    };

    nextcloud = {
      enable = true;
      hostName = "nextcloud.demoninajar.com";

      # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud28;

      # Let NixOS install and configure the database automatically.
      database.createLocally = true;

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";
      https = true;

      autoUpdateApps.enable = true;
      extraAppsEnable = true;

      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit calendar contacts mail notes tasks;
      };

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = config.age.secrets."adminpassFile.txt".path;
      };

      settings = {
        overwriteprotocol = "https";
      };
    };
  };

  system.stateVersion = "23.11";
}
