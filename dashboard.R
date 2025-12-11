# DIGITAL COMPETENCE DASHBOARD ====================================================

library(tidyverse)
library(dashboardr)



translation <- read_csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vRHn6F7oL_0WCNdlwvV5WvT8JtT-XRKO2YQ8zX1zJbbPkznXGEVbXC80F4fC0NUjWK87kdirUXn6eLh/pub?gid=1284654467&single=true&output=csv")

# translation <- read_csv("../dashboardr/translations.xlsx")


transl <- function(x, lang) {
  translation %>% filter(variable == x) %>% 
    pull(lang)
}


if(!exists("lang")){
  lang <- "en"
}

lang_change <- function(lang) {
  if(lang == "en"){
    return("nl")
  } else {
    return("en")
  }
}

# 1. SETUP & CONFIGURATION =====================================================

## TODO check if the recoding is actually correct please
## TODO in dimension Skills, Performance, and Knowledge aggegration?
## TODO in Dimsension also over time?
## TODO add by survey type?? 
## TODO create timeline and stackedbar dont create the same value!
## TODO pimp the graphs??
## TODO mix between text and graphs needs to be possible!
## TODO: Knowledge question seem perhaps incorrect and are missing sometimes across waves

# the_colors <- c("#F5D76E", "#E28D50", "#3D7271", "#C7E6D5", "#0F6B5A", "#BABACD")
the_colors <- c("#3D7271",  "#E28D50",  "#F5D76E", "#C7E6D5", "#0F6B5A", "#BABACD")

recode_survey <- function(df) {
  
  
  # 1) SKILL ITEMS: coerce to numeric IN PLACE and set 66/99 -> NA
  skill_vars <- c(
    "SInfo1","SInfo3_V2","SInfo4","SInfo5","SInfo6","SInfo7",
    "SCom1_V2","SCom2","SCom3","SCom4_V2","SCom5",
    "SCrea2","SCrea3","SCrea4","SCrea5",
    "SSafDev1","SSafDev2",
    "SPriv1","SPriv2","SPriv3","SPriv4",
    "SHealth1","SHealth2_V2","SHealth3_V2",
    "SEnv1","SEnv2","SEnv3",
    "SProbl1","SProbl2",
    "Strans1","Strans2","Strans3","Strans4","Strans5",
    "SAI1","SAI2",
    "SGAI1","SGAI2","SGAI3","SGAI4","SGAI5",
    # optionally already-numeric helper mentioned in your code
    "GetHelp_V2N"
  )
  skill_present <- intersect(names(df), skill_vars)
  
  # coerce to numeric in place
  df <- df |> mutate(across(all_of(skill_present), ~ suppressWarnings(as.numeric(.x))))
  # set 66/99 to NA
  df <- df |> mutate(across(all_of(skill_present), ~ replace(.x, .x %in% c(66, 99), NA_real_)))
  
  true_set  <- c("KInfo3","KCom1","KCrea1","KCrea2","KSafDev2","KSafDev_new",
                 "KPriv2","KPriv3_V2","KHealth2","KHealth3","KEnv1","KEnv2",
                 "Ktrans1","KAI1","KAI3","KAI4","KGAI3","KGAI4","KGAI5")
  false_set <- c("KInfo1","KInfo2","KCom3","KCrea3","KPriv1","KHealth1","KEnv3",
                 "Ktrans2","Ktrans3","KAI2","KGAI1","KGAI2")
  knowledge_items <- c(true_set, false_set)
  
  map_true  <- c(`1`="Correct", `2`="Incorrect", `3`="Don't know", `66`="Don't understand")
  map_false <- c(`1`="Incorrect", `2`="Correct", `3`="Don't know", `66`="Don't understand")
  
  recode_by_col <- function(x, col) {
    m <- if (col %in% true_set) map_true else map_false
    dplyr::recode_factor(as.character(x), !!!m, .default = NA_character_)
  }
  
  df <- df |>
    mutate(
      across(contains(knowledge_items),
             ~ recode_by_col(.x, cur_column()),
             .names = "{.col}R"
      )
    ) |>
    mutate(
      across(ends_with("R"),
             ~ as.integer(.x == "Correct"),
             .names = "{.col}C"
      )
    )
  
  # 3) SUBSCALES (using IN-PLACE skill vars; no ...N names)
  
  # helper to rowMeans over present columns (keeps NA handling identical to base: na.rm = FALSE)
  rm_mean <- function(d, vars) {
    v <- intersect(names(d), vars)
    if (length(v) == 0) return(rep(NA_real_, nrow(d)))
    rowMeans(d[v])
  }
  
  df$MeanStratInfo <- rm_mean(df, c("SInfo1","SInfo3_V2","SInfo4"))
  df$MeanCritInfo  <- rm_mean(df, c("SInfo5","SInfo6","SInfo7"))
  df$MeanNet       <- rm_mean(df, c("SCom1_V2","SCom2","SCom4_V2","SCom5"))
  df$MeanCrea      <- rm_mean(df, c("SCrea2","SCrea3","SCrea4","SCrea5"))
  df$MeanSaf       <- rm_mean(df, c("SSafDev1","SSafDev2","SPriv1","SPriv2","SPriv3","SPriv4","SCom3"))
  df$MeanHealth    <- rm_mean(df, c("SHealth1","SHealth2_V2","SHealth3_V2"))
  df$MeanGreen     <- rm_mean(df, c("SEnv1","SEnv2","SEnv3"))
  df$MeanTrans     <- rm_mean(df, c("Strans1","Strans2","Strans3","Strans4","Strans5"))
  df$MeanProbl     <- rm_mean(df, c("SProbl1","SProbl2"))
  df$MeanAI        <- rm_mean(df, c("SAI1","SAI2"))
  df$MeangenAI     <- rm_mean(df, c("SGAI1","SGAI2","SGAI3","SGAI4","SGAI5"))
  
  
  
  # 4) TOTAL KNOWLEDGE SCORE (sum of *RC columns you listed)
  
  knowledge_rc_order <- c(
    "KInfo1RC","KInfo2RC","KInfo3RC",
    "KCom1RC","KCom3RC",
    "KCrea1RC","KCrea2RC","KCrea3RC",
    "KSafDev2RC",
    "KPriv1RC","KPriv2RC","KPriv3_V2RC",
    "KHealth1RC","KHealth2RC","KHealth3RC",
    "KEnv1RC","KEnv2RC","KEnv3RC",
    "Ktrans1RC","Ktrans2RC","Ktrans3RC",
    "KAI1RC","KAI2RC","KAI3RC", "KAI4RC",
    "KGAI1RC","KGAI2RC","KGAI3RC","KGAI4RC","KGAI5RC"
  )
  # df <- data
  present_rc <- intersect(knowledge_rc_order, names(df))
  if (length(present_rc)) {
    # match your explicit + ... + behavior (NA if any NA)
    df$MeanKnowledge <- rowSums(df[present_rc], na.rm = T)
  } else {
    df$MeanKnowledge <- NA_real_
  }
  
  
  df %>% 
    mutate(
      across(
        any_of(knowledge_rc_order),
        ~ ifelse(is.na(.x),   transl("dunno_understand", lang), .x)
      )
    )
}
# read_csv2("data/wave1.csv") -> wads
# wads <- read_csv("data/wave1.csv")
# wads %>% count(geslacht)
# data_w1 <- read_csv2("data/DigCom24CompleteWithWeights.csv") %>% #table()
# mutate(AgeGroup = case_when(
#   Age %in% 16:17 ~ "16-17",
#   Age %in% 18:24 ~ "18-24",
#   Age %in% 25:34 ~ "25-34",
#   Age %in% 35:44 ~ "35-44",
#   Age %in% 45:54 ~ "45-54",
#   Age %in% 55:64 ~ "55-64",
#   Age %in% 65:150 ~ "65+",
# )) %>%
data_w1 <- read_csv("data/wave1.csv") %>% #table()
  mutate(weging_GAMO = str_replace(weging_GAMO, ",", ".") %>% as.numeric) %>% 
  mutate(geslacht = case_when(
    geslacht == 1 ~ transl("label_male", lang),
    geslacht == 2 ~ transl("label_female", lang),
    T ~ NA_character_
  )) %>% 
  mutate(Education = EducationR) %>% 
  mutate(Education = case_when(
    Education == "Low" ~ transl("label_low_education", lang),
    Education == "Middle" ~ transl("label_middle_education", lang),
    Education == "High" ~ transl("label_high_education", lang),
    T ~ Education
  )) %>% 
  mutate(Education = fct_relevel(Education, c(transl("label_low_education", lang), transl("label_middle_education", lang), transl("label_high_education", lang)))) %>% 
  recode_survey()
# getwd()
# data <- read_csv2("data/DigCom25CompleteWithWeights.csv") %>% #table()
data <- read_csv("data/wave2.csv") %>% 
  # mutate(AgeGroup = case_when(
  #   Age %in% 16:17 ~ "16-17",
  #   Age %in% 18:24 ~ "18-24",
  #   Age %in% 25:34 ~ "25-34",
  #   Age %in% 35:44 ~ "35-44",
  #   Age %in% 45:54 ~ "45-54",
  #   Age %in% 55:64 ~ "55-64",
  #   Age %in% 65:150 ~ "65+",
  # )) %>%
  mutate(weging_GAMO = str_replace(weging_GAMO, ",", ".") %>% as.numeric) %>% 
  mutate(geslacht = case_when(
    Gender == 1 | Gender == "Male" ~ transl("label_male", lang),
    Gender == 2 | Gender == "Female" ~ transl("label_female", lang),
    T ~ NA_character_
  )) %>% 
  mutate(Education = EducationR)  %>% 
  mutate(Education = case_when(
    Education == "Low" ~ transl("label_low_education", lang),
    Education == "Middle" ~ transl("label_middle_education", lang),
    Education == "High" ~ transl("label_high_education", lang),
    T ~ Education
  )) %>% 
  mutate(Education = fct_relevel(Education, c(transl("label_low_education", lang), transl("label_middle_education", lang), transl("label_high_education", lang)))) %>% 
  recode_survey()

smart_bind_rows <- function(...) {
  dfs <- list(...)
  
  # names per df
  cols_list <- lapply(dfs, names)
  
  # columns that appear in at least 2 dfs
  all_cols <- unlist(cols_list, use.names = FALSE)
  overlap_cols <- names(which(table(all_cols) > 1))
  
  # for each overlapping col, check classes per df
  for (col in overlap_cols) {
    # get classes for this col in each df (NA if missing)
    classes <- map_chr(dfs, ~ if (col %in% names(.x)) class(.x[[col]])[1] else NA_character_)
    
    # do we have >1 non-NA class?
    non_na_classes <- unique(na.omit(classes))
    if (length(non_na_classes) > 1) {
      # coerce this column to character in every df that has it
      dfs <- lapply(dfs, function(.x) {
        if (col %in% names(.x)) {
          .x[[col]] <- as.character(.x[[col]])
        }
        .x
      })
    }
  }
  
  bind_rows(dfs)
}



# digicom_data$
digicom_data <- data %>% 
  mutate(wave = 2) %>% 
  # mutate_all(as.character) %>% 
  # mutate_at(vars(Sample, Time, QR, PSCS3_1), as.character) %>% 
  smart_bind_rows(data_w1 %>% 
                    mutate(wave = 1)) %>% 
  mutate_at(vars(PSCS3_1, PSCS3_2, PSCS3_3, PSCS3_4, PSCS3_5, PSCS3_6, PSCS3_7, PSCS3_8, PSCS3_9, PDHWS1_1, PDHWS1_3), as.numeric) %>% 
  mutate(wave_time_label = ifelse(wave == 1, paste0("Dec. 24 (", transl("tab_wave1", lang), ")"), paste0("Jun. 25 (", transl("tab_wave2", lang), ")"))) %>% 
  mutate(wave_time_label = factor(wave_time_label, levels = c(paste0("Dec. 24 (", transl("tab_wave1", lang), ")"), paste0("Jun. 25 (", transl("tab_wave2", lang), ")")))) %>% 
  mutate(Education = case_when(
    Education == "66" ~ NA_character_,
    Education == "99" ~ NA_character_,
    T ~ Education
  )) %>% 
  mutate(Education = fct_relevel(Education, c(transl("label_low_education", lang), transl("label_middle_education", lang), transl("label_high_education", lang)))) %>% 
  mutate(MigrationBackground = case_when(
    MigrationBackground == "yes" ~ transl("label_yes", lang),
    MigrationBackground == "no" ~ transl("label_no", lang),
    T ~ MigrationBackground
  )) %>% 
  mutate(AgeGroup = case_when(
    Age %in% 10:15 ~ "10-15",
    Age %in% 15:30 ~ "16-30",
    Age %in% 31:64 ~ "31-64",
    Age %in% 65:150 ~ "65+",
  ))

