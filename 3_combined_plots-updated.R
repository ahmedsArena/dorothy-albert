# Load necessary libraries
library(ggplot2)
library(gridExtra)
library(ComplexHeatmap)

# Read the CSV file (replace with your actual file path)
data <- read.csv("/home/devlien/test.csv")

# Scatter plot for year of isolation
plot_1 <- ggplot(data, aes(x = year_of_isolation, y = Assembly_accession)) +
  geom_point() +
  labs(x = "Year of Isolation", y = "Assembly Accession") +
  theme_bw()

# Colored box plot for country of isolation
plot_2 <- ggplot(data, aes(x = "", y = Assembly_accession, fill = country_of_isolation)) +
  geom_tile(width = 0.4) +  # Decrease the width of the tiles
  labs(fill = "Country") +
  theme_bw() +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank())

# Colored box plot for AMR profile
plot_3 <- ggplot(data, aes(x = "", y = Assembly_accession, fill = AMR_profile)) +
  geom_tile(width = 0.4) +  # Decrease the width of the tiles
  labs(fill = "AMR Profile") +
  theme_bw() +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank())

# Arrange plots horizontally
grid.arrange(
  plot_1,
  plot_2,
  plot_3,
  ncol = 3
)
# Prepare data for heatmap
gene_data <- data[5:26]  # Select columns containing gene presence/absence
rownames(gene_data) <- data$Assembly_accession

# Convert gene_data to a matrix
gene_data_matrix <- as.matrix(gene_data)

# Create heatmap using the matrix
heatmap <- Heatmap(gene_data_matrix,
                   cluster_rows = FALSE, cluster_columns = FALSE,
                   show_row_names = TRUE, show_column_names = TRUE,
                   name = "Gene Presence/Absence")

# Display the heatmap
draw(heatmap)


#creating tree

library(tidyverse)
library(ggtree)
library(dplyr)

detach("package:dplyr", unload = TRUE)
# Read the tree from the file
tree <- read.tree("/home/yossraf/RAxML_bestTree.rooted_tree")
tree

# Create the basic tree plot with tip labels and a tree scale
p <- ggtree(tree) +
  geom_tiplab() +
  geom_treescale() +
  theme_tree2()

# Customize the tree appearance
ggtree(tree) +
  geom_tiplab() +
  geom_treescale() +
  theme_tree2()
ggtree(tree, branch.length = "none", color = "red", size = 1, linetype = 5)



