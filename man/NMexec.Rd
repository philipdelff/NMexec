% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/NMexec.R
\name{NMexec}
\alias{NMexec}
\title{execute nonmem while also archiving input data}
\usage{
NMexec(
  files,
  file.pattern,
  dir,
  sge = TRUE,
  file.data.archive,
  nc = 64,
  dir.data = NULL,
  wait = FALSE,
  args.execute,
  update.only = FALSE
)
}
\arguments{
\item{files}{File paths to the models (control stream) to
edit. See file.pattern too.}

\item{file.pattern}{Alternatively to files, you can supply a
regular expression which will be passed to list.files as the
pattern argument. If this is used, use dir argument as
well. Also see data.file to only process models that use a
specific data file.}

\item{dir}{If file.pattern is used, dir is the directory to search
in.}

\item{sge}{Use the sge queing system. Default is TRUE. Disable for
quick models not to wait.}

\item{file.data.archive}{A function of the model file path to
generate the path in which to archive the input data as
RDS. Set to NULL not to archive the data.}

\item{nc}{Number of cores to use if sending to the cluster. Default
is 64.}

\item{dir.data}{The directory in which the data file is
stored. This is normally not needed as data will be found
using the path in the control stream. This argument may be
removed in the future since it should not be needed.}

\item{wait}{Wait for process to finish before making R console
available again? This is useful if calling NMexec from a
function that needs to wait for the output of the Nonmem run
to be available for further processing.}

\item{args.execute}{A character string with arguments passed to
execute. Default is
"-model_dir_name -nm_output=xml,ext,cov,cor,coi,phi".}

\item{update.only}{Only run model(s) if control stream or data
updated since last run?}
}
\description{
execute nonmem while also archiving input data
}
\details{
Use this to read the archived input data when retrieving
    the nonmem results
    NMdataConf(file.data=function(x)fnExtension(fnAppend(x,"input"),".rds"))
}
\examples{
file.mod <- "run001.mod"
## run locally - not on cluster
NMexec(file.mod,sge=FALSE)
## run on cluster with 16 cores. 64 cores is default
NMexec(file.mod,nc=16)
## submit multiple models to cluster
multiple.models <- c("run001.mod","run002.mod")
NMexec(multiple.models,nc=16)
## run all models called run001.mod - run099.mod if updated. 64 cores to each.
NMexec(file.pattern="run0..\\\\.mod",dir="models",nc=16,update.only=TRUE)
}
