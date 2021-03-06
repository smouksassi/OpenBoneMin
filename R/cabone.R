
camodel <- "OpenBoneMin"

##' Plotting helper functions.
##' @param ... passed to \code{ggplot::scale_color_brewer}
##' @rdname colSet1
##' @export
.colSet1 <- function(...) ggplot2::scale_color_brewer(palette="Set1",...)
##' @export
##' @rdname colSet1 
.colSet2 <- function(...) ggplot2::scale_color_brewer(palette="Set2",...)

##' Get the locaton of model source code.
##' 
##' @examples
##' 
##' BoneMinLib()
##' 
##' @export
BoneMinLib <- function() system.file(package="OpenBoneMin")

##' Calcium / bone homeostatis model.
##' 
##' @param file export file name
##' @param overwrite passed to \code{\link{writeLines}}
##' @param ... passed to update
##' 
##' @examples
##' 
##' mod <- BoneMin(end = 365, delta = 0.5)
##' 
##' BoneMin_export()
##' 
##' @export
BoneMin <- function(...) {
  update(mread_cache(camodel,BoneMinLib()),...)
}


##' @rdname BoneMin
##' @export
BoneMin_export <- function(file=tempfile(fileext=".cpp"), overwrite=FALSE) {
  if(is.null(file)) {
    stop("please provide a file name to write model code.", call.=FALSE)
  }
  if(!grepl(".*\\.cpp$",file)) {
    stop("file must end in '.cpp'",call.=FALSE)
  }
  file <- normalizePath(file,mustWork=FALSE)
  if(file.exists(file) & !overwrite) {
    stop("output file already exists.", call.=FALSE)
  }
  mod <- mread(camodel,BoneMinLib(),compile=FALSE)
  message("Writing model code to file ", file)
  writeLines(mod@code,file)
  return(file)
}

##' Convert teriparatide doses
##' 
##' @param x teriparatide dose in micrograms
##' 
##' @return teriparatide dose in 
##' 
##' @examples
##' 
##' amt_teri(20)
##' 
##' @export
amt_teri <- function(x) x*1E6/4117.8

##' Convert denosumab doses
##' 
##' @param x denosumab dose in milligrams
##' 
##' @return denosumab dose in mmol
##' @export
amt_denos <- function(x) x*1


##' Simulate with teriparatide dosing
##' 
##' @param dose teriparatide dose in micrograms
##' @param ii dosing interval in hours
##' @param dur number of doses to simulate
##' @param delta simulation time grid
##' @param request outputs to request
##' 
##' @examples
##' 
##' out <- sim_teri(dose=c(20,40), dur=9)
##' 
##' head(out)
##' 
##' plot(out)
##' 
##' @export
sim_teri <- function(dose=20, ii=24, dur=27, delta=0.1, request="PTHpm,CaC") {
  mod <- BoneMin()
  cmtn <- mrgsolve::cmtn(mod,"TERISC")
  data <- expand.ev(amt=amt_teri(dose), ii=ii, addl=dur, cmt=cmtn)
  mrgsim(mod, data=data, delta=delta, end=(dur+1)*ii, Req=request)
}



##' Simulate with denosumab dosing
##' 
##' @param dose denosumab dose in milligrams
##' @param ii dosing interval in months
##' @param dur number of doses to simulate
##' @param delta simulation time grid in hours
##' @param request outputs to request
##' @param tscale factor for rescaling time in simulated output
##' 
##' @examples
##' 
##' out <- sim_denos(dose=c(10,60,210), dur=6)
##' 
##' plot(out, log(DENCP) + BMDlsDENchange ~ time, xlab="Time (months)")
##' 
##' @export
sim_denos <- function(dose=60, ii=6, dur=3, delta=4, 
                      request="DENCP,DENMOL,BMDlsDENchange", 
                      tscale=1/(24*28)) {
  mod <- BoneMin()
  cmtn <- mrgsolve::cmtn(mod,"DENSC")
  ii <- ii*28*24
  data <- expand.ev(amt = amt_denos(dose), ii=ii, addl=dur-1, cmt=cmtn)
  mrgsim(mod, data=data, delta=delta, end=(dur+1)*ii,
         tscale=tscale,
         Req=request)
}

