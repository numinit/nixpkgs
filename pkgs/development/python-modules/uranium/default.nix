{ stdenv, buildPythonPackage, fetchFromGitHub, python, cmake
, pyqt5, numpy, scipy, libarcus, doxygen, gettext, pythonOlder }:

buildPythonPackage rec {
  version = "3.4.1";
  pname = "uranium";
  format = "other";

  src = fetchFromGitHub {
    owner = "Ultimaker";
    repo = "Uranium";
    rev = version;
    sha256 = "1r6d65c9xfkn608k6wv3dprpks5h8g2v9mi4a67ifpzyw4y3f0rk";
  };

  disabled = pythonOlder "3.5.0";

  buildInputs = [ python gettext ];
  propagatedBuildInputs = [ pyqt5 numpy scipy libarcus ];
  nativeBuildInputs = [ cmake doxygen ];

  postPatch = ''
    sed -i 's,/python''${PYTHON_VERSION_MAJOR}/dist-packages,/python''${PYTHON_VERSION_MAJOR}.''${PYTHON_VERSION_MINOR}/site-packages,g' CMakeLists.txt
    sed -i \
     -e "s,Resources.addSearchPath(os.path.join(os.path.abspath(os.path.dirname(__file__)).*,Resources.addSearchPath(\"$out/share/uranium/resources\")," \
     -e "s,self._plugin_registry.addPluginLocation(os.path.join(os.path.abspath(os.path.dirname(__file__)).*,self._plugin_registry.addPluginLocation(\"$out/lib/uranium/plugins\")," \
     UM/Application.py
  '';

  meta = with stdenv.lib; {
    description = "A Python framework for building Desktop applications";
    homepage = https://github.com/Ultimaker/Uranium;
    license = licenses.agpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ abbradar ];
  };
}
