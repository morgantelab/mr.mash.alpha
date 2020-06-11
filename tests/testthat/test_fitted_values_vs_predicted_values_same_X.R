context("Test fitted vs predicted values with the same X")

test_that("mr.mash fitted vs predicted values with same X are equal", {
  ###Set seed
  set.seed(123)
  
  ###Simulate X and Y
  n <- 100
  p <- 10
  
  ###Set residual covariance
  V <- rbind(c(1.0,0.2),
             c(0.2,0.4))
  
  ###Set true effects
  B <- matrix(c(-2, -2,
                5, 5,
                rep(0, (p-2)*2)), byrow=TRUE, ncol=2)
  
  ###Simulate X
  X <- matrix(rnorm(n*p), nrow=n, ncol=p)
  X <- scale(X, center=TRUE, scale=FALSE)
  
  ###Simulate Y from MN(XB, I_n, V) where I_n is an nxn identity
  ###matrix and V is the residual covariance
  Y <- sim_mvr(X, B, V)
  
  ###Specify the mixture weights and covariance matrices for the
  ###mixture-of-normals prior
  grid  <- seq(1, 5)
  S0mix <- compute_cov_canonical(ncol(Y), singletons=TRUE,
                                 hetgrid=c(0, 0.25, 0.5, 0.75, 0.99),
                                 grid, zeromat=TRUE)
  
  w0    <- rep(1/(length(S0mix)), length(S0mix))
  
  ###Estimate residual covariance
  V_est <- cov(Y)
  
  ###Fit the model
  capture.output(
    fit <- mr.mash(X, Y, S0mix, w0, V_est, update_w0=TRUE,
                   update_w0_method="EM", compute_ELBO=TRUE, standardize=TRUE,
                   verbose=FALSE, update_V=FALSE, version="R"))
  capture.output(
    fit_rcpp <- mr.mash(X, Y, S0mix, w0, V_est, update_w0=TRUE,
                        update_w0_method="EM", compute_ELBO=TRUE,
                        standardize=TRUE, verbose=FALSE, update_V=FALSE,
                        version="Rcpp"))
  
  ###Predict values with the same X 
  Yhat      <- predict(fit, X)
  Yhat_rcpp <- predict(fit_rcpp, X)
  
  ###Tests
  expect_equal(fit$fitted, Yhat, tolerance = 1e-10, scale = 1)
  expect_equal(fit_rcpp$fitted, Yhat_rcpp, tolerance = 1e-10, scale = 1)
})