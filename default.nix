self: super: {


# hsDevFunctions provides to attributes: hsShell and hsBuild that enable a
# development environment and a build environment. In case overrideParDir is
# given, that directory is scanned for additional packages.
#  > with (import <nixpkgs> {});
#  > hsDevFunctions ./.

# TODO change overrideParDir into a list of such directories.

hsDevFunctions = thisDir: { overrideParDir ? null }:
  let
    # check child directories below this one
    parentContent = builtins.readDir overrideParDir;
    # extract sibling folders that contain a default.nix file
    parentDirs = builtins.filter (d: builtins.pathExists (overrideParDir + ("/" + d + "/default.nix"))) (builtins.attrNames parentContent);
    # construct set of names / source directories for override
    hsSrcSet = builtins.listToAttrs (map (d: {name = "${d}"; value = overrideParDir + ("/" + d);}) parentDirs);
    # extend the set of packages with source overrides
    hsPkgs = if (isNull overrideParDir) then self.haskellPackages else self.haskellPackages.extend (self.haskell.lib.packageSourceOverrides hsSrcSet);
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