# digicom_data %>% count(Age, sort =T)

std.error <- function(x) sd(x, na.rm =T)/sqrt(length(x))

# digicom_data %>% count(MigrationBackground, wave)

# 2. HELPER FUNCTIONS & DATA PREPARATION =======================================

# Translation mapping functions for common demographic values
get_gender_map <- function(lang) {
  list(
    "Male" = transl("label_male", lang),
    "Female" = transl("label_female", lang)
  )
}

get_education_map <- function(lang) {
  list(
    "Low" = transl("label_low_education", lang),
    "Middle" = transl("label_middle_education", lang),
    "High" = transl("label_high_education", lang)
  )
}

get_yes_no_map <- function(lang) {
  list(
    "Yes" = transl("label_yes", lang),
    "No" = transl("label_no", lang)
  )
}

get_y_label_percentage <- function(lang) {
  transl("label_percentage_respondents", lang)
}

get_y_label_number <- function(lang) {
  transl("label_number_respondents", lang)
}

education_levels <- c("Primary (basisonderwijs)", 
                      "Pre-Vocational (vmbo)", 
                      "Secondary (havo/vwo)", 
                      "Vocational (mbo)", 
                      "Applied Sciences (hbo)", 
                      "University (wo)") %>% 
  tibble(eng = ., oplcat = c("basisonderwijs",
                             "vmbo",
                             "havo/vwo",
                             "mbo",
                             "hbo",
                             "wo"))



# Helper functions for creating multiple visualizations
add_all_viz_timeline <- function(viz, vars, group_var, tbgrp, demographic, wave_label, questions) {
  wave_path <- tolower(gsub(" ", "", wave_label))
  
  for (i in seq_along(vars)) {
    # When there's only 1 question, don't add item{i} to avoid single subtab
    tabgroup_path <- if (length(vars) == 1) {
      glue::glue("{tbgrp}/{wave_path}/{demographic}")
    } else {
      glue::glue("{tbgrp}/{wave_path}/{demographic}/item{i}")
    }
    
    viz <- viz |>
      add_viz(
        title = questions[[i]],
        response_var = vars[[i]],
        group_var    = group_var,
        tabgroup     = tabgroup_path
      )
  }
  viz
}

add_all_viz_timeline_single <- function(viz, vars, tbgrp, demographic, wave_label, questions) {
  wave_path <- tolower(gsub(" ", "", wave_label))
  
  for (i in seq_along(vars)) {
    # When there's only 1 question, don't add item{i} to avoid single subtab
    tabgroup_path <- if (length(vars) == 1) {
      glue::glue("{tbgrp}/{wave_path}/{demographic}")
    } else {
      glue::glue("{tbgrp}/{wave_path}/{demographic}/item{i}")
    }
    
    viz <- viz |>
      add_viz(
        title = questions[[i]],
        response_var = vars[[i]],
        tabgroup     = tabgroup_path
      )
  }
  viz
}

add_all_viz_stackedbar <- function(viz, vars, questions, stack_var,
                                   tbgrp, demographic, wave_label) {
  
  wave_path <- tolower(gsub(" ", "", wave_label))
  
  # map demographic -> translation key
  label_keys <- c(
    age    = "tab_age",
    gender = "tab_gender",
    edu    = "tab_education",
    mig    = "tab_migration"
  )
  
  label_key <- label_keys[[demographic]]
  
  for (i in seq_along(vars)) {
    tabgroup_path <- if (length(vars) == 1) {
      glue::glue("{tbgrp}/{wave_path}/{demographic}")
    } else {
      glue::glue("{tbgrp}/{wave_path}/{demographic}/item{i}")
    }
    
    viz <- viz |>
      add_viz(
        title    = questions[[i]],
        x_var    = stack_var,
        x_label  = transl(label_key, lang),   # <- changes with demographic
        stack_var = vars[[i]],
        tabgroup  = tabgroup_path
      )
  }
  viz
}
# stack_map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang))

# Main function
create_vizzes <- function(qs, vs, lbs, tex, breaks = c(0.5, 2.5, 3.5, 5.5), 
                          colors = the_colors, 
                          tbgrp, graph_title, high_values = 4:5, 
                          text_b_tabset = "ADD TEXT BEFORE TABSET", 
                          aggr_lab = get_y_label_percentage(lang),
                          lang = "en") {
  
  # Wave 1 & 2 Overall (stackedbars)
  sis_viz <- create_viz(
    type = "stackedbars",
    questions = vs,
    question_labels = qs,
    stacked_type = "percent",
    color_palette = colors,
    horizontal = TRUE,
    x_label = "", 
    text_before_tabset = text_b_tabset,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_order = rev(lbs),
    drop_na_vars = F,
    stack_label = NULL,
    weight_var = "weging_GAMO"
  ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 1",
      filter = ~ wave == 1,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave1/overall")
    ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 2",
      filter = ~ wave == 2,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave2/overall")
    )
  
  # Over Time Overall (timeline without group_var)
  sis_subvizzes_time <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    text_before_tabset = text_b_tabset,
    response_filter = high_values, 
    response_filter_label = aggr_lab,
    response_filter_combine = T,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    y_min = 0,
    y_max = 100,
    response_filter_label = NULL,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline_single(vs, tbgrp, "overall", wave_label = "Over Time", questions = qs)  # Pass tbgrp!
  
  # Wave 1 by Age/Gender/Education
  sis_subvizzes <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    text_before_tabset = text_b_tabset,
    stack_order = rev(lbs),
    filter = ~ wave == 1,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 1") |>       # Pass tbgrp AND "age"
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 1") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 1")  |>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 1")
  # Pass tbgrp AND "edu"
  
  # Wave 2 by Age/Gender/Education
  sis_subvizzes2 <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_order = rev(lbs),
    text_before_tabset = text_b_tabset,
    filter = ~ wave == 2,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 2")|>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 2")
  
  # Over Time by Age/Gender/Education
  sis_subvizzes3 <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_filter = high_values, 
    text_before_tabset = text_b_tabset,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    y_min = 0,
    y_max = 100,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline(vs, "AgeGroup", tbgrp, "age", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "geslacht", tbgrp, "gender", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "Education", tbgrp, "edu", wave_label = "Over Time", questions = qs)|>
    add_all_viz_timeline(vs, "MigrationBackground", tbgrp, "mig", wave_label = "Over Time", questions = qs)
  
  # Combine all
  sis_viz %>% 
    combine_viz(sis_subvizzes_time) %>%
    combine_viz(sis_subvizzes) %>%
    combine_viz(sis_subvizzes2) %>%
    combine_viz(sis_subvizzes3)
}

create_vizzes2 <- function(qs, vs, lbs, tex, breaks = c(0.5, 2.5, 3.5, 5.5), 
                           colors = the_colors, 
                           tbgrp, graph_title, high_values = 1, map_values, 
                           text_b_tabset = "ADD TEXT BEFORE TABSET", 
                           aggr_lab = transl("label_percentage_correct", lang),
                           lang = "en") {
  
  # Wave 1 & 2 Overall (stackedbars)
  sis_viz <- create_viz(
    type = "stackedbars",
    questions = vs,
    question_labels = qs,
    stacked_type = "percent",
    color_palette = colors,
    horizontal = TRUE,
    x_label = "",
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = lbs,
    text = "", 
    text_before_tabset = text_b_tabset,
    drop_na_vars = F,
    stack_label = NULL,
    weight_var = "weging_GAMO"
  ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 1",
      filter = ~ wave == 1,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave1/overall")
    ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 2",
      filter = ~ wave == 2,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave2/overall")
    )
  
  # Over Time Overall (timeline without group_var)
  sis_subvizzes_time <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_filter = high_values, 
    y_min = 0,
    y_max = 100,
    response_filter_label = aggr_lab,
    response_filter_combine = T,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline_single(vs, tbgrp, "overall", wave_label = "Over Time", questions = qs)  # Pass tbgrp!
  
  # Wave 1 by Age/Gender/Education
  sis_subvizzes <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = lbs,
    filter = ~ wave == 1,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 1") |>       # Pass tbgrp AND "age"
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 1") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 1")  |>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 1")         # Pass tbgrp AND "edu"
  
  # Wave 2 by Age/Gender/Education
  sis_subvizzes2 <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = lbs,
    filter = ~ wave == 2,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 2")|>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 2")
  
  # Over Time by Age/Gender/Education
  sis_subvizzes3 <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_filter = high_values, 
    y_min = 0,
    y_max = 100,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    response_filter_label = NULL,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline(vs, "AgeGroup", tbgrp, "age", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "geslacht", tbgrp, "gender", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "Education", tbgrp, "edu", wave_label = "Over Time", questions = qs)|>
    add_all_viz_timeline(vs, "MigrationBackground", tbgrp, "mig", wave_label = "Over Time", questions = qs)
  
  # Combine all
  sis_viz %>% 
    combine_viz(sis_subvizzes_time) %>%
    combine_viz(sis_subvizzes) %>%
    combine_viz(sis_subvizzes2) %>%
    combine_viz(sis_subvizzes3)
}



create_vizzes3 <- function(qs, vs, lbs, tex, breaks = c(0.5, 2.5, 3.5, 5.5), 
                           colors = the_colors, 
                           tbgrp, graph_title, high_values = 1, map_values, 
                           text_b_tabset = "ADD TEXT BEFORE TABSET", 
                           aggr_lab = transl("label_percentage_correct", lang),
                           lang = "en") {
  
  # Wave 1 & 2 Overall (stackedbars)
  sis_viz <- create_viz(
    type = "stackedbars",
    questions = vs,
    question_labels = qs,
    stacked_type = "percent",
    color_palette = colors,
    horizontal = TRUE,
    x_label = "",
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = rev(lbs),
    text = "", 
    text_before_tabset = text_b_tabset,
    drop_na_vars = F,
    stack_label = NULL,
    weight_var = "weging_GAMO"
  ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 1",
      filter = ~ wave == 1,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave1/overall")
    ) %>%
    add_viz(
      title = graph_title, 
      title_tabset = "Wave 2",
      filter = ~ wave == 2,
      icon = "ph:chart-bar",
      tabgroup = glue::glue("{tbgrp}/wave2/overall")
    )
  
  # Over Time Overall (timeline without group_var)
  sis_subvizzes_time <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_filter = high_values, 
    y_min = 0,
    y_max = 100,
    response_filter_label = aggr_lab,
    response_filter_combine = T,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline_single(vs, tbgrp, "overall", wave_label = "Over Time", questions = qs)  # Pass tbgrp!
  
  # Wave 1 by Age/Gender/Education
  sis_subvizzes <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = rev(lbs),
    filter = ~ wave == 1,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 1") |>       # Pass tbgrp AND "age"
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 1") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 1")  |>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 1")         # Pass tbgrp AND "edu"
  
  # Wave 2 by Age/Gender/Education
  sis_subvizzes2 <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = T,
    stack_breaks = breaks,
    stack_bin_labels = lbs,
    stack_map_values = map_values,
    stack_order = rev(lbs),
    filter = ~ wave == 2,
    drop_na_vars = F,
    color_palette = colors,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_stackedbar(vs, qs, "AgeGroup", tbgrp, "age", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "geslacht", tbgrp, "gender", wave_label = "Wave 2") |>
    add_all_viz_stackedbar(vs, qs, "Education", tbgrp, "edu", wave_label = "Wave 2")|>
    add_all_viz_stackedbar(vs, qs, "MigrationBackground", tbgrp, "mig", wave_label = "Wave 2")
  
  # Over Time by Age/Gender/Education
  sis_subvizzes3 <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_filter = high_values, 
    y_min = 0,
    y_max = 100,
    x_label = "", 
    y_label = aggr_lab,
    color_palette = the_colors,
    response_filter_label = NULL,
    weight_var = "weging_GAMO"
  ) |>
    add_all_viz_timeline(vs, "AgeGroup", tbgrp, "age", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "geslacht", tbgrp, "gender", wave_label = "Over Time", questions = qs) |>
    add_all_viz_timeline(vs, "Education", tbgrp, "edu", wave_label = "Over Time", questions = qs)|>
    add_all_viz_timeline(vs, "MigrationBackground", tbgrp, "mig", wave_label = "Over Time", questions = qs)
  
  # Combine all
  sis_viz %>% 
    combine_viz(sis_subvizzes_time) %>%
    combine_viz(sis_subvizzes) %>%
    combine_viz(sis_subvizzes2) %>%
    combine_viz(sis_subvizzes3)
}


