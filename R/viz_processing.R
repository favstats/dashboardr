# =================================================================
# viz_processing
# =================================================================


#' This function handles both viz_collection objects and plain lists of visualization
#' specifications. It:
#' - Attaches data_path to each visualization
#' - Groups visualizations by their tabgroup parameter (supports nested hierarchies)
#' - Converts single-item groups to standalone visualizations with group titles
#' - Creates tab group objects for multi-item groups
#' - Applies custom tab group labels if provided
#' @keywords internal
.process_visualizations <- function(viz_input, data_path, tabgroup_labels = NULL) {
  # Handle different input types
  if (inherits(viz_input, "viz_collection") || inherits(viz_input, "content_collection")) {
    if (is.null(viz_input) || length(viz_input$items) == 0) {
      return(NULL)
    }
    viz_list <- viz_input$items
    tabgroup_labels <- viz_input$tabgroup_labels
  } else if (is.list(viz_input)) {
    if (length(viz_input) == 0) {
      return(NULL)
    }
    viz_list <- viz_input
  } else {
    return(NULL)
  }

  # Attach data path to each visualization
  # Only attach if data_path is a single path (not a list of paths for multi-dataset)
  if (!is.null(data_path) && !is.list(data_path)) {
    for (i in seq_along(viz_list)) {
      viz_list[[i]]$data_path <- data_path
    }
  } else if (is.list(data_path)) {
    # For multi-dataset pages, mark that data exists but don't attach specific path
    # The viz's `data` parameter will determine which dataset to use
    for (i in seq_along(viz_list)) {
      viz_list[[i]]$has_data <- TRUE
      viz_list[[i]]$multi_dataset <- TRUE
    }
  }

  # IMPORTANT: Extract pagination markers BEFORE processing hierarchy
  # They need to preserve their original sequential position
  pagination_positions <- list()  # Store position and marker for each pagination
  viz_only_list <- list()  # Visualizations without pagination markers
  
  for (i in seq_along(viz_list)) {
    viz <- viz_list[[i]]
    if (!is.null(viz$type) && viz$type == "pagination") {
      # Store pagination marker with its original position
      pagination_positions[[length(pagination_positions) + 1]] <- list(
        position = i,
        marker = viz
      )
    } else {
      # Regular viz - add to processing list
      viz_only_list <- c(viz_only_list, list(viz))
    }
  }
  
  # SMART APPROACH: Only use filter grouping when needed
  # Detect if we have multiple parent tabs with same root but different filters
  
  # Step 1: Analyze structure - check for multiple parents with same root but different filters
  root_parents <- list()  # Track parent tabs by root name
  root_nested <- list()   # Track nested tabs by root name
  
  for (viz in viz_only_list) {
    if (!is.null(viz$tabgroup) && length(viz$tabgroup) > 0) {
      root_name <- viz$tabgroup[1]
      
      if (length(viz$tabgroup) == 1) {
        # This is a parent tab
        if (is.null(root_parents[[root_name]])) {
          root_parents[[root_name]] <- list()
        }
        root_parents[[root_name]] <- c(root_parents[[root_name]], list(viz))
      } else {
        # This is a nested tab
        if (is.null(root_nested[[root_name]])) {
          root_nested[[root_name]] <- list()
        }
        root_nested[[root_name]] <- c(root_nested[[root_name]], list(viz))
      }
    }
  }
  
  # Step 2: Determine which roots need filter-based grouping
  needs_filter_grouping <- list()
  for (root_name in names(root_parents)) {
    parents <- root_parents[[root_name]]
    
    # Check if there are nested tabs at this root
    has_nested <- !is.null(root_nested[[root_name]]) && length(root_nested[[root_name]]) > 0
    
    if (length(parents) > 1) {
      # Multiple parents - check if they have different filters
      filters <- sapply(parents, function(v) .get_filter_signature(v))
      unique_filters <- unique(filters)
      if (length(unique_filters) > 1) {
        # Multiple parents with different filters - needs special handling
        needs_filter_grouping[[root_name]] <- TRUE
      } else {
        needs_filter_grouping[[root_name]] <- FALSE
      }
    } else if (length(parents) == 1 && has_nested) {
      # Single parent but with nested children
      # If the parent has a filter AND there are nested children with filters,
      # we need filter grouping to properly nest them
      parent_filter <- .get_filter_signature(parents[[1]])
      if (nzchar(parent_filter)) {
        # Parent has a filter - check if any nested items also have filters
        nested_items <- root_nested[[root_name]]
        nested_has_filters <- any(sapply(nested_items, function(v) {
          !is.null(v$filter)
        }))
        needs_filter_grouping[[root_name]] <- nested_has_filters
      } else {
        needs_filter_grouping[[root_name]] <- FALSE
      }
    } else {
      needs_filter_grouping[[root_name]] <- FALSE
    }
  }
  
  # Step 3: Build hierarchy using appropriate strategy
  if (any(unlist(needs_filter_grouping))) {
    # Use filter-based grouping for roots that need it
    tree <- list(visualizations = list(), children = list())
    
    # Group by root+filter for roots that need it
    root_groups <- list()
    
    for (viz in viz_only_list) {
      if (is.null(viz$tabgroup)) {
        # No tabgroup - add to root level
        tree$visualizations <- c(tree$visualizations, list(viz))
      } else {
        root_name <- viz$tabgroup[1]
        
        if (isTRUE(needs_filter_grouping[[root_name]])) {
          # This root needs filter grouping
          # Non-filtered items should still be grouped under this root, just with empty filter signature
          # This keeps them nested under the correct parent (e.g., sis/time under sis)
          filter_sig <- .get_filter_signature(viz)  # Will be "" for items without filter
          group_key <- paste0(root_name, "::", filter_sig)
          
          if (is.null(root_groups[[group_key]])) {
            root_groups[[group_key]] <- list()
          }
          root_groups[[group_key]] <- c(root_groups[[group_key]], list(viz))
        } else {
          # Standard hierarchy building
          tree <- .insert_into_hierarchy(tree, viz$tabgroup, viz)
        }
      }
    }
    
    # Build separate trees for filter groups
    # First, process standard items into tree
    standard_tree <- tree
    
    # Then create filter-grouped structure
    filter_grouped_trees <- list()
    
    # Add standard tree items (roots that don't need filter grouping) to result directly
    standard_result <- .tree_to_viz_list(standard_tree, tabgroup_labels)
    
    # Now build filter-grouped structures
    for (group_key in names(root_groups)) {
      parts <- strsplit(group_key, "::", fixed = TRUE)[[1]]
      root_name <- parts[1]
      # Handle empty filter signature (when group_key ends with "::")
      # Note: R cannot use "" as a list key, so we use a sentinel value
      filter_sig <- if (length(parts) > 1) parts[2] else "__no_filter__"
      
      # Build tree for this filter group
      # For filter groups, we remove the root prefix since all items share the same root
      filter_tree <- list(visualizations = list(), children = list())
      for (viz in root_groups[[group_key]]) {
        # Remove root prefix from tabgroup path for filter tree
        if (length(viz$tabgroup) > 1 && viz$tabgroup[1] == root_name) {
          relative_path <- viz$tabgroup[-1]
        } else if (length(viz$tabgroup) == 1 && viz$tabgroup[1] == root_name) {
          relative_path <- character(0)  # Parent viz goes at root of filter tree
        } else {
          relative_path <- viz$tabgroup  # Fallback - shouldn't happen
        }
        filter_tree <- .insert_into_hierarchy(filter_tree, relative_path, viz)
      }
      
      if (is.null(filter_grouped_trees[[root_name]])) {
        filter_grouped_trees[[root_name]] <- list()
      }
      filter_grouped_trees[[root_name]][[filter_sig]] <- filter_tree
    }
    
    # Merge standard result with filter-grouped results
    filter_result <- .merge_filtered_trees(filter_grouped_trees, tabgroup_labels)
    result <- c(standard_result, filter_result)
    
    # IMPORTANT: Sort combined results by minimum insertion index to preserve sequential order
    # This ensures items appear in the order they were added, not grouped by filter vs non-filter
    if (length(result) > 0) {
      result_min_indices <- sapply(result, function(item) {
        indices <- .extract_all_insertion_indices(item)
        if (length(indices) > 0) min(indices, na.rm = TRUE) else Inf
      })
      result <- result[order(result_min_indices)]
    }
  } else {
    # Standard approach - no filter grouping needed
    tree <- list(visualizations = list(), children = list())
    
    for (viz in viz_only_list) {
      tree <- .insert_into_hierarchy(tree, viz$tabgroup, viz)
    }
    
    result <- .tree_to_viz_list(tree, tabgroup_labels)
  }
  
  # IMPORTANT: Re-insert pagination markers at their original sequential positions
  # Use insertion indices to determine correct position in transformed result
  if (length(pagination_positions) > 0) {
    for (pag_info in pagination_positions) {
      marker <- pag_info$marker
      
      # Get the pagination marker's insertion index (set by combine_content)
      pag_insertion_idx <- marker$.insertion_index
      
      if (is.null(pag_insertion_idx)) {
        # Fallback: use position if no insertion index
        # (shouldn't happen but be defensive)
        warning("Pagination marker missing .insertion_index, using position as fallback")
        pag_insertion_idx <- pag_info$position
      }
      
      # Find where to insert this pagination marker based on insertion indices
      # It should go AFTER all items whose max insertion index is < pagination's index
      insert_after_idx <- 0
      
      for (i in seq_along(result)) {
        result_item <- result[[i]]
        
        # Get all insertion indices from this result item (could be tabgroup with nested items)
        item_indices <- .extract_all_insertion_indices(result_item)
        
        if (length(item_indices) > 0) {
          max_item_index <- max(item_indices, na.rm = TRUE)
          # If this result item contains visualizations with indices < pagination index,
          # the pagination should go after this result item
          if (max_item_index < pag_insertion_idx) {
            insert_after_idx <- i
          }
        }
      }
      
      # Insert pagination marker at the determined position
      if (insert_after_idx == 0) {
        # Insert at the beginning
        result <- c(list(marker), result)
      } else if (insert_after_idx >= length(result)) {
        # Insert at the end
        result <- c(result, list(marker))
      } else {
        # Insert in the middle
        result <- append(result, list(marker), after = insert_after_idx)
      }
    }
  }
  
  result
}

