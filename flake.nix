{
  description = "kaptanto — change data capture for Postgres and MongoDB in a single static Go binary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      debug = false;
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        config,
        pkgs,
        lib,
        ...
      }: let
        # Version metadata injected at link time, mirroring the Makefile's LDFLAGS.
        # Derived from the flake so builds stay reproducible: a clean tree uses the
        # commit rev/date, a dirty tree falls back to a sentinel.
        version = "0.2.0";
        commit = inputs.self.rev or inputs.self.dirtyRev or "unknown";
        # self.lastModifiedDate is "YYYYMMDDHHMMSS"; reshape to RFC 3339 / ISO 8601.
        date = inputs.self.lastModifiedDate or "19700101000000";
        buildDate = "${lib.substring 0 4 date}-${lib.substring 4 2 date}-${lib.substring 6 2 date}T${lib.substring 8 2 date}:${lib.substring 10 2 date}:${lib.substring 12 2 date}Z";
      in {
        # `nix build` / `nix build .#kaptanto` — equivalent to `make build`:
        # a pure-Go (CGO disabled), trimpath, version-stamped static binary.
        packages.kaptanto = pkgs.buildGoModule {
          pname = "kaptanto";
          inherit version;

          src = ./.;

          # Update after dependency changes: set to lib.fakeHash, build, then
          # copy the "got:" hash Nix prints into this field.
          vendorHash = "sha256-r/Mvnv/ffK9ShNQY4dVDgCxENgRGYaab+GyjfBBipIM=";

          # Mirror `make build`: only the CLI entrypoint, no CGO.
          subPackages = ["cmd/kaptanto"];
          env.CGO_ENABLED = 0;

          # buildGoModule already passes -trimpath.
          ldflags = [
            "-s"
            "-w"
            "-X github.com/olucasandrade/kaptanto/internal/version.Version=${version}"
            "-X github.com/olucasandrade/kaptanto/internal/version.Commit=${commit}"
            "-X github.com/olucasandrade/kaptanto/internal/version.BuildDate=${buildDate}"
          ];

          # `make build` does not run the suite (tests need external services);
          # keep the package build hermetic. Use `make test` for the test run.
          doCheck = false;

          meta = {
            description = "Change data capture for Postgres and MongoDB in a single static Go binary";
            homepage = "https://github.com/olucasandrade/kaptanto";
            license = lib.licenses.asl20;
            mainProgram = "kaptanto";
          };
        };

        packages.default = config.packages.kaptanto;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [nil nixd];
        };
      };
    };
}
