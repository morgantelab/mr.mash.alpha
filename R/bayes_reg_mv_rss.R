# Bayesian multivariate regression with mixture-of-normals prior
# (mixture weights w0 and covariance matrices S0) with standardized X.
#
# The outputs are: the log-Bayes factor (logbf), the posterior assignment probabilities
# (w1), the posterior mean of the coefficients given that all the
# coefficients are not nonzero (mu1), and the posterior covariance of
# the coefficients given that all the coefficients are not zero (S1).
bayes_mvr_mix_standardized_X_rss <- function (n, xtY, w0, S0, S, S1, SplusS0_chol, S_chol, eps) {
  
  
  # Get the number of conditions (r), the number of mixture
  # components (K).
  r <- length(xtY)
  K <- length(S0)
  
  # Compute the least-squares estimate.
  b <- xtY/(n-1)
  
  # Compute the Bayes factors and posterior statistics separately for
  # each mixture component.
  bayes_mvr_ridge_lapply <- function(i){
    bayes_mvr_ridge_standardized_X(b, S0[[i]], S, S1[[i]], SplusS0_chol[[i]], S_chol)
  }
  out <- lapply(1:K, bayes_mvr_ridge_lapply)
  
  # Compute the posterior assignment probabilities for the latent
  # indicator variable.
  logbf <- sapply(out,function (x) x$logbf)
  w1    <- softmax(logbf + log(w0 + eps))
  
  # Compute the posterior mean (mu1_mix) and covariance (S1_mix) of the
  # regression coefficients.
  A   <- matrix(0,r,r)
  mu1_mix <- rep(0,r)
  for (k in 1:K) {
    wk  <- w1[k]
    muk <- out[[k]]$mu1
    Sk  <- S1[[k]]
    mu1_mix <- mu1_mix + wk*muk
    A   <- A   + wk*(Sk + tcrossprod(muk))
  }
  S1_mix <- A - tcrossprod(mu1_mix)

  # Compute the log-Bayes factor for the mixture as a linear combination of the
  # individual BFs foreach mixture component.
  u     <- max(logbf)
  logbf_mix <- u + log(sum(w0 * exp(logbf - u)))
  
  # Return the log-Bayes factor for the mixture (logbf), the posterior assignment probabilities (w1), the
  # posterior mean of the coefficients (mu1), and the posterior
  # covariance of the coefficients (S1).
  return(list(logbf = logbf_mix,w1 = w1,mu1 = mu1_mix,S1 = S1_mix))
}


# Bayesian multivariate regression with mixture-of-normals prior
# (mixture weights w0 and covariance matrices S0) and centered X
#
# The outputs are: the log-Bayes factor (logbf), the posterior assignment probabilities
# (w1), the posterior mean of the coefficients given that all the
# coefficients are not nonzero (mu1), and the posterior covariance of
# the coefficients given that all the coefficients are not zero (S1).
bayes_mvr_mix_centered_X_rss <- function (xtY, V, w0, S0, xtx, Vinv, V_chol, d, QtimesV_chol, eps) {
  
  # Get the number of variables (n) and the number of mixture
  # components (k).
  r <- length(xtY)
  K <- length(S0)
  
  # Compute the least-squares estimate and covariance.
  b <- xtY/xtx
  S <- V/xtx
  
  # Compute quantities needed for bayes_mvr_ridge_centered_X()
  S_chol <- V_chol/sqrt(xtx)
  
  # Compute the Bayes factors and posterior statistics separately for
  # each mixture component.
  bayes_mvr_ridge_lapply <- function(i){
    bayes_mvr_ridge_centered_X(V, b, S, S0[[i]], xtx, Vinv, V_chol, S_chol, d[[i]], QtimesV_chol[[i]])
  }
  out <- lapply(1:K, bayes_mvr_ridge_lapply)
  
  # Compute the posterior assignment probabilities for the latent
  # indicator variable.
  logbf <- sapply(out,function (x) x$logbf)
  w1    <- softmax(logbf + log(w0 + eps))
  
  # Compute the posterior mean (mu1_mix) and covariance (S1_mix) of the
  # regression coefficients.
  A   <- matrix(0,r,r)
  mu1_mix <- rep(0,r)
  for (k in 1:K) {
    wk  <- w1[k]
    muk <- out[[k]]$mu1
    Sk  <- out[[k]]$S1
    mu1_mix <- mu1_mix + wk*muk
    A   <- A   + wk*(Sk + tcrossprod(muk))
  }
  S1_mix <- A - tcrossprod(mu1_mix)

  # Compute the log-Bayes factor for the mixture as a linear combination of the
  # individual BFs foreach mixture component.
  u     <- max(logbf)
  logbf_mix <- u + log(sum(w0 * exp(logbf - u)))
  
  # Return the log-Bayes factor for the mixture (logbf), the posterior assignment probabilities (w1), the
  # posterior mean of the coefficients (mu1), and the posterior
  # covariance of the coefficients (S1).
  return(list(logbf = logbf_mix,w1 = w1,mu1 = mu1_mix,S1 = S1_mix))
}