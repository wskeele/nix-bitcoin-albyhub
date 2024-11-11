{ buildGoModule, fetchFromGitHub }: buildGoModule rec {
  pname = "albyhub";
  version = "1.10.4";

  src = fetchFromGitHub {
    owner = "getAlby";
    repo = "hub";
    rev = "v${version}";
    hash = "sha256-FIgWwQ6K7zJNUhVWW75oYZjvnOMOwgLCxhFYeJWHAM4=";
  };

  vendorHash = "sha256-5ZLW6WdGi479hacOWMPGNKO5CrilPoa9ZN0EW80poic=";
}
