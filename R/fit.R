.ff_opt <- function(fun, starts, control) {
  safe <- function(t) {
    v <- tryCatch(fun(t), error = function(e) Inf)
    if (length(v) != 1L || !is.finite(v)) 1e100 else v
  }
  results <- lapply(starts, function(s) tryCatch(stats::optim(s, safe, method = 'Nelder-Mead', control = .ff_optim_control(control, 'Nelder-Mead', length(s))), error = function(e) NULL))
  good <- vapply(results, function(r) !is.null(r) && r$convergence == 0 && is.finite(r$value) && r$value < 1e99, logical(1))
  if (!any(good)) stop('No converged finite optimization result.')
  results <- results[good]
  values <- vapply(results, function(r) r$value, numeric(1))
  best <- results[[which.min(values)]]
  best$diagnostics <- list(converged_starts = sum(good), attempted_starts = length(starts),
    objective_range = range(values), boundary = FALSE, optimizer = 'Nelder-Mead')
  best
}
.ff_fit_model <- function(x, all_x, model, control) {
  origin <- if (startsWith(model, 'Burr')) 0 else stats::median(x)
  scale <- stats::sd(x)
  y <- (x - origin) / scale; yall <- (all_x - origin) / scale
  xmin <- min(yall); xmax <- max(yall); span <- xmax - xmin
  decode <- identity; k <- 4L; method <- 'MLE'
  if (model == 'Pearson') {
    if (!requireNamespace('PearsonDS', quietly = TRUE)) stop('PearsonDS is not installed; install.packages("PearsonDS").')
    centered <- y - mean(y); m2 <- mean(centered^2)
    t <- PearsonDS::pearsonFitM(mean = mean(y), variance = m2, skewness = mean(centered^3) / m2^1.5, kurtosis = mean(centered^4) / m2^2)
    return(list(model = model, theta = t, origin = origin, scale = scale, k = k, method = 'Moment matching'))
  }
  if (startsWith(model, 'Johnson')) {
    out <- .ff_fit_johnson(y, yall, model, control)
    return(list(model = model, theta = out$theta, origin = origin, scale = scale,
      k = if (model == 'JohnsonSL') 3L else 4L, method = method, diagnostics = out$diagnostics))
  } else if (startsWith(model, 'Burr')) {
    if (any(all_x <= 0)) stop('Burr III/XII require strictly positive observations; no values were removed.')
    k <- 3L
    starts <- list(c(0, 0, log(stats::median(y))), c(log(2), 0, log(stats::median(y))))
  } else if (model == 'GLD') {
    method <- 'Quantile matching'
    p <- c(.01, .05, .1, .25, .5, .75, .9, .95, .99)
    emp <- as.numeric(stats::quantile(y, p, type = 5))
    starts <- list(c(stats::median(y), 0, .1, .1), c(0, 0, 0, 0), c(0, 0, -.1, -.1))
    opt <- .ff_opt(function(t) sum((.ff_gld_q(p, t) - emp)^2), starts, control)
    return(list(model = model, theta = opt$par, origin = origin, scale = scale, k = k, method = method, diagnostics = opt$diagnostics))
  } else stop('Unknown model.')
  opt <- .ff_opt(function(a) -sum(.ff_logd(y, model, decode(a))), starts, control)
  list(model = model, theta = decode(opt$par), origin = origin, scale = scale, k = k, method = method, diagnostics = opt$diagnostics)
}
.ff_metrics <- function(x, fit) {
  n <- length(x); y <- (x - fit$origin) / fit$scale
  cdf_values <- .ff_p(y, fit$model, fit$theta)
  if (any(!is.finite(cdf_values)) || any(cdf_values < 0 | cdf_values > 1)) stop('Invalid fitted CDF.')
  i <- seq_len(n)
  ks <- max(i / n - cdf_values, cdf_values - (i - 1) / n)
  legacy <- max(abs(cdf_values - (i - .5) / n))
  p <- c(.1, .25, .5, .75, .9, .95, .99)
  fq <- .ff_p(as.numeric(stats::quantile(y, p, type = 5)), fit$model, fit$theta)
  tail <- p >= .9
  nll <- if (fit$method == 'MLE') -sum(.ff_logd(y, fit$model, fit$theta) - log(fit$scale)) else NA_real_
  data.frame(model = fit$model, method = fit$method, KS = ks, D_CDF = legacy,
    MatchRate = 100 * (1 - legacy), CDF_quantile_RMSE = sqrt(mean((fq - p)^2)),
    TailError = sqrt(mean((log10(1 - fq[tail] + .Machine$double.eps) - log10(1 - p[tail] + .Machine$double.eps))^2)),
    NLL = nll, AIC = if (is.na(nll)) NA_real_ else 2 * fit$k + 2 * nll,
    status = 'OK', note = '', stringsAsFactors = FALSE)
}
#' Fit and compare continuous univariate distribution families
#' @param x A numeric vector.
#' @param families Johnson by default; subset of Pearson, Johnson, Burr, GLD, or all.
#' @param na_action Either fail or omit; omission is recorded.
#' @param component Either all (default), or positive for an explicitly
#'   conditional fit to positive observations. No zero-inflated model is implied.
#' @param min_n Minimum retained sample size, at least 5.
#' @param max_fit_n Optional estimation subsample size; Inf uses all data.
#' @param seed NULL (default) to subsample with the current RNG stream, or an
#'   integer applied locally for reproducible subsampling; the caller's RNG
#'   state is then restored.
#' @param control List passed to optim. Johnson uses L-BFGS-B; other MLE models use Nelder-Mead.
#' @param johnson_types Any subset of SU, SL and SB.
#' @param ks_warning Descriptive warning threshold; not a significance level.
#' @return A familyfit_univariate object with ranking, models and data audit.
#' @export
fit_univariate <- function(x, families = 'Johnson',
                           na_action = c('fail', 'omit'), component = c('all', 'positive'),
                           min_n = 20L, max_fit_n = Inf, seed = NULL,
                           control = list(maxit = 8000, reltol = 1e-9),
                           johnson_types = c('SU', 'SL', 'SB'), ks_warning = 0.2) {
  input_audit <- NULL
  if (inherits(x, 'familyfit_data')) {
    .ff_validate_prepared(x)
    if (ncol(x$data) != 1L) stop('Univariate analysis requires exactly one column.')
    input_audit <- x$audit; x <- x$data[[1]]
  }
  if (!.ff_numeric_vector(x)) stop('x must be a numeric vector.')
  na_action <- match.arg(na_action); component <- match.arg(component)
  if (identical(families, 'all')) families <- c('Pearson', 'Johnson', 'Burr', 'GLD')
  if (!is.character(johnson_types) || !length(johnson_types) || anyNA(johnson_types) || any(!johnson_types %in% c('SU', 'SL', 'SB'))) stop('johnson_types must select SU, SL and/or SB.')
  if (!is.numeric(ks_warning) || length(ks_warning) != 1L || !is.finite(ks_warning) || ks_warning <= 0 || ks_warning > 1) stop('ks_warning must lie in (0, 1].')
  .ff_validate_control(control)
  if (!is.character(families) || !length(families) || anyNA(families) || any(!families %in% c('Pearson', 'Johnson', 'Burr', 'GLD'))) stop('Unknown or empty families.')
  if (!is.numeric(min_n) || length(min_n) != 1 || !is.finite(min_n) || min_n < 5 || min_n != floor(min_n)) stop('min_n must be an integer >= 5.')
  if (!is.numeric(max_fit_n) || length(max_fit_n) != 1 || is.na(max_fit_n) || max_fit_n < min_n || (is.finite(max_fit_n) && max_fit_n != floor(max_fit_n))) stop('Invalid max_fit_n.')
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1 || !is.finite(seed) || seed < 0 || seed > .Machine$integer.max || seed != floor(seed))) stop('seed must be NULL or a single nonnegative integer.')
  finite <- is.finite(x)
  if (any(!finite) && na_action == 'fail') stop('Missing/non-finite values: use na_action = "omit" explicitly.')
  retained <- finite & (component == 'all' | x > 0)
  values <- sort(x[retained])
  if (length(values) < min_n) stop('Too few retained observations.')
  if (!is.finite(stats::sd(values)) || stats::sd(values) <= 0) stop('Constant or numerically unscalable data.')
  integer_like <- all(abs(values - round(values)) < 1e-8)
  if (integer_like) warning('Integer-valued data: fitted distributions are continuous approximations.', call. = FALSE)
  if (mean(values == 0) >= .1) warning('Many exact zeros: continuous fits do not model a point mass at zero.', call. = FALSE)
  fit_values <- values
  if (length(values) > max_fit_n) {
    if (!is.null(seed)) {
      # A user-supplied seed is applied locally; the caller's RNG state is restored.
      exists_seed <- exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)
      if (exists_seed) old_seed <- get('.Random.seed', envir = .GlobalEnv)
      on.exit(if (exists_seed) assign('.Random.seed', old_seed, envir = .GlobalEnv) else if (exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)) rm('.Random.seed', envir = .GlobalEnv), add = TRUE)
      set.seed(seed)
    }
    # Without a seed the current RNG stream is used, as in base R sampling functions.
    estimation_index <- sort(sample.int(length(values), max_fit_n))
    fit_values <- values[estimation_index]
  }
  keys <- unique(unlist(lapply(families, function(f) switch(f, Pearson = 'Pearson', Johnson = paste0('Johnson', unique(johnson_types)), Burr = c('BurrIII', 'BurrXII'), GLD = 'GLD'))))
  models <- list(); rows <- list()
  for (model in keys) {
    attempt <- tryCatch({
      fit <- .ff_fit_model(fit_values, values, model, control)
      row <- .ff_metrics(values, fit)
      if (fit$method == 'MLE' && !is.finite(row$NLL)) stop('Non-finite evaluation likelihood.')
      checks <- .ff_diagnose(values, fit, ks_warning, metrics = row)
      fit$diagnostics <- utils::modifyList(if (is.null(fit$diagnostics)) list() else fit$diagnostics, checks)
      row$status <- checks$status; row$note <- checks$note
      if (isTRUE(fit$diagnostics$boundary)) row$AIC <- NA_real_
      if (length(fit_values) < length(values)) {
        row$AIC <- NA_real_
        row$note <- paste(row$note, 'AIC omitted: estimation used a subsample.')
      }
      list(fit = fit, row = row)
    }, error = function(e) e)
    if (inherits(attempt, 'error')) {
      rows[[model]] <- data.frame(model = model, method = NA_character_, KS = NA_real_, D_CDF = NA_real_, MatchRate = NA_real_, CDF_quantile_RMSE = NA_real_, TailError = NA_real_, NLL = NA_real_, AIC = NA_real_, status = 'Failed', note = conditionMessage(attempt))
    } else { models[[model]] <- attempt$fit; rows[[model]] <- attempt$row }
  }
  ranking <- do.call(rbind, rows); rownames(ranking) <- NULL
  ranking <- ranking[order(ranking$KS, na.last = TRUE), ]; rownames(ranking) <- NULL
  good <- ranking$model[ranking$status %in% c('OK', 'Warning')]
  structure(list(ranking = ranking, models = models, best = if (length(good)) good[1] else NA_character_,
    status = if (!length(good)) 'No usable candidate' else ranking$status[match(good[1], ranking$model)],
    data = values, settings = list(families = unique(families), johnson_types = unique(johnson_types), ks_warning = ks_warning,
      max_fit_n = max_fit_n, seed = seed), selection = 'Lowest classical KS among numerically usable candidates; not a goodness-of-fit acceptance test.',
    input_audit = input_audit, audit = list(n_input = if (is.null(input_audit)) length(x) else input_audit$n_input,
      n_preprocessing_excluded = if (is.null(input_audit)) 0L else input_audit$n_input - length(x),
      n_nonfinite = sum(!finite), n_conditionally_excluded = sum(finite & !retained), n_retained = length(values),
      n_estimation = length(fit_values), retained_rows = if (is.null(input_audit)) which(retained) else input_audit$retained_rows[retained],
      excluded_rows = if (is.null(input_audit)) which(!retained) else setdiff(seq_len(input_audit$n_input), input_audit$retained_rows[retained]),
      component = component, integer_like = integer_like, zero_share = mean(values == 0))), class = 'familyfit_univariate')
}