#' Extract all insertion indices from a viz item (including nested items)
#' @param item A viz item, which could be a tabgroup with nested visualizations
#' @return Vector of all insertion indices found in this item and its children
#' @keywords internal
.extract_all_insertion_indices <- function(item) {
  indices <- c()
  
  # Get this item's insertion index if it exists
  if (!is.null(item$.insertion_index)) {
    indices <- c(indices, item$.insertion_index)
  }
  
  # Recursively get indices from nested visualizations (tabgroups use 'visualizations' field)
  if (!is.null(item$visualizations) && length(item$visualizations) > 0) {
    for (child in item$visualizations) {
      child_indices <- .extract_all_insertion_indices(child)
      indices <- c(indices, child_indices)
    }
  }
  
  # Also check nested_children for backwards compatibility
  if (!is.null(item$nested_children) && length(item$nested_children) > 0) {
    for (child in item$nested_children) {
      child_indices <- .extract_all_insertion_indices(child)
      indices <- c(indices, child_indices)
    }
  }
  
  indices
}



.insert_into_hierarchy <- function(tree, tabgroup_vec, viz) {
  if (is.null(tabgroup_vec) || length(tabgroup_vec) == 0) {
    # No tabgroup - add to root level
    tree$visualizations <- c(tree$visualizations, list(viz))
    return(tree)
  }
  
  # Recursive helper to insert at the right level
  .insert_recursive <- function(node, path, viz_to_insert) {
    if (length(path) == 0) {
      # We've reached the target level - add the viz here
      node$visualizations <- c(node$visualizations, list(viz_to_insert))
      return(node)
    }
    
    # Get the first level name and remaining path
    level_name <- path[1]
    remaining_path <- if (length(path) > 1) path[-1] else character(0)
    
    # Initialize children list if needed
    if (is.null(node$children)) {
      node$children <- list()
    }
    
    # Get or create child node
    if (is.null(node$children[[level_name]])) {
      node$children[[level_name]] <- list(
        name = level_name,
        visualizations = list(),
        children = list(),
        .min_index = Inf  # Track minimum insertion index for sorting
      )
    }
    
    # Update minimum index for this node
    if (!is.null(viz_to_insert$.insertion_index)) {
      current_min <- node$children[[level_name]]$.min_index %||% Inf
      node$children[[level_name]]$.min_index <- min(current_min, viz_to_insert$.insertion_index)
    }
    
    # Recursively insert into child node
    node$children[[level_name]] <- .insert_recursive(
      node$children[[level_name]], 
      remaining_path, 
      viz_to_insert
    )
    
    return(node)
  }
  
  # Use recursive helper
  tree <- .insert_recursive(tree, tabgroup_vec, viz)
  return(tree)
}

