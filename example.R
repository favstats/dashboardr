
# ---------- Packages ----------
library(ggplot2)
library(ggpattern)
library(scales)

# ---------- Palettes & order ----------
lvls <- c("Image/Video","Platform","Post text","None")
pal_grey <- c(
  "Image/Video" = "#6e6e6e",  # darkest
  "Platform"    = "#6e6e6e",
  "Post text"   = "#b5b5b5",
  "None"        = "#e8e8e8"   # lightest
)
pat_vals <- c(
  "Image/Video" = "stripe",
  "Platform"    = "crosshatch",
  "Post text"   = "circle",
  "None"        = "none"
)

# ---------- Data prep ----------
stopifnot(all(c("party_ord","pct","pct_label","channel") %in% names(plot_disc)))
plot_disc$channel <- factor(plot_disc$channel, levels = lvls)

# Ensure party_ord is a factor (keep existing order if already a factor)
if (!is.factor(plot_disc$party_ord)) {
  plot_disc$party_ord <- factor(plot_disc$party_ord, levels = unique(plot_disc$party_ord))
}
if ("party_ord" %in% names(party_labels) && !is.factor(party_labels$party_ord)) {
  party_labels$party_ord <- factor(party_labels$party_ord, levels = levels(plot_disc$party_ord))
}

# Parties to render bold on the axis (with ** removed)
majors <- c("CDU/CSU","SPD","AfD","FDP","B90/GRÜNE","LINKE","BSW","Freie Wähler")

# Build plotmath expressions (bold for majors)
ylvls <- levels(plot_disc$party_ord)

# Remove ** from labels for display
ylvls_clean <- gsub("\\*\\*", "", ylvls)

# ---------- HIGHLIGHTED CHANGE START ----------
# Create a named vector for N lookup to ensure correct matching
# NOTE: Replace 'n' with the actual column name containing counts in party_labels
party_counts <- setNames(party_labels$n, party_labels$party_ord)
# ----------------------------------------------

expr_list <- lapply(seq_along(ylvls_clean), function(i) {
  lbl <- ylvls_clean[i]
  
  # ---------- HIGHLIGHTED CHANGE START ----------
  # Retrieve N using the original factor level (ylvls[i])
  n_val <- party_counts[ylvls[i]]
  
  # Append N to the label
  if (!is.na(n_val)) {
    lbl <- paste0(lbl, " (N = ", n_val, ")")
  }
  # ----------------------------------------------

  if (lbl %in% majors) {
    bquote(bold(.(lbl)))
  } else {
    bquote(.(lbl))
  }
})
names(expr_list) <- ylvls  # Keep original names with ** for matching


# ---------- Plot ----------
p_disc_party <- ggplot(
  plot_disc,
  aes(x = party_ord, y = pct, fill = channel, pattern = channel)
) +
  geom_col_pattern(
    width = 0.9, color = "grey30", linewidth = 0.15,
    pattern_fill    = "black",
    pattern_colour  = NA,
    pattern_density = 0.30,
    pattern_spacing = 0.02,
    pattern_angle   = 35
  ) +
  # Inside-bar percent labels (white on dark; black on light)
  # geom_text(
  #   aes(label = pct_label,
  #       colour = ifelse(channel %in% c("Image/Video","Platform"), "dark", "light")),
  #   position = position_stack(vjust = 0.5),
  #   size = 2.8, fontface = "bold"
  # ) +
  scale_colour_manual(values = c(dark = "white", light = "black"), guide = "none") +
  # Right-edge total labeled %
  geom_text(
    data = party_labels,
    aes(x = party_ord, y = 1.02, label = any_label),
    inherit.aes = FALSE,
    hjust = 0, size = 3.2, fontface = "bold"
  ) +
  geom_label(
    aes(label = pct_label),
            # inherit.aes = FALSE, #size = 3,
    fill = alpha("white", 0.8),   # semi-transparent background
      position = position_stack(vjust = 0.5),
    colour = "black",              # text color
    label.size = 0,                # no border
    label.r = unit(2, "pt"),       # small rounded corners (use 0 for square)
    label.padding = unit(2, "pt"), # compact padding
    size = 3.2, lineheight = 0.95) +
  coord_flip(clip = "off") +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.15))) +
  # Axis labels with plotmath (bold for majors)
  scale_x_discrete(limits = ylvls, labels = expr_list) +
  # Greys + patterns (merged legend: same name, limits, breaks)
  scale_fill_manual(values = pal_grey, limits = lvls, breaks = lvls,
                    name = "Disclaimer type") +
  scale_pattern_manual(values = pat_vals, limits = lvls, breaks = lvls,
                       name = "Disclaimer type") +
  guides(
    fill    = guide_legend(order = 1),
    pattern = guide_legend(order = 1,
      override.aes = list(pattern_density = .30, pattern_spacing = .02,
                          pattern_fill = "black", pattern_colour = NA))
  ) +
  labs(x = NULL, y = "Share of (AI) posts") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position    = "top",
    legend.key.width   = grid::unit(18, "pt"),
    legend.key.height  = grid::unit(12, "pt"),
    panel.grid.major.y = element_blank(),
    axis.text.y        = element_text(),
    axis.text.x        = element_text()
  )

p_disc_party


ggsave("img/pXX_disclaimers_by_party.png", p_disc_party,
       width = 12, height = 9, dpi = 900, bg = "white")