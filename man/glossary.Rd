\name{DistFamilyFit_glossary}
\alias{DistFamilyFit_glossary}
\alias{DistFamilyFit-glossary}
\title{Abbreviations and diagnostic terminology}
\description{Full names and detailed interpretation of abbreviations, identifiers and result fields used by DistFamilyFit.}
\details{These definitions describe the implemented methods. A computational status or descriptive distance is not statistical model acceptance.}
\section{Abbreviations and identifiers}{
\describe{
\item{SU}{Johnson unbounded form. A Johnson distribution whose support extends over the whole real line. Its normal-scale transformation uses the inverse hyperbolic sine. SU is a family identifier, not a fit-quality score.}
\item{SL}{Johnson lognormal form. A Johnson distribution with a lognormal-type transformation and a finite lower endpoint. The implementation fixes a redundant scale parameter, leaving three identifiable parameters. SL does not mean that the original observations are normally distributed.}
\item{SB}{Johnson bounded form. A Johnson distribution supported between two finite endpoints. Its normal-scale transformation is based on a log ratio of distances to the endpoints. The implemented Johnson labels are SU, SL and SB; SD is not an implemented family label.}
\item{GLD}{Generalized lambda distribution. A flexible continuous distribution specified through its quantile function. In this package it is fitted by matching selected empirical quantiles. Its cumulative probabilities are obtained by numerical inversion; the fitted quantile curve does not guarantee the correct family or accurate extreme tails.}
\item{FKML}{Freimer-Kollia-Mudholkar-Lin. The names identifying the generalized lambda parameterization implemented here. It has location, scale and two shape parameters. This identifies a parameterization, not the estimation method: DistFamilyFit estimates its parameters by quantile matching, not maximum likelihood.}
\item{MLE}{Maximum likelihood estimation. Parameter estimation by maximizing the product of model densities at the observed values, equivalently minimizing negative log-likelihood. Johnson uses profiled, multistart numerical optimization; Burr uses numerical optimization. Convergence does not establish a global optimum. Pearson moment matching and generalized lambda quantile matching are not maximum likelihood estimates.}
\item{CDF}{Cumulative distribution function. For a value x, the cumulative distribution function is the model probability P(X <= x). It ranges from zero to one. cdf_fit() evaluates it on the original measurement scale. A density value is different: a continuous-variable density is not the probability of observing one exact value.}
\item{ECDF}{Empirical cumulative distribution function. The fraction of retained observations less than or equal to x. It is a step function calculated directly from the sample. The classical distance uses its left and right limits; the separately preserved midpoint distance uses sorted plotting positions instead.}
\item{KS}{Kolmogorov-Smirnov. Here, the largest absolute difference between the fitted cumulative distribution function and the empirical cumulative distribution function, accounting for the left and right limits of its steps. Smaller values indicate closer sample fit. The reported distance is not a p-value, and ks_warning is a descriptive threshold rather than a significance level.}
\item{NLL}{Negative log-likelihood. Minus the sum of log model densities for the retained observations, evaluated in original measurement units. Smaller values mean larger likelihood on the same observations and scale. It is reported for maximum-likelihood candidates. Numerical boundary or subsampling caveats still apply to any information criterion derived from it.}
\item{AIC}{Akaike information criterion. A likelihood criterion combining fit and parameter count: AIC = 2*k - 2*logLik, equivalently 2*k + 2*NLL. The univariate implementation omits it for non-likelihood fits, flagged search-boundary solutions and estimation subsampling. Compare only compatible likelihood fits to the same data. A small value does not establish model acceptance.}
\item{BIC}{Bayesian information criterion. A likelihood criterion with an additional sample-size-dependent penalty: BIC = k*log(n) - 2*logLik. In this package BIC_Z is provided only for the conditional normal model on a fixed transformed data set. It excludes marginal estimation, is omitted for ridge regularization, and must not be compared across different transformations or interpreted as full original-scale joint-model evidence.}
\item{RMSE}{Root mean square error. The square root of the average squared discrepancy. The CDF_quantile_RMSE field compares fitted cumulative probabilities at empirical quantiles with their target probabilities. Its seven probabilities are 0.1, 0.25, 0.5, 0.75, 0.9, 0.95 and 0.99. It is measured on the probability scale, not in the original variable units.}
\item{Q-Q}{Quantile-quantile. A plot comparing theoretical model quantiles with ordered observed values. Proximity to the identity line supports descriptive agreement, while endpoint departures may indicate tail mismatch. The multivariate reference plot compares squared Mahalanobis distances with chi-square quantiles and is descriptive rather than a calibrated test.}
\item{L-BFGS-B}{Limited-memory Broyden-Fletcher-Goldfarb-Shanno algorithm with box constraints. A numerical optimizer that uses limited memory and lower/upper parameter bounds. It optimizes the profiled Johnson location/support parameters. Reaching the finite search guards is a warning, not proof of a distribution support endpoint or a global maximum.}
\item{RNG}{Random number generator. The mechanism producing pseudorandom draws. With seed = NULL, optional estimation subsampling uses and advances the current random number generator state. An explicit seed is applied locally and the previous state is restored. A reproducible seed does not remove sampling uncertainty.}
\item{CSV}{Comma-separated values. A rectangular plain-text data format commonly using commas between fields. One header row names the columns. DistFamilyFit requires explicit separator and decimal-mark choices; semicolon-delimited files are handled by setting sep accordingly.}
\item{TSV}{Tab-separated values. A rectangular plain-text format using a tab character between fields. Use sep="\\t" when reading this format. Numeric columns still follow the same observation, missing-value and decimal-mark requirements.}
\item{UTF-8}{8-bit Unicode Transformation Format. The text encoding expected for input files and used for the package source. It represents non-ASCII characters, including the authors names, without replacing them with unrelated characters. It is an encoding name, not a delimiter or a statistical method.}
\item{ID}{Identifier. A row, subject, application or other label used to identify records. An identifier column is not automatically an analysis variable. Select numeric analysis columns explicitly rather than fitting a distribution to numeric-looking identifiers.}
\item{NA}{Not available. The standard R marker for a missing value. Blank input fields and the text NA denote missing values by default. Missing or nonfinite selected observations cause an error unless na_action="omit" is explicitly requested; omission and original row indices are recorded.}
\item{CRAN}{Comprehensive R Archive Network. The repository network used to distribute R and contributed packages. A successful local package check does not imply acceptance by its reviewers. Release and development-version checks also do not replace native operating-system tests.}
\item{MIT}{The MIT License is named after the Massachusetts Institute of Technology. DESCRIPTION records MIT + file LICENSE; LICENSE supplies the copyright year and holders. The license permits use, modification and redistribution, including commercial use, subject to retaining the copyright and permission notices.}
\item{Rd}{R documentation. The source format of the function and package help pages in the man directory. R uses these files to generate help views and the reference manual. These files are maintained directly in this package.}
\item{S3}{R S3 method-dispatch system. The name of the R system used to dispatch print(), summary() and plot() to methods appropriate for the fitted object class. It is a system name, not a distribution family or a fit statistic.}
\item{PDF}{Portable Document Format. The rendered format of the worked vignette and generated reference manual. The editable vignette source is the Sweave file; the rendered document must be rebuilt when that source changes.}
\item{HTML}{HyperText Markup Language. The markup format used for browser-based R help pages. Package checks can validate the generated help in this format as well as the rendered reference manual.}
\item{MATLAB}{Matrix Laboratory. The software name associated with the original implementation and the separately retained midpoint-distance convention. The software name does not denote a distribution or an accuracy measure.}
\item{OK}{Okay; computational checks passed. A result-status label, not a calibrated statistical decision. Warning candidates may also be selected; Unstable and Failed candidates are excluded from automatic selection. Inspect diagnostic notes before interpreting the selected model.}
}
}
\section{Other result fields}{
\code{Z} denotes Johnson-transformed observations. It is a mathematical symbol,
not an acronym. \code{logLik_Z}, \code{AIC_Z} and \code{BIC_Z} are conditional
normal-model quantities on a fixed transformed data set, excluding marginal estimation.

\code{MatchRate} is 100 times one minus the midpoint distance evaluated at
plotting positions (i - 0.5)/n; it is not accuracy, a probability or a p-value.
\code{TailError} is the root mean square difference of base-10 logarithms of
fitted and target survival probabilities at 0.9, 0.95 and 0.99, with a machine-
precision offset before taking logarithms. It is not a tail confidence bound.

Burr III and XII denote types three and twelve. \pkg{PearsonDS} is an optional
software package name, not a statistical quantity. TRUE, FALSE, NULL and Inf
are R constants or special values.}
\seealso{\code{\link{fit_univariate}}, \code{\link{fit_multivariate}}, \code{\link{plot_fit}}}
