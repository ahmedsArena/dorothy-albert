#!/bin/bash

# Define base directory
base_dir="/home/devlien/Stage_3"

# Create necessary directories
mkdir -p "$base_dir/Genomes"
mkdir -p "$base_dir/Reference"
mkdir -p "$base_dir/gubbins"
mkdir -p "$base_dir/raxml-ng"
mkdir -p "$base_dir/Snippy"
mkdir -p "$base_dir/snp_sites"
mkdir -p "$base_dir/snp-dists" 

# Subset of filtered genome assemblies accessions
accessions=(
    GCA_010456585.1
    GCA_007005205.1
    GCA_006991505.1
    GCA_007356445.1
    GCA_007659725.1
    GCA_006396155.1
    GCA_006405415.1
    GCA_006431955.1
    GCA_029370385.1
    GCA_029345665.1
    GCA_029370325.1
    GCA_029370305.1
    GCA_029370285.1
    GCA_029345605.1
    GCA_029345565.1
    GCA_029370245.1
    GCA_029350065.1
    GCA_029370145.1
    GCA_029350245.1
    GCA_029345505.1
    GCA_029370105.1
    GCA_029370005.1
    GCA_029369885.1
    GCA_029680145.1
    GCA_029344205.1
    GCA_029344165.1
    GCA_029344145.1
    GCA_029368665.1
    GCA_029344945.1
    GCA_029368645.1
    GCA_029349095.1
    GCA_029368565.1
    GCA_029680085.1
    GCA_029344925.1
    GCA_029368625.1
    GCA_029368585.1
    GCA_029349005.1
    GCA_029368545.1
    GCA_029368485.1
    GCA_029348905.1
    GCA_029368465.1
    GCA_029368405.1
    GCA_029368425.1
    GCA_029368385.1
    GCA_029368365.1
    GCA_029368345.1
    GCA_029348925.1
    GCA_029343965.1
    GCA_029368285.1
    GCA_011269625.1
)

# Reference genome accession
reference_accession="GCA_008727535.1"

# Function to download and rename genomes
download_and_rename() {
    # Download genomes and extract to Genomes directory
    cd "$base_dir/Genomes"
    datasets download genome accession ${accessions[*]} --filename genomes.zip
    unzip genomes.zip && rm genomes.zip
    find ncbi_dataset/data -name "*.fna" -exec mv {} ./ \;

    # Rename downloaded .fna files
    for file in *.fna; do
        new_name=$(echo "$file" | sed 's/_PDT.*\.fna/.fna/')
        mv "$file" "$new_name"
    done

    rm -rf ncbi_dataset README.md

    # Check if .fna files are moved successfully
    if [ $(ls *.fna | wc -l) -eq 0 ]; then
        echo "ERROR: No genome files were moved."
        exit 1
    fi
}

# Function to download and setup the reference genome
download_reference() {
    cd "$base_dir/Reference"
    datasets download genome accession $reference_accession --filename reference.zip
    unzip reference.zip && rm reference.zip
    find ncbi_dataset/data -name "*.fna" -exec mv {} ./ \;

    # Rename reference .fna file
    mv *.fna "$reference_accession.fna"

    rm -rf ncbi_dataset README.md

    # Verify that the reference genome file is moved correctly
    if [ ! -f "$reference_accession.fna" ]; then
        echo "ERROR: Reference genome file was not moved."
        exit 1
    fi
}

# Run Snippy on renamed genomes
run_snippy() {
    REFERENCE_FILE="$base_dir/Reference/$reference_accession.fna"
    OUTPUT_DIR="$base_dir/Genomes"
    INPUT_TAB="$base_dir/Snippy/input.tab"

    ls $OUTPUT_DIR/*.fna | xargs -n 1 basename | sed 's/\.fna//' | awk -v dir="$OUTPUT_DIR" '{print $1 "\t" dir "/" $1 ".fna"}' > $INPUT_TAB

    cd "$base_dir/Snippy"
    snippy-multi $INPUT_TAB --ref $REFERENCE_FILE --cpus 16 > runme.sh
    chmod +x runme.sh
    ./runme.sh
}

# Gubbins analysis
run_gubbins() {
    cd "$base_dir/gubbins"
    run_gubbins.py --prefix "gubbins" --threads 16 "$base_dir/Snippy/core.full.aln"
}

# SNP-sites to create a SNP-only alignment
run_snp_sites() {
    cd "$base_dir/snp_sites"
    snp-sites -o snp_sites -m -v -p "$base_dir/gubbins/gubbins.filtered_polymorphic_sites.fasta"
}

# RAxML analysis
run_raxml() {
    cd "$base_dir/raxml-ng"
    raxml-ng --msa "$base_dir/snp_sites/snp_sites.snp_sites.aln" --model GTR+G+ASC_LEWIS --tree rand{100} --prefix raxml --threads auto --seed 42 --search

    cd "$base_dir/raxml-ng"  # Ensure we are in the correct directory
    raxmlHPC -m GTRGAMMA -s "$base_dir/snp_sites/snp_sites.snp_sites.aln" -t "$base_dir/raxml-ng/raxml.raxml.bestTree" -o GCA_011269625.1 -n rooted_tree
}

# SNP-dists to calculate SNP distances
run_snp_dists() {
    cd "$base_dir/snp-dists"
    snp-dists "$base_dir/snp_sites/snp_sites.snp_sites.aln" > distances.tab
    cat distances.tab
}

# Main script
echo "Downloading and renaming genomes..."
download_and_rename

echo "Downloading and setting up the reference genome..."
download_reference

echo "Running Snippy on renamed genomes..."
run_snippy

echo "Running Gubbins analysis..."
run_gubbins

echo "Creating SNP-only alignment..."
run_snp_sites

echo "Running RAxML analysis..."
run_raxml

echo "Calculating SNP distances..."
run_snp_dists

echo "Pipeline execution complete!"

