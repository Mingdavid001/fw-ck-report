#' Dunnett vs CK on fresh weight (preferred for inference)
#' @param data data.frame with treatment and fresh_weight_g
#' @param ck_level label of control, default "CK"
#' @return rstatix Dunnett result
dunnett_fw <- function(data, ck_level = "CK") {
  stopifnot(all(c("treatment", "fresh_weight_g") %in% names(data)))
  data$treatment <- stats::relevel(factor(data$treatment), ref = ck_level)
  rstatix::dunnett_test(data, fresh_weight_g ~ treatment)
}
