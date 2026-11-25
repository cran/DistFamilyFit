\name{fit_univariate}
\alias{fit_univariate}
\title{Fit and Compare Continuous Distribution Families}
\description{Fit and rank Pearson, Johnson, Burr and Freimer-Kollia-Mudholkar-Lin (FKML) generalized lambda
candidates for one numeric variable.}
\usage{fit_univariate(x, families = "Johnson",
  na_action = c("fail", "omit"), component = c("all", "positive"),
  min_n = 20L, max_fit_n = Inf, seed = NULL,
  control = list(maxit = 8000, reltol = 1e-9),
  johnson_types = c("SU", "SL", "SB"), ks_warning = 0.2)}
\arguments{
\item{x}{Numeric vector or one-column prepared dataset.}
\item{families}{Nonempty selection of \code{"Pearson"}, \code{"Johnson"},
  \code{"Burr"} and \code{"GLD"}, or \code{"all"}. Johnson is the default.}
\item{na_action}{Fail or explicitly omit nonfinite values.}
\item{component}{All data, or a conditional fit to the positive observations.}
\item{min_n}{Minimum retained sample size, at least five.}
\item{max_fit_n}{Maximum estimation sample size. When the retained sample is
  larger, parameters are estimated on a random subsample of this size; all
  retained observations are still used for evaluation. \code{Inf} (default)
  uses all observations and involves no random numbers.}
\item{seed}{Only used when \code{max_fit_n} triggers subsampling. \code{NULL}
  (default) draws the subsample from the current random number stream, so
  results follow \code{\link{set.seed}} called beforehand. A nonnegative
  integer is applied locally for a reproducible subsample, after which the
  caller's random number state is restored.}
\item{control}{Named control options: maxit, reltol, factr, pgtol, trace,
  REPORT, ndeps, alpha, beta, gamma. Solver-specific options are filtered;
  ndeps is a positive scalar. Objective direction and scaling cannot be
  overridden. Johnson uses profile likelihood and the limited-memory Broyden-Fletcher-Goldfarb-Shanno algorithm with box constraints (L-BFGS-B).}
\item{johnson_types}{Subset of unbounded (SU), lognormal (SL) and bounded (SB) Johnson forms.}
\item{ks_warning}{Descriptive warning threshold, not a significance level.}}
\value{A \code{familyfit_univariate} object containing the ranking table,
fitted models, best candidate, retained data, settings and data audit.}
\details{
Pearson curves are fitted by matching the first four empirical moments with
\pkg{PearsonDS} (Pearson, 1895). Johnson unbounded (SU), lognormal (SL) and bounded (SB) forms (Johnson, 1949) are fitted
by maximum likelihood with the normal-scale mean and variance profiled out
analytically. Burr Type III and Type XII (Burr, 1942; Tadikamalla, 1980) are
fitted by numerical maximum likelihood and require strictly positive data. The
generalized lambda distribution (Ramberg and Schmeiser, 1974) uses the FKML
parameterization (Freimer et al., 1988; Chalabi et al., 2012) and is fitted by
matching empirical quantiles; its CDF is evaluated by numerical inversion of
the quantile function.

These are continuous models. Discrete data and point masses are not modeled.
\code{KS} is the classical ECDF distance and \code{D_CDF} is the
plotting-position distance \eqn{\max_i |F(x_{(i)}) - (i - 0.5)/n|}.
\code{MatchRate} is \eqn{100 (1 - D_{CDF})}, not a probability or p-value.
Original-row audit identifiers survive preprocessing;
\code{n_preprocessing_excluded} counts previous omissions. Pearson moment
targets use the empirical divisor-n convention. SL has three identifiable
parameters. Pearson and GLD do not receive AIC, and AIC is omitted when
estimation uses a subsample. Status OK denotes computational diagnostics,
not statistical acceptance. Warning candidates may be selected; Unstable and
Failed candidates are excluded. Numerical Johnson search bounds on
standardized log scales are [-12, 12]; reaching them is reported.
}
\references{
Karakaya Demir, Ş. Ş., Purutçuoğlu, V. and Bursalı, A. (2026). Modeling Mobile
Application Usage with Distribution Families. Accepted at the 3rd
International Conference on Advanced Technology in Electronic and Electrical
Engineering (ICATEEE 2026), Hammamet, Tunisia.

Pearson, K. (1895) \doi{10.1098/rsta.1895.0010}.
Johnson, N. L. (1949) \doi{10.1093/biomet/36.1-2.149}.
Burr, I. W. (1942) \doi{10.1214/aoms/1177731607}.
Tadikamalla, P. R. (1980) \doi{10.2307/1402945}.
Ramberg, J. S. and Schmeiser, B. W. (1974) \doi{10.1145/360827.360840}.
Freimer, M., Kollia, G., Mudholkar, G. S. and Lin, C. T. (1988)
\doi{10.1080/03610928808829820}.
Chalabi, Y., Scott, D. J. and Wuertz, D. (2012) MPRA Paper No. 43333.
See \code{\link{DistFamilyFit-package}} for full citations.
}
\seealso{\code{\link{fit_johnson_univariate}}, \code{\link{cdf_fit}},
\code{\link{plot_fit}}}
\examples{
set.seed(1)
f <- fit_univariate(rnorm(80), families = "Johnson")
print(f)

# Estimation on a subsample: reproducible either through set.seed() or seed.
x <- sinh(rnorm(300))
a <- fit_univariate(x, johnson_types = "SU", max_fit_n = 100, seed = 42)
b <- fit_univariate(x, johnson_types = "SU", max_fit_n = 100, seed = 42)
identical(a$ranking, b$ranking)
}
