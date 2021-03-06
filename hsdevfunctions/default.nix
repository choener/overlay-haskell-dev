self: super: {

# hsDevFunctions provides to attributes: hsShell and hsBuild that enable a
# development environment and a build environment. In case overrideParDir is
# given, that directory is scanned for additional packages.
#  > with (import <nixpkgs> {});
#  > hsDevFunctions ./.

# @--argstr ghc ghc863@ will use ghc863 instead of the default ghc
# @env-haskell-nixos --argstr ghc ghc863@ is such a call

hsDevFunctions = thisDir: { overrideParDir ? null, ghc ? null }:
  with builtins;
  let
    # check child directories below this one
    parentContentSel = {
      # we have multiple directories with overrides, later ones override
      # earlier ones.
      "list" = super.lib.lists.foldl' (s: p: s // eachOverrideParDir p) {} overrideParDir;
      # actually not needed due to laziness.
      "null" = {};
      # single directory with overrides.
      "path" = eachOverrideParDir overrideParDir;
    };
    eachOverrideParDir = opd:
      let
        # extract sibling folders that contain a default.nix file
        parentDir = builtins.filter (d: builtins.pathExists (opd + ("/" + d + "/default.nix"))
                                        || builtins.pathExists (opd + "/" + d + "/envhs.nix")
                                    )
                    (builtins.attrNames  (readDir opd));
        # construct set of names / source directories for override
        hsSrcSet = builtins.listToAttrs (map (d: {name = "${d}"; value = opd + ("/" + d);}) parentDir);
      in if pathExists opd then hsSrcSet else {};
    # select how to process based on the type of the pardir argument
    globalhsSrcSets = (parentContentSel."${typeOf overrideParDir}");

    # any local overrides? These have higher precedence!
    overridesFile = thisDir + "/overrides.nix";
    localOverrides = if pathExists (toPath overridesFile)
      then (import overridesFile) self
      else {};

    # haskell-ci
    haskell-ci = if builtins.pathExists <unstable> then [ (import <unstable> {}).haskell-ci ] else [];

    # my own little tool
    cabalghcisrc = builtins.fetchGit {
      url = let local = ~/Documents/University/devel/ghcicabal;
            in  (if builtins.pathExists local then local else https://github.com/choener/ghcicabal);
      ref = "master";
    };
    cabalghci = self.haskellPackages.callPackage cabalghcisrc {};

    # hsSrcSets = globalhsSrcSets // localOverrides;
    # these are now package-ified source overrides
    #srcOverrides = self.haskell.lib.packageSourceOverrides hsSrcSets;
    # where we disable all testing, except for the current package, which we benchmark as well
    #noTestOverrides = (x: y: z: let a = x y z; in mapAttrs
    #  (name: drv: if name != this then self.haskell.lib.dontCheck drv else self.haskell.lib.doBenchmark drv
    #  ) a) srcOverrides;
    # extend the set of packages with source overrides
    #hsPkgs = if isNull ghc
    #  then self.haskellPackages.extend noTestOverrides
    #  else self.haskell.packages.${ghc}.extend noTestOverrides;
    #
    # two lines below don't work because we don't capture interdependencies between our local packages!
    #
    #srcOverrides = mapAttrs (name: path: super.haskellPackages.callPackage path {}) hsSrcSets;
    #noTestOverrides = mapAttrs (name: drv: if name != this then self.haskell.lib.dontCheck drv else self.haskell.lib.doBenchmark drv) srcOverrides;
    #
    hsPkgs = self.haskellPackages.override {
      overrides = hself: hsuper:
        ( mapAttrs (name: drv: if name != this then self.haskell.lib.dontCheck drv else self.haskell.lib.doBenchmark drv)
          (mapAttrs (name: path: hself.callPackage path {}) globalhsSrcSets)
        ) // ( if pathExists (toPath (thisDir + "/overrides/"))
                then (self.haskell.lib.packagesFromDirectory { directory = (thisDir + "/overrides/"); }) hself hsuper else {}
        );
    };
    # name of this module
    # this = builtins.trace (self.cabal-install.patches or null) (baseNameOf thisDir);
    this = (baseNameOf thisDir);
  in {

    # the hsShell gives a build environment in which we can run @cabal repl / cabal new-repl@
    hsShell = hsPkgs.shellFor {
      packages = p: [ p."${this}" ];
      withHoogle = true;
      buildInputs = [
        self.cabal-install
        self.llvm
        self.haskellPackages.ghcid # can use current default
        self.haskellPackages.hpack # can use current default
        cabalghci
        # hsPkgs.nvim-hs-ghcid
      ] # ++ (if self ? hssnack then [ self.hssnack.snack-exe ] else [])
        ++ haskell-ci;
    }; # hsShell

    # hsBuild provides the option to completely build the project and place the result symlink
    # nix-build -A hsBuild
    # this shall build and put into ./result
    # the result is a typical ./bin/; ./lib/ etc.
    hsCallCabal = hsPkgs.callCabal2nix "${this}" thisDir {};

    # provide haskellPackages again
    haskellPackages = hsPkgs;

    # provide a statically built package
    #
    # nix-build --arg overrideParDir "~/Documents/University/devel" static.nix -A hsCallStatic
    #
    # cat static.nix:
    # with (import <nixpkgs> {}).pkgsMusl;
    # hsDevFunctions ./.
    #
    # TODO llvm
    #
    hsCallStatic =
      let ps = self // { haskellPackages = hsPkgs; };
          thisDeriv = ps.haskell.lib.dontCheck (ps.haskell.lib.dontBenchmark (ps.haskell.lib.overrideCabal (ps.haskellPackages.callPackage thisDir {}) (drv: staticFlags)));
          staticFlags =
            { isLibrary = false;
              isExecutable = true;
              enableSharedExecutables = false;
              enableSharedLibraries = false;
              enableLibraryProfiling = false;
              configureFlags = [
                "--ghc-option=-optl=-static"
                "--extra-lib-dirs=${ps.gmp6.override { withStatic = true; }}/lib"
                "--extra-lib-dirs=${ps.zlib.static}/lib"
                "--extra-lib-dirs=${ps.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib"
              ];
            };
      in  thisDeriv;

    # return everything again
    pkgs = self // { haskellPackages = hsPkgs; };
  }; # return set

} # self,super

