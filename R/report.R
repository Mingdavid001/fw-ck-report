#' Write a one-page HTML report from a CSV (symmetric long or asymmetric wide)
#'
#' @param csv_path path to CSV
#' @param out_html output HTML path
#' @param design "long" (default) or "asymmetric"
#' @param control no-dose control column/level (asymmetric or long CK label)
#' @param methods_footnote if TRUE, inject ARRIVE-lite Methods sentence +
#'   judgment-receipt checklist into the HTML footer (Card 6)
#' @param arrive_lite alias of methods_footnote
#' @return path to written HTML (invisible)
render_fw_report <- function(csv_path,
                             out_html = "fw-ck-report.html",
                             design = c("long", "asymmetric"),
                             control = "CK",
                             methods_footnote = FALSE,
                             arrive_lite = FALSE) {
  design <- match.arg(design)
  methods_footnote <- isTRUE(methods_footnote) || isTRUE(arrive_lite)
  raw_input <- readr::read_csv(csv_path, show_col_types = FALSE)
  raw <- raw_input

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

  # Summary means for Fig-style panels (tables; asterisks vs CK from Dunnett)
  sum_tab <- NULL
  if (all(c("treatment", "fresh_weight_g") %in% names(tab))) {
    trt <- as.character(tab$treatment)
    fw <- tab$fresh_weight_g
    mu <- tapply(fw, trt, mean, na.rm = TRUE)
    se <- tapply(fw, trt, function(x) {
      x <- x[is.finite(x)]
      if (length(x) < 2L) return(NA_real_)
      stats::sd(x) / sqrt(length(x))
    })
    n <- tapply(fw, trt, function(x) sum(is.finite(x)))
    inhib <- inhibition_pct(as.numeric(mu), res$ck_mean)
    # Map Dunnett p -> asterisks (* / ** / ***); CK row blank
    stars <- setNames(rep("", length(mu)), names(mu))
    if (nrow(dun_df) && "contrast" %in% names(dun_df) && "p.value" %in% names(dun_df)) {
      for (i in seq_len(nrow(dun_df))) {
        ctr <- as.character(dun_df$contrast[[i]])
        # multcomp labels look like "T1 - CK" or "dose_1x - CK"
        left <- trimws(sub("\\s*-\\s*.*$", "", ctr))
        p <- suppressWarnings(as.numeric(dun_df$p.value[[i]]))
        st <- if (!is.finite(p)) {
          ""
        } else if (p < 0.001) {
          "***"
        } else if (p < 0.01) {
          "**"
        } else if (p < 0.05) {
          "*"
        } else {
          "ns"
        }
        if (left %in% names(stars)) stars[[left]] <- st
      }
    }
    sum_tab <- data.frame(
      treatment = names(mu),
      n = as.integer(n[names(mu)]),
      fw_mean = as.numeric(mu),
      fw_se = as.numeric(se[names(mu)]),
      dunnett_vs_ck = as.character(stars[names(mu)]),
      inhibition_pct_mean = as.numeric(inhib[names(mu)]),
      stringsAsFactors = FALSE
    )
  }

  footer_html <- ""
  if (methods_footnote) {
    sentence <- methods_footnote_sentence(tab, control = res$control)
    chk <- arrive_lite_checks(
      long = tab,
      control = res$control,
      raw = raw_input,
      dunnett = dun_df
    )
    if (length(chk$warnings)) {
      for (w in chk$warnings) warning(w, call. = FALSE)
    }
    footer_html <- arrive_lite_footer_html(sentence, chk$checks, esc)
  }

  panel_html <- ""
  if (!is.null(sum_tab)) {
    rows_sum <- apply(sum_tab, 1L, function(r) {
      paste0(
        "<tr>",
        paste0("<td>", esc(r), "</td>", collapse = ""),
        "</tr>"
      )
    })
    panel_html <- paste0(
      "<h2>Fig-style panels (A) fresh weight mean±SE vs CK; ",
      "(B) % inhibition from post-analysis means (descriptive; no second test)</h2>\n",
      "<p>Asterisks mark Dunnett vs ", esc(res$control),
      " on fresh weight (* P&lt;0.05, ** P&lt;0.01, *** P&lt;0.001); ",
      "stars belong to panel A only, not compact letter display. Panel B is descriptive from treatment/",
      esc(res$control), " means after analysis.</p>\n",
      "<table><thead><tr>",
      paste0("<th>", esc(names(sum_tab)), "</th>", collapse = ""),
      "</tr></thead><tbody>\n",
      paste(rows_sum, collapse = "\n"),
      "\n</tbody></table>\n"
    )
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
    "footer{margin-top:2rem;padding-top:0.5rem;color:#222;}",
    "footer .seat{font-size:0.9rem;color:#444;}",
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
    panel_html,
    "<p><em>Inference uses fresh weight + Dunnett vs control, not uncorrected t-tests on % inhibition.</em></p>\n",
    footer_html,
    "</body></html>\n"
  )

  writeLines(html, out_html, useBytes = TRUE)
  message("Wrote ", normalizePath(out_html, winslash = "/", mustWork = FALSE))
  invisible(out_html)
}
