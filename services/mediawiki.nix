{config, lib, pkgs, ...}:
let
  unstable = import <nixos-unstable> {};
in
{
 
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
    name = "Sciences.Re Wiki";
 
    passwordFile = "/run/secrets/mediawiki_admin_initial_password";

    database = {
      type = "mysql";
    };

    extensions = {
      VisualEditor = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/VisualEditor-REL1_35-f089b74.tar.gz";
        sha256 = "1f7izrpcc3525pwn3cbyxb374lq5pk7pz2xvk0fydnjz5g3pkgrg";
      };
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
     $wgGroupPermissions['*']['edit'] = false;
     $wgOpenIDConnect_Config['https://auth.sciences.re/auth/realms/master/'] = [
	'clientID' => 'wiki.sciences.re',
	'clientsecret' => 'b0b8779b-32c0-4d7e-89ab-400e5d287d77',
	'scope' => ['openid', 'profile', 'email']
     ];
     $wgGroupPermissions['*']['autocreateaccount'] = true;
     $wgGroupPermissions['*']['createaccount'] = false;
     $wgDefaultSkin = "timeless";
     $wgLogos = [ '1x' => "$wgResourceBasePath/sciences-re-square-black.png" ];
     wfLoadSkin( 'MonoBook' );
     wfLoadSkin( 'Timeless' );
     wfLoadSkin( 'Vector' );
     $wgShowExceptionDetails = true;
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
    };
  };


  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."wiki.sciences.re" = {
      enableACME = true;
      forceSSL = true;
      locations."=/sciences-re-square-black.png" = {
         alias =  "/etc/nixos/static/sciences-re-square-black.png";
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
