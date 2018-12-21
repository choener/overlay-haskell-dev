self: super: {

hsDevFunctions = ((import ./hsdevfunctions) self super).hsDevFunctions;

vimPlugins.ghcid = self.vimUtils.buildVimPlugin {
  name = "vim-ghcid";
  src = self.fetchFromGitHub {
    owner = "ndmitchell";
    repo = "ghcid";
    rev = "b38d16bae64e036063650279d2811d13368b5b55";
    sha256 = "083d12cp4cldlmc0fqxj3j4xpa9azgbbd2392s7b9pp6rjk0gcjn";
  };
  sourceRoot = "source/plugins/nvim";
};

}
