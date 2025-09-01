{
  pkgs ? import <nixpkgs> { }
}:

with pkgs;

stdenv.mkDerivation {
  pname = "widgetbinding";
  version = "0.0.1";
  src = ../.; # also include ../utils/pyside_config.py
  nativeBuildInputs = [
    cmake
    # kdePackages.extra-cmake-modules # ECMGeneratePythonBindings.cmake
    (python3.withPackages (pp: with pp; [
      shiboken6
      pyside6
      # build # ECMGeneratePythonBindings.cmake
    ]))
  ];
  buildInputs = [
    qt6.qtbase
    # glibc_multi # stdc-predef.h stdlib.h ...
  ];
  # debug
  /*
  preUnpack = ''
    echo kdePackages.extra-cmake-modules = ${kdePackages.extra-cmake-modules}
    echo python3.pkgs.shiboken6 = ${python3.pkgs.shiboken6}
    echo python3.pkgs.pyside6 = ${python3.pkgs.pyside6}
    # exit 1
  '';
  */
  preConfigure = ''
    set -x
    python utils/pyside_config.py --shiboken-module-shared-libraries-cmake
    python utils/pyside_config.py --shiboken-generator-path
    python utils/pyside_config.py --pyside-include-path
    python utils/pyside_config.py --shiboken-include-path
    set +x
    cd widgetbinding
  '';
  # help cmake find ${kdePackages.extra-cmake-modules}/share/ECM/modules/ECMGeneratePythonBindings.cmake
  cmakeFlags = [
    # "-DCMAKE_MODULE_PATH=${kdePackages.extra-cmake-modules}/share/ECM/modules"
  ];
  dontWrapQtApps = true;
  # enableParallelBuilding = false; # debug
  # preBuild = "set -x"; # debug
  # makeFlags = [ "-d" ]; # debug
  # debug: what env-vars contain C++ include paths
  /*
  buildCommand = ''
    env | grep -- -iconv- | while read -r line; do
      parts=($(echo "$line" | tr '[:=]' ' '))
      key=''${parts[0]}
      for val in ''${parts[@]}; do
        if echo "$val" | grep -q -- -iconv-; then
          echo "$key $val"
        fi
      done
    done
    exit 1
  '';
  */
  # fix: RPATH of binary $out/lib/wiggly.so contains a forbidden reference to /build/
  # patchelf --replace-needed libwiggly.so $out/lib/libwiggly.so wiggly.so
  # $ORIGIN = dirname of wiggly.so
  postBuild = ''
    patchelf --replace-needed libwiggly.so \$ORIGIN/libwiggly.so wiggly.so
  '';
  postInstall = ''
    mkdir -p $out/bin
    ln -sr $out/lib/main.py $out/bin/wiggly
    chmod +x $out/lib/main.py
  '';
}