# 3. KNOWLEDGE VISUALIZATIONS ==================================================

## 3.1 Knowledge Tabs Setup ----

knowledge_labs <- c("Low (0-9)", "Middle (10-19)", "High (20-29)")
knowledge_breaks <- c(0, 10, 20, 30)
vs <- "MeanKnowledge"
qs <- "Knowledge Score"
tbgrp <- "knowledge"

knowledge_tex <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_knowledge", lang), "\", preset = \"question\")"),
  "```"
)




# Using create_viz + add_viz
knowledge_viz <- create_viz(
  type = "bar",
  horizontal = TRUE,
  bar_type = "percent",
  icon = "ph:chart-bar",
  text_before_tabset = knowledge_tex,
  drop_na_vars = F,
  text_position = "above",
  color_palette = the_colors,
  drop_na_vars = F,
  weight_var = "weging_GAMO"
) %>%
  add_viz(
    title = "Knowledge Scores",
    x_var = "MeanKnowledge",
    title_tabset = "Wave 1",
    filter = ~ wave == 1,
    x_breaks = knowledge_breaks,
    x_bin_labels = knowledge_labs,
    x_order = knowledge_labs,
    tabgroup = "knowledge/wave1/overall"
  ) %>%
  add_viz(
    title = "Knowledge Scores",
    x_var = "MeanKnowledge",
    title_tabset = "Wave 2",
    filter = ~ wave == 2,
    x_breaks = knowledge_breaks,
    x_bin_labels = knowledge_labs,
    x_order = knowledge_labs,
    tabgroup = "knowledge/wave2/overall"
  ) 

# Wave 1 by demographics
knowledge_subvizzes_wave1 <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = knowledge_breaks,
  stack_bin_labels = knowledge_labs,
  stack_order = knowledge_labs,
  filter = ~ wave == 1,
  drop_na_vars = F,
  weight_var = "weging_GAMO",
  color_palette = the_colors
) |>
  add_viz(
    title = qs,
    x_var = "AgeGroup",
    stack_var = vs,
    tabgroup = "knowledge/wave1/age"
  ) |>
  add_viz(
    title = qs,
    x_var = "geslacht",
    stack_var = vs,
    tabgroup = "knowledge/wave1/gender"
  ) |>
  add_viz(
    title = qs,
    x_var = "Education",
    stack_var = vs,
    tabgroup = "knowledge/wave1/edu"
  ) |>
  add_viz(
    title = qs,
    x_var = "MigrationBackground",
    stack_var = vs,
    tabgroup = "knowledge/wave1/mig"
  )

# Wave 2 by demographics
knowledge_subvizzes_wave2 <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = knowledge_breaks,
  stack_bin_labels = knowledge_labs,
  stack_order = knowledge_labs,
  filter = ~ wave == 2,
  drop_na_vars = F,
  weight_var = "weging_GAMO",
  color_palette = the_colors
) |>
  add_viz(
    title = qs,
    x_var = "AgeGroup",
    stack_var = vs,
    tabgroup = "knowledge/wave2/age"
  ) |>
  add_viz(
    title = qs,
    x_var = "geslacht",
    stack_var = vs,
    tabgroup = "knowledge/wave2/gender"
  ) |>
  add_viz(
    title = qs,
    x_var = "Education",
    stack_var = vs,
    tabgroup = "knowledge/wave2/edu"
  ) |>
  add_viz(
    title = qs,
    x_var = "MigrationBackground",
    stack_var = vs,
    tabgroup = "knowledge/wave2/mig"
  )

# Over Time - Overall (timeline without group_var)
knowledge_overtime_overall <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  response_var = "MeanKnowledge",
  response_breaks = knowledge_breaks,  # Bin the knowledge scores
  response_bin_labels = knowledge_labs,
  y_min = 0,
  y_max = 100,
  drop_na_vars = F,
  weight_var = "weging_GAMO"
) |>
  add_viz(
    title = "Knowledge Scores Over Time",
    tabgroup = "knowledge/overtime/overall"  # ← Timeline for overall!
  )

# Over Time - by demographics (timeline with group_var)
knowledge_overtime_demographics <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  response_var = "MeanKnowledge",
  response_breaks = knowledge_breaks,
  y_min = 0,
  y_max = 100,
  response_bin_labels = knowledge_labs,
  drop_na_vars = F
) |>
  add_viz(
    group_var = "AgeGroup",
    tabgroup = "knowledge/overtime/age"
  ) |>
  add_viz(
    group_var = "geslacht",
    tabgroup = "knowledge/overtime/gender"
  ) |>
  add_viz(
    group_var = "Education",
    tabgroup = "knowledge/overtime/edu"
  ) |>
  add_viz(
    group_var = "MigrationBackground",
    tabgroup = "knowledge/overtime/mig"
  )

# Combine all
knowledge_viz <- knowledge_viz %>%
  combine_viz(knowledge_subvizzes_wave1) %>%
  combine_viz(knowledge_subvizzes_wave2) %>%
  combine_viz(knowledge_overtime_overall) %>%
  combine_viz(knowledge_overtime_demographics)


## 3.2 Strategic Information Knowledge (kinfo_viz) ----

kinfo_questions <- c(
  transl("KInfo1", lang),
  transl("KInfo2", lang)
)

kinfo_vars <- c("KInfo1RC", "KInfo2RC")

# keep the order from your original code: rev(c("Incorrectly", "Correctly", "X"))
kinfo_labs <- c(transl("label_correctly_answered", lang), transl("label_incorrectly_answered", lang), transl("dunno_understand", lang))

kinfo_info_text <- transl("strategic_info_description", lang)

kinfo_tex_link <- md_text(
  kinfo_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_strategic", lang), "](strategic_information.html)")
)

kinfo_viz <- create_vizzes2(
  breaks = knowledge_breaks,
  kinfo_questions,
  kinfo_vars,
  kinfo_labs,
  "",
  tbgrp   = "kinfo",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kinfo_tex_link,
  lang = lang
)


## 3.3 Critical Information Knowledge (critinfo_viz) ----

# TODO: Supposedly there is ANOTHER question here but where?

critinfo_questions <- c(
  transl("KInfo3", lang)
)

critinfo_vars <- c("KInfo3RC")

critinfo_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

critinfo_info_text <- transl("critical_info_description", lang)

critinfo_tex_link <- md_text(
  critinfo_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_critical", lang), "](critical_information.html)")
)

critinfo_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  critinfo_questions,
  critinfo_vars,
  critinfo_labs,
  "",
  tbgrp        = "critinfo",
  graph_title  = critinfo_questions, 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = critinfo_tex_link,
  lang = lang
)


## 3.4 Netiquette Knowledge (knet_viz) ----

knet_questions <- c(
  transl("KCom3", lang)
)

knet_vars <- c("KCom3RC")

knet_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

knet_info_text <- transl("netiquette_description", lang)

knet_tex_link <- md_text(
  knet_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_netiquette", lang), "](netiquette.html)")
)

knet_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  knet_questions,
  knet_vars,
  knet_labs,
  "",
  tbgrp        = "knet",
  graph_title  = knet_questions,
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = knet_tex_link,
  lang = lang
)



## 3.5 Creative / Content Creation Knowledge (kcrea_viz) ----

kcrea_questions <- c(
  transl("KCrea2", lang),
  transl("KCrea3", lang)
)

kcrea_vars <- c("KCrea2RC", "KCrea3RC")

kcrea_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

kcrea_info_text <- transl("content_creation_description", lang)

kcrea_tex_link <- md_text(
  kcrea_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_content_creation", lang), "](digital_content_creation.html)")
)

kcrea_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  kcrea_questions,
  kcrea_vars,
  kcrea_labs,
  "",
  tbgrp        = "kcrea",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kcrea_tex_link,
  lang = lang
)



## 3.6 Safety & Control of Devices Knowledge (ksafety_viz) ----

ksafety_questions <- c(
  transl("KSafDev2", lang),
  transl("KPriv1", lang),
  transl("KPriv2", lang)
)

ksafety_vars <- c(
  "KSafDev2RC",
  "KPriv1RC",
  "KPriv2RC"
)

ksafety_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

ksafety_info_text <- transl("safety_description", lang)

ksafety_tex_link <- md_text(
  ksafety_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_safety", lang), "](safety.html)")
)

ksafety_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  ksafety_questions,
  ksafety_vars,
  ksafety_labs,
  "",
  tbgrp        = "ksafety",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = ksafety_tex_link,
  lang = lang
)



## 3.7 Health & Wellbeing Knowledge (khealth_viz) ----

khealth_questions <- c(
  transl("KHealth2", lang),
  transl("KHealth3", lang)
)

khealth_vars <- c("KHealth2RC", "KHealth3RC")

khealth_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

khealth_info_text <- transl("health_description", lang)

khealth_tex_link <- md_text(
  khealth_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_health", lang), "](digital_health.html)")
)

khealth_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  khealth_questions,
  khealth_vars,
  khealth_labs,
  "",
  tbgrp        = "khealth",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = khealth_tex_link,
  lang = lang
)



## 3.8 Green / Sustainable Digital Knowledge (kgreen_viz) ----

kgreen_questions <- c(
  transl("KEnv2", lang),
  transl("KEnv3", lang)
)

kgreen_vars <- c("KEnv2RC", "KEnv3RC")

kgreen_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

kgreen_info_text <- transl("green_description", lang)

kgreen_tex_link <- md_text(
  kgreen_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_green", lang), "](green_digital.html)")
)

kgreen_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  kgreen_questions,
  kgreen_vars,
  kgreen_labs,
  "",
  tbgrp        = "kgreen",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kgreen_tex_link,
  lang = lang
)



## 3.9 Transactional Knowledge (ktrans_viz) ----

ktrans_questions <- c(
  transl("Ktrans2", lang),
  transl("Ktrans3", lang)
)

ktrans_vars <- c("Ktrans2RC", "Ktrans3RC")

ktrans_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

ktrans_info_text <- transl("transactional_description", lang)

ktrans_tex_link <- md_text(
  ktrans_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_transactional", lang), "](transactional.html)")
)

ktrans_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  ktrans_questions,
  ktrans_vars,
  ktrans_labs,
  "",
  tbgrp        = "ktrans",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = ktrans_tex_link,
  lang = lang
)



## 3.10 AI Knowledge (kai_viz) ----

kai_questions <- c(
  transl("KAI1", lang),
  transl("KAI2", lang),
  transl("KAI3", lang),
  transl("KAI4", lang)
)

kai_vars <- c("KAI1RC", "KAI2RC", "KAI3RC", "KAI4RC")

kai_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

kai_info_text <- transl("ai_description", lang)

kai_tex_link <- md_text(
  kai_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_ai", lang), "](ai.html)")
)

kai_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  kai_questions,
  kai_vars,
  kai_labs,
  "",
  tbgrp        = "kai",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kai_tex_link,
  lang = lang
)



## 3.11 Generative AI Knowledge (kgai_viz) ----

kgai_questions <- c(
  transl("KGAI1", lang),
  transl("KGAI2", lang),
  transl("KGAI3", lang),
  transl("KGAI4", lang),
  transl("KGAI5", lang)
)

kgai_vars <- c("KGAI1RC", "KGAI2RC", "KGAI3RC", "KGAI4RC", "KGAI5RC")

kgai_labs <- c(
  # transl("label_dont_know", lang),
  transl("label_correctly_answered", lang),
  transl("label_incorrectly_answered", lang), transl("dunno_understand", lang)
)

kgai_info_text <- transl("genai_description", lang)

kgai_tex_link <- md_text(
  kgai_info_text,
  "",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_genai", lang), "](gen_ai.html)")
)

kgai_viz <- create_vizzes2(
  breaks       = knowledge_breaks,
  kgai_questions,
  kgai_vars,
  kgai_labs,
  "",
  tbgrp        = "kgai",
  graph_title  = "", map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kgai_tex_link,
  lang = lang
)


