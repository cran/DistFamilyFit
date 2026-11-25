# Internal distribution functions. Fit parameters use standardized data.
.ff_softplus <- function(x) pmax(x, 0) + log1p(exp(-abs(x)))
.ff_logexpm1 <- function(x) x + log(-expm1(-x))
.ff_logaddexp <- function(a, b) {
  m <- pmax(a, b)
  out <- m + log(exp(a - m) + exp(b - m))
  infinite <- is.infinite(m)
  out[infinite] <- m[infinite]
  out
}
.ff_gld_q <- function(u, t) {
  term <- function(v, a) if (a == 0) log(v) else expm1(a * log(v)) / a
  t[1] + (term(u, t[3]) - term(1 - u, t[4])) / exp(t[2])
}
.ff_gld_p <- function(x, t) {
  # Vectorized bisection avoids linear interpolation/extrapolation in the tails.
  if (anyNA(x)) {
    out <- rep(NA_real_, length(x)); ok <- !is.na(x)
    out[ok] <- .ff_gld_p(x[ok], t); return(out)
  }
  lo <- rep(0, length(x)); hi <- rep(1, length(x))
  lower <- .ff_gld_q(0, t); upper <- .ff_gld_q(1, t)
  active <- which(is.finite(x) & x > lower & x < upper)
  # Relative tail accuracy; central values finish quickly, only tail points remain.
  # 1075 bisections cover the binary64 subnormal probability range.
  for (i in seq_len(1075)) {
    if (!length(active)) break
    mid <- lo[active] + (hi[active] - lo[active]) / 2
    stalled <- mid == lo[active] | mid == hi[active]
    smaller <- .ff_gld_q(mid, t) < x[active]
    lo[active[smaller]] <- mid[smaller]; hi[active[!smaller]] <- mid[!smaller]
    done <- stalled | (hi[active] - lo[active] <= 8 * .Machine$double.eps * pmin(mid, 1 - mid))
    active <- active[!done]
  }
  ans <- lo + (hi - lo) / 2
  ans[x <= lower] <- 0
  ans[x >= upper] <- 1
  ans[is.na(x)] <- NA_real_
  ans
}
.ff_z_jac <- function(x, model, t) {
  g <- t[1]; d <- exp(t[2]); xi <- t[3]; lam <- exp(t[4])
  z <- rep(NA_real_, length(x)); jac <- rep(-Inf, length(x))
  if (model == 'JohnsonSU') {
    v <- (x - xi) / lam
    z <- g + d * asinh(v)
    jac <- log(d) - log(lam) - .ff_softplus(2 * log(abs(v))) / 2
  } else if (model == 'JohnsonSL') {
    ok <- !is.na(x) & x > xi
    z[ok] <- g + d * log((x[ok] - xi) / lam)
    jac[ok] <- log(d) - log(x[ok] - xi)
    z[!is.na(x) & x <= xi] <- -Inf
  } else if (model == 'JohnsonSB') {
    ok <- !is.na(x) & x > xi & x < xi + lam
    z[ok] <- g + d * (log(x[ok] - xi) - log(xi + lam - x[ok]))
    jac[ok] <- log(d) + log(lam) - log(x[ok] - xi) - log(xi + lam - x[ok])
    z[!is.na(x) & x <= xi] <- -Inf
    z[!is.na(x) & x >= xi + lam] <- Inf
  }
  list(z = z, log_jacobian = jac)
}
.ff_p <- function(x, model, t) {
  if (startsWith(model, 'Johnson')) return(stats::pnorm(.ff_z_jac(x, model, t)$z))
  if (model == 'Pearson') return(PearsonDS::ppearson(x, params = t))
  if (model == 'GLD') return(.ff_gld_p(x, t))
  ans <- rep(0, length(x)); ok <- !is.na(x) & x > 0
  a <- exp(t[1]); k <- exp(t[2]); lam <- exp(t[3])
  v <- log(x[ok]) - t[3]
  ans[ok] <- if (model == 'BurrXII') -expm1(-k * .ff_softplus(a * v)) else exp(-k * .ff_softplus(-a * v))
  ans[is.na(x)] <- NA_real_
  ans
}
.ff_logd <- function(x, model, t) {
  if (startsWith(model, 'Johnson')) {
    r <- .ff_z_jac(x, model, t)
    return(stats::dnorm(r$z, log = TRUE) + r$log_jacobian)
  }
  if (model == 'Pearson') return(PearsonDS::dpearson(x, params = t, log = TRUE))
  if (model == 'GLD') {
    u <- .ff_gld_p(x, t)
    out <- t[2] - .ff_logaddexp((t[3] - 1) * log(u), (t[4] - 1) * log1p(-u))
    out[u <= 0 | u >= 1] <- -Inf
    return(out)
  }
  ans <- rep(-Inf, length(x)); ok <- !is.na(x) & x > 0
  a <- exp(t[1]); k <- exp(t[2]); lam <- exp(t[3]); v <- log(x[ok]) - t[3]
  w <- if (model == 'BurrXII') a * v else -a * v
  ans[ok] <- t[1] + t[2] - log(x[ok]) - k * .ff_softplus(w) - .ff_softplus(-w)
  ans[is.infinite(x)] <- -Inf
  ans[is.na(x)] <- NA_real_
  ans
}
.ff_q <- function(p, model, t) {
  if (model == 'Pearson') return(PearsonDS::qpearson(p, params = t))
  if (model == 'GLD') return(.ff_gld_q(p, t))
  if (startsWith(model, 'Johnson')) {
    z <- (stats::qnorm(p) - t[1]) / exp(t[2]); lam <- exp(t[4])
    return(t[3] + lam * switch(model, JohnsonSU = sinh(z), JohnsonSL = exp(z), JohnsonSB = stats::plogis(z)))
  }
  a <- exp(t[1]); k <- exp(t[2]); lam <- exp(t[3])
  if (model == 'BurrXII') exp(t[3] + .ff_logexpm1(-log1p(-p) / k) / a) else exp(t[3] - .ff_logexpm1(-log(p) / k) / a)
}
