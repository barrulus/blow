{
  lib,
  stdenv,
  runCommand,
  zig_0_16,
  makeWrapper,
  git,
  ripgrep,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "flow-control";
  version = "0.7.2";

  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ../build.zig
      ../build.zig.zon
      ../help.md
      ../src
      ../test
    ];
  };

  zigDependencyArchives = zig_0_16.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-thwkL3kSUSHiacDVxeun+qjalzi5dC0Md4STN+iwqfg=";
  };

  # Zig 0.16 fetches compressed packages, but --system expects directories.
  zigDeps = runCommand "flow-control-zig-deps-unpacked" { } ''
    mkdir -p "$out"
    for archive in ${finalAttrs.zigDependencyArchives}/*.tar.gz; do
      package=$(basename "$archive" .tar.gz)
      mkdir "$out/$package"
      tar -xzf "$archive" -C "$out/$package" --strip-components=1
    done
  '';

  nativeBuildInputs = [
    zig_0_16
    makeWrapper
  ];
  env.VERSION = finalAttrs.version;
  strictDeps = true;
  dontSetZigDefaultFlags = true;
  zigBuildFlags = [
    "--system"
    "${finalAttrs.zigDeps}"
    "-Dcpu=baseline"
    "-Dtarget=${stdenv.hostPlatform.parsed.cpu.name}-linux-musl"
    "-Doptimize=ReleaseSafe"
    "-Drenderer=terminal"
  ];

  postFixup = ''
    wrapProgram "$out/bin/flow" --prefix PATH : ${
      lib.makeBinPath [
        git
        ripgrep
      ]
    }
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export FLOW_CONFIG_DIR="$TMPDIR/flow-install-check"
    "$out/bin/flow" --help > /dev/null
    "$out/bin/flow" --version > version.txt
    grep -Fq "version: ${finalAttrs.version}" version.txt
    "$out/bin/flow" --list-languages > languages.txt
    grep -q zig languages.txt
    runHook postInstallCheck
  '';

  meta = {
    description = "Programmer's text editor with tree-sitter syntax highlighting";
    homepage = "https://github.com/barrulus/blow";
    license = lib.licenses.mit;
    mainProgram = "flow";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