## 3.12 Knowledge Collection ----
knowledge_collection <- #knowledge_viz %>% 
  # combine_viz(kinfo_viz) %>%
  kinfo_viz %>% 
  combine_viz(critinfo_viz) %>%
  combine_viz(knet_viz)  %>%
  add_pagination() %>%
  combine_viz(kcrea_viz) %>%
  combine_viz(ksafety_viz) %>%
  combine_viz(khealth_viz) %>%
  combine_viz(kgreen_viz)  %>%
  add_pagination() %>%
  combine_viz(ktrans_viz) %>%
  combine_viz(kai_viz) %>%
  combine_viz(kgai_viz) %>%
  set_tabgroup_labels(
    knowledge = "{{< iconify ph chart-bar-fill >}} Knowledge Score",
    kinfo     = "{{< iconify ph magnifying-glass >}} Strategic Information",
    critinfo  = "{{< iconify ph detective-fill >}} Critical Information",
    knet      = "{{< iconify ph chats-fill >}} Netiquette",
    kcrea     = "{{< iconify ph palette-fill >}} Digital Content Creation",
    ksafety   = "{{< iconify ph shield-check-fill >}} Safety",
    khealth   = "{{< iconify ph heart-fill >}} Digital Health",
    kgreen    = "{{< iconify ph recycle-fill >}} Green Digital",
    ktrans    = "{{< iconify ph wallet-fill >}} Transactional",
    kai       = "{{< iconify ph robot-fill >}} AI",
    kgai      = "{{< iconify ph magic-wand-fill >}} Gen AI",
    age    = "{{< iconify mdi:human-male-male-child >}} Age",
    gender = "{{< iconify mdi gender-transgender >}} Gender",
    edu    = "{{< iconify ph graduation-cap-fill >}} Education",
    overtime   = "{{< iconify ph chart-line-fill >}} Over Time",
    mig = "{{< iconify ph globe-hemisphere-east >}} Migration Background",
    wave1 = "{{< iconify ph number-circle-one-fill >}} Wave 1",
    wave2 = "{{< iconify ph number-circle-two-fill >}} Wave 2",
    overall = "{{< iconify ph users-fill >}} Overall",
    item1  = "{{< iconify ph chat-circle-fill >}} Question 1",
    item2  = "{{< iconify ph chat-circle-fill >}} Question 2",
    item3  = "{{< iconify ph chat-circle-fill >}} Question 3",
    item4  = "{{< iconify ph chat-circle-fill >}} Question 4",
    item5  = "{{< iconify ph chat-circle-fill >}} Question 5",
    item6  = "{{< iconify ph chat-circle-fill >}} Question 6",
    item7  = "{{< iconify ph chat-circle-fill >}} Question 7",
    item8  = "{{< iconify ph chat-circle-fill >}} Question 8"
  )



# Generate dashboard
# proj <- create_dashboard(output_dir = "my_dashboard") %>%
#   add_dashboard_page("page1", visualizations = viz_collection, data_path = "data.rds")
# 
# generate_dashboard(proj)

# 4. SKILLS VISUALIZATIONS =====================================================

## 4.1 Strategic Information Skills (sis_viz) ----

sis_questions <- c(
  transl("SInfo1", lang),
  transl("SInfo3_V2", lang),
  transl("SInfo4", lang)
)

sis_vars <- c("SInfo1", "SInfo3_V2", "SInfo4")

sis_labs <- c(
  transl("scale_completely_untrue", lang), 
  transl("scale_neither", lang), 
  transl("scale_completely_true", lang)
) #%>% rev()

sis_info_text <- transl("strategic_info_description", lang)

sis_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)


sys_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_strategic", lang), "](strategic_information.html)")



sis_tex_complete <- paste0(
  sis_info_text, "\n",
  sys_tex_more_link
)





sis_viz <- create_vizzes(sis_questions, 
                         sis_vars, sis_labs, 
                         "",#sis_tex2, 
                         breaks = c(0.5, 2.5, 3.5, 5.5), 
                         tbgrp = "sis", 
                         text_b_tabset = sis_tex_complete,
                         graph_title = transl("title_strategic_information_skills", lang))


## 4.2 Critical Information Skills (cis_viz) ----

cis_vars <- c("SInfo5", "SInfo6", "SInfo7")


cis_questions <- c(transl("SInfo5", lang), 
                   transl("SInfo6", lang),
                   transl("SInfo7", lang)) 

cis_info_text <- transl("critical_info_description", lang)

cis_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

cis_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_critical", lang), "](critical_information.html)")

cis_tex_complete <- paste0(
  cis_info_text, "\n",
  cis_tex_more_link
)

cis_viz <- create_vizzes(cis_questions, 
                         cis_vars, sis_labs, 
                         "",#cis_tex_link, 
                         breaks = c(0.5, 2.5, 3.5, 5.5), 
                         tbgrp = "cis",
                         text_b_tabset = cis_tex_complete,
                         graph_title = transl("title_critical_information_skills", lang))

## 4.3 Netiquette Skills (nskills_viz) ----


nskills_questions <- c(transl("SCom1_V2", lang), transl("SCom2", lang), transl("SCom4_V2", lang), transl("SCom5", lang))


nskills_vars <- c("SCom1_V2", "SCom2", "SCom4_V2", "SCom5")

nskills_info_text <- transl("netiquette_description", lang)

nskills_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

nskills_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_netiquette", lang), "](netiquette.html)")

nskills_tex_complete <- paste0(
  nskills_info_text, "\n",
  nskills_tex_more_link
)

nskills_viz  <- create_vizzes(nskills_questions, 
                              nskills_vars, sis_labs, 
                              "",#nskills_tex_link, 
                              breaks = c(0.5, 2.5, 3.5, 5.5), 
                              tbgrp = "nskills",
                              text_b_tabset = nskills_tex_complete,
                              graph_title = transl("title_netiquette_skills", lang))



## 4.4 Digital Content Creation Skills (dccs_viz) ----

dccs_questions <- c(transl("SCrea2", lang), transl("SCrea3", lang), transl("SCrea4", lang), transl("SCrea5", lang))


dccs_vars <- c("SCrea2", "SCrea3", "SCrea4", "SCrea5")

dccs_info_text <- transl("content_creation_description", lang)

dccs_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

dccs_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_content_creation", lang), "](digital_content_creation.html)")

dccs_tex_complete <- paste0(
  dccs_info_text, "\n",
  dccs_tex_more_link
)

dccs_viz  <- create_vizzes(dccs_questions, 
                           dccs_vars, sis_labs, 
                           "",#dccs_tex_link, 
                           breaks = c(0.5, 2.5, 3.5, 5.5), 
                           tbgrp = "dccs",
                           text_b_tabset = dccs_tex_complete,
                           graph_title = transl("title_digital_content_creation_skills", lang))



## 4.5 Safety & Control of Devices (safety_viz) ----
safety_questions <- c(
  transl("SSafDev1", lang),
  transl("SSafDev2", lang),
  transl("SPriv1", lang),
  transl("SPriv2", lang),
  transl("SPriv3", lang),
  transl("SPriv4", lang),
  transl("SCom3", lang)
)
safety_vars <- c("SSafDev1", "SSafDev2", "SPriv1", "SPriv2", "SPriv3", "SPriv4", "SCom3")

safety_info_text <- transl("safety_description", lang)

safety_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

safety_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_safety", lang), "](safety.html)")

safety_tex_complete <- paste0(
  safety_info_text, "\n",
  safety_tex_more_link
)

safety_viz <- create_vizzes(
  safety_questions, safety_vars, sis_labs,
  "",#safety_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "safety",
  text_b_tabset = safety_tex_complete,
  graph_title = transl("title_safety_control_skills", lang))


## 4.6 Digital Health & Wellbeing (dhealth_viz) ----
dhealth_questions <- c(
  transl("SHealth1", lang),
  transl("SHealth2_V2", lang),
  transl("SHealth3_V2", lang)
)
dhealth_vars <- c("SHealth1", "SHealth2_V2", "SHealth3_V2")

dhealth_info_text <- transl("digital_health_description", lang)

dhealth_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

dhealth_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_digital_health", lang), "](digital_health.html)")

dhealth_tex_complete <- paste0(
  dhealth_info_text, "\n",
  dhealth_tex_more_link
)

dhealth_viz <- create_vizzes(
  dhealth_questions, dhealth_vars, sis_labs,
  "",#dhealth_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "dhealth",
  text_b_tabset = dhealth_tex_complete,
  graph_title = transl("title_digital_health_wellbeing_skills", lang))


## 4.7 Green / Sustainable Digital (green_viz) ----
green_questions <- c(
  transl("SEnv1", lang),
  transl("SEnv2", lang),
  transl("SEnv3", lang)
)
green_vars <- c("SEnv1", "SEnv2", "SEnv3")

green_info_text <- transl("green_description", lang)

green_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

green_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_green", lang), "](green_digital.html)")

green_tex_complete <- paste0(
  green_info_text, "\n",
  green_tex_more_link
)

green_viz <- create_vizzes(
  green_questions, green_vars, sis_labs,
  "",#green_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "green",
  text_b_tabset = green_tex_complete,
  graph_title = transl("title_sustainable_green_digital_skills", lang))


## 4.8 Digital Problem Solving (dprob_viz) ----
dprob_questions <- c(
  transl("SProbl1", lang),
  transl("SProbl2", lang)
)
dprob_vars <- c("SProbl1", "SProbl2")

dprob_info_text <- transl("problem_solving_description", lang)

dprob_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

dprob_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_problem_solving", lang), "](digital_problem_solving.html)")

dprob_tex_complete <- paste0(
  dprob_info_text, "\n",
  dprob_tex_more_link
)

dprob_viz <- create_vizzes(
  dprob_questions, dprob_vars, sis_labs,
  "",#dprob_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "dprob",
  text_b_tabset = dprob_tex_complete,
  graph_title = transl("title_digital_problem_solving_skills", lang)
)


## 4.9 Transactional Skills (trans_viz) ----
trans_questions <- c(
  transl("Strans1", lang),
  transl("Strans2", lang),
  transl("Strans3", lang),
  transl("Strans4", lang),
  transl("Strans5", lang)
)
trans_vars <- c("Strans1", "Strans2", "Strans3", "Strans4", "Strans5")

trans_info_text <- transl("transactional_description", lang)

trans_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

trans_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_transactional", lang), "](transactional.html)")

trans_tex_complete <- paste0(
  trans_info_text, "\n",
  trans_tex_more_link
)

trans_viz <- create_vizzes(
  trans_questions, trans_vars, sis_labs,
  "",#trans_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "trans",
  text_b_tabset = trans_tex_complete,
  graph_title = transl("title_transactional_skills", lang)
)


## 4.10 AI Skills (ai_viz) ----
ai_questions <- c(
  transl("SAI1", lang),
  transl("SAI2", lang)
)

# digicom_data$sai3 %>% count(SAI)

ai_vars <- c("SAI1", "SAI2")

ai_info_text <- transl("ai_description", lang)

ai_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

ai_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_ai", lang), "](ai.html)")

ai_tex_complete <- paste0(
  ai_info_text, "\n",
  ai_tex_more_link
)

ai_viz <- create_vizzes(
  ai_questions, ai_vars, sis_labs,
  "",#ai_tex_link,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "ai",
  text_b_tabset = ai_tex_complete,
  graph_title = transl("title_ai_skills", lang)
)


## 4.11 Generative AI Skills (genai_viz) ----
# SGAI4 and SGAI5 are only in wave 2+
# Define all possible questions/vars
genai_questions_all <- c(
  transl("SGAI1", lang),
  transl("SGAI2", lang),
  transl("SGAI3", lang),
  transl("SGAI4", lang),
  transl("SGAI5", lang)
)
genai_vars_all <- c("SGAI1", "SGAI2", "SGAI3", "SGAI4", "SGAI5")

# Wave 1: only SGAI1-3 exist
genai_questions_w1 <- genai_questions_all[1:3]
genai_vars_w1 <- genai_vars_all[1:3]

# Wave 2+: all SGAI1-5 exist
genai_questions_w2 <- genai_questions_all
genai_vars_w2 <- genai_vars_all

genai_info_text <- transl("genai_description", lang)

genai_tex_question <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
  "```"
)

genai_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_genai", lang), "](gen_ai.html)")

genai_tex_complete <- paste0(
  genai_info_text, "\n",
  genai_tex_more_link
)

# Manually construct genai viz to handle different vars per wave
# Wave 1 has SGAI1-3, Wave 2 has SGAI1-5, but same tabgroup structure

# Wave 1 visualizations (only SGAI1-3)
genai_viz_w1 <- create_viz(
  type = "stackedbars",
  questions = genai_vars_w1,
  question_labels = genai_questions_w1,
  stacked_type = "percent",
  color_palette = the_colors,
  horizontal = TRUE,
  x_label = "", 
  text_before_tabset = genai_tex_complete,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  drop_na_vars = F,
  stack_label = NULL,
  filter = ~ wave == 1,
  weight_var = "weging_GAMO"
) %>%
  add_viz(
    title = "GenAI Skills", 
    title_tabset = "Wave 1",
    icon = "ph:chart-bar",
    tabgroup = "genai/wave1/overall"
  )

