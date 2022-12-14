##' execute nonmem while also archiving input data

##' @param files File paths to the models (control stream) to
##'     edit. See file.pattern too.
##' @param file.pattern Alternatively to files, you can supply a
##'     regular expression which will be passed to list.files as the
##'     pattern argument. If this is used, use dir argument as
##'     well. Also see data.file to only process models that use a
##'     specific data file.
##' @param dir If file.pattern is used, dir is the directory to search
##'     in.
##' @param sge Use the sge queing system. Default is TRUE. Disable for
##'     quick models not to wait.
##' @param file.data.archive A function of the model file path to
##'     generate the path in which to archive the input data as
##'     RDS. Set to NULL not to archive the data.
##' @param nc Number of cores to use if sending to the cluster. Default
##'     is 64.
##' @param dir.data The directory in which the data file is
##'     stored. This is normally not needed as data will be found
##'     using the path in the control stream. This argument may be
##'     removed in the future since it should not be needed.
##' @param wait Wait for process to finish before making R console
##'     available again? This is useful if calling NMexec from a
##'     function that needs to wait for the output of the Nonmem run
##'     to be available for further processing.
##' @param args.execute A character string with arguments passed to
##'     execute. Default is
##'     "-model_dir_name -nm_output=xml,ext,cov,cor,coi,phi".
##' @param update.only Only run model(s) if control stream or data
##'     updated since last run?
##' @details Use this to read the archived input data when retrieving
##'     the nonmem results
##'     NMdataConf(file.data=function(x)fnExtension(fnAppend(x,"input"),".rds"))
##' @import NMdata
##' @examples
##' file.mod <- "run001.mod"
##' ## run locally - not on cluster
##' NMexec(file.mod,sge=FALSE)
##' ## run on cluster with 16 cores. 64 cores is default
##' NMexec(file.mod,nc=16)
##' ## submit multiple models to cluster
##' multiple.models <- c("run001.mod","run002.mod")
##' NMexec(multiple.models,nc=16)
##' ## run all models called run001.mod - run099.mod if updated. 64 cores to each.
##' NMexec(file.pattern="run0..\\.mod",dir="models",nc=16,update.only=TRUE)
##' @export


### -nm_version=nm74_gf

NMexec <- function(files,file.pattern,dir,sge=TRUE,file.data.archive,nc=64,dir.data=NULL,wait=FALSE,args.execute,update.only=FALSE,nmquiet=FALSE){
    

    if(missing(file.data.archive)){
        file.data.archive <- function(file){
            fn.input <- fnAppend(file,"input")
            fn.input <- fnExtension(fn.input,".rds")
            fn.input
        }
    }
    if(missing(args.execute) || is.null(args.execute)){
        args.execute <- "-model_dir_name -nm_output=xml,ext,cov,cor,coi,phi"
    }

    if(missing(files)) files <- NULL
    if(missing(dir)) dir <- NULL
    if(missing(file.pattern)) file.pattern <- NULL
    if(is.null(files) && is.null(file.pattern)) file.pattern <- ".+\\.mod"
    files.all <- NMdata:::getFilePaths(files=files,file.pattern=file.pattern,dir=dir,quiet=TRUE)

    files.exec <- files.all
    if(update.only){
        files.exec <- findUpdated(files.all)
    }

    message(paste(files.exec,collapse=", "))
    
    for(file.mod in files.exec){    
        message(file.mod)
        ### cat(file.mod,"\n")

        ## replace extension of fn.input based on path.input - prefer rds
        rundir <- dirname(file.mod)

        if(!is.null(file.data.archive)){
            fn.input <- file.data.archive(file.mod)

            ## copy input data
            dat.inp <- NMscanInput(file.mod,file.mod=file.mod,translate=FALSE,applyFilters = FALSE,file.data="extract",dir.data=dir.data,quiet=TRUE)
            saveRDS(dat.inp,file=file.path(rundir,basename(fn.input)))
        }

        string.cmd <- paste0("cd ",rundir,"; execute ",args.execute)
        if(sge){
            file.pnm <- file.path(rundir,"NMexec.pnm")
            pnm <- NMgenPNM(nc=nc,file=file.pnm)
            string.cmd <- paste0(string.cmd," -run_on_sge -sge_prepend_flags=\"-pe orte ",nc," -V\" -parafile=",basename(pnm)," -nodes=",nc)
        }

        ## } else {
        ##     string.cmd <- paste0("cd ",rundir,"; execute ",basename(file.mod))
        ## }

        string.cmd <- paste(string.cmd,basename(file.mod))
        if(nmquiet) string.cmd <- paste(string.cmd, ">/dev/null")
        if(!wait) string.cmd <- paste(string.cmd,"&")

        system(string.cmd,ignore.stdout=nmquiet)
    }

    return(invisible(NULL))
}


## execute nonmem
## system(
##     paste0("cd ",rundir,"; execute -model_dir_name -run_on_sge -sge_prepend_flags=\"-pe orte ",nc," -V\" -parafile=",basename(pnm)," -nodes=",nc," ",basename(file.mod)," &")
## )
