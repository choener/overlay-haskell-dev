self: super: {

hsDevFunctions = ((import ./hsdevfunctions) self super).hsDevFunctions;

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

}
