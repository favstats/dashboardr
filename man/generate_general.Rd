% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dashboard.R
\name{generate_general}
\alias{generate_general}
\title{Generate a General Summary Bar Chart}
\usage{
generate_general(
  data,
  var1,
  var2,
  thevarlabs,
  thelabel = "<- 1: never     -     7: very often ->"
)
}
\arguments{
\item{data}{A data frame containing the survey data.}

\item{var1}{The starting variable name (unquoted) for the range of variables to be analyzed.
The variables should be selectable using \code{select(data, var1:var2)}.}

\item{var2}{The ending variable name (unquoted) for the range of variables to be analyzed.}

\item{thevarlabs}{A character vector of labels for the variables. The order of these
labels should correspond to the order of the variables selected by \code{var1:var2}.}

\item{thelabel}{A character string for the y-axis label.
Defaults to "<- 1: never     -     7: very often ->".}
}
\value{
A \code{highchart} object representing the generated plot.
}
\description{
This function takes a dataset and a range of variables to create
a bar chart summarizing the means of these variables. It also
includes error bars representing standard errors. The chart is
ordered by the mean values of the variables.
}
\details{
The function performs the following steps:
1. Selects the specified range of variables from the input \code{data}.
2. Removes rows with any missing values in the selected variables.
3. Calculates the mean, standard error (\code{std.error} function is assumed to be defined elsewhere),
and count (n) for each variable.
4. Assigns the provided \code{thevarlabs} to the variables.
5. Reorders the variables (and their labels) based on their mean values in descending order.
6. Stores the order of variable labels in a global variable \code{theorder}.
7. Generates an interactive bar chart using \code{highcharter} where:
- Bars represent the mean values.
- Error bars represent mean +/- standard error.
- Each bar has a distinct color from the \code{thecolors} vector.
- Y-axis is scaled from 1 to 7.
- A caption with the total number of observations (N) and a note about error bars is included.
}
\examples{
# Assuming 'survey_data' is your data frame,
# 'q1' to 'q5' are your variables,
# and 'var_labels' is a vector of corresponding labels:
# generate_general(survey_data, q1, q5, var_labels)

# To use a custom y-axis label:
# generate_general(survey_data, q1, q5, var_labels, "Custom Y-axis Label")

Dependencies: dplyr, tidyr, highcharter, forcats
              (Note: `std.error` function needs to be defined in the environment)
}