#' Convert hierarchy tree to flat list of viz specs and nested tabgroups
#' @param tree Hierarchy tree to convert
#' @param tabgroup_labels Custom labels for tabgroups
#' @param is_nested_context Whether we're in a nested context (processing children)


#' Convert hierarchy tree to flat list of viz specs and nested tabgroups
#' @param tree Hierarchy tree to convert
#' @param tabgroup_labels Custom labels for tabgroups
#' @param is_nested_context Whether we're in a nested context (processing children)
#' @noRd
.tree_to_viz_list <- function(tree, tabgroup_labels = NULL, is_nested_context = FALSE) {
  result <- list()
  
  # Add standalone visualizations at this level
  if (!is.null(tree$visualizations) && length(tree$visualizations) > 0) {
    for (viz in tree$visualizations) {
      result <- c(result, list(viz))
    }
  }
  
  # Process children (nested tabgroups)
  if (!is.null(tree$children) && length(tree$children) > 0) {
    # Sort children by insertion order (min_index) instead of alphabetically
    child_names <- names(tree$children)
    child_indices <- sapply(child_names, function(nm) {
      tree$children[[nm]]$.min_index %||% Inf
    })
    child_names_sorted <- child_names[order(child_indices)]
    
    for (child_name in child_names_sorted) {
      child_node <- tree$children[[child_name]]
      
      # Look up custom display label if provided
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels))) {
          display_label <- tabgroup_labels[[child_name]]
        } else if (is.list(tabgroup_labels)) {
          display_label <- tabgroup_labels[[child_name]]
        }
      }
      
      # Check if this node has multiple parent visualizations with different filters
      # and nested children - if so, create per-parent nested structures
      has_viz <- !is.null(child_node$visualizations) && length(child_node$visualizations) > 0
      has_children <- !is.null(child_node$children) && length(child_node$children) > 0
      
      if (has_viz && has_children && length(child_node$visualizations) > 1) {
        # Multiple parent tabs with nested children - attach matching nested children to each parent
        parent_viz_list <- child_node$visualizations
        nested_children <- child_node$children
        
        # Process each parent viz and attach its matching nested children
        parent_results <- list()
        for (parent_viz in parent_viz_list) {
          parent_filter_sig <- .get_filter_signature(parent_viz)
          
          # Find nested children with matching filter
          matching_nested <- list()
          for (nested_name in names(nested_children)) {
            nested_node <- nested_children[[nested_name]]
            # Check if any viz in nested node matches this parent's filter
            if (!is.null(nested_node$visualizations)) {
              for (nested_viz in nested_node$visualizations) {
                nested_filter_sig <- .get_filter_signature(nested_viz)
                if (nested_filter_sig == parent_filter_sig || nested_filter_sig == "") {
                  # Create a modified nested node with only matching visualizations
                  matching_node <- list(
                    name = nested_name,
                    visualizations = Filter(function(v) {
                      v_sig <- .get_filter_signature(v)
                      v_sig == parent_filter_sig || v_sig == ""
                    }, nested_node$visualizations),
                    children = nested_node$children
                  )
                  if (length(matching_node$visualizations) > 0) {
                    matching_nested[[nested_name]] <- matching_node
                  }
                  break
                }
              }
            }
          }
          
          # Create a mini-tree for this parent with its matching nested children
          parent_tree <- list(
            visualizations = list(parent_viz),
            children = matching_nested
          )
          
          # Convert to viz list - this will create nested structures
          parent_result <- .tree_to_viz_list(parent_tree, tabgroup_labels, is_nested_context = TRUE)
          
          # Add each item from parent_result
          for (item in parent_result) {
            parent_results <- c(parent_results, list(item))
          }
        }
        
        # Create one tabgroup containing all parent tabs (each with their nested children)
        result <- c(result, list(list(
          type = "tabgroup",
          name = child_name,
          label = display_label,
          visualizations = parent_results
        )))
      } else {
        # Standard case - process normally
        # Pass is_nested_context = TRUE since we're processing children
        child_result <- .tree_to_viz_list(child_node, tabgroup_labels, is_nested_context = TRUE)
        
        if (has_viz || has_children) {
          # In nested contexts (is_nested_context = TRUE), always preserve named levels as tabgroups
          # to maintain the explicit hierarchy the user specified.
          # Only flatten at the absolute root level when there's truly a single item with no structure.
          
          if (has_children) {
            # Has nested children - always create tabgroup to preserve hierarchy
            result <- c(result, list(list(
              type = "tabgroup",
              name = child_name,
              label = display_label,
              visualizations = child_result
            )))
          } else if (length(child_result) == 1 && !is_nested_context) {
            # Single visualization, no nested children, and we're at root level
            # Can flatten only if not in nested context
            single_viz <- child_result[[1]]
            if (is.null(single_viz$title) || single_viz$title == "") {
              single_viz$title <- display_label %||% child_name
            }
            result <- c(result, list(single_viz))
          } else {
            # In nested context OR multiple visualizations - always create tabgroup
            # This preserves explicit hierarchy levels like "age/item1" even when item1 only has one viz
            result <- c(result, list(list(
              type = "tabgroup",
              name = child_name,
              label = display_label,
              visualizations = child_result
            )))
          }
        }
      }
    }
  }
  
  result
}

