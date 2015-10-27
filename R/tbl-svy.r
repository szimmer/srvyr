#' svy_tbl object.
#'
#' A \code{svy_tbl} wraps a locally stored svydesign and adds methods for
#' dplyr single-table verbs like \code{mutate}, \code{group_by} and
#' \code{summarise}. Create a \code{svy_tbl} using \code{\link{design_survey}}.
#'
#' @section Methods:
#'
#' \code{tbl_df} implements these methods from dplyr.
#'
#' \describe{
#' \item{\code{\link[dplyr]{select}} or \code{\link[dplyr]{rename}}}{
#'   Select or rename variables in a survey's dataset.}
#' \item{\code{\link[dplyr]{mutate}} or \code{\link[dplyr]{transmute}}}{
#'   Modify and create variables in a survey's dataset.}
#' \item{\code{\link{group_by}} and \code{\link{summarise}}}{
#'  Get descriptive statistics from survey.}
#' }
#'
#' @examples
#' library(survey)
#' data(api)
#' svy <- design_survey(apistrat, strata = stype, weights = pw)
#' svy
#'
#' # Data manipulation verbs ---------------------------------------------------
#' filter(svy, pcttest > 95)
#' select(svy, starts_with("acs")) # variables used in survey design are automatically kept
#' summarise(svy, col.grad = survey_mean(col.grad))
#' mutate(svy, api_diff = api00 - api99)
#'
#' # Group by operations -------------------------------------------------------
#' # To calculate survey
#' svy_group <- group_by(svy, dname)
#'
#' summarise(svy, col.grad = survey_mean(col.grad),
#'           api00 = survey_mean(api00, vartype = "ci"))
#' @name tbl_svy
NULL

# Mostly mimics survey:::print.survey.design2
#' @export
print.tbl_svy <- function (x, varnames = TRUE, design.summaries = FALSE, ...) {
  NextMethod()

  print(survey_vars(x))
  if(!is.null(groups(x))) {
    cat("Grouping variables: ")
    cat(paste0(deparse_all(groups(x)), collapse = ", "))
    cat("\n")
  }
  if (design.summaries) {
    cat("Probabilities:\n")
    print(summary(x$prob))
    if (x$has.strata) {
      if (NCOL(x$cluster) > 1)
        cat("First-level ")
      cat("Stratum Sizes: \n")
      oo <- order(unique(x$strata[, 1]))
      a <- rbind(obs = table(x$strata[, 1]),
                 design.PSU = x$fpc$sampsize[!duplicated(x$strata[,1]), 1][oo],
                 actual.PSU = table(x$strata[!duplicated(x$cluster[, 1]), 1]))
      print(a)
    }
    if (!is.null(x$fpc$popsize)) {
      if (x$has.strata) {
        cat("Population stratum sizes (PSUs): \n")
        s <- !duplicated(x$strata[, 1])
        a <- x$fpc$popsize[s, 1]
        names(a) <- x$strata[s, 1]
        a <- a[order(names(a))]
        print(a)
      }
      else {
        cat("Population size (PSUs):", x$fpc$popsize[1, 1], "\n")
      }
    }
  }
  if (varnames) {
    vars <- colnames(x$variables)
    types <- vapply(x$variables, dplyr::type_sum, character(1))

    var_types <- paste0(vars, " (", types, ")", collapse = ", ")
    cat(wrap("Data variables: ", var_types), "\n", sep = "")
    invisible(x)
  }
}

#' List variables produced by a tbl.
#' #' @param x A \code{tbl} object
#' @name tbl_vars
#' @export
#' @importFrom dplyr tbl_vars
NULL


#' @export
tbl_vars.tbl_svy <- function(x) {
  names(x[["variables"]])
}
