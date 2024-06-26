context("Test computation of the rank of the variables according to logBF")

test_that("R and Rcpp version of compute_rank_variables_BFmix return the same results", {
  ###Set seed
  set.seed(123)
  
  ###Simulate X and Y
  n  <- 100
  p <- 10
  
  ###Set residual covariance
  V  <- rbind(c(1.0,0.2),
              c(0.2,0.4))
  
  ###Set true effects
  B  <- matrix(c(-2, -2,
                 5, 5,
                 rep(0, (p-2)*2)), byrow=TRUE, ncol=2)
  
  ###Simulate X
  X <- matrix(rnorm(n*p), nrow=n, ncol=p)
  X <- scale(X, center=TRUE, scale=FALSE)
  
  ###Simulate Y from MN(XB, I_n, V) where I_n is an nxn identity matrix and V is the residual covariance
  Y <- sim_mvr(X, B, V)
  
  ###Specify the mixture weights and covariance matrices for the mixture-of-normals prior
  grid <- seq(1, 5)
  S0mix <- compute_cov_canonical(ncol(Y), singletons=TRUE, hetgrid=c(0, 0.25, 0.5, 0.75, 0.99), grid, zeromat=TRUE)
  S0mix <- lapply(S0mix, makePD, e=1e-8)
  
  w0    <- rep(1/(length(S0mix)), length(S0mix))
  
  ###Compute the inverse of V
  Vinv <- solve(V)
  
  ###Compute quantities needed for rss version
  XtY <- crossprod(X, scale(Y, center=TRUE, scale=FALSE))
  
  ###Set eps
  eps <- .Machine$double.eps
  
  ###Compute logbf with standardize=TRUE
  comps_r <- precompute_quants(n, V, S0mix, standardize=TRUE, version="R")
  ranks_r <- compute_rank_variables_BFmix(X, Y, V, Vinv, w0, S0mix, comps_r, standardize=TRUE, version="R", decreasing=TRUE, eps)
  
  comps_rcpp <- precompute_quants(n, V, S0mix, standardize=TRUE, version="Rcpp")
  ranks_rcpp <- compute_rank_variables_BFmix(X, Y, V, Vinv, w0, S0mix, comps_rcpp, standardize=TRUE, version="Rcpp", decreasing=TRUE, eps, nthreads=1)

  ranks_rss_r <- compute_rank_variables_BFmix_rss(n, XtY, V, Vinv, w0, S0mix, comps_r, standardize=TRUE, version="R", decreasing=TRUE, eps)
  
  ranks_rss_rcpp <- compute_rank_variables_BFmix_rss(n, XtY, V, Vinv, w0, S0mix, comps_rcpp, standardize=TRUE, version="Rcpp", decreasing=TRUE, eps, nthreads=1)
  
    
  ###Compute logbf with standardize=FALSE
  comps1_r <- precompute_quants(n, V, S0mix, standardize=FALSE, version="R")
  comps1_r$xtx <- colSums(X^2)
  ranks1_r <- compute_rank_variables_BFmix(X, Y, V, Vinv, w0, S0mix, comps1_r, standardize=FALSE, version="R", decreasing=TRUE, eps)
  
  comps1_rcpp <- precompute_quants(n, V, S0mix, standardize=FALSE, version="Rcpp")
  comps1_rcpp$xtx <- colSums(X^2)
  ranks1_rcpp <- compute_rank_variables_BFmix(X, Y, V, Vinv, w0, S0mix, comps1_rcpp, standardize=FALSE, version="Rcpp", decreasing=TRUE, eps, nthreads=1)
 
  ranks1_rss_r <- compute_rank_variables_BFmix_rss(n, XtY, V, Vinv, w0, S0mix, comps1_r, standardize=FALSE, version="R", decreasing=TRUE, eps)
  
  ranks1_rss_rcpp <- compute_rank_variables_BFmix_rss(n, XtY, V, Vinv, w0, S0mix, comps1_rcpp, standardize=FALSE, version="Rcpp", decreasing=TRUE, eps, nthreads=1)
  
   
  ###Tests
  expect_equal(ranks_r, ranks_rcpp, tolerance = 1e-10, scale = 1)
  expect_equal(ranks1_r, ranks1_rcpp, tolerance = 1e-10, scale = 1)
  expect_equal(ranks_rss_r, ranks_rss_rcpp, tolerance = 1e-10, scale = 1)
  expect_equal(ranks1_rss_r, ranks1_rss_rcpp, tolerance = 1e-10, scale = 1)
  expect_equal(ranks_rss_rcpp, ranks_rcpp, tolerance = 1e-10, scale = 1)
  expect_equal(ranks1_rss_rcpp, ranks1_rcpp, tolerance = 1e-10, scale = 1)
  
})