#' This function handles both viz_collection objects and plain lists of visualization
#' specifications. It:
#' - Attaches data_path to each visualization
#' - Groups visualizations by their tabgroup parameter (supports nested hierarchies)
#' - Converts single-item groups to standalone visualizations with group titles
#' - Creates tab group objects for multi-item groups
#' - Applies custom tab group labels if provided


#' Reorganize nested tabs to match with filter-matched parents
#' 
#' When we have multiple parent tabs with different filters (e.g., Wave 1, Wave 2),
#' and nested tabs with matching filters, we need to nest each child under its
#' matching parent, not create a shared nested structure.
#' @noRd
.reorganize_nested_tabs_by_filter <- function(tree) {
  if (is.null(tree$children) || length(tree$children) == 0) {
    return(tree)
  }
  
  # Process each child level
  for (child_name in names(tree$children)) {
    child_node <- tree$children[[child_name]]
    
    # Check if this level has visualizations (parent tabs) and nested children
    has_parent_viz <- !is.null(child_node$visualizations) && length(child_node$visualizations) > 0
    has_nested_children <- !is.null(child_node$children) && length(child_node$children) > 0
    
    if (has_parent_viz && has_nested_children && length(child_node$visualizations) > 1) {
      # Multiple parent tabs - need to reorganize nested children per parent
      
      # Group parent visualizations by filter
      parent_groups <- list()
      for (viz in child_node$visualizations) {
        filter_sig <- .get_filter_signature(viz)
        if (is.null(parent_groups[[filter_sig]])) {
          parent_groups[[filter_sig]] <- list()
        }
        parent_groups[[filter_sig]] <- c(parent_groups[[filter_sig]], list(viz))
      }
      
      # For each nested child level, match to parent groups
      nested_children <- child_node$children
      child_node$children <- list()
      
      # Create separate nested structures for each parent group
      for (filter_sig in names(parent_groups)) {
        parent_viz_list <- parent_groups[[filter_sig]]
        
        # Find nested children with matching filters
        matching_nested <- list()
        for (nested_name in names(nested_children)) {
          nested_node <- nested_children[[nested_name]]
          
          # Check if any visualization in nested node matches the filter
          if (!is.null(nested_node$visualizations)) {
            for (nested_viz in nested_node$visualizations) {
              nested_filter_sig <- .get_filter_signature(nested_viz)
              if (nested_filter_sig == filter_sig || nested_filter_sig == "") {
                # Match found - include this nested node
                if (is.null(matching_nested[[nested_name]])) {
                  matching_nested[[nested_name]] <- nested_node
                } else {
                  # Merge visualizations if node already exists
                  matching_nested[[nested_name]]$visualizations <- c(
                    matching_nested[[nested_name]]$visualizations,
                    nested_node$visualizations
                  )
                }
                break
              }
            }
          }
        }
        
        # Attach matching nested children to first parent viz
        # We'll create separate tabgroup structures for each parent group
        if (length(matching_nested) > 0) {
          # Store nested structure reference in parent visualization
          # The first parent viz will carry the nested structure
          if (length(parent_viz_list) > 0) {
            parent_viz_list[[1]]$nested_children <- matching_nested
          }
        }
        
        # Add all parent visualizations to this group
        for (parent_viz in parent_viz_list) {
          child_node$visualizations <- c(child_node$visualizations, list(parent_viz))
        }
      }
    } else {
      # Recursively process nested levels
      child_node <- .reorganize_nested_tabs_by_filter(child_node)
    }
    
    tree$children[[child_name]] <- child_node
  }
  
  return(tree)
}

