# overlay-haskell-dev
haskell development related functionality

Currently, this overlay helps dealing with large, private, interdependent Haskell repositories.

My setup is basically:

- ```./dir/project-1```
- ```...```
- ```./dir/project-N```

where the different projects form a directed acyclic graph.

The following ```default.nix``` is needed in the current project:
```
with (import <nixpkgs> {});
hsDevFunctions ./.
```

Enter the Haskell environment with:
```nix-shell --arg overrideParDir ~/dir/ -A hsShell```
- ```overrideParDir``` can be a list as well: ```"[ ./dir ./other ]"```
- ```overrideParDir``` can be missing

One may build a project via ```nix-build -A hsBuild```
One may use ```--arg overrideParDir``` for hsBuild, too.

```hsDevFunctions``` currently exports ```hsShell```, ```hsBuild```, and
```haskellPackages```. The latter might is useful for complex scripts.



## NOTES

- Currently, the ```master``` branch of nixpkgs is required because
  https://github.com/NixOS/nixpkgs/issues/45318 needs to be fixed.
  (Alternatively, an older version may be used before the bug-introducing
  change)



#### Contact

Christian Hoener zu Siederdissen  
Leipzig University, Leipzig, Germany  
choener@bioinf.uni-leipzig.de  
http://www.bioinf.uni-leipzig.de/~choener/  

