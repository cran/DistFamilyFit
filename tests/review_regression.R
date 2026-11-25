if (dir.exists('DistFamilyFit/R')) {
  for (f in list.files('DistFamilyFit/R', full.names = TRUE)) source(f)
} else {
  library(DistFamilyFit)
  for (name in c('.ff_gld_q', '.ff_gld_p', '.ff_q', '.ff_p', '.ff_logd')) assign(name, getFromNamespace(name, 'DistFamilyFit'))
}
expect_error <- function(expr) stopifnot(inherits(tryCatch(force(expr), error = identity), 'error'))
set.seed(2026); x <- sinh(rnorm(60))
# No silent expansion of matrix columns, temporal vectors or corrupt row audits.
expect_error(prepare_fit_data(data.frame(a = I(cbind(x, x + 1)))))
expect_error(fit_univariate(as.POSIXct('2026-01-01') + seq_len(60)))
expect_error(prepare_fit_data(data.frame(a = as.POSIXct('2026-01-01') + seq_len(60))))
expect_error(fit_univariate(x, control = list(fnscale = -1)))
expect_error(fit_univariate(x, control = list(maxit = 0)))
expect_error(fit_univariate(x, control = list(factr = NA_real_)))
expect_error(fit_univariate(x, control = list(foo = 1)))
f <- fit_johnson_univariate(x, types = 'SU', control = list(maxit = 8000, ndeps = 1e-4))
stopifnot(!is.na(f$best))
# Original observation numbers survive two preprocessing steps and positive filtering.
d <- data.frame(a = x, b = exp(x / 2)); d$a[3] <- NA
p <- prepare_fit_data(d, na_action = 'omit')
u <- fit_univariate(prepare_fit_data(p, columns = 'b'))
stopifnot(u$audit$n_input == 60L, u$audit$n_preprocessing_excluded == 1L)
stopifnot(identical(u$audit$retained_rows, setdiff(seq_len(60), 3L)), identical(u$audit$excluded_rows, 3L))
fits <- fit_columns(p, johnson_types = 'SU')
stopifnot(all(vapply(fits, function(f) identical(f$audit$excluded_rows, 3L), logical(1))))
m <- suppressWarnings(fit_johnson_multivariate(p, types = 'SU'))
stopifnot(all(vapply(m$marginals, function(f) identical(f$audit$retained_rows, p$audit$retained_rows), logical(1))))
corrupt <- p; corrupt$audit$retained_rows <- 1:2
expect_error(prepare_fit_data(corrupt))
expect_error(fit_univariate(corrupt))
pos <- suppressWarnings(fit_univariate(prepare_fit_data(p, columns = 'a'), component = 'positive', min_n = 5))
expected <- p$audit$retained_rows[p$data$a > 0]
stopifnot(identical(pos$audit$retained_rows, expected), pos$audit$n_input == 60L)
# Tail checks against mathematical identities, outside the original 1%-99% diagnostic grid.
t <- c(0, 0, -.2, .1)
prob <- c(1e-100, 1e-30, 1e-10, .1, .5, .9)
actual <- .ff_gld_p(.ff_gld_q(prob, t), t)
stopifnot(max(abs(actual / prob - 1)) < 1e-10)
# For a=1000, k=1e-5, scale=1, p=.99, log quantile is near log(1e200).
par <- c(log(1000), log(1e-5), 0)
q <- .ff_q(.99, 'BurrXII', par)
stopifnot(is.finite(q), abs(log(q) - log(1e200)) < 1e-8)
stopifnot(abs(.ff_p(q, 'BurrXII', par) - .99) < 1e-10)
stopifnot(is.finite(.ff_logd(q, 'BurrXII', par)))
# Stable cancellation-free density at an extreme but finite point.
stopifnot(is.finite(.ff_logd(1e300, 'BurrXII', c(log(1000), log(.00001), 0))))
stopifnot(is.na(.ff_gld_p(NA_real_, t)))
q <- .ff_gld_q(1e-300, t)
expected <- -log(1e-300) * (1 - t[3])
stopifnot(is.finite(.ff_logd(q, 'GLD', t)), abs(.ff_logd(q, 'GLD', t) + expected) < 1e-8)
# The string 'NA' is a legitimate header, not a missing column name.
file <- tempfile(fileext = '.csv')
write.table(data.frame(NA_column = x), file, sep = ',', row.names = FALSE, quote = FALSE)
lines <- readLines(file); lines[1] <- 'NA'; writeLines(lines, file)
stopifnot(identical(names(read_fit_data(file)$data), 'NA'))
expect_error(read_fit_data(file, sep = NA_character_))
expect_error(quantile_fit(f, matrix(.5, 1, 1)))
# Graphics options no longer collide with defaults; plotting restores par settings.
pdf(tempfile(fileext = '.pdf'), width = 8, height = 8)
plot_fit(f, 'cdf', main = 'Custom CDF', xlab = 'Measurement', ylab = 'Probability')
plot_fit(f, 'qq', main = 'Custom Q-Q')
plot_fit(f, 'density', main = 'Custom density', breaks = 8)
plot_comparison(f, main = 'Custom comparison')
plot_transformed(m, main = 'Custom pair plot')
plot_transformed(m, 'mahalanobis', main = 'Custom joint diagnosis')
old <- par('mar'); plot_dependence(m); stopifnot(identical(par('mar'), old))
expect_error(plot_fit(f, 'density', freq = TRUE))
invisible(dev.off())
# All Pearson moment targets use the same empirical n-divisor convention.
if (requireNamespace('PearsonDS', quietly = TRUE)) {
  pear <- fit_univariate(x, families = 'Pearson')
  stopifnot(!is.na(pear$best))
  par <- pear$models$Pearson
  y <- (x - par$origin) / par$scale; central <- y - mean(y); m2 <- mean(central^2)
  target <- c(mean(y), m2, mean(central^3) / m2^1.5, mean(central^4) / m2^2)
  actual <- unlist(PearsonDS::pearsonMoments(params = par$theta))
  stopifnot(length(actual) == 4L, max(abs(actual - target)) < 1e-6)
}
cat('Review regressions passed: data, audit, optim controls, graphics and tails.\n')
