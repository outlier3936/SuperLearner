#' extraTrees SuperLearner wrapper
#'
#' Supports the Extremely Randomized Trees package for SuperLearning, which is
#' a variant of random forest.
#'
#' If Java runs out of memory: java.lang.OutOfMemoryError: Java heap space, then
#' (assuming you have free memory) you can increase the heap size by: options(
#' java.parameters = "-Xmx2g" ) before calling library(extraTrees),
#'
#' @param Y Outcome variable
#' @param X Covariate dataframe
#' @param newX Optional dataframe to predict the outcome
#' @param obsWeights Optional observation-level weights (supported but not tested)
#' @param id Optional id to group observations from the same unit (not used
#'   currently).
#' @param family "gaussian" for regression, "binomial" for binary classification.
#' @param ntree Number of trees (default 500).
#' @param mtry Number of features tested at each node. Default is ncol(x) / 3
#'   for regression and sqrt(ncol(x)) for classification.
#' @param nodesize The size of leaves of the tree. Default is 5 for regression
#'   and 1 for classification.
#' @param numRandomCuts the number of random cuts for each (randomly chosen)
#'   feature (default 1, which corresponds to the official ExtraTrees method).
#'   The higher the number of cuts the higher the chance of a good cut.
#' @param evenCuts if FALSE then cutting thresholds are uniformly sampled
#'   (default). If TRUE then the range is split into even intervals (the number
#'   of intervals is numRandomCuts) and a cut is uniformly sampled from each
#'   interval.
#' @param numThreads the number of CPU threads to use (default is 1).
#' @param quantile if TRUE then quantile regression is performed (default is
#'   FALSE), only for regression data. Then use predict(et, newdata, quantile=k)
#'   to make predictions for k quantile.
#' @param subsetSizes subset size (one integer) or subset sizes (vector of
#'   integers, requires subsetGroups), if supplied every tree is built from a
#'   random subset of size subsetSizes. NULL means no subsetting, i.e. all
#'   samples are used.
#' @param subsetGroups list specifying subset group for each sample: from
#'   samples in group g, each tree will randomly select subsetSizes[g] samples.
#' @param tasks vector of tasks, integers from 1 and up. NULL if no multi-task
#'   learning. (untested)
#' @param probOfTaskCuts probability of performing task cut at a node (default
#'   mtry / ncol(x)). Used only if tasks is specified. (untested)
#' @param numRandomTaskCuts number of times task cut is performed at a node
#'   (default 1). Used only if tasks is specified. (untested)
#' @param verbose Verbosity of model fitting.
#' @param ... Any remaining arguments (not supported though).
#'
#' @seealso \code{\link[extraTrees]{extraTrees}}
#'   \code{\link{predict.SL.extraTrees}}
#'   \code{\link[extraTrees]{predict.extraTrees}}
#'
#' @references
#' Geurts, P., Ernst, D., & Wehenkel, L. (2006). Extremely randomized trees.
#' Machine learning, 63(1), 3-42.
#'
#' Simm, J., de Abril, I. M., & Sugiyama, M. (2014). Tree-based ensemble
#' multi-task learning method for classification and regression. IEICE
#' TRANSACTIONS on Information and Systems, 97(6), 1677-1681.
#'
#' @examples
#'
#' data(Boston, package = "MASS")
#' Y = Boston$medv
#' # Remove outcome from covariate dataframe.
#' X = Boston[, -14]
#'
#' set.seed(1)
#'
#' # Sample rows to speed up example.
#' row_subset = sample(nrow(X), 30)
#'
#' sl = SuperLearner(Y[row_subset], X[row_subset, ], family = gaussian(),
#' cvControl = list(V = 2), SL.library = c("SL.mean", "SL.extraTrees"))
#'
#' print(sl)
#'
#' @export
SL.extraTrees =
  function(Y, X, newX, family, obsWeights, id,
           ntree = 500,
           mtry = if (family$family == "gaussian")
             max(floor(ncol(X) / 3), 1) else floor(sqrt(ncol(X))),
           nodesize = if (family$family == "gaussian") 5 else 1,
           numRandomCuts = 1,
           evenCuts = FALSE,
           numThreads = 1,
           quantile = FALSE,
           subsetSizes = NULL,
           subsetGroups = NULL,
           tasks = NULL,
           probOfTaskCuts = mtry / ncol(X),
           numRandomTaskCuts = 1,
           verbose = FALSE,
           ...) {

  .SL.require("extraTrees")

  # For classification convert Y to a factor.
  if (family$family == "binomial") {
    Y = as.factor(Y)
  }

  # Fit model.
  model =
    extraTrees::extraTrees(X, Y, nodesize = nodesize, mtry = mtry,
                           numRandomCuts = numRandomCuts,
                           evenCuts = evenCuts,
                           numThreads = numThreads,
                           quantile = quantile,
                           weights = obsWeights,
                           subsetSizes = subsetSizes,
                           subsetGroups = subsetGroups,
                           tasks = tasks,
                           probOfTaskCuts = probOfTaskCuts,
                           numRandomTaskCuts = numRandomTaskCuts)

  if (family$family == "binomial") {
    pred = predict(model, newdata = newX, probability = TRUE)[, "1"]
  } else {
    pred = predict(model, newdata = newX)
  }

  fit = list(object = model, family = family$family)
  class(fit) = c("SL.extraTrees")
  out = list(pred = pred, fit = fit)
  return(out)
}

#' extraTrees prediction on new data
#' @param object Model fit object from SuperLearner
#' @param newdata Dataframe
#' @param family Binomial or gaussian
#' @param ... Any remaining arguments (not used).
predict.SL.extraTrees <- function(object, newdata, family, ...) {
  .SL.require("extraTrees")
  if (object$family == "binomial") {
    pred = predict(object$object, newdata = newdata, probability = TRUE)[, "1"]
  } else {
    pred = predict(object$object, newdata = newdata)
  }
  return(pred)
}