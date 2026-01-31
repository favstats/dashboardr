# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

# Fix for testthat failing in R CMD check but working in devtools::test()
# See: https://github.com/r-lib/testthat/issues/144
Sys.setenv(R_TESTS = "")

library(testthat)
library(dashboardr)

test_check("dashboardr")