#' Merge filtered trees into final structure
#'
#' Takes trees grouped by root name and filter, and merges them so that
#' each filter group becomes a separate parent tab with its own nested structure.
#'
#' @param all_trees List of trees grouped by root name, then by filter
#' @param tabgroup_labels Custom labels for tabgroups
#' @return Final list of visualization specifications with nested tabgroups


#' Merge filtered trees into final structure
#'
#' Takes trees grouped by root name and filter, and merges them so that
#' each filter group becomes a separate parent tab with its own nested structure.
#'
#' @param all_trees List of trees grouped by root name, then by filter
#' @param tabgroup_labels Custom labels for tabgroups
#' @return Final list of visualization specifications with nested tabgroups
#' @noRd
.merge_filtered_trees <- function(all_trees, tabgroup_labels = NULL) {
  result <- list()
  
  # Handle root-level visualizations first
  if (!is.null(all_trees[["__root__"]])) {
    root_result <- .tree_to_viz_list(all_trees[["__root__"]], tabgroup_labels)
    result <- c(result, root_result)
  }
  
  # Process each root tabgroup
  for (root_name in names(all_trees)) {
    if (root_name == "__root__") next
    
    root_data <- all_trees[[root_name]]
    
    # If only one filter group, process normally
    if (is.list(root_data) && !is.null(root_data$visualizations)) {
      # Single tree - process normally
      root_result <- .tree_to_viz_list(root_data, tabgroup_labels)
      
      # Look up custom display label
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels)) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        } else if (is.list(tabgroup_labels) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        }
      }
      
      # Add as tabgroup
      result <- c(result, list(list(
        type = "tabgroup",
        name = root_name,
        label = display_label,
        visualizations = root_result
      )))
    } else {
      # Multiple filter groups - each gets its own structure
      # Collect all parent tabs and their nested structures
      parent_tabs <- list()
      
      # Separate filtered and non-filtered items
      # Empty filter signature means no filter - these should be added directly to tabgroup
      non_filtered_items <- list()
      
      for (filter_sig in names(root_data)) {
        filter_tree <- root_data[[filter_sig]]
        
        # Handle non-filtered items separately
        # Check for the sentinel value we use for non-filtered items
        is_no_filter <- isTRUE(filter_sig == "__no_filter__")
        
        if (is_no_filter) {
          # No filter - check if this has nested structure or just visualizations
          has_nested_children <- !is.null(filter_tree$children) && length(filter_tree$children) > 0
          has_root_viz <- !is.null(filter_tree$visualizations) && length(filter_tree$visualizations) > 0
          
          if (has_nested_children && !has_root_viz) {
            # This is a nested structure without a parent viz (like timeline items)
            # We need to create a parent tab for it
            # Convert the tree and wrap it as a parent tab
            nested_content <- .tree_to_viz_list(filter_tree, tabgroup_labels)
            
            # Create a virtual parent visualization that will hold these nested items
            # The tab label will be "Over Time" (or can be customized in the future)
            parent_viz <- list(
              type = "placeholder",  # Won't render content, just holds nested_children
              title_tabset = "Over Time",  # Use title_tabset for tab label
              nested_children = nested_content
            )
            
            non_filtered_items <- c(non_filtered_items, list(parent_viz))
          } else {
            # Standard non-filtered items - convert tree directly
            non_filtered_result <- .tree_to_viz_list(filter_tree, tabgroup_labels)
            non_filtered_items <- c(non_filtered_items, non_filtered_result)
          }
          next  # Skip to next filter group
        }
        
        # The filter_tree structure (after removing root prefix):
        # - visualizations: [parent viz]  (for tabgroup = "sis")
        # - children: { "age": { children: { "item1": { visualizations: [nested_viz] } } } }
        
        # Get parent visualizations from root level
        if (!is.null(filter_tree$visualizations) && length(filter_tree$visualizations) > 0) {
          parent_viz_list <- filter_tree$visualizations
          
          # Process each parent viz (usually just one, but handle multiple)
          for (parent_viz in parent_viz_list) {
            # Process nested children if they exist
            if (!is.null(filter_tree$children) && length(filter_tree$children) > 0) {
              # Create a tree with just this parent and its nested children
              parent_tree <- list(
                visualizations = list(parent_viz),
                children = filter_tree$children
              )
              
              # Convert to viz list - this will handle nested structures correctly
              # We're processing nested children, so pass is_nested_context = TRUE
              parent_result <- .tree_to_viz_list(parent_tree, tabgroup_labels, is_nested_context = TRUE)
              
              # If parent_result has the parent viz first, followed by nested tabgroups,
              # attach the nested tabgroups to the parent viz so they appear INSIDE the parent tab
              if (length(parent_result) > 0) {
                # Separate visualizations and tabgroups
                vizes <- list()
                tabgroups <- list()
                
                for (item in parent_result) {
                  if (!is.null(item$type) && item$type == "tabgroup") {
                    tabgroups <- c(tabgroups, list(item))
                  } else {
                    vizes <- c(vizes, list(item))
                  }
                }
                
                # If we have visualizations AND tabgroups, attach tabgroups to first viz
                if (length(vizes) > 0 && length(tabgroups) > 0) {
                  parent_viz_with_nested <- vizes[[1]]
                  parent_viz_with_nested$nested_children <- tabgroups
                  parent_tabs <- c(parent_tabs, list(parent_viz_with_nested))
                  # Add remaining visualizations if any
                  if (length(vizes) > 1) {
                    for (i in 2:length(vizes)) {
                      parent_tabs <- c(parent_tabs, list(vizes[[i]]))
                    }
                  }
                } else {
                  # Standard case - add all items as they are
                  for (item in parent_result) {
                    parent_tabs <- c(parent_tabs, list(item))
                  }
                }
              }
            } else {
              # No nested children - just add the parent viz
              parent_tabs <- c(parent_tabs, list(parent_viz))
            }
          }
        }
      }
      
      # Add non-filtered items to parent tabs
      # These appear alongside filtered items (e.g., "Over Time" alongside "Wave 1", "Wave 2")
      if (length(non_filtered_items) > 0) {
        parent_tabs <- c(parent_tabs, non_filtered_items)
      }
      
      # Look up custom display label
      display_label <- NULL
      if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
        if (!is.null(names(tabgroup_labels)) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        } else if (is.list(tabgroup_labels) && root_name %in% names(tabgroup_labels)) {
          display_label <- tabgroup_labels[[root_name]]
        }
      }
      
      # Create tabgroup with all parent tabs (filtered + non-filtered)
      result <- c(result, list(list(
        type = "tabgroup",
        name = root_name,
        label = display_label,
        visualizations = parent_tabs
      )))
    }
  }
  
  result
}


