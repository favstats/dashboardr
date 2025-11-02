# Refactoring Plan for create_dashboard_new.R

## Current State
- **Total lines:** 6,080
- **Total functions:** 67
- **Status:** Massive monolithic file, hard to navigate and maintain

## Goals
1. Split into logical, manageable files (300-800 lines each)
2. Remove unused "AI slop" code
3. Maintain all functionality
4. Improve code organization and discoverability

---

## 📋 Proposed File Structure

### **1. R/utils_core.R** (~150 lines)
**Purpose:** Core utility functions used throughout the package

**Functions:**
- `.pkg_root()` - Find package root
- `.is_subpath()` - Check if path is subpath
- `.resolve_output_dir()` - Resolve output directory
- `.suggest_alternative()` - Suggest alternatives for typos
- `.stop_with_hint()` - Error with helpful hint
- `.stop_with_suggestion()` - Error with suggestion
- `.serialize_arg()` - Serialize R arguments to strings

**Keep?** ✅ All actively used

---

### **2. R/utils_incremental.R** (~100 lines)
**Purpose:** Incremental build system (hashing, manifest)

**Functions:**
- `.compute_hash()` - Compute MD5 hash
- `.save_manifest()` - Save build manifest
- `.load_manifest()` - Load build manifest
- `.needs_rebuild()` - Check if page needs rebuild

**Keep?** ✅ All actively used

**Remove:**
- ❌ `.copy_template()` - UNUSED (only 1 reference = definition)

---

### **3. R/viz_collection.R** (~700 lines)
**Purpose:** Visualization collection management

**Functions:**
- `create_viz()` - Create viz collection
- `combine_viz()` - Combine collections
- `add_viz()` - Add visualization
- `add_vizzes()` - Add multiple visualizations
- `set_tabgroup_labels()` - Set custom labels
- `spec_viz()` - Create viz spec
- `.parse_tabgroup()` - Parse tabgroup paths
- `.sort_viz_by_tabgroup_hierarchy()` - Sort by hierarchy
- `print.viz_collection()` - S3 print method

**Keep?** ✅ All core functionality

**Remove:**
- ❌ `.build_hierarchy_key()` - UNUSED (only 1 reference)

---

### **4. R/viz_processing.R** (~800 lines)
**Purpose:** Process and organize visualizations into hierarchy

**Functions:**
- `.process_visualizations()` - Main processing logic
- `.insert_into_hierarchy()` - Build hierarchy tree
- `.tree_to_viz_list()` - Flatten tree to list
- `.reorganize_nested_tabs_by_filter()` - Handle filtered nested tabs
- `.merge_filtered_trees()` - Merge filter-based trees
- `.get_filter_signature()` - Get filter signature
- `.collect_unique_filters()` - Collect unique filters

**Keep?** ✅ All core hierarchy logic

**Remove:**
- ❌ `.get_filter_dataset_name()` - UNUSED (only 1 reference)

---

### **5. R/viz_generation.R** (~900 lines)
**Purpose:** Generate QMD code for visualizations

**Functions:**
- `.generate_viz_from_specs()` - Generate viz QMD
- `.generate_single_viz()` - Single viz chunk
- `.generate_typed_viz()` - Type-specific viz
- `.generate_function_viz()` - Function-based viz
- `.generate_auto_viz()` - Auto viz
- `.generate_tabgroup_viz()` - Tabgroup QMD
- `.generate_tabgroup_viz_content()` - Tabgroup content
- `.generate_chunk_label()` - Generate R chunk labels

**Keep?** ✅ All core generation logic

---

### **6. R/dashboard_project.R** (~500 lines)
**Purpose:** Dashboard project creation and management

**Functions:**
- `create_dashboard()` - Create dashboard project
- `add_dashboard_page()` - Add page to project
- `print.dashboard_project()` - S3 print method

**Keep?** ✅ Core project management

---

### **7. R/page_generation.R** (~600 lines)
**Purpose:** Generate page content (QMD files)

**Functions:**
- `.generate_default_page_content()` - Default page QMD
- `.generate_global_setup_chunk()` - Setup chunk
- `.process_template()` - Process template files
- `.substitute_template_vars()` - Substitute variables
- `.process_viz_specs()` - Process viz specs in template

**Keep?** ✅ All page generation logic

---

### **8. R/quarto_yml.R** (~700 lines)
**Purpose:** Generate _quarto.yml configuration

**Functions:**
- `.generate_quarto_yml()` - Main YAML generation
- `.generate_loading_overlay_chunk()` - Loading overlay
- `.generate_tabset_color_scss()` - Tabset colors
- `.check_for_icons()` - Check for icons
- `.install_iconify_extension()` - Install iconify

**Keep?** ✅ All Quarto configuration logic

---

