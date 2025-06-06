% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dashboard.R
\name{by_pol2}
\alias{by_pol2}
\title{Generate Bar Chart of Means for Three Specific Variables by Political Category}
\usage{
by_pol2(
  data,
  var1,
  var2,
  var3,
  thevarlabs,
  thelabel = "<- 1: never     -     7: very often ->"
)
}
\arguments{
\item{data}{A data frame. Must include \code{pol_cat} and \code{var1}, \code{var2}, \code{var3}.}

\item{var1}{The first variable name (unquoted).}

\item{var2}{The second variable name (unquoted).}

\item{var3}{The third variable name (unquoted).}

\item{thevarlabs}{A character vector of three labels for \code{var1}, \code{var2}, \code{var3}.}

\item{thelabel}{A character string for the y-axis label.
Defaults to "<- 1: never     -     7: very often ->".}
}
\value{
A \code{highchart} object.
}
\description{
Similar to \code{by_pol}, but for three explicitly named variables
(\code{var1}, \code{var2}, \code{var3}). Creates a grouped bar chart of means by
political category (\code{pol_cat}), with error bars.
}
\details{
Steps:
1. Maps \code{var1}, \code{var2}, \code{var3} to \code{thevarlabs}.
2. Converts \code{pol_cat} to labels. Selects vars, \code{pol_cat}, removes NAs.
3. Calculates mean, SE, N for each of the three vars, grouped by \code{pol_cat}.
4. Joins labels, orders vars by global \code{theorder}, relevels \code{pol_cat}.
5. Generates \code{highcharter} grouped column chart (means per political category) with error bars.
Y-axis 1-7. Legend for political categories. Caption with N and \code{pol_cat} definition.
}
\examples{
# `theorder` should exist.
# by_pol2(survey_data, q1, q2, q3, c("LQ1", "LQ2", "LQ3"))

Dependencies: dplyr, tidyr, highcharter, forcats, sjmisc
              (Note: `std.error` defined elsewhere; `theorder` global variable)
}
