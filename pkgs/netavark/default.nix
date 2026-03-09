{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  mandown,
  protobuf,
  nixosTests,
  go-md2man,
}:

rustPlatform.buildRustPackage rec {
  pname = "netavark";
  version = "1.7.0-dhcp";

  src = fetchFromGitHub {
    owner = "wangxiaoerYah";
    repo = "netavark";
    rev = version;
    hash = "sha256-/tMVP+GzRThyMKCVqayiTfv9y0yy8h/OmXcPaREh/ds=";
  };

  patches = [ ./enable_v6.patch ];

  cargoHash = "sha256-evtL8A9xMp/V9dsG4N6t+zXzlukpQcESsATJ1Z2NT04=";

  nativeBuildInputs = [
    installShellFiles
    mandown
    protobuf
    go-md2man
  ];

  postBuild = ''
    make -C docs netavark.1
    installManPage docs/netavark.1
  '';

  passthru.tests = { inherit (nixosTests) podman; };

  meta = {
    description = "Rust based network stack for containers";
    homepage = "https://github.com/containers/netavark";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ yah ];
    platforms = lib.platforms.linux;
  };
}