### **9. R/ui_components.R** (~300 lines)
**Purpose:** UI helper components

**Functions:**
- `icon()` - Icon helper
- `card()` - Card component
- `card_row()` - Card row layout
- `md_text()` - Markdown text
- `text_lines()` - Text lines helper

**Keep?** ✅ All UI components

---

### **10. R/navigation.R** (~200 lines)
**Purpose:** Navigation components

**Functions:**
- `sidebar_group()` - Sidebar group
- `navbar_section()` - Navbar section
- `navbar_menu()` - Navbar menu

**Keep?** ✅ All navigation components

---

### **11. R/dashboard_generation.R** (~800 lines)
**Purpose:** Main dashboard generation and rendering

**Functions:**
- `generate_dashboard()` - Main generation function
- `.render_dashboard()` - Quarto rendering
- `.show_dashboard_summary()` - Show summary

**Keep?** ✅ Core generation logic

---

### **12. R/progress_display.R** (~150 lines)
**Purpose:** Progress display utilities

**Functions:**
- `.progress_msg()` - Progress message
- `.progress_step()` - Progress step
- `.progress_header()` - Progress header
- `.progress_section()` - Progress section
- `.progress_bar()` - Progress bar (currently unused but may be useful)

**Keep?** ✅ All progress functions (even `.progress_bar` for future use)

---

## 🗑️ Functions to Remove (Dead Code)

1. **`.copy_template()`** (line ~165) - Never actually called
2. **`.build_hierarchy_key()`** (line ~2040) - Never actually called  
3. **`.get_filter_dataset_name()`** (line ~4575) - Never actually called

**Impact:** Removing ~200 lines of dead code

---

## 📊 Summary

| File | Lines | Functions | Purpose |
|------|-------|-----------|---------|
| `utils_core.R` | ~150 | 7 | Core utilities |
| `utils_incremental.R` | ~80 | 4 | Incremental builds |
| `viz_collection.R` | ~650 | 9 | Viz management |
| `viz_processing.R` | ~700 | 7 | Hierarchy processing |
| `viz_generation.R` | ~900 | 8 | QMD generation |
| `dashboard_project.R` | ~500 | 3 | Project management |
| `page_generation.R` | ~600 | 5 | Page QMD generation |
| `quarto_yml.R` | ~700 | 5 | Quarto config |
| `ui_components.R` | ~300 | 5 | UI helpers |
| `navigation.R` | ~200 | 3 | Navigation |
| `dashboard_generation.R` | ~800 | 3 | Main generation |
| `progress_display.R` | ~150 | 5 | Progress UI |
| **TOTAL** | **~5,730** | **64** | **(removed 3 dead functions)** |

---

## 🎯 Benefits

1. **Easier navigation:** Find functions by category
2. **Better maintenance:** Smaller files are easier to modify
3. **Clearer architecture:** Logical separation of concerns
4. **Faster loading:** R loads smaller files faster
5. **Better testing:** Can test modules independently
6. **Less clutter:** Remove 350+ lines of dead code

---

## ⚠️ Migration Strategy

### Phase 1: Preparation
1. Run full test suite to establish baseline
2. Create new file structure
3. Keep `create_dashboard_new.R` as backup

### Phase 2: Split Files
1. Extract functions in dependency order (utils first)
2. Update `@keywords internal` documentation
3. Add file-level documentation headers
4. Ensure all functions are properly exported/internal

### Phase 3: Validation
1. Run full test suite
2. Test all demo scripts
3. Check package load time
4. Verify all examples work

### Phase 4: Cleanup
1. Delete `create_dashboard_new.R`
2. Update NAMESPACE if needed
3. Run `devtools::document()`
4. Final test suite run

---

## 🚀 Next Steps

**Option A: Do it all now** (~2 hours of careful work)
- Split all files in one go
- Run comprehensive tests
- High risk but fast

**Option B: Incremental approach** (~30 min per file, safer)
- Split one category at a time
- Test after each split
- Lower risk, more time

**Recommendation:** Option B - Safer for critical infrastructure

**Order:**
1. Start with utilities (least dependent)
2. Then UI components (standalone)
3. Then navigation (standalone)
4. Then viz collection (used by others)
5. Then processing/generation (complex)
6. Finally dashboard generation (depends on all)

---

## 🔍 Additional Cleanup Opportunities

1. **Comment blocks:** Remove excessive comment dividers
2. **Debug code:** Remove any leftover debug `message()` calls
3. **Duplicate docs:** Some `@param` duplicated across functions
4. **Magic numbers:** Extract to constants
5. **Long functions:** Some functions >200 lines could be split further

---

**Ready to proceed?** Let me know if you want to:
- A) Go with this plan as-is
- B) Adjust the file organization
- C) Start with a specific category first
- D) Do it all in one shot

