library(DistFamilyFit)

# Execute the shipped vignette script and demo in an existing user session.
# Success AND plotting failures must preserve options, directory and graphics.
check_session_state <- function() {
  plot_file <- tempfile(fileext = '.pdf')
  grDevices::pdf(plot_file, width = 9, height = 8)
  on.exit({ grDevices::dev.off(); unlink(plot_file) }, add = TRUE)
  old_options <- options(width = 93, digits = 5)
  on.exit(options(old_options), add = TRUE)
  graphics::par(mfrow = c(2, 1), mar = c(4.2, 4.3, 2.1, 1.2), las = 1)
  graphics::plot.new()
  snapshot <- function() list(options = options(), wd = getwd(),
                              par = graphics::par(no.readonly = TRUE))
  assert_restored <- function(before) {
    stopifnot(identical(options(), before$options), identical(getwd(), before$wd))
    now <- graphics::par(no.readonly = TRUE)
    stopifnot(isTRUE(all.equal(now, before$par, tolerance = 1e-10)))
  }
  scripts <- c(
    system.file('doc', 'getting-started.R', package = 'DistFamilyFit'),
    system.file('examples', 'demo.R', package = 'DistFamilyFit'))
  stopifnot(all(nzchar(scripts)), all(file.exists(scripts)))
  for (script in scripts) {
    before <- snapshot()
    invisible(capture.output(sys.source(script, envir = new.env(parent = globalenv()))))
    assert_restored(before)
    # Simulate an error after altering actual graphical parameters.
    env <- new.env(parent = globalenv())
    env$plot_fit <- function(...) {
      graphics::par(mar = c(1, 2, 3, 4), las = 2)
      stop('Injected plotting failure for cleanup verification.')
    }
    before <- snapshot()
    result <- NULL
    invisible(capture.output(result <- tryCatch(sys.source(script, envir = env),
                                               error = identity)))
    stopifnot(inherits(result, 'error'),
              grepl('Injected plotting failure', conditionMessage(result)))
    assert_restored(before)
  }
}
check_session_state()
cat('Session options, working directory and graphical parameters restored on success and injected failure.\n')
