{ pkgs }:
pkgs.python39Packages.buildPythonPackage {
  pname = "aws2-wrap";
  version = "1.3.0";
  src = pkgs.python39Packages.fetchPypi
    {
      pname = "aws2-wrap";
      version = "1.3.0";
      sha256 = "sha256-iiRgXG+wc+T/zrYwAPqKzaihpIYIB7Fsknm8ZM83uv8=";
    };
  propagatedBuildInputs = with pkgs.python39Packages; [
    psutil
  ];
}
