#' Locked Methods sentence (Card 6 / ARRIVE-lite) with n filled from data
#'
#' Exact English copy agreed with 英语工坊 / 仓筛. Prefer Unicode minus/times;
#' callers may substitute ASCII if a Windows code page breaks them.
#'
#' @param long long data.frame with treatment and fresh_weight_g
#' @param control control level name (default "CK")
#' @return character scalar Methods sentence
methods_footnote_sentence <- function(long, control = "CK") {
  stopifnot(is.data.frame(long), "treatment" %in% names(long))
  n_by <- tapply(long$treatment, long$treatment, length)
  n_by <- n_by[!is.na(n_by)]
  if (!length(n_by)) {
    n_txt <- "[n]"
  } else if (length(unique(as.integer(n_by))) == 1L) {
    n_txt <- as.character(as.integer(n_by[[1]]))
  } else {
    parts <- paste0(names(n_by), "=", as.integer(n_by))
    n_txt <- paste0(
      min(as.integer(n_by)), "-", max(as.integer(n_by)),
      " (", paste(parts, collapse = "; "), ")"
    )
  }
  paste0(
    "Fresh weight per pot was compared with the untreated control (",
    control,
    ") using Dunnett's test. ",
    "Percent inhibition was calculated after analysis from treatment and ",
    control,
    " means as (",
    control,
    " mean − treatment mean)/",
    control,
    " mean × 100. ",
    "Pairwise t-tests among treatments were not used. ",
    "n = ", n_txt, " pots per treatment."
  )
}

#' ARRIVE-lite design-transparency checks (plant pot; warn only)
#'
#' Borrowed from ARRIVE transparency items rewritten for pot trials:
#' CK definition, n pots (experimental unit = pot), Dunnett vs CK on fresh
#' weight (not serial t-tests), inhibition as post-hoc means (not per-pot
#' Abbott then ANOVA). Animal items (strain, ethics) are dropped.
#'
#' @param long long data.frame after flatten (treatment, fresh_weight_g, ...)
#' @param control control level
#' @param raw optional raw input (wide or long) for Abbott-as-response heuristics
#' @param dunnett optional Dunnett result (presence documents inference path)
#' @return list(warnings = character, checks = data.frame)
arrive_lite_checks <- function(long,
                               control = "CK",
                               raw = NULL,
                               dunnett = NULL) {
  warns <- character()
  rows <- list()

  add_check <- function(id, ok, detail, severity = "ok") {
    rows[[length(rows) + 1L]] <<- data.frame(
      id = id,
      status = if (isTRUE(ok)) "pass" else severity,
      detail = detail,
      stringsAsFactors = FALSE
    )
    if (!isTRUE(ok) && severity == "warn") {
      warns <<- c(warns, paste0("[", id, "] ", detail))
    }
  }

  # 1. n per treatment; experimental unit = pot; n < 2 -> warn
  if (!"treatment" %in% names(long)) {
    add_check("n_pots", FALSE, "No treatment column; cannot verify n per pot.", "warn")
  } else {
    n_by <- tapply(seq_len(nrow(long)), long$treatment, length)
    bad <- names(n_by)[as.integer(n_by) < 2L]
    if (length(bad)) {
      add_check(
        "n_pots",
        FALSE,
        paste0(
          "Experimental unit = pot; n < 2 for: ",
          paste(bad, collapse = ", "),
          " (n = ", paste(as.integer(n_by[bad]), collapse = ", "), ")."
        ),
        "warn"
      )
    } else {
      add_check(
        "n_pots",
        TRUE,
        paste0(
          "Each treatment has n >= 2 pots (experimental unit = pot). n: ",
          paste(paste0(names(n_by), "=", as.integer(n_by)), collapse = ", "),
          "."
        )
      )
    }
  }

  # 2. Named CK; inference is Dunnett vs CK
  has_ck <- "treatment" %in% names(long) && control %in% as.character(long$treatment)
  has_dun <- !is.null(dunnett) && NROW(dunnett) > 0
  if (!has_ck) {
    add_check(
      "ck_dunnett",
      FALSE,
      paste0("Named control '", control, "' not found in treatment levels."),
      "warn"
    )
  } else if (!has_dun) {
    add_check(
      "ck_dunnett",
      FALSE,
      paste0(
        "Control '", control,
        "' present but Dunnett vs CK contrasts were not produced."
      ),
      "warn"
    )
  } else {
    add_check(
      "ck_dunnett",
      TRUE,
      paste0(
        "Named CK '", control,
        "' present; inference is Dunnett vs CK on fresh weight ",
        "(not uncorrected serial t-tests)."
      )
    )
  }

  # 3. Inhibition from treatment mean vs CK mean after analysis; missing reps
  if (!"fresh_weight_g" %in% names(long)) {
    add_check(
      "inhibition_means",
      FALSE,
      "No fresh_weight_g column; cannot define post-hoc mean inhibition.",
      "warn"
    )
  } else if (!has_ck) {
    add_check(
      "inhibition_means",
      FALSE,
      "Cannot compute CK mean; inhibition formula undefined.",
      "warn"
    )
  } else {
    empty <- FALSE
    if ("treatment" %in% names(long)) {
      empty_groups <- names(which(tapply(
        long$fresh_weight_g,
        long$treatment,
        function(x) all(is.na(x)) || length(x) == 0L
      )))
      if (length(empty_groups)) {
        empty <- TRUE
        add_check(
          "inhibition_means",
          FALSE,
          paste0(
            "Missing reps / empty groups: ",
            paste(empty_groups, collapse = ", "),
            "."
          ),
          "warn"
        )
      }
    }
    if (!empty) {
      add_check(
        "inhibition_means",
        TRUE,
        paste0(
          "Inhibition is defined after analysis from treatment and ",
          control,
          " means: (",
          control,
          " mean - treatment mean)/",
          control,
          " mean x 100."
        )
      )
    }
  }

  # 4. Heuristic: per-pot Abbott/inhibition already used as tested response
  abbott_hit <- FALSE
  detail4 <- paste0(
    "Response for Dunnett is fresh_weight_g; inhibition is computed afterwards ",
    "from means (Piepho: do not ANOVA/test per-plot Abbott)."
  )
  if (!is.null(raw) && is.data.frame(raw)) {
    nms <- tolower(names(raw))
    suspect <- grepl("abbott|inhib", nms) & !grepl("fresh|fw|weight", nms)
    # Ignore inhibition_pct we ourselves attach after reading fresh_weight_g
    has_fw <- any(nms %in% c("fresh_weight_g", "fresh_weight", "fw"))
    if (has_fw) {
      suspect <- suspect & !(nms %in% c("inhibition_pct", "inhib_pct", "inhibition"))
    }
    if (any(suspect)) {
      abbott_hit <- TRUE
      detail4 <- paste0(
        "Input columns look like per-pot Abbott/inhibition already present (",
        paste(names(raw)[suspect], collapse = ", "),
        "). Do not ANOVA/test per-plot Abbott; test fresh weight, then report ",
        "inhibition from means."
      )
    }
  }
  if (!abbott_hit && "fresh_weight_g" %in% names(long) && has_ck) {
    ck_vals <- long$fresh_weight_g[as.character(long$treatment) == control]
    ck_vals <- ck_vals[is.finite(ck_vals)]
    all_fw <- long$fresh_weight_g[is.finite(long$fresh_weight_g)]
    if (length(ck_vals) && mean(ck_vals) < 1e-6 &&
          length(all_fw) && all(all_fw >= -5 & all_fw <= 105)) {
      abbott_hit <- TRUE
      detail4 <- paste0(
        "CK mean of fresh_weight_g is ~0 and values sit in a %-like range: ",
        "input may already be per-pot Abbott/inhibition. ",
        "Test raw fresh weight; compute inhibition afterwards from means."
      )
    }
  }
  add_check("no_perpot_abbott", !abbott_hit, detail4, if (abbott_hit) "warn" else "ok")

  checks <- if (length(rows)) {
    do.call(rbind, rows)
  } else {
    data.frame(id = character(), status = character(), detail = character(),
               stringsAsFactors = FALSE)
  }
  list(warnings = warns, checks = checks)
}

