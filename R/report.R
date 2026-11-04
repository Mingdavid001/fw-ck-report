#' Write a one-page HTML report from a CSV (symmetric long or asymmetric wide)
#'
#' @param csv_path path to CSV
#' @param out_html output HTML path
#' @param design "long" (default) or "asymmetric"
#' @param control no-dose control column/level (asymmetric or long CK label)
#' @return path to written HTML (invisible)
render_fw_report <- function(csv_path,
                             out_html = "fw-ck-report.html",
                             design = c("long", "asymmetric"),
                             control = "CK") {
  design <- match.arg(design)
  raw <- readr::read_csv(csv_path, show_col_types = FALSE)

  if (design == "asymmetric") {
    res <- run_asymmetric(raw, control = control)
  } else {
    # long: rep, treatment, fresh_weight_g
    stopifnot(all(c("treatment", "fresh_weight_g") %in% names(raw)))
    ck_mean <- mean(raw$fresh_weight_g[raw$treatment == control], na.rm = TRUE)
    raw$inhibition_pct <- inhibition_pct(raw$fresh_weight_g, ck_mean)
    dun <- dunnett_fw(as.data.frame(raw), ck_level = control)
    res <- list(long = as.data.frame(raw), ck_mean = ck_mean, control = control, dunnett = dun)
  }

  tab <- res$long
  dun_df <- as.data.frame(res$dunnett)

  esc <- function(x) {
    x <- as.character(x)
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    x <- gsub(">", "&gt;", x, fixed = TRUE)
    x
  }

  rows_obs <- apply(tab, 1L, function(r) {
    paste0(
      "<tr>",
      paste0("<td>", esc(r), "</td>", collapse = ""),
      "</tr>"
    )
  })
  rows_dun <- if (nrow(dun_df)) {
    apply(dun_df, 1L, function(r) {
      paste0(
        "<tr>",
        paste0("<td>", esc(r), "</td>", collapse = ""),
        "</tr>"
      )
    })
  } else {
    "<tr><td colspan='8'>(no Dunnett rows)</td></tr>"
  }

  html <- paste0(
    "<!DOCTYPE html>\n<html><head><meta charset='utf-8'/>",
    "<title>fw-ck-report</title>",
    "<style>",
    "body{font-family:system-ui,sans-serif;margin:2rem;}",
    "table{border-collapse:collapse;margin:1rem 0;}",
    "th,td{border:1px solid #ccc;padding:0.35rem 0.6rem;font-size:0.9rem;}",
    "th{background:#f4f4f4;}",
    "code{background:#f0f0f0;padding:0.1rem 0.3rem;}",
    "</style></head><body>\n",
    "<h1>fw-ck-report</h1>\n",
    "<p>Design: <code>", esc(design), "</code> · Control: <code>",
    esc(res$control), "</code> · CK mean FW: <strong>",
    signif(res$ck_mean, 4), "</strong></p>\n",
    "<p>Input: <code>", esc(csv_path), "</code></p>\n",
    "<h2>Observations (inhibition % vs CK)</h2>\n",
    "<table><thead><tr>",
    paste0("<th>", esc(names(tab)), "</th>", collapse = ""),
    "</tr></thead><tbody>\n",
    paste(rows_obs, collapse = "\n"),
    "\n</tbody></table>\n",
    "<h2>Dunnett vs ", esc(res$control), " (on fresh weight)</h2>\n",
    "<table><thead><tr>",
    paste0("<th>", esc(names(dun_df)), "</th>", collapse = ""),
    "</tr></thead><tbody>\n",
    paste(rows_dun, collapse = "\n"),
    "\n</tbody></table>\n",
    "<p><em>Inference uses fresh weight + Dunnett vs control, not uncorrected t-tests on % inhibition.</em></p>\n",
    "</body></html>\n"
  )

  writeLines(html, out_html, useBytes = TRUE)
  message("Wrote ", normalizePath(out_html, winslash = "/", mustWork = FALSE))
  invisible(out_html)
}