#' Get filter signature for matching
#'
#' Internal helper to get a comparable string representation of a filter.
#'
#' @param viz A visualization specification
#' @return Character string representation of the filter
#' @noRd
.get_filter_signature <- function(viz) {
  if (is.null(viz$filter)) {
    return("")
  }
  paste(deparse(viz$filter[[2]]), collapse = " ")
}

#' Reorganize nested tabs to match with filter-matched parents
#' 
#' When we have multiple parent tabs with different filters (e.g., Wave 1, Wave 2),
#' and nested tabs with matching filters, we need to nest each child under its
#' matching parent, not create a shared nested structure.


#' Collect unique filters from all visualizations
#'
#' @param visualizations List of visualization specifications
#' @return List of unique filter formulas with generated names, including source dataset
#' @noRd
.collect_unique_filters <- function(visualizations) {
  if (is.null(visualizations) || length(visualizations) == 0) {
    return(list())
  }
  
  filters <- list()
  
  # Recursive function to extract filters from nested structures
  .extract_filters <- function(viz_list) {
    for (viz in viz_list) {
      if (!is.null(viz$type) && viz$type == "tabgroup") {
        # Nested tabgroup - recurse
        .extract_filters(viz$visualizations)
      } else if (!is.null(viz$filter)) {
        # Has a filter - add it with dataset context
        filter_expr <- deparse(viz$filter[[2]], width.cutoff = 500L)
        filter_key <- paste(filter_expr, collapse = " ")
        
        # Get source dataset - default to "data" if not specified
        if (!is.null(viz$data) && nzchar(viz$data)) {
          source_dataset <- viz$data
        } else {
          source_dataset <- "data"
        }
        
        # Create composite key: dataset + filter
        composite_key <- paste0(source_dataset, "::", filter_key)
        
        if (!composite_key %in% names(filters)) {
          filters[[composite_key]] <<- list(
            formula = viz$filter,
            source_dataset = source_dataset,
            filter_expr = filter_key
          )
        }
      }
    }
  }
  
  .extract_filters(visualizations)
  
  # Generate unique names for each filter
  result <- list()
  for (composite_key in names(filters)) {
    filter_info <- filters[[composite_key]]
    filter_formula <- filter_info$formula
    source_dataset <- filter_info$source_dataset
    filter_expr <- filter_info$filter_expr
    
    # Create a short hash for the filter
    filter_hash <- substr(digest::digest(filter_expr), 1, 8)
    filtered_dataset_name <- paste0(source_dataset, "_filtered_", filter_hash)
    
    result[[filtered_dataset_name]] <- list(
      name = filtered_dataset_name,
      formula = filter_formula,
      expr = deparse(filter_formula[[2]], width.cutoff = 500L),
      source_dataset = source_dataset
    )
  }
  
  result
}

#' Find the dataset name for a given filter
#'
#' @param filter Formula filter to find
#' @param filter_map List of filter mappings from .collect_unique_filters()
#' @return Character string of dataset name, or "data" if no filter

