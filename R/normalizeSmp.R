#' Normalize Samples
#'
#' Calculate sample concentration based on the fit of standard dilutions.
#'
#' @details
#'
#' @param dfout   data frame containing samples
#' @param pdate   date of the processing
#' @param FUNinv  inverse function to infer sample concentration
#' @param par     values of model function parameters
#' @param bounds  named vector with values for extrema and bounds indicating
#'   "flat" regions of the curve
#' @param fitflag flag for the fit as returned by \code{fitStd}
#' @inheritParams processLum
#'
#' @return a data frame
#'
#' @export

normalizeSmp <- function(dfout, antigen, fname, pdate, yvar, FUNinv, par,
                         bounds, fitflag, trim.flat = TRUE) {
  smps             <- dfout
  smps$Conc        <- NA
  smps$trimmed     <- FALSE                 # for convenience (redundant)
  smps$antigen     <- antigen
  smps$file_name   <- fname
  smps$flagged_run <- fitflag
  smps$date_plate  <- pdate
  smps$min         <- bounds["mindet"]
  smps$max         <- bounds["maxdet"]
  smps$lower_bound <- bounds["lowerbound"]  # if NA, good - no flat portion
  smps$upper_bound <- bounds["upperbound"]
  smps$Flag        <- ""
  if (is.null(par)) {
    smps$trim_lo <- smps$trim_up <- NA
    return(smps)
  }

  imin  <- smps[, yvar] < bounds["mindet"]
  imax  <- smps[, yvar] > bounds["maxdet"]
  ilobd <- smps[, yvar] < bounds["lowerbound"]
  iupbd <- smps[, yvar] > bounds["upperbound"]
  smps$Flag[ilobd] <- "below_lower_bound"
  smps$Flag[iupbd] <- "above_upper_bound"           # NA's OK
  smps$Flag[imin]  <- "below_min"                   # overwrites
  smps$Flag[imax]  <- "above_max"                   # overwrites

  if (trim.flat && !is.na(bounds["lowerbound"])) {
    ilo <- ilobd
    smps$trim_lo <- bounds["lowerbound"]
  } else {
    ilo <- imin
    smps$trim_lo <- bounds["mindet"]
  }
  if (trim.flat && !is.na(bounds["upperbound"])) {
    iup <- iupbd
    smps$trim_up <- bounds["upperbound"]
  } else {
    iup <- imax
    smps$trim_up <- bounds["maxdet"]
  }
  imid <- which(!(ilo | iup))  # get rid of NA's
  ilo  <- which(ilo)
  iup  <- which(iup)
  smps$Conc[ilo]  <- exp(FUNinv(smps$trim_lo[1],  par))*smps$Dilution[ilo]
  smps$Conc[iup]  <- exp(FUNinv(smps$trim_up[1],  par))*smps$Dilution[iup]
  smps$Conc[imid] <- exp(FUNinv(smps[imid, yvar], par))*smps$Dilution[imid]
  smps$trimmed[c(ilo, iup)] <- TRUE
  return(smps)
}