.ff_diagnose <- function(x, fit, ks_warning, metrics = NULL) {
  p <- seq(.01, .99, length.out = 99)
  q <- .ff_q(p, fit$model, fit$theta)
  cdf_values <- .ff_p(q, fit$model, fit$theta)
  usable <- all(is.finite(q)) && all(diff(q) > 0) && all(is.finite(cdf_values)) && max(abs(cdf_values - p)) < 1e-5
  notes <- character()
  if (!usable) notes <- c(notes, 'CDF/quantile round-trip or monotonicity check failed; excluded from automatic selection.')
  boundary <- !is.null(fit$diagnostics) && isTRUE(fit$diagnostics$boundary)
  if (boundary) notes <- c(notes, fit$diagnostics$note)
  if (is.null(metrics)) metrics <- .ff_metrics(x, fit)
  if (metrics$KS > ks_warning) notes <- c(notes, 'KS exceeds the descriptive warning threshold; this is not a significance test.')
  if (!is.null(fit$diagnostics) && fit$diagnostics$converged_starts < fit$diagnostics$attempted_starts) notes <- c(notes, 'Some optimization starts did not converge.')
  list(status = if (!usable) 'Unstable' else if (length(notes)) 'Warning' else 'OK',
    note = paste(notes, collapse = ' '), roundtrip_error = if (all(is.finite(cdf_values))) max(abs(cdf_values - p)) else Inf,
    numerically_usable = usable)
}