#' HTML footer fragment: Methods sentence + judgment-receipt checklist
#'
#' @param sentence Methods sentence
#' @param checks data.frame from arrive_lite_checks()$checks
#' @param esc HTML escape function
#' @return character HTML
arrive_lite_footer_html <- function(sentence, checks, esc) {
  status_label <- function(s) {
    switch(s, pass = "PASS", warn = "WARN", "INFO")
  }
  check_rows <- character()
  if (NROW(checks)) {
    check_rows <- apply(checks, 1L, function(r) {
      paste0(
        "<tr><td><code>", esc(r[["id"]]), "</code></td>",
        "<td><strong>", esc(status_label(r[["status"]])), "</strong></td>",
        "<td>", esc(r[["detail"]]), "</td></tr>"
      )
    })
  }
  paste0(
    "<hr/>\n",
    "<footer id='arrive-lite'>\n",
    "<h2>Methods footnote (ARRIVE-lite, pot trial)</h2>\n",
    "<p>", esc(sentence), "</p>\n",
    "<p><em>Design transparency (plant pot, not animal ARRIVE): ",
    "CK definition; n pots per treatment (experimental unit = pot); ",
    "fresh weight + Dunnett vs CK (not a series of t-tests); ",
    "inhibition from post-hoc means, not per-pot Abbott then ANOVA.</em></p>\n",
    "<h2>Judgment receipt checklist</h2>\n",
    "<table><thead><tr><th>Check</th><th>Status</th><th>Detail</th></tr></thead><tbody>\n",
    if (length(check_rows)) paste(check_rows, collapse = "\n") else
      "<tr><td colspan='3'>(no checks)</td></tr>",
    "\n</tbody></table>\n",
    "<p class='seat'>Report-ready written judgment (paid seat): inquire via ",
    "<a href='https://github.com/Mingdavid001/fw-ck-report/issues'>GitHub Issues</a> ",
    "with label <code>seat-inquiry</code>. Core analysis stays free; seats buy a ",
    "written call, not running the analysis.</p>\n",
    "</footer>\n"
  )
}
