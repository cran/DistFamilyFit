if (dir.exists('DistFamilyFit/R')) {
  for (f in list.files('DistFamilyFit/R', full.names = TRUE)) source(f)
} else {
  library(DistFamilyFit)
  for (name in c('.ff_q', '.ff_p', '.ff_logd')) assign(name, getFromNamespace(name, 'DistFamilyFit'))
}
# Independently generated normal transformations, not draws from fitted code.
set.seed(2026)
z <- rnorm(500)
vectors <- list(SU = -2 + 1.5 * sinh((z - .7) / 1.3),
                SL = -3 + exp((z + .4) / 1.1),
                SB = -2 + 5 * plogis((z - .5) / 1.4))
for (type in names(vectors)) {
  f <- fit_johnson_univariate(vectors[[type]], types = type)
  stopifnot(!is.na(f$best), f$ranking$KS < .12)
  x <- vectors[[type]]
  g <- fit_johnson_univariate(1e4 * x + 1e6, types = type)
  stopifnot(!is.na(g$best), abs(f$ranking$KS - g$ranking$KS) < .002)
  stopifnot(max(abs(cdf_fit(f, x) - cdf_fit(g, 1e4 * x + 1e6))) < .005)
}
# Endpoint and missing-value behavior for evaluation functions.
f <- fit_johnson_univariate(vectors$SL, types = 'SL')
stopifnot(identical(cdf_fit(f, c(-Inf, Inf)), c(0, 1)))
stopifnot(all(density_fit(f, c(-Inf, Inf)) == 0), is.na(cdf_fit(f, NA_real_)))
for (model in c('BurrIII', 'BurrXII')) stopifnot(all(.ff_logd(c(-Inf, Inf), model, c(0, 0, 0)) == -Inf))
cat('Johnson recovery, affine scaling and evaluation endpoint checks passed.\n')
