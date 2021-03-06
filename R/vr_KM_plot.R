#' Plot Kaplan-Meier Curve for Existing Tidy Survival Object
#'
#' TODO: Currently we choose between survival and cumhazard using the cumhazard argument => use funs = argument to define what to plot
#' Apply the fun argument similar to survival:::plot.survfit 
#' an arbitrary function defining a transformation of the survival curve. 
#' fun=log => axis labeled with log(S) values 
#' fun=sqrt => square root scale. 
#' "S" gives the usual survival curve,
#' "log" is the same as using the log=T option
#' "event" or "F" plots the empirical CDF F(t)= 1-S(t) (f(y) = 1-y),
#' "cumhaz" plots the cumulative hazard function (see details)
#' "cloglog" creates a complimentary log-log survival plot (f(y) = log(-log(y)) along with log scale for the x-axis).
#' The terms "identity" and "surv" are allowed as synonyms for type="S".
#' 
#' 
#' TODO: legend_pos option where: inside vs outside. This determines the ggrob later on


#' @inheritparams survival:::plot.survival
#' @return ggplot object 
#' @export
#'
#' @examples
#' # TODO: Define an example for this function
#' library(survival)
#' library(glue)
#' library(dplyr)
#' library(tidyr)
#' library(ggplot2)
#' 
#' fit <- vr_KM_est(data = adtte, strata = "TRTP")
#'
#' ## Plot survival probability
#' vr_KM_plot(survfit_object = fit)
#' 
#' ## Plot cumulative hazard
#' vr_KM_plot(survfit_object = fit, fun = "cumhaz")


vr_KM_plot <- function( survfit_object = NULL
                       ,y_label = NULL
                       ,x_label = NULL
                       ,x_units = NULL
                       ,time_ticks = NULL
                       ,y_ticks = NULL
                       ,fun = "identity"
                       ,debug = F
                      )
{
  
  if (debug == T) browser()
  
  #### Input validation ####
  if (!inherits(survfit_object, "survfit")) stop("survfit object is not of class `survfit`")
  if (!fun %in% c("identity", "surv", "S", "cumhaz", "log", "event", "cloglog")) stop(paste0(fun, " not part of the possibilities."))

  ### Extended tidy of survfit class ####
  tidy_object <- tidyme.survfit(survfit_object)
  
  ### obtain fun ###
  if (fun %in% c("S", "surv", "identity")) fun <- "surv"

  #### Obtain alternatives for X-axis ####
  if (is.null(x_label)){
    if ("PARAM" %in% names(survfit_object)) x_label = survfit_object$PARAM
    if (!is.null(x_label) && !is.null(x_units)) x_label = paste0(x_label, " (", x_units, ")")
  }
  if (is.null(time_ticks)) time_ticks = pretty(survfit_object$time, 10)
  
  #### Obtain alternatives for Y-axis ####
  if (is.null(y_ticks) && fun == "cumhaz") y_ticks <- pretty(survfit_object$cumhaz, 5)
  if (is.null(y_ticks) && fun == "surv") y_ticks <- pretty(c(0,1), 5)

  if (is.null(y_label) && fun == "cumhaz") y_label <- "Cumulative hazard"
  if (is.null(y_label) && fun == "surv") y_label <- "Survival probability"

  #### Plotit ####
  xscaleFUN <- function(x) sprintf("%.0f", x)
  yscaleFUN <- function(x) sprintf("%.2f", x)
  
  gg <- ggplot2::ggplot(tidy_object, aes(x = time, group = strata)) +
    { if (fun == "cumhaz") {
        ggplot2::geom_step(aes(y = cumhaz, col = strata))
      } else if (fun == "surv") {
        ggplot2::geom_step(aes(y = surv, col = strata))
      }
    } +
    ggsci::scale_color_nejm() + 
    ggsci::scale_fill_nejm() + 
    ggplot2::scale_x_continuous(name = paste0("\n", x_label), breaks = time_ticks, labels = xscaleFUN, limits = c(min(time_ticks), max(time_ticks))) +
    ggplot2::scale_y_continuous(name = paste0(y_label, "\n"), breaks = y_ticks, labels = yscaleFUN, limits = c(min(y_ticks), max(y_ticks))) +
    ggplot2::theme_bw() +
    NULL

  gg$plotfun <- fun
  class(gg) <- append(class(gg), "ggKMsurv")
  
  return(gg)
}