{config, lib, pkgs, ...}:
let
  unstable = import <nixos-unstable> {};
in
{

  imports = [ <nixos-unstable/nixos/modules/services/web-apps/mediawiki.nix> ];
  disabledModules = [ "services/web-apps/mediawiki.nix" ];

  sops.secrets.mediawiki_admin_initial_password = {
    format = "yaml";
    key = "mediawiki_admin_initial_password";
    mode = "0440";
    owner = "mediawiki";
    group = "users";
  };

  systemd.services.mediawiki-init = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

 
  services.mediawiki = {
    enable = true;
    package = unstable.mediawiki;
    name = "Sciences.Re";
 
    passwordFile = "/run/secrets/mediawiki_admin_initial_password";

    database = {
      type = "mysql";
    };

    extensions = {
      VisualEditor = null;
      PluggableAuth = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_35-2a465ae.tar.gz";
        sha256 = "0bv5cf44z33ydprnry2qpmjs0vk2p28kdnnfvz4dsr1rmwndnzch";
      };
      OpenIDConnect = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_35-05d76c0.tar.gz";
        sha256 = "0ggs9kyqz3bqf5jh3m0vxc6n51nivi3ddrmwxb224jwainbhrn27";
      };
    };

    extraConfig = ''
     $wgServer = "https://wiki.sciences.re";
     $wgEmergencyContact = "contact@sciences.re";
     $wgPasswordSender = "contact@sciences.re";
     $wgGroupPermissions['*']['edit'] = true;
     $wgOpenIDConnect_Config['https://auth.sciences.re/auth/realms/master/'] = [
	'clientID' => 'wiki.sciences.re',
	'clientsecret' => 'b0b8779b-32c0-4d7e-89ab-400e5d287d77',
	'scope' => ['openid', 'profile', 'email']
     ];
     $wgGroupPermissions['*']['autocreateaccount'] = true;
     $wgGroupPermissions['*']['createaccount'] = false;
     $wgDefaultSkin = "timeless";
     $wgLogos = [ '1x' => "$wgResourceBasePath/logo_small.svg" ];
     $wgLanguageCode = "fr";
     wfLoadSkin( 'MonoBook' );
     wfLoadSkin( 'Timeless' );
     wfLoadSkin( 'Vector' );
     $wgShowExceptionDetails = true;
     ## https://www.mediawiki.org/wiki/Manual:Short_URL
     $wgArticlePath = "/wiki/$1";
     ## https://www.mediawiki.org/wiki/Manual:File_cache
     $wgUseFileCache = true; // default: false
     $wgFileCacheDirectory = "$IP/cache"; // default: "{$wgUploadDirectory}/cache" which equals to "$IP/images/cache"
    '';

    virtualHost = {
      hostName = "wiki.sciences.re";
      adminAddr = "remy@grunblatt.org";
      listen = [
        {
          ip = "127.0.0.1";
          port = 7777;
        }
      ];
      extraConfig = ''
        ## https://www.mediawiki.org/wiki/Manual:Short_URL/Apache

        # Enable the rewrite engine
        RewriteEngine On

        # Short URL for wiki pages
        RewriteRule ^/?wiki(/.*)?$ %{DOCUMENT_ROOT}/index.php [L]

        # Redirect / to Main Page
        RewriteRule ^/*$ %{DOCUMENT_ROOT}/index.php [L]
      '';
    };
  };


  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    virtualHosts."wiki.sciences.re" = {
      enableACME = true;
      forceSSL = true;
      locations."=/logo_small.svg" = {
         alias =  "/etc/nixos/static/logo_small.svg";
      };
      locations."/" = {
        proxyPass = "http://127.0.0.1:7777";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "wiki.sciences.re" = {
         email = "contact@sciences.re";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

}
