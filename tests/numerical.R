# Run from the project root: Rscript DistFamilyFit/tests/numerical.R
# When R CMD check runs this file, the installed package is used.
if (dir.exists('DistFamilyFit/R')) {
  for (f in list.files('DistFamilyFit/R', full.names = TRUE)) source(f)
} else {
  library(DistFamilyFit)
  for (name in c('.ff_gld_q', '.ff_gld_p', '.ff_p', '.ff_logd', '.ff_q', '.ff_metrics')) {
    assign(name, getFromNamespace(name, 'DistFamilyFit'))
  }
}
expect_error <- function(expr) stopifnot(inherits(tryCatch(force(expr), error = identity), 'error'))
# Independent known distribution identities.
p <- seq(.01, .99, length.out = 99)
t <- c(0, 0, 0, 0)
stopifnot(max(abs(.ff_gld_q(p, t) - qlogis(p))) < 1e-10)
stopifnot(max(abs(.ff_gld_p(qlogis(p), t) - p)) < 1e-10)
stopifnot(max(abs(exp(.ff_logd(qlogis(p), 'GLD', t)) - dlogis(qlogis(p)))) < 1e-8)
stopifnot(max(abs(.ff_p(exp(qnorm(p)), 'JohnsonSL', t) - p)) < 1e-12)
stopifnot(max(abs(.ff_p(qlogis(p), 'JohnsonSU', t) - pnorm(asinh(qlogis(p))))) < 1e-12)
# Burr XII c=k=scale=1 is the unit log-logistic distribution.
y <- c(.01, .5, 1, 2, 100)
stopifnot(max(abs(.ff_p(y, 'BurrXII', rep(0, 3)) - y / (1 + y))) < 1e-12)
stopifnot(max(abs(exp(.ff_logd(y, 'BurrXII', rep(0, 3))) - 1 / (1 + y)^2)) < 1e-12)
stopifnot(max(abs(.ff_p(y, 'BurrIII', rep(0, 3)) - y / (1 + y))) < 1e-12)
for (model in c('JohnsonSU', 'JohnsonSL', 'JohnsonSB', 'BurrIII', 'BurrXII', 'GLD')) {
  theta <- if (startsWith(model, 'Burr')) c(.2, -.1, .3) else c(.1, -.2, .2, .3)
  stopifnot(max(abs(.ff_p(.ff_q(p, model, theta), model, theta) - p)) < 1e-8)
}
# Numerical integration checks normalization of analytic densities.
for (model in c('JohnsonSU', 'JohnsonSL', 'JohnsonSB', 'BurrIII', 'BurrXII')) {
  theta <- if (startsWith(model, 'Burr')) rep(0, 3) else rep(0, 4)
  lower <- if (model == 'JohnsonSU') -Inf else 0
  upper <- if (model == 'JohnsonSB') 1 else Inf
  integral <- integrate(function(x) exp(.ff_logd(x, model, theta)), lower, upper)$value
  stopifnot(abs(integral - 1) < 1e-5)
}
expect_error(fit_univariate(rep(1, 30)))
expect_error(fit_univariate(c(NA, rnorm(30))))
expect_error(fit_multivariate(data.frame(a = 1:30, b = letters[1:30])))
set.seed(99)
x <- rnorm(150, -3, 2)
u <- fit_univariate(x, families = c('Johnson', 'Burr', 'GLD'))
stopifnot(u$audit$n_retained == length(x), length(u$models) >= 2)
stopifnot(all(u$ranking$status[u$ranking$model %in% c('BurrIII', 'BurrXII')] == 'Failed'))
# Verify reported KS against independent ECDF left/right limits.
cdf_values <- cdf_fit(u, sort(x)); n <- length(x)
D <- max(abs(cdf_values - ecdf(x)(sort(x))), abs(cdf_values - (seq_len(n) - 1) / n))
stopifnot(abs(u$ranking$KS[u$ranking$model == u$best] - D) < 1e-12)
# An explicit seed is applied locally and the caller's RNG state is restored.
old <- .Random.seed
us <- fit_univariate(x, families = 'Johnson', max_fit_n = 80, seed = 7)
stopifnot(identical(.Random.seed, old), us$audit$n_estimation == 80)
us_again <- fit_univariate(x, families = 'Johnson', max_fit_n = 80, seed = 7)
stopifnot(identical(us$ranking, us_again$ranking))
# Without a seed no fixed value is imposed: the current RNG stream is used.
stopifnot(is.null(formals(fit_univariate)$seed))
set.seed(1); d1 <- fit_univariate(x, families = 'Johnson', johnson_types = 'SU', max_fit_n = 40)
set.seed(1); d2 <- fit_univariate(x, families = 'Johnson', johnson_types = 'SU', max_fit_n = 40)
set.seed(2); d3 <- fit_univariate(x, families = 'Johnson', johnson_types = 'SU', max_fit_n = 40)
stopifnot(identical(d1$ranking, d2$ranking), !identical(d1$models, d3$models))
old <- .Random.seed
d4 <- fit_univariate(x, families = 'Johnson', johnson_types = 'SU', max_fit_n = 40)
stopifnot(!identical(.Random.seed, old))
# Full-data estimation consumes no random numbers.
old <- .Random.seed
invisible(fit_univariate(x, families = 'Johnson', johnson_types = 'SU'))
stopifnot(identical(.Random.seed, old))
expect_error(fit_univariate(x, max_fit_n = 80, seed = -1))
expect_error(fit_univariate(x, max_fit_n = 80, seed = 'a'))
# Known correlation through independently generated latent normal variables.
z <- rnorm(250); w <- .65 * z + sqrt(1 - .65^2) * rnorm(250)
m <- fit_multivariate(data.frame(a = sinh(z), b = exp(w)))
stopifnot(all(is.finite(m$Z)), is.finite(m$criteria_Z['logLik_Z']))
stopifnot(abs(m$correlation_Z[1, 2] - .65) < .2)
# Dependent duplicate columns must be reported, not silently regularized.
m2 <- suppressWarnings(fit_multivariate(cbind(a = x, b = x)))
stopifnot(is.na(m2$criteria_Z['logLik_Z']))
cat('All numerical and input checks passed.\n')
if (requireNamespace('PearsonDS', quietly = TRUE)) {
  # Symmetric evenly spaced normal quantiles produce a valid moment fit.
  normal_sample <- qnorm((seq_len(300) - .5) / 300)
  pear <- fit_univariate(normal_sample, families = 'Pearson')
  stopifnot(pear$ranking$status == 'OK')
  stopifnot(max(abs(cdf_fit(pear, quantile_fit(pear, p)) - p)) < 1e-7)
  stopifnot(is.na(pear$ranking$AIC))
  cat('PearsonDS branch checks passed.\n')
}
with_missing <- c(NA, x, Inf)
clean <- fit_univariate(with_missing, families = 'Johnson', na_action = 'omit')
stopifnot(clean$audit$n_nonfinite == 2, clean$audit$n_retained == length(x))
positive <- suppressWarnings(fit_univariate(c(rep(0, 5), exp(x)), families = 'Burr', component = 'positive'))
stopifnot(positive$audit$n_conditionally_excluded == 5, positive$audit$n_retained == length(x))
stopifnot(any(positive$ranking$status == 'OK'))
# Plot methods must run in a headless R session.
pdf(file = tempfile(fileext = '.pdf'))
plot(u, type = 'cdf'); plot(u, type = 'density'); plot(u, type = 'qq'); plot(m)
invisible(dev.off())
cat('Audit and plotting checks passed.\n')
