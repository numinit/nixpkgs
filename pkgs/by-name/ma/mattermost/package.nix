{ lib
, buildGoModule
, fetchFromGitHub
, buildNpmPackage
, runCommand
, jq
, go
, nixosTests
}:

buildGoModule rec {
  pname = "mattermost";
  # ESR releases only.
  # See https://docs.mattermost.com/upgrade/extended-support-release.html
  # When a new ESR version is available (e.g. 8.1.x -> 9.5.x), update
  # the version regex in passthru.updateScript as well.
  version = "9.11.6";

  src = fetchFromGitHub {
    owner = "mattermost";
    repo = "mattermost";
    rev = "v${version}";
    hash = "sha256-5nUzUnVWVBnQErbMJeSe2ZxCcdcHSmT34JXjFlRMW/s=";
  };

  # Needed because buildGoModule does not support go workspaces yet.
  # We use go 1.22's workspace vendor command, which is not yet available
  # in the default version of go used in nixpkgs, nor is it used by upstream:
  # https://github.com/mattermost/mattermost/issues/26221#issuecomment-1945351597
  overrideModAttrs = (_: {
    buildPhase = ''
      make setup-go-work
      go work vendor -e
    '';
  });

  webapp = buildNpmPackage rec {
    pname = "mattermost-webapp";
    inherit version src;

    sourceRoot = "${src.name}/webapp";

    # Fix build dependency conflicts
    patchedPackageJSON = runCommand "package.json" { } ''
      ${jq}/bin/jq '.devDependencies.ajv = "8.17.1" |
        .overrides."@types/scheduler" = "< 0.23.0"
      ' ${src}/webapp/package.json > $out
    '';

    postPatch = ''
      cp ${patchedPackageJSON} package.json
      cp ${./package-lock.json} package-lock.json

      # Remove deprecated image-webpack-loader causing build failures
      # See: https://github.com/tcoopman/image-webpack-loader#deprecated
      sed -i 's/options: {},/options: { disable: true },/' channels/webpack.config.js
    '';

    makeCacheWritable = true;
    forceGitDeps = true;

    npmRebuildFlags = [ "--ignore-scripts" ];
    npmDepsHash = "sha256-E31gKv9ITjlGN/J5Ly38Qq0OsWsdWzwFJNVVzLRj8BA=";

    buildPhase = ''
      runHook preBuild

      npm run build --workspace=platform/types
      npm run build --workspace=platform/client
      npm run build --workspace=platform/components
      npm run build --workspace=channels

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r channels/dist/* $out

      runHook postInstall
    '';
  };

  vendorHash = "sha256-Gwv6clnq7ihoFC8ox8iEM5xp/us9jWUrcmqA9/XbxBE=";

  modRoot = "./server";
  preBuild = ''
    make setup-go-work
  '';

  subPackages = [ "cmd/mattermost" ];

  tags = [ "production" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/mattermost/mattermost/server/public/model.Version=${version}"
    "-X github.com/mattermost/mattermost/server/public/model.BuildNumber=${version}-nixpkgs"
    "-X github.com/mattermost/mattermost/server/public/model.BuildDate=1970-01-01"
    "-X github.com/mattermost/mattermost/server/public/model.BuildHash=v${version}"
    "-X github.com/mattermost/mattermost/server/public/model.BuildHashEnterprise=none"
    "-X github.com/mattermost/mattermost/server/public/model.BuildEnterpriseReady=false"
  ];

  postInstall = ''
    mkdir -p $out/{client,i18n,fonts,templates,config}
    cp -r ${webapp}/* $out/client/
    cp -r ${src}/server/i18n/* $out/i18n/
    cp -r ${src}/server/fonts/* $out/fonts/
    cp -r ${src}/server/templates/* $out/templates/
    OUTPUT_CONFIG=$out/config/config.json \
      ${go}/bin/go run -tags production ./scripts/config_generator

    # For some reason a bunch of these files are executable
    find $out/{client,i18n,fonts,templates,config} -type f -exec chmod -x {} \;
  '';

  passthru = {
    updateScript = ./update.sh;
    tests.mattermost = nixosTests.mattermost;
  };

  meta = with lib; {
    description = "Mattermost is an open source platform for secure collaboration across the entire software development lifecycle";
    homepage = "https://www.mattermost.org";
    license = with licenses; [ agpl3Only asl20 ];
    maintainers = with maintainers; [ ryantm numinit kranzes mgdelacroix ];
    mainProgram = "mattermost";
  };
}
