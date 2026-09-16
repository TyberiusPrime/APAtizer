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
          ];

    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              R
              pkgs.snakemake
              pkgs.python314Packages.htseq
              pkgs.python3
              pkgs.gatk
            ];
            env = {
            };
            shellHook = ''
              #unset PYTHONPATH
              #export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
        }
      );

      # packages = forAllSystems (system: {
      #   default = pythonSets.${system}.mkVirtualEnv "hello-world-env" workspace.deps.default;
      # });
    };
}