# Wave 2 visualizations (all SGAI1-5)
genai_viz_w2 <- create_viz(
  type = "stackedbars",
  questions = genai_vars_w2,
  question_labels = genai_questions_w2,
  stacked_type = "percent",
  color_palette = the_colors,
  horizontal = TRUE,
  x_label = "", 
  text_before_tabset = genai_tex_complete,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  drop_na_vars = F,
  stack_label = NULL,
  filter = ~ wave == 2,
  weight_var = "weging_GAMO"
) %>%
  add_viz(
    title = "GenAI Skills", 
    title_tabset = "Wave 2",
    icon = "ph:chart-bar",
    tabgroup = "genai/wave2/overall"
  )

# Over Time Overall (timeline without group_var) - only for SGAI1-3 (exist in both waves)
genai_overtime_overall <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  text_before_tabset = genai_tex_complete,
  response_filter = 4:5, 
  response_filter_label = "Percentage who answered (Completely) True (4-5)",
  response_filter_combine = T,
  x_label = "", 
  y_label = "Percentage who answered (Completely) True (4-5)",
  color_palette = the_colors,
  y_min = 0,
  y_max = 100,
  response_filter_label = NULL,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_timeline_single(genai_vars_w1, "genai", "overall", wave_label = "Over Time", questions = genai_questions_w1)

# Wave 1 by Age/Gender/Education/Migration - only SGAI1-3
genai_demo_w1 <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  text_before_tabset = genai_tex_complete,
  stack_order = rev(sis_labs),
  filter = ~ wave == 1,
  drop_na_vars = F,
  color_palette = the_colors,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "AgeGroup", "genai", "age", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "geslacht", "genai", "gender", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "Education", "genai", "edu", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "MigrationBackground", "genai", "mig", wave_label = "Wave 1")

# Wave 2 by Age/Gender/Education/Migration - all SGAI1-5
genai_demo_w2 <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  text_before_tabset = genai_tex_complete,
  filter = ~ wave == 2,
  drop_na_vars = F,
  color_palette = the_colors,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "AgeGroup", "genai", "age", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "geslacht", "genai", "gender", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "Education", "genai", "edu", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "MigrationBackground", "genai", "mig", wave_label = "Wave 2")

# Over Time by Age/Gender/Education/Migration - only for SGAI1-3 (exist in both waves)
genai_overtime_demo <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  response_filter = 4:5, 
  text_before_tabset = genai_tex_complete,
  x_label = "", 
  y_label = "Percentage who answered (Completely) True (4-5)",
  color_palette = the_colors,
  y_min = 0,
  y_max = 100,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_timeline(genai_vars_w1, "AgeGroup", "genai", "age", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "geslacht", "genai", "gender", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "Education", "genai", "edu", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "MigrationBackground", "genai", "mig", wave_label = "Over Time", questions = genai_questions_w1)

# Combine them all
genai_viz <- genai_viz_w1 %>% 
  combine_viz(genai_viz_w2) %>%
  combine_viz(genai_overtime_overall) %>%
  combine_viz(genai_demo_w1) %>%
  combine_viz(genai_demo_w2) %>%
  combine_viz(genai_overtime_demo)


## 4.12 Skills Collection ----
skills_viz <- sis_viz %>% 
  combine_viz(cis_viz) %>% 
  combine_viz(nskills_viz) %>%
  combine_viz(dccs_viz)  %>%
  add_pagination() %>%
  # new ones
  combine_viz(safety_viz) %>%
  combine_viz(dhealth_viz) %>%
  combine_viz(green_viz) %>%
  combine_viz(dprob_viz)  %>%
  add_pagination() %>%
  combine_viz(trans_viz) %>%
  combine_viz(ai_viz) %>%
  combine_viz(genai_viz) %>%
  # labels for ALL tabgroups - using dimension-specific icons
  set_tabgroup_labels(
    sis     = "{{< iconify ph magnifying-glass >}} Strategic Information",
    cis     = "{{< iconify ph detective-fill >}} Critical Information",
    nskills = "{{< iconify ph chats-fill >}} Netiquette",
    dccs    = "{{< iconify ph palette-fill >}} Digital Content Creation",
    safety  = "{{< iconify ph shield-check-fill >}} Safety",
    dhealth = "{{< iconify ph heart-fill >}} Digital Health",
    green   = "{{< iconify ph recycle-fill >}} Green Digital",
    dprob   = "{{< iconify ph lightbulb-fill >}} Digital Problem Solving",
    trans   = "{{< iconify ph wallet-fill >}} Transactional",
    ai      = "{{< iconify ph robot-fill >}} AI",
    genai   = "{{< iconify ph magic-wand-fill >}} Gen AI",
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)),
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age    = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)),
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)),
    edu    = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime   = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)),
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 1"),
    item2  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 2"),
    item3  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 3"),
    item4  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 4"),
    item5  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 5"),
    item6  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 6"),
    item7  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 7"),
    item8  = paste0("{{< iconify ph chat-circle-fill >}} ", transl("tab_question", lang), " 8")
  )



# 5. PERFORMANCE VISUALIZATIONS ================================================

## 5.0 Performance Setup: Shared Labels ----
perf_correct_labs <- c(transl("label_incorrect", lang), transl("label_correct", lang))
perf_selected_labs <- c(transl("label_not_selected", lang), transl("label_selected", lang))

# suggested text block (mirror your knowledge_tex style)
performance_tex <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance", lang), '", preset = "question")'),
  "```"
)


## 5.1 Performance: Strategic Information (perf_sis_viz) -----
perf_sis_questions <- c(
  transl("PSIS2", lang)
)
## TODO: its missing PSIS1RC??
# digicom_data %>% count(PSIS1)
# digicom_data$PCIS1R <- ifelse(digicom_data$PCIS1N == 2, 1, ifelse (digicom_data$PCIS1N == 5 | digicom_data$PCIS1N == 6, NA, 0))
perf_sis_vars <- c("PSIS2R")

perf_sis_info_text <- transl("strategic_info_description", lang)

perf_sis_tex_link <- md_text(
  perf_sis_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_sis", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_strategic", lang), "](strategic_information.html)")
)

perf_sis_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_sis_questions,
  perf_sis_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_sis",
  graph_title  = perf_sis_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_sis_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PSIS2R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("strategic_info_infobox_image", lang)),
    image_width = "50%"
  ) 



## 5.2 Performance: Critical Information (perf_cis_viz) ----
perf_cis_questions <- c(
  transl("PCIS1", lang),
  transl("PCIS2", lang),
  transl("PCIS3", lang)
)

perf_cis_vars <- c("PCIS1R", "PCIS2R", "PCIS3R")

perf_cis_info_text <- transl("critical_info_description", lang)

perf_cis_tex_link <- md_text(
  perf_cis_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_cis", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_critical", lang), "](critical_information.html)")
)

perf_cis_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_cis_questions,
  perf_cis_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_cis",
  graph_title  = "",
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_cis_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PCIS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q1_infobox_image", lang)),
    image_width = "50%"
  ) %>%
  add_modal(
    modal_id = "PCIS2R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q2_infobox_image", lang)),
    image_width = "50%"
  ) %>%
  add_modal(
    modal_id = "PCIS3R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q3_infobox_image", lang)),
    image_width = "50%"
  )


## 5.3 Performance: Netiquette (perf_netiquette_viz) ----
perf_n_questions <- c(
  transl("PNS1", lang)
)

perf_n_vars <- c("PNS1R")

perf_n_info_text <- transl("netiquette_description", lang)

perf_n_tex_link <- md_text(
  perf_n_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_netiquette", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_netiquette", lang), "](netiquette.html)")
)

perf_netiquette_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_n_questions,
  perf_n_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_netiquette",
  graph_title  = perf_n_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_n_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PNS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("netiquette_competence_infobox_image", lang)),
    image_width = "50%"
  )



## 5.4 Performance: Digital Content Creation (perf_dccs_viz) ----
perf_dccs_questions <- c(
  transl("PDCCS1", lang)
)

perf_dccs_vars <- c("PDCCS1R")

perf_dccs_info_text <- transl("content_creation_description", lang)

perf_dccs_tex_link <- md_text(
  perf_dccs_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  # Use the actual question text (PDCCS1) which now has the modal link embedded
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_dccs", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_content_creation", lang), "](digital_content_creation.html)")
) 


perf_dccs_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_dccs_questions,
  perf_dccs_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_dccs",
  graph_title  = perf_dccs_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_dccs_tex_link,
  lang = lang
)  %>%
  add_modal(
    modal_id = "PDCCS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("digital_content_creation_competence_infobox_image", lang)),
    image_width = "50%"
  )



## 5.5 Performance: Safety & Control of Devices (perf_safety_viz) ----
perf_safety_questions <- c(
  transl("PSCS3_1", lang),
  transl("PSCS3_2", lang),
  transl("PSCS3_3", lang),
  transl("PSCS3_4", lang),
  transl("PSCS3_5", lang),
  transl("PSCS3_6", lang),
  transl("PSCS3_7", lang),
  transl("PSCS3_8", lang),
  transl("PSCS3_9", lang),
  transl("PSCS3_10", lang)
)

# TODO: *Privacy, Safety & Control:* PSCS1R (dichotomous correct/incorrect)
# PSCS3R (dichotomous doing behavior yes/no) (BEHAVIORAL item) PSCS3C
# (dichotomous incorrect answer yes/no)
# digicom_data %>% count(PSCS3_10)
perf_safety_vars <- c(
  "PSCS3_1","PSCS3_2","PSCS3_3","PSCS3_4","PSCS3_5",
  "PSCS3_6","PSCS3_7","PSCS3_8","PSCS3_9", "PSCS3_10"
)

perf_safety_info_text <- transl("safety_description", lang)

perf_safety_tex_link <- md_text(
  perf_safety_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_safety", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_safety", lang), "](safety.html)")
)

perf_safety_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_safety_questions,
  perf_safety_vars,
  perf_selected_labs,
  "",
  tbgrp        = "perf_safety",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  text_b_tabset = perf_safety_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PSCS3_1",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("safety_competence_infobox_image", lang)),
    image_width = "50%"
  )



## 5.6 Performance: Health & Wellbeing (perf_health_viz) ----
perf_health_questions <- c(
  transl("PDHWS1_1", lang),
  transl("PDHWS1_2", lang),
  transl("PDHWS1_3", lang),
  transl("PDHWS1_4", lang),
  transl("PDHWS1_5", lang),
  transl("PDHWS1_6", lang),
  transl("PDHWS1_7", lang),
  transl("PDHWS1_8", lang)
)

perf_health_vars <- c(
  "PDHWS1_1","PDHWS1_2","PDHWS1_3","PDHWS1_4",
  "PDHWS1_5","PDHWS1_6","PDHWS1_7","PDHWS1_8"
)

perf_health_info_text <- transl("digital_health_description", lang)

perf_health_tex_link <- md_text(
  perf_health_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_health", lang), '", preset = "question")'),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_digital_health", lang), "](digital_health.html)")
)

perf_health_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_health_questions,
  perf_health_vars,
  perf_selected_labs,
  "",
  tbgrp        = "perf_health",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  text_b_tabset = perf_health_tex_link,
  lang = lang
)



## 5.7 Performance: Green Skills (perf_green_viz) ----
perf_green_questions <- c(
  transl("PSGDS1_1", lang),
  transl("PSGDS1_2", lang),
  transl("PSGDS1_3", lang),
  transl("PSGDS1_4", lang),
  transl("PSGDS1_5", lang),
  transl("PSGDS1_6", lang),
  transl("PSGDS1_7", lang),
  transl("PSGDS1_8", lang),
  transl("PSGDS1_9", lang)
)

perf_green_vars <- c(
  "PSGDS1_1","PSGDS1_2","PSGDS1_3","PSGDS1_4",
  "PSGDS1_5","PSGDS1_6","PSGDS1_7","PSGDS1_8","PSGDS1_9"
)

perf_green_info_text <- transl("green_description", lang)

perf_green_tex_link <- md_text(
  perf_green_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_green", lang), '", preset = "question")'),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_green", lang), "](green_digital.html)")
)

perf_green_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_green_questions,
  perf_green_vars,
  perf_selected_labs,
  "",
  tbgrp        = "perf_green",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  text_b_tabset = perf_green_tex_link,
  lang = lang
)



