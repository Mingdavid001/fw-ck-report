#' Dunnett vs CK on fresh weight (preferred for inference)
#'
#' Uses multcomp Dunnett contrasts (rstatix has no dunnett_test export
#' in current CRAN builds used here).
#'
#' @param data data.frame with treatment and fresh_weight_g
#' @param ck_level label of control, default "CK"
#' @return data.frame of Dunnett contrasts vs control
dunnett_fw <- function(data, ck_level = "CK") {
  stopifnot(all(c("treatment", "fresh_weight_g") %in% names(data)))
  if (!requireNamespace("multcomp", quietly = TRUE)) {
    stop("Package 'multcomp' is required for dunnett_fw().", call. = FALSE)
  }
  data <- as.data.frame(data)
  data$treatment <- stats::relevel(factor(data$treatment), ref = ck_level)
  fit <- stats::aov(fresh_weight_g ~ treatment, data = data)
  dun <- multcomp::glht(fit, linfct = multcomp::mcp(treatment = "Dunnett"))
  s <- summary(dun)
  ct <- s$test
  data.frame(
    contrast = names(ct$coefficients),
    estimate = as.numeric(ct$coefficients),
    statistic = as.numeric(ct$tstat),
    p.value = as.numeric(ct$pvalues),
    method = "Dunnett",
    stringsAsFactors = FALSE
  )
}
