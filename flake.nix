{
  description = "hello world application using uv2nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixR.url = "github:tyberiusprime/nixR";
  };

  outputs =
    {
      nixpkgs,
      nixR,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      R =
        nixR
        #."2026-04-29" [
        #."2025-11-06"
        #."2025-10-30" # to new, APALyzer removed in bioc 3.22
        ."2025-10-29"
          [
            "apeglm"
            "APAlyzer"
            "clusterProfiler"
            "data.table"
            "DESeq2"
            "dplyr"
            "DT"
            "EnhancedVolcano"
            "enrichplot"
            "ggplot2"
            "ggpubr"
            "ggvenn"
            "org.Hs.eg.db"
            "org.Mm.eg.db"
            "pheatmap"
            "purrr"
            "RColorBrewer"
            "readr"
            "repmis"
            "Rsamtools"
            "shiny"
            "shinyalert"
            "shinythemes"
            "splitstackshape"
            "SummarizedExperiment"
            "TCGAbiolinks"
            "tidyverse"
            "VennDiagram"
            "TBX20BamSubset"
          ];

      binPrefix = "Apatizer";

    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # everything that should be available in the devshell AND on the
          # PATH of the Apatizer_* wrappers
          devshellPackages = [
            R
            pkgs.snakemake
            pkgs.python314Packages.htseq
            pkgs.python3
            pkgs.gatk
          ];
        in
        {
          default = pkgs.mkShell {
            packages = devshellPackages;
            env = {
            };
            shellHook = ''
              #unset PYTHONPATH
              #export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # PATH components for the wrappers: the same tools as in the devshell
          wrapperPath = lib.makeBinPath ([
            R
            pkgs.snakemake
            pkgs.python314Packages.htseq
            pkgs.python3
            pkgs.gatk
          ]);

          # exports R/bin/* as bin/${binPrefix}_*, with PATH set up so that
          # snakemake, htseq, python, gatk (and R itself) are reachable from
          # the wrapped R / Rscript
          apatizer =
            pkgs.runCommand "apatizer-wrapped-R"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
                meta = {
                  description = "R (${binPrefix} wrapper) with the APAtizer toolchain on PATH";
                  mainProgram = "${binPrefix}_Rscript";
                };
                passthru = { inherit R; };
              }
              ''
                mkdir -p $out/bin
                for target in ${R}/bin/*; do
                  name="$(basename "$target")"
                  makeWrapper "$target" "$out/bin/${binPrefix}_$name" \
                    --prefix PATH : '${wrapperPath}' \
                    --set SHELL ${pkgs.runtimeShell}
                done
              '';
        in
        {
          apatizer = apatizer;
          default = apatizer;
        }
      );
    };
}