## 5.8 Performance: Problem Solving (perf_ps_viz) ----
perf_ps_questions <- c(
  transl("SourceHelp_1", lang),
  transl("SourceHelp_2", lang),
  transl("SourceHelp_3", lang),
  transl("SourceHelp_4", lang),
  transl("SourceHelp_5", lang),
  transl("SourceHelp_6", lang),
  transl("SourceHelp_7", lang),
  transl("SourceHelp_8", lang),
  transl("SourceHelp_9", lang)
)

perf_ps_vars <- c(
  "SourceHelp_1","SourceHelp_2","SourceHelp_3","SourceHelp_4",
  "SourceHelp_5","SourceHelp_6","SourceHelp_7","SourceHelp_8","SourceHelp_9"
)

perf_ps_info_text <- transl("problem_solving_description", lang)

perf_ps_tex_link <- md_text(
  perf_ps_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_problem_solving", lang), '", preset = "question")'),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_problem_solving", lang), "](digital_problem_solving.html)")
)

perf_ps_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_ps_questions,
  perf_ps_vars,
  perf_selected_labs,
  "",
  tbgrp        = "perf_ps",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  text_b_tabset = perf_ps_tex_link,
  lang = lang
)



## 5.9 Performance: Transactional (perf_trans_viz) ----
perf_trans_questions <- c(
  transl("PTS1", lang)
)
# digicom_data %>% count(PTS1R)
perf_trans_vars <- c("PTS1R")

perf_trans_info_text <- transl("transactional_description", lang)

perf_trans_tex_link <- md_text(
  perf_trans_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_trans", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_transactional", lang), "](transactional.html)")
)

perf_trans_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_trans_questions,
  perf_trans_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_trans",
  graph_title  = perf_trans_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_trans_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PTS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("transcational_competence_infobox_image", lang)),
    image_width = "50%"
  )



## 5.10 Performance: AI (perf_ai_viz) ----
perf_ai_questions <- c(
  transl("PAIS2_1", lang),
  transl("PAIS2_2", lang),
  transl("PAIS2_3", lang),
  transl("PAIS2_4", lang),
  transl("PAIS2_5", lang),
  transl("PAIS2_6", lang),
  transl("PAIS2_7", lang),
  transl("PAIS2_8", lang),
  transl("PAIS2_9", lang)
)

perf_ai_vars <- c(
  "PAIS2_1","PAIS2_2","PAIS2_3","PAIS2_4","PAIS2_5",
  "PAIS2_6","PAIS2_7","PAIS2_8","PAIS2_9"
)

perf_ai_info_text <- transl("ai_description", lang)

perf_ai_tex_link <- md_text(
  perf_ai_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_ai", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_ai", lang), "](ai.html)")
)

perf_ai_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_ai_questions,
  perf_ai_vars,
  perf_selected_labs,
  "",
  tbgrp        = "perf_ai",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  text_b_tabset = perf_ai_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PAIS2_1",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("ai_competence_infobox_image", lang)),
    image_width = "50%"
  )



## 5.11 Performance: GenAI (perf_genai_viz) ----
perf_genai_questions <- c(
  transl("PAIS1", lang)
)

perf_genai_vars <- c("PAIS1R")

perf_genai_info_text <- transl("genai_description", lang)

perf_genai_tex_link <- md_text(
  perf_genai_info_text,
  "",
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_genai", lang))), "', preset = 'question')"),
  "```",
  paste0("[{{< iconify ph cards >}} ", transl("link_see_all_genai", lang), "](gen_ai.html)")
)

perf_genai_viz <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_genai_questions,
  perf_genai_vars,
  perf_correct_labs,
  "",
  tbgrp        = "perf_genai",
  graph_title  = perf_genai_questions,
  # in original you reversed categories_dat; here we can still map 1=Correct
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  text_b_tabset = perf_genai_tex_link,
  lang = lang
) %>%
  add_modal(
    modal_id = "PAIS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("genai_competence_infobox_image", lang)),
    image_width = "50%"
  )



# 6. VISUALIZATION COLLECTIONS =================================================

## 6.1 Performance Collection ----
performance_collection <- perf_sis_viz %>%
  combine_viz(perf_cis_viz) %>%
  combine_viz(perf_dccs_viz) %>%
  add_pagination() %>% 
  combine_viz(perf_netiquette_viz) %>%
  combine_viz(perf_safety_viz) %>%
  combine_viz(perf_health_viz) %>%
  add_pagination() %>%
  combine_viz(perf_green_viz) %>%
  combine_viz(perf_ps_viz)  %>%
  combine_viz(perf_trans_viz) %>%
  add_pagination() %>%
  combine_viz(perf_ai_viz) %>%
  combine_viz(perf_genai_viz) %>%
  set_tabgroup_labels(
    perf_sis    = paste0("{{< iconify ph magnifying-glass >}} ", transl("dimension_strategic_info", lang)),
    perf_cis    = paste0("{{< iconify ph detective-fill >}} ", transl("dimension_critical_info", lang)),
    perf_netiquette = paste0("{{< iconify ph chats-fill >}} ", transl("dimension_netiquette", lang)),
    perf_dccs   = paste0("{{< iconify ph palette-fill >}} ", transl("dimension_content_creation", lang)),
    perf_safety = paste0("{{< iconify ph shield-check-fill >}} ", transl("dimension_safety", lang)),
    perf_health = paste0("{{< iconify ph heart-fill >}} ", transl("dimension_digital_health", lang)),
    perf_green  = paste0("{{< iconify ph recycle-fill >}} ", transl("dimension_green", lang)),
    perf_ps     = paste0("{{< iconify ph lightbulb-fill >}} ", transl("dimension_problem_solving", lang)),
    perf_trans  = paste0("{{< iconify ph wallet-fill >}} ", transl("dimension_transactional", lang)),
    perf_ai     = paste0("{{< iconify ph robot-fill >}} ", transl("dimension_ai", lang)),
    perf_genai  = paste0("{{< iconify ph magic-wand-fill >}} ", transl("dimension_genai", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)),
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age    = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)),
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)),
    edu    = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime   = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)),
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")),
    item2  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")),
    item3  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")),
    item5  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")),
    item6  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")),
    item8  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8")),
    item9  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 9")),
    item10  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 10"))
  )

# 7. DIMENSION-SPECIFIC COMBINED VISUALIZATIONS ================================

library(htmltools)

## 7.0 Setup: Icon System ----
# Create combined visualizations for dimension pages with proper labels
# Consistent icon system:
# 💪 Skills = ph:lightning-fill (abilities/capabilities)
# 📚 Knowledge = ph:book-open-fill (understanding/learning)
# 🏆 Performance = ph:trophy-fill (achievement/testing)



performance_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_performance", lang), "](performance.html)")

knowledge_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_knowledge", lang), "](knowledge.html)")

skills_tex_more_link <- paste0("[{{< iconify ph cards >}} ", transl("link_see_all_skills", lang), "](skills.html)")


skills_short <- transl("page_text_skills_short", lang)
performance_short <- transl("page_text_performance_short", lang)
knowledge_short <- transl("page_text_knowledge_short", lang)


sis_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)


## Knowledge _wo_link vizzes ----

kinfo_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

kinfo_viz_wo_link <- create_vizzes2(
  breaks = knowledge_breaks,
  kinfo_questions,
  kinfo_vars,
  kinfo_labs,
  "",
  tbgrp   = "kinfo",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kinfo_tex_wo_complete,
  lang = lang
)

critinfo_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

critinfo_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  critinfo_questions,
  critinfo_vars,
  critinfo_labs,
  "",
  tbgrp        = "critinfo",
  graph_title  = critinfo_questions,
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = critinfo_tex_wo_complete,
  lang = lang
)

knet_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

knet_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  knet_questions,
  knet_vars,
  knet_labs,
  "",
  tbgrp        = "knet",
  graph_title  = knet_questions, 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = knet_tex_wo_complete,
  lang = lang
)

kcrea_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

kcrea_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  kcrea_questions,
  kcrea_vars,
  kcrea_labs,
  "",
  tbgrp        = "kcrea",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kcrea_tex_wo_complete,
  lang = lang
)

ksafety_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

ksafety_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  ksafety_questions,
  ksafety_vars,
  ksafety_labs,
  "",
  tbgrp        = "ksafety",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = ksafety_tex_wo_complete,
  lang = lang
)

khealth_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

khealth_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  khealth_questions,
  khealth_vars,
  khealth_labs,
  "",
  tbgrp        = "khealth",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = khealth_tex_wo_complete,
  lang = lang
)

kgreen_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

kgreen_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  kgreen_questions,
  kgreen_vars,
  kgreen_labs,
  "",
  tbgrp        = "kgreen",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kgreen_tex_wo_complete,
  lang = lang
)

ktrans_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

ktrans_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  ktrans_questions,
  ktrans_vars,
  ktrans_labs,
  "",
  tbgrp        = "ktrans",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = ktrans_tex_wo_complete,
  lang = lang
)

kai_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

kai_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  kai_questions,
  kai_vars,
  kai_labs,
  "",
  tbgrp        = "kai",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kai_tex_wo_complete,
  lang = lang
)

kgai_tex_wo_complete <- paste0(
  knowledge_short, "\n",
  knowledge_tex, "\n",
  knowledge_tex_more_link
)

kgai_viz_wo_link <- create_vizzes2(
  breaks       = knowledge_breaks,
  kgai_questions,
  kgai_vars,
  kgai_labs,
  "",
  tbgrp        = "kgai",
  graph_title  = "", 
  map_values = list("1" = transl("label_correctly_answered", lang), "0" = transl("label_incorrectly_answered", lang)),
  text_b_tabset = kgai_tex_wo_complete,
  lang = lang
)

## Skills _wo_link vizzes ----

sis_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

sis_viz_wo_link <- create_vizzes(sis_questions, 
                                 sis_vars, sis_labs, 
                                 sis_tex_question, breaks = c(0.5, 2.5, 3.5, 5.5), 
                                 tbgrp = "sis", text_b_tabset = sis_tex_wo_complete,
                                 graph_title = transl("title_strategic_information_skills", lang))

cis_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

cis_viz_wo_link <- create_vizzes(cis_questions, 
                                 cis_vars, sis_labs, 
                                 cis_tex_question, breaks = c(0.5, 2.5, 3.5, 5.5), 
                                 tbgrp = "cis",
                                 text_b_tabset = cis_tex_wo_complete,
                                 graph_title = transl("title_critical_information_skills", lang))

nskills_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

nskills_viz_wo_link  <- create_vizzes(nskills_questions, 
                                      nskills_vars, sis_labs, 
                                      nskills_tex_question, breaks = c(0.5, 2.5, 3.5, 5.5), 
                                      tbgrp = "nskills",
                                      text_b_tabset = nskills_tex_wo_complete,
                                      graph_title = transl("title_netiquette_skills", lang))

dccs_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

dccs_viz_wo_link  <- create_vizzes(dccs_questions, 
                                   dccs_vars, sis_labs, 
                                   dccs_tex_question, breaks = c(0.5, 2.5, 3.5, 5.5), 
                                   tbgrp = "dccs",
                                   text_b_tabset = dccs_tex_wo_complete,
                                   graph_title = transl("title_digital_content_creation_skills", lang))

safety_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

safety_viz_wo_link <- create_vizzes(
  safety_questions, safety_vars, sis_labs,
  safety_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "safety",
  text_b_tabset = safety_tex_wo_complete,
  graph_title = transl("title_safety_control_skills", lang))

dhealth_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

dhealth_viz_wo_link <- create_vizzes(
  dhealth_questions, dhealth_vars, sis_labs,
  dhealth_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "dhealth",
  text_b_tabset = dhealth_tex_wo_complete,
  graph_title = transl("title_digital_health_wellbeing_skills", lang))

green_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

green_viz_wo_link <- create_vizzes(
  green_questions, green_vars, sis_labs,
  green_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "green",
  text_b_tabset = green_tex_wo_complete,
  graph_title = transl("title_sustainable_green_digital_skills", lang))

dprob_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

dprob_viz_wo_link <- create_vizzes(
  dprob_questions, dprob_vars, sis_labs,
  dprob_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "dprob",
  text_b_tabset = dprob_tex_wo_complete,
  graph_title = transl("title_digital_problem_solving_skills", lang)
)

trans_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

trans_viz_wo_link <- create_vizzes(
  trans_questions, trans_vars, sis_labs,
  trans_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "trans",
  text_b_tabset = trans_tex_wo_complete,
  graph_title = transl("title_transactional_skills", lang)
)

ai_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

