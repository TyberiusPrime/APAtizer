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

      apatizer_build =
        pkgs:
        pkgs.stdenv.mkDerivation rec {
          name = "apatizer";
          version = "0.1";
          src = ./.;
          buildPhase = ''
            mkdir $out
            cp ${src}/* $out -r
            mkdir $out/bin -p
            printf "#!/bin/sh\necho '$out'" > $out/bin/find_apatizer_source
            chmod +x $out/bin/find_apatizer_source
          '';
        };

    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # the APAtizer toolchain (also the input bins of the packages.apatizer
          # symlink forest)
          devshellPackages = [
            R
            pkgs.snakemake
            pkgs.python314Packages.htseq
            pkgs.python3
            pkgs.gatk
            pkgs.hisat2
            (apatizer_build pkgs)
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

          # symlink forest of all the tool bins (R, Rscript, snakemake,
          # htseq-*, python3, hisat2, gatk, ...) in a single bin/ directory
          apatizer = pkgs.symlinkJoin {
            name = "apatizer-env";
            paths = [
              R
              pkgs.snakemake
              pkgs.python314Packages.htseq
              pkgs.python3
              pkgs.hisat2
              pkgs.gatk
              (apatizer_build pkgs)
            ];
            meta = {
              description = "APAtizer toolchain: R with snakemake, htseq, python, hisat2 and gatk";
              mainProgram = "Rscript";
            };
            passthru = { inherit R; };
          };
        in
        {
          apatizer = apatizer;
          default = apatizer;
        }
      );
    };
}
