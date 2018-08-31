self: super: {

# hsDevFunctions provides to attributes: hsShell and hsBuild that enable a
# development environment and a build environment. In case overrideParDir is
# given, that directory is scanned for additional packages.
#  > with (import <nixpkgs> {});
#  > hsDevFunctions ./.

# TODO change overrideParDir into a list of such directories.

hsDevFunctions = thisDir: { overrideParDir ? null }:
  with builtins;
  let
    # check child directories below this one
    parentContentSel = {
      # we have multiple directories with overrides, later ones override
      # earlier ones.
      "list" = super.lib.lists.foldl' (s: p: s // eachOverrideParDir p) {} overrideParDir;
      # actually not needed due to laziness.
      "null" = [];
      # single directory with overrides.
      "path" = eachOverrideParDir overrideParDir;
    };
    eachOverrideParDir = opd:
      let
        # extract sibling folders that contain a default.nix file
        parentDir = builtins.filter (d: builtins.pathExists (overrideParDir + ("/" + d + "/default.nix")))
                    (builtins.attrNames  (readDir opd));
        # construct set of names / source directories for override
        hsSrcSet = builtins.listToAttrs (map (d: {name = "${d}"; value = opd + ("/" + d);}) parentDir);
      in hsSrcSet;
    # select how to process based on the type of the pardir argument
    hsSrcSets = (parentContentSel."${typeOf overrideParDir}");
    # extend the set of packages with source overrides
    hsPkgs = if (isNull overrideParDir)
             then self.haskellPackages
             else self.haskellPackages.extend (self.haskell.lib.packageSourceOverrides hsSrcSets);
    # name of this module
    # this = builtins.trace (self.cabal-install.patches or null) (baseNameOf thisDir);
    this = (baseNameOf thisDir);
  in {
    hsShell = hsPkgs.shellFor {
      packages = p: [ p."${this}" ];
      withHoogle = true;
      buildInputs = [
        self.cabal-install
      ];
    }; # hsShell
    # nix-build -A hsBuild
    # this shall build and put into ./result
    # the result is a typical ./bin/; ./lib/ etc.
    hsBuild = hsPkgs.callCabal2nix "${this}" ./. {};
  }; # return set


} # self,super