ai_viz_wo_link <- create_vizzes(
  ai_questions, ai_vars, sis_labs,
  ai_tex_question,
  breaks = c(0.5, 2.5, 3.5, 5.5),
  tbgrp  = "ai",
  text_b_tabset = ai_tex_wo_complete,
  graph_title = transl("title_ai_skills", lang)
)

genai_tex_wo_complete <- paste0(
  skills_short, "\n",
  sis_tex_question, "\n",
  skills_tex_more_link
)

# Wave 1 visualizations (only SGAI1-3)
genai_viz_wo_link_w1 <- create_viz(
  type = "stackedbars",
  questions = genai_vars_w1,
  question_labels = genai_questions_w1,
  stacked_type = "percent",
  color_palette = the_colors,
  horizontal = TRUE,
  x_label = "", 
  text_before_tabset = genai_tex_wo_complete,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  drop_na_vars = F,
  stack_label = NULL,
  filter = ~ wave == 1,
  weight_var = "weging_GAMO"
) %>%
  add_viz(
    title = "GenAI Skills", 
    title_tabset = "Wave 1",
    icon = "ph:chart-bar",
    tabgroup = "genai/wave1/overall"
  )

# Wave 2 visualizations (all SGAI1-5)
genai_viz_wo_link_w2 <- create_viz(
  type = "stackedbars",
  questions = genai_vars_w2,
  question_labels = genai_questions_w2,
  stacked_type = "percent",
  color_palette = the_colors,
  horizontal = TRUE,
  x_label = "", 
  text_before_tabset = genai_tex_wo_complete,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  drop_na_vars = F,
  stack_label = NULL,
  filter = ~ wave == 2,
  weight_var = "weging_GAMO"
) %>%
  add_viz(
    title = "GenAI Skills", 
    title_tabset = "Wave 2",
    icon = "ph:chart-bar",
    tabgroup = "genai/wave2/overall"
  )

# Over Time Overall (timeline without group_var) - only for SGAI1-3
genai_overtime_overall_wo_link <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  text_before_tabset = genai_tex_wo_complete,
  response_filter = 4:5, 
  response_filter_label = "Percentage who answered (Completely) True (4-5)",
  response_filter_combine = T,
  x_label = "", 
  y_label = "Percentage who answered (Completely) True (4-5)",
  color_palette = the_colors,
  y_min = 0,
  y_max = 100,
  response_filter_label = NULL,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_timeline_single(genai_vars_w1, "genai", "overall", wave_label = "Over Time", questions = genai_questions_w1)

# Wave 1 by Age/Gender/Education/Migration - only SGAI1-3
genai_demo_w1_wo_link <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  text_before_tabset = genai_tex_wo_complete,
  stack_order = rev(sis_labs),
  filter = ~ wave == 1,
  drop_na_vars = F,
  color_palette = the_colors,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "AgeGroup", "genai", "age", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "geslacht", "genai", "gender", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "Education", "genai", "edu", wave_label = "Wave 1") |>
  add_all_viz_stackedbar(genai_vars_w1, genai_questions_w1, "MigrationBackground", "genai", "mig", wave_label = "Wave 1")

# Wave 2 by Age/Gender/Education/Migration - all SGAI1-5
genai_demo_w2_wo_link <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = T,
  stack_breaks = c(0.5, 2.5, 3.5, 5.5),
  stack_bin_labels = sis_labs,
  stack_order = rev(sis_labs),
  text_before_tabset = genai_tex_wo_complete,
  filter = ~ wave == 2,
  drop_na_vars = F,
  color_palette = the_colors,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "AgeGroup", "genai", "age", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "geslacht", "genai", "gender", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "Education", "genai", "edu", wave_label = "Wave 2") |>
  add_all_viz_stackedbar(genai_vars_w2, genai_questions_w2, "MigrationBackground", "genai", "mig", wave_label = "Wave 2")

# Over Time by Age/Gender/Education/Migration - only for SGAI1-3
genai_overtime_demo_wo_link <- create_viz(
  type = "timeline",
  time_var = "wave_time_label",
  chart_type = "line",
  response_filter = 4:5, 
  text_before_tabset = genai_tex_wo_complete,
  x_label = "", 
  y_label = "Percentage who answered (Completely) True (4-5)",
  color_palette = the_colors,
  y_min = 0,
  y_max = 100,
  weight_var = "weging_GAMO"
) |>
  add_all_viz_timeline(genai_vars_w1, "AgeGroup", "genai", "age", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "geslacht", "genai", "gender", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "Education", "genai", "edu", wave_label = "Over Time", questions = genai_questions_w1) |>
  add_all_viz_timeline(genai_vars_w1, "MigrationBackground", "genai", "mig", wave_label = "Over Time", questions = genai_questions_w1)

# Combine them all
genai_viz_wo_link <- genai_viz_wo_link_w1 %>% 
  combine_viz(genai_viz_wo_link_w2) %>%
  combine_viz(genai_overtime_overall_wo_link) %>%
  combine_viz(genai_demo_w1_wo_link) %>%
  combine_viz(genai_demo_w2_wo_link) %>%
  combine_viz(genai_overtime_demo_wo_link)

## Performance _wo_link vizzes ----

perf_sis_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_sis", lang))), "', preset = 'question')"),
  "```"
)

perf_sis_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_sis_blockquote, "\n",
  performance_tex_more_link
)

perf_sis_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_sis_questions,
  perf_sis_vars,
  perf_correct_labs,
  text_b_tabset = perf_sis_tex_wo_complete,
  tbgrp        = "perf_sis",
  graph_title  = perf_sis_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PSIS2R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("strategic_info_infobox_image", lang)),
    image_width = "50%"
  )

perf_cis_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_cis", lang))), "', preset = 'question')"),
  "```"
)

perf_cis_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_cis_blockquote, "\n",
  performance_tex_more_link
)

perf_cis_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_cis_questions,
  perf_cis_vars,
  perf_correct_labs,
  text_b_tabset = perf_cis_tex_wo_complete,
  tbgrp        = "perf_cis",
  graph_title  = "",
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PCIS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q1_infobox_image", lang)),
    image_width = "50%"
  ) %>%
  add_modal(
    modal_id = "PCIS2R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q2_infobox_image", lang)),
    image_width = "50%"
  ) %>%
  add_modal(
    modal_id = "PCIS3R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("critical_info_competence_q3_infobox_image", lang)),
    image_width = "50%"
  )

perf_n_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_netiquette", lang))), "', preset = 'question')"),
  "```"
)

perf_n_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_n_blockquote, "\n",
  performance_tex_more_link
)

perf_netiquette_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_n_questions,
  perf_n_vars,
  perf_correct_labs,
  text_b_tabset = perf_n_tex_wo_complete,
  tbgrp        = "perf_netiquette",
  graph_title  = perf_n_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PNS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("netiquette_competence_infobox_image", lang)),
    image_width = "50%"
  )

perf_dccs_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_dccs", lang))), "', preset = 'question')"),
  "```"
)

perf_dccs_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_dccs_blockquote, "\n",
  performance_tex_more_link
)

perf_dccs_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_dccs_questions,
  perf_dccs_vars,
  perf_correct_labs,
  text_b_tabset = perf_dccs_tex_wo_complete,
  tbgrp        = "perf_dccs",
  graph_title  = perf_dccs_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
)  %>%
  add_modal(
    modal_id = "PDCCS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("digital_content_creation_competence_infobox_image", lang)),
    image_width = "50%"
  )

perf_safety_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_safety", lang))), "', preset = 'question')"),
  "```"
)

perf_safety_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_safety_blockquote, "\n",
  performance_tex_more_link
)

perf_safety_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_safety_questions,
  perf_safety_vars,
  perf_selected_labs,
  text_b_tabset = perf_safety_tex_wo_complete,
  tbgrp        = "perf_safety",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PSCS3_1",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("safety_competence_infobox_image", lang)),
    image_width = "50%"
  )

perf_health_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_health", lang), '", preset = "question")'),
  "```"
)

perf_health_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_health_blockquote, "\n",
  performance_tex_more_link
)

perf_health_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_health_questions,
  perf_health_vars,
  perf_selected_labs,
  text_b_tabset = perf_health_tex_wo_complete,
  tbgrp        = "perf_health",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  lang = lang
)

perf_green_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_green", lang), '", preset = "question")'),
  "```"
)

perf_green_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_green_blockquote, "\n",
  performance_tex_more_link
)

perf_green_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_green_questions,
  perf_green_vars,
  perf_selected_labs,
  text_b_tabset = perf_green_tex_wo_complete,
  tbgrp        = "perf_green",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  lang = lang
)

perf_ps_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0('create_blockquote("', transl("blockquote_performance_problem_solving", lang), '", preset = "question")'),
  "```"
)

perf_ps_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_ps_blockquote, "\n",
  performance_tex_more_link
)

perf_ps_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_ps_questions,
  perf_ps_vars,
  perf_selected_labs,
  text_b_tabset = perf_ps_tex_wo_complete,
  tbgrp        = "perf_ps",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  lang = lang
)

perf_trans_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_trans", lang))), "', preset = 'question')"),
  "```"
)

perf_trans_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_trans_blockquote, "\n",
  performance_tex_more_link
)

perf_trans_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_trans_questions,
  perf_trans_vars,
  perf_correct_labs,
  text_b_tabset = perf_trans_tex_wo_complete,
  tbgrp        = "perf_trans",
  graph_title  = perf_trans_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PTS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("transactional_competence_infobox_image", lang)),
    image_width = "50%"
  )

perf_ai_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_ai", lang))), "', preset = 'question')"),
  "```"
)

perf_ai_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_ai_blockquote, "\n",
  performance_tex_more_link
)

perf_ai_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_ai_questions,
  perf_ai_vars,
  perf_selected_labs,
  text_b_tabset = perf_ai_tex_wo_complete,
  tbgrp        = "perf_ai",
  graph_title  = "",
  map_values   = list("1" = transl("label_selected", lang), "0" = transl("label_not_selected", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PAIS2_1",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("ai_competence_infobox_image", lang)),
    image_width = "50%"
  )

perf_genai_blockquote <- md_text(
  "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
  paste0("create_blockquote('", gsub('"', '\\\\"', gsub("'", "\\\\'", transl("blockquote_performance_genai", lang))), "', preset = 'question')"),
  "```"
)

perf_genai_tex_wo_complete <- paste0(
  performance_short, "\n",
  perf_genai_blockquote, "\n",
  performance_tex_more_link
)

perf_genai_viz_wo_link <- create_vizzes3(
  breaks       = knowledge_breaks,
  perf_genai_questions,
  perf_genai_vars,
  perf_correct_labs,
  text_b_tabset = perf_genai_tex_wo_complete,
  tbgrp        = "perf_genai",
  graph_title  = perf_genai_questions,
  map_values   = list("1" = transl("label_correct", lang), "0" = transl("label_incorrect", lang)),
  lang = lang
) %>%
  add_modal(
    modal_id = "PAIS1R",
    title = transl("more_info", lang),
    image = paste0("https://raw.githubusercontent.com/favstats/digicomp/refs/heads/main/img/", transl("genai_competence_infobox_image", lang)),
    image_width = "50%"
  )

## 7.1 Strategic Information Dimension ----
strategic_visualizations <- (sis_viz_wo_link + kinfo_viz_wo_link + perf_sis_viz_wo_link)  %>%
  set_tabgroup_labels(
    sis = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_skills", lang)),
    kinfo = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_knowledge", lang)),
    perf_sis = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)),
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)),
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3"))
  )

## 7.2 Critical Information Dimension ----
critical_info_visualizations <- (cis_viz_wo_link + critinfo_viz_wo_link + perf_cis_viz_wo_link) %>%
  set_tabgroup_labels(
    cis = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_critical_info_skills", lang)),
    critinfo = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_critical_info_knowledge", lang)),
    perf_cis = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_critical_info_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3"))
  )

## 7.3 Netiquette Dimension ----
netiquette_visualizations <- (nskills_viz_wo_link + knet_viz_wo_link) %>%
  set_tabgroup_labels(
    nskills = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_netiquette_skills", lang)),
    knet = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_netiquette_knowledge", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")), 
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4"))
  )

## 7.4 Digital Content Creation Dimension ----
content_creation_visualizations <- (dccs_viz_wo_link + kcrea_viz_wo_link + perf_dccs_viz_wo_link) %>%
  set_tabgroup_labels(
    dccs = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_content_creation_skills", lang)),
    kcrea = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_content_creation_knowledge", lang)),
    perf_dccs = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_content_creation_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")), 
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4"))
  )

