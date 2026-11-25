\name{read_fit_data}
\alias{read_fit_data}
\alias{prepare_fit_data}
\title{Read and Validate Rectangular Numeric Data}
\description{Select explicit numeric columns, validate observations and record every omitted row.}
\usage{read_fit_data(file, sep = ",", dec = ".", columns = NULL,
  na_strings = c("", "NA"), na_action = c("fail", "omit"), min_n = 20L)
prepare_fit_data(data, columns = NULL, na_action = c("fail", "omit"),
  convert_numeric = FALSE, min_n = 20L)}
\arguments{\item{file}{Existing UTF-8 CSV or TSV text file with a unique header.}
\item{data}{Numeric vector, matrix, data.frame or familyfit_data object.}
\item{sep}{Single-character separator.}
\item{dec}{Decimal mark, dot or comma; distinct from sep.}
\item{columns}{Distinct existing column names or positive indices. NULL means all columns.}
\item{na_strings}{Strings representing missing values.}
\item{na_action}{Fail or explicitly omit rows with nonfinite selected values.}
\item{min_n}{Minimum retained sample size, at least five.}
\item{convert_numeric}{Explicitly allow safe character-to-numeric conversion in memory.}}
\value{A familyfit_data object containing a numeric data.frame and an audit.}
\details{One row represents one observation. For multivariate analysis all values in a row must correspond to the same observation. ID, category and date columns must be excluded with columns. Matrix-valued data.frame columns and time-valued analysis vectors are rejected. No negative-value, zero or outlier deletion is performed. Omission applies only to selected columns and is complete-case across them.}
\examples{
set.seed(1)
d <- data.frame(id = letters[1:20], value = rnorm(20))
p <- prepare_fit_data(d, columns = "value")
p$audit
path <- system.file("extdata", "input_template.csv", package = "DistFamilyFit")
read_fit_data(path, columns = "variable_1")$audit$n_retained
}
