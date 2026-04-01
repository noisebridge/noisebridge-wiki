{
  config,
  hostMeta,
  lib,
  pkgs,
  siteConfig,
  ...
}:
let
  dumpConfig = siteConfig.mediawiki.dumps;

  dumpHostEnabled = hostMeta.role == "replica";
  mediawikiBin = "${config.system.path}/bin/mediawiki-run";

  mkDumpScript =
    {
      name,
      outputDir,
      keepDays,
      dumpArgs,
    }:
    pkgs.writeShellScript "mediawiki-dump-${name}" ''
      set -euo pipefail

      ts="$(date -u +%Y%m%d)"
      output_dir="${outputDir}"
      output_file="$output_dir/noisebridge-$ts-${name}.xml.gz"
      tmp_file="$output_file.tmp"
      latest_link="$output_dir/latest-${name}.xml.gz"

      rm -f "$tmp_file"
      trap 'rm -f "$tmp_file"' EXIT

      ${mediawikiBin} dumpBackup \
        --output "gzip:$tmp_file" \
        ${dumpArgs}

      mv "$tmp_file" "$output_file"
      ln -sfn "$(basename "$output_file")" "$latest_link"
      find "$output_dir" -maxdepth 1 -type f -name 'noisebridge-*-${name}.xml.gz' -mtime +${toString keepDays} -delete
    '';

in
{
  config = lib.mkIf dumpHostEnabled {
    systemd.tmpfiles.rules = [
      "d ${dumpConfig.privateDir} 0750 mediawiki mediawiki -"
      "d ${dumpConfig.publicDir} 0755 mediawiki mediawiki -"
    ];

    systemd.services.mediawiki-dump-private = {
      description = "Generate private MediaWiki dump";
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "mediawiki";
        Group = "mediawiki";
        ExecStart = mkDumpScript {
          name = "full";
          outputDir = dumpConfig.privateDir;
          keepDays = dumpConfig.privateKeepDays;
          dumpArgs = "--full --uploads --include-files";
        };
      };
    };

    systemd.timers.mediawiki-dump-private = {
      description = "Nightly private MediaWiki dump";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = dumpConfig.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    systemd.services.mediawiki-dump-public = {
      description = "Generate public MediaWiki dump";
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "mediawiki";
        Group = "mediawiki";
        ExecStart = mkDumpScript {
          name = "public";
          outputDir = dumpConfig.publicDir;
          keepDays = dumpConfig.publicKeepDays;
          dumpArgs = "--current";
        };
      };
    };

    systemd.timers.mediawiki-dump-public = {
      description = "Nightly public MediaWiki dump";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = dumpConfig.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    services.caddy.virtualHosts.${dumpConfig.publicDomain}.extraConfig = ''
      encode zstd gzip
      root * ${dumpConfig.publicDir}
      file_server browse
    '';
  };
}