## 7.5 Safety & Control Dimension ----
safety_visualizations <- (safety_viz_wo_link + ksafety_viz_wo_link + perf_safety_viz_wo_link) %>%
  set_tabgroup_labels(
    safety = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_safety_skills", lang)),
    ksafety = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_safety_knowledge", lang)),
    perf_safety = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_safety_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")), 
    item6 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")), 
    item8 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8")), 
    item9 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 9"))
  )

## 7.6 Digital Health & Wellbeing Dimension ----
health_visualizations <- (dhealth_viz_wo_link + khealth_viz_wo_link + perf_health_viz_wo_link) %>%
  set_tabgroup_labels(
    dhealth = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_digital_health_skills", lang)),
    khealth = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_digital_health_knowledge", lang)),
    perf_health = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_digital_health_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")), 
    item6 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")), 
    item7 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7"))
  )

## 7.7 Green / Sustainable Digital Dimension ----
green_visualizations <- (green_viz_wo_link + kgreen_viz_wo_link + perf_green_viz_wo_link) %>%
  set_tabgroup_labels(
    green = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_green_skills", lang)),
    kgreen = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_green_knowledge", lang)),
    perf_green = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_green_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")), 
    item6 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")), 
    item8 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8"))
  )

## 7.8 Digital Problem Solving Dimension ----
problem_solving_visualizations <- (dprob_viz_wo_link + perf_ps_viz_wo_link) %>%
  set_tabgroup_labels(
    dprob = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_problem_solving_skills", lang)),
    perf_ps = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_problem_solving_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")), 
    item6 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")), 
    item8 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8")), 
    item9 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 9"))
  )

## 7.9 Transactional Dimension ----
transactional_visualizations <- (trans_viz_wo_link + ktrans_viz_wo_link + perf_trans_viz_wo_link) %>%
  set_tabgroup_labels(
    trans = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_transactional_skills", lang)),
    ktrans = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_transactional_knowledge", lang)),
    perf_trans = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_transactional_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5"))
  )

## 7.10 AI Dimension ----
ai_visualizations <- (ai_viz_wo_link + kai_viz_wo_link + perf_ai_viz_wo_link) %>%
  set_tabgroup_labels(
    ai = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_ai_skills", lang)),
    kai = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_ai_knowledge", lang)),
    perf_ai = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_ai_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")), 
    item6 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")), 
    item8 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8")), 
    item9 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 9"))
  )

## 7.11 Generative AI Dimension ----
genai_combined_visualizations <- (genai_viz_wo_link + kgai_viz_wo_link + perf_genai_viz_wo_link) %>%
  set_tabgroup_labels(
    genai = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_genai_skills", lang)),
    kgai = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_genai_knowledge", lang)),
    perf_genai = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_genai_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)), 
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)), 
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)), 
    edu = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)), 
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")), 
    item2 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")), 
    item3 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")), 
    item5 = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5"))
  )

strategic_visualizations <- (sis_viz_wo_link + kinfo_viz_wo_link + perf_sis_viz_wo_link)  %>%
  set_tabgroup_labels(
    sis = paste0("{{< iconify ph lightning-fill >}} ", transl("tab_skills", lang)),
    kinfo = paste0("{{< iconify ph book-open-fill >}} ", transl("tab_knowledge", lang)),
    perf_sis = paste0("{{< iconify ph clipboard-text >}} ", transl("tab_performance", lang)),
    wave1 = paste0("{{< iconify ph number-circle-one-fill >}} ", transl("tab_wave1", lang)),
    wave2 = paste0("{{< iconify ph number-circle-two-fill >}} ", transl("tab_wave2", lang)),
    age    = paste0("{{< iconify mdi:human-male-male-child >}} ", transl("tab_age", lang)),
    gender = paste0("{{< iconify mdi gender-transgender >}} ", transl("tab_gender", lang)),
    edu    = paste0("{{< iconify ph graduation-cap-fill >}} ", transl("tab_education", lang)),
    mig = paste0("{{< iconify ph globe-hemisphere-east >}} ", transl("tab_migration", lang)),
    overtime   = paste0("{{< iconify ph chart-line-fill >}} ", transl("tab_overtime", lang)),
    overall = paste0("{{< iconify ph users-fill >}} ", transl("tab_overall", lang)),
    item1  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 1")),
    item2  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 2")),
    item3  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 3")),
    item4  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 4")),
    item5  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 5")),
    item6  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 6")),
    item7  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 7")),
    item8  = paste0("{{< iconify ph chat-circle-fill >}} ", paste0(transl("tab_question", lang), " 8"))
  )


# 8. DASHBOARD CREATION ========================================================

## 8.1 Navigation Menus ----
dimensions_menu <- navbar_menu(
  text = transl("menu_dimensions", lang),
  pages = c(transl("page_name_strategic_info", lang), transl("page_name_critical_info", lang), 
            transl("page_name_netiquette", lang), transl("page_name_content_creation", lang),
            transl("page_name_safety", lang), transl("page_name_digital_health", lang), 
            transl("page_name_green", lang),
            transl("page_name_problem_solving", lang), transl("page_name_transactional", lang),
            transl("page_name_ai", lang), transl("page_name_genai", lang)),
  icon = "ph:books-fill"
)




# transl("landing_page_text", "en") %>% md_text()

## 8.2 Dashboard Pages & Configuration ----
# Create comprehensive dashboard with ALL features
dashboard <- create_dashboard(
  ## Descriptions
  title = "DigIQ Monitor", 
  output_dir = "qmds", 
  publish_dir = "../docs",
  author = "Fabio Votta",
  description = "DigIQ Monitor",
  page_footer = "© 2025 DigIQ Monitor - All Rights Reserved",
  date = "2025-11-20",
  logo = "logo.png",
  ## Themes / Styles
  page_layout = "full",
  theme = "flatly",  # Options: cosmo, flatly, darkly, minty, pulse, etc.
  tabset_theme = "underline",  # This is YOUR style! 
  math = "katex",
  mobile_toc = T,
  search = TRUE,
  code_overflow = "wrap",        # ← From your original
  html_math_method = "mathjax",  # ← From your original
  #### Navbar settings
  navbar_sections = list(dimensions_menu),  # Just pass the menus!
  navbar_style = "dark",
  navbar_brand = "Digital Competence Insights Dashboard",
  navbar_toggle = "collapse",
  navbar_bg_color = "#f0f0f0",
  navbar_text_color = "#3A1B00E6", 
  navbar_text_hover_color = "lightgrey",
  ## pagination settings
  pagination_position = "both",
  pagination_separator = "/", 
  # github = "https://github.com/favstats/dashboardr",
  # linkedin = "https://linkedin.com/in/username",
  # email = "user@example.com",
  # website = "https://www.dedigiq.nl/",
  breadcrumbs = FALSE,
  page_navigation = TRUE,
  back_to_top = TRUE,
  # repo_url = "https://github.com/username/dashboardr",
  self_contained = F,        # ← From your original
  # viewport_width = 1200,
  # viewport_scale = 0.3,
  # toc = "floating",
  # toc_depth = 3,
  code_tools = FALSE,  # ← Add this to explicitly disable the Code button
  code_folding = NULL, # ← Make sure this is NULL or FALSE too
  plausible = "pa-UnPiJwxFi8TS-XAvCdgQx",
  metrics_style = "bootstrap"
) %>%
  # Landing page with icon
  add_page(
    name = transl("dashboard_title", lang),
    text = md_text(
      "<div style='text-align: center;'>",
      transl("landing_page_text", lang),
      "",
      "<br>",
      "<br>",
      "<center><img src='bzk.jpg' width='360'></center>",
      "</div>"
    ),
    icon = "line-md:monitor-mutlple",
    is_landing_page = TRUE
  ) %>%
  # Analysis page with data and visualizations
  add_page(
    overlay = T,
    overlay_duration = 1,
    name = transl("page_name_skills", lang),
    data = digicom_data,
    visualizations = skills_viz,
    icon = "ph:lightning-fill",
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("page_text_skills", lang),
      "",
      transl("intro_text_skills", lang),
      "",
      "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
      paste0("create_blockquote(\"", transl("blockquote_skills", lang), "\", preset = \"question\")"),
      "```"
    )
  ) %>%
  add_page(
    overlay = T,
    overlay_duration = 1,
    name = transl("page_name_performance", lang),
    data = digicom_data,
    visualizations = performance_collection,
    icon = "ph:clipboard-text",
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("page_text_performance", lang)
    )
  ) %>%
  # Analysis page with data and visualizations
  add_page(
    overlay = T,
    overlay_duration = 1,
    name = transl("page_name_knowledge", lang),
    data = digicom_data,
    visualizations = knowledge_collection,
    icon = "ph:book-open-fill",
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("page_text_knowledge", lang),
      "",
      transl("intro_text_knowledge", lang),
      "",
      "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
      paste0("create_blockquote(\"", transl("blockquote_knowledge", lang), "\", preset = \"question\")"),
      "```"
    )
  ) %>%
  # Analysis page with data and visualizations
  add_page(
    name = transl("page_name_highlights", lang),
    data = digicom_data,
    icon = "ph:star-fill",
    # visualizations = genai_viz,
    text = md_text(
      "<div style='text-align: justify;'>",
      paste0("### ", transl("highlights_wave1_title", lang)),
      transl("highlights_intro", lang),
      "",
      transl("key_finding_1", lang),
      "",
      transl("key_finding_2", lang),
      "",
      transl("key_finding_3", lang),
      "</div>"
    )
  )%>%
  # Analysis page with data and visualizations
  add_page(
    name = transl("page_name_strategic_info", lang),
    icon = "ph:magnifying-glass",
    data = digicom_data,
    visualizations = strategic_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("strategic_info_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_critical_info", lang),
    icon = "ph:detective-fill",
    data = digicom_data,
    visualizations = critical_info_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("critical_info_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_netiquette", lang),
    icon = "ph:chats-fill",
    data = digicom_data,
    visualizations = netiquette_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("netiquette_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_content_creation", lang),
    icon = "ph:palette-fill",
    data = digicom_data,
    visualizations = content_creation_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("content_creation_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_safety", lang),
    icon = "ph:shield-check-fill",
    data = digicom_data,
    visualizations = safety_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("safety_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_digital_health", lang),
    icon = "ph:heart-fill",
    data = digicom_data,
    visualizations = health_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("digital_health_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_green", lang),
    icon = "ph:recycle-fill",
    data = digicom_data,
    visualizations = green_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("green_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_problem_solving", lang),
    icon = "ph:lightbulb-fill",
    data = digicom_data,
    visualizations = problem_solving_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("problem_solving_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_transactional", lang),
    icon = "ph:wallet-fill",
    data = digicom_data,
    visualizations = transactional_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("transactional_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_ai", lang),
    icon = "ph:robot-fill",
    data = digicom_data,
    visualizations = ai_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("ai_description", lang)
    )
  ) %>%
  
  add_page(
    name = transl("page_name_genai", lang),
    icon = "ph:magic-wand-fill",
    data = digicom_data,
    visualizations = genai_combined_visualizations,
    text = md_text(
      transl("mockup_warning", lang),
      "",
      transl("genai_description", lang)
    )
  ) %>%
  # Text-only page with icon showcasing card function
  add_page(
    name = transl("page_name_about", lang),
    icon = "ph:info-fill",
    navbar_align = "right",
    text = md_text(
      "<div style='text-align: justify;'>",
      transl("about_page_text", lang),
      "",
      "<br>",
      "<br>",
      "<center><img src='bzk.jpg' width='360'></center>",
      "</div>"
    )
  ) %>%
  add_powered_by_dashboardr(style = "badge", size = "large") %>%
  # Add a "Powered by" link with icon and text
  add_navbar_element(
    text = lang_change(lang),
    icon = "circle-flags:uk",
    # circle-flags:uk
    href = "https://favstats.github.io/digicomp/en",
    align = "right"
  )  

# Test the print methods
cat("=== Dashboard Project Summary ===\n")
print(dashboard)

cat("\n=== Visualization Collection Summary ===\n")
# print(skills_viz)

# cat("\n=== Summary Visualizations ===\n")
# print(summary_vizzes)

files_to_delete <- dir("qmds", pattern = "\\.markdown$", full.names = TRUE)
file.remove(files_to_delete)

files_to_delete <- dir("qmds", pattern = "\\.markdown$", full.names = TRUE)
file.remove(files_to_delete)
# generate_dashboard(dashboard, render = F,  open = "browser")

## 8.3 Generate Dashboard ----
# Generate the dashboard
cat("\n=== Generating Dashboard ===\n")
generate_dashboard(dashboard, render = F, open = "browser")


