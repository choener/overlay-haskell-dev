self: super:

{

hsDevFunctions = ((import ./hsdevfunctions) self super).hsDevFunctions;

#snackify = (import ./snack) self super;

vimPlugins = super.vimPlugins // {
  ghcid = self.vimUtils.buildVimPlugin {
    name = "vim-ghcid";
    src = self.fetchFromGitHub {
      owner = "ndmitchell";
      repo = "ghcid";
      rev = "50eb9908d6da67e5e4b4e6db2828b81bd7468ae3";
      sha256 = "0wbp44gvb0rljqjr58slsqzzzy9knn9lfl4xdhwwczw7dvz594vb";
    };
    sourceRoot = "source/plugins/nvim";
  };
};

# easy dependency management with niv (not just for Haskell stuff)
# This is a set, niv is under @niv.niv@

#niv = import (self.fetchFromGitHub {
#    owner  = "nmattia";
#    repo   = "niv";
#    rev    = "8b7b70465c130d8d7a98fba1396ad1481daee518";
#    sha256 = "0fgdrxn2vzpnzr6pxaiyn5zzbd812c6f7xjjhfir0kpzamjnxwwl";
#  }) {};

}

