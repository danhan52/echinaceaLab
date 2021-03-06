#' create a data frame of scan filenames and batch ids.
#' 
#' This function takes all the scanned image files in a selected folder and
#' returns a dataframe with all file names, their associated batches and letnos.
#' 
#' @param path character directory or path containing the files of interest
#' @return dataframe that report characteristics of each file in the directory
#'   of interest
#'   
#' @keywords scan file batch letno
#' @examples
#'
#'\dontrun{
#'scans <- loadScans("I:\\Departments\\Research\\EchinaceaCG2012\\scanExamples")}
#'
#' @seealso \code{\link{check.batch}}
#'   
loadScans <- function(path = "."){
  x <- list.files(path, full.names = FALSE, 
                  recursive = TRUE, include.dirs = FALSE)
  filename <- basename(x)
  paths <- dirname(x) 
  scans <- data.frame(batch = paths, filename = filename)
  x <- as.character(scans$filename)
  #remove scan prefix and .jpg--this should work for 3 or 4-digit batch numbers
  nolets <- substr(x, nchar(x) - (nchar(x) - 2), nchar(x) - 4)
  lets <- substr(nolets, nchar(nolets) - 1, nchar(nolets)) 
  nos <- substr(nolets, 1, nchar(nolets) - 2)
  scans$letno <- paste(toupper(lets), nos, sep = "-")
  scans <<- scans
  scans
}


#' Compare letnos or nolets from scan files with harvest list for an 
#' experiment.
#' 
#' This function compares the vector scans$letno with the vector hh.2012$letno. 
#' Make sure you set the working directory to the directory that contains the 
#' dataframes scans and hh.2012.
#' 
#' @param batch character the hh.2013 and hh.2014 dataframes has the batch field populated with experiment name. In 2012 and before batch was an integer identifier for a garden in cg1. batch defaults to SPP.
#' @param scansdf dataframe in format of output from function loadScans. The
#'   default name is scans.
#' @param harvestFile dataframe such as hh.2012 or hh.2013
#'  
#' @return names list of of interest
#'   
#' @keywords scan file batch letno
#' @examples
#'
#'\dontrun{
#'scans <- loadScans("I:\\Departments\\Research\\EchinaceaCG2012\\scanExamples")
#'check.batch("321")}
#'
#' @seealso \code{\link{loadScans}}
#' @seealso \code{\link{check.year}}
#'   
check.batch <- function(batch = "SPP", scansdf = scans, harvestFile = hh.2014){
  w <- setdiff(scansdf[scansdf$batch %in% batch, "letno"],
               harvestFile[harvestFile$batch %in% batch, "letno"])
  m <- setdiff(harvestFile[harvestFile$batch %in% batch, "letno"],
               scansdf[scansdf$batch %in% batch, "letno"])
  b  <- length(harvestFile[harvestFile$batch %in% batch, "letno"])
  s  <- length(scansdf[scansdf$batch %in% batch, "letno"])
  list(batchCount = b, scanCount = s, missingCount = length(m), 
       missing = m, wrong = w)
}

#' Compare letnos or nolets from scan files with harvest list for a given 
#' year.
#' 
#' This function runs check.batch over all experiments and then creates a
#' summary for what is missing.
#' 
#' @param scanFolder the location of the scan files
#' @param harvestFile one of the hh.year files that comes with this package
#' @param writeTo the file to which the summary will be written
#' @return none, write to a csv
#' 
check.year <- function(scanFolder, harvestFile, writeTo = "./scanSummary.csv") {
  loadScans(scanFolder)
  # remove "extra" files, if present
  scans <- scans[!(scans$filename %in% c("Thumbs.db", "itfiles.ini")),]
  # folders that should be there but aren't
  stillNeed <- setdiff(levels(hh.2013$batch), levels(scans$batch))
  # folders that are there but shouldn't be
  ignore <- setdiff(levels(scans$batch), levels(hh.2013$batch))
  
  # check batch for all batches separately
  batchecks <- aaply(levels(scans$batch), .margins = 1, .fun = check.batch, harvestFile=hh.2013)
  batchecks <- cbind(batchecks, levels(scans$batch))
  colnames(batchecks)[6] <- "batchName"
  batchecks <- batchecks[,c(6,1,2,3,4,5)]
  
  # rename writeTo to have date
  write.csv(batchecks, file = writeTo, row.names = F)
  write.table(c("need experiments:", stillNeed, "\n"), file = writeTo, append = T,
              row.names = F, col.names = F)
  write.table(c("ignore:", ignore, "\n"), file = writeTo, append = T,
              row.names = F, col.names = F)
  message("File can be found here:", writeTo) 
}


#' Transfer files from one folder to another
#' 
#' This function will compare the contents of two folders and transfer
#' any files that are not in the second folder but are in the first folder
#' from the first to the second. If the second folder doesn't exist, it will
#' create one. It will also inform you how many files are
#' in the second folder but not the first
#' 
#' @param from path to a folder that you want all files from
#' @param to path to a folder which you want files transferred to
#' @param showNotInFrom logical: should files not in the from folder but in
#'  the to folder be printed
#' @keywords scans
#' 
#' @examples
#' \dontrun{
#' path <- "C:\\Users\\dhanson\\Documents\\scanTest"
#' pathos <- "E:\\cg2014scans\\exPt2"
#' transferFiles(pathos, path, showNotInFrom = TRUE)}
#'
transferFiles <- function(from, to, showNotInFrom = FALSE) {
  xFrom <- list.files(from, full.names = FALSE, recursive = TRUE, 
                      include.dirs = FALSE)
  filenamesFrom <- basename(xFrom)
  pathsFrom <- dirname(xFrom)
  if (!file.exists(to))
    dir.create(to)
  xTo <- list.files(to, full.names = FALSE, recursive = TRUE, 
                    include.dirs = FALSE)
  filenamesTo <- basename(xTo)
  pathsTo <- dirname(xTo)
  
  
  notInTo <- setdiff(filenamesFrom, filenamesTo)
  notInTo <- notInTo[!notInTo %in% c("Thumbs.db", "itfiles.ini")]
  
  if (length(notInTo) > 0) {
    dope <- txtProgressBar(0, length(notInTo), 0, "~", style = 3)
    i <- 1
    setTxtProgressBar(dope, i)
    for (fn in notInTo) {
      # cat(paste("copying", fn))
      fromFn <- paste(from, fn, sep="/")
      toFn <- paste(to, fn, sep="/")
      file.copy(fromFn, to)
      i <- i+1
      setTxtProgressBar(dope, i)
    }
  }
  cat("\nCopied", length(notInTo), "file(s) from\n", from, "to\n", to, "\n")
  message()
  
  notInFrom <- setdiff(filenamesTo, filenamesFrom)
  message(paste(length(notInFrom), "files are in\n", to, "but not in\n", from, "\n"))
  if (showNotInFrom) {
    message()
    message(paste("Files not in", from, ":"))
    message(cat(notInFrom))
  }
}

#' Transfer files from all subfolders to analogous subfolders
#' 
#' This function will user the transferFiles function to go through all
#' subfolders of the selected folder and transfer files not in one folder
#' to the other
#' 
#' @param from path to a folder whose subfolders you want checked,
#' (e.g. "C:/cg2015scans" or "I:/Departments/Research/EchinaceaCG2015/cg2015scans")
#' @param to the drive on which the wanted folder is found (e.g. "F:/", "D:/", or
#' "I:/Departments/Research/EchinaceaCG2015/")
#' @param askBeforeContinue logical: should a message be printed before continuing
#'  to check other subfolders
#' @keywords scans
#' @details Works from any from and any to as long as the name of the from folder
#' ends with "cgXXXXscans" where XXXX is a number
#' 
#' @examples
#' \dontrun{
#' path1 <- "C:/cg2014scans"
#' pathos <- "E:/"
#' transferScanFiles(pathos, path)}
#'
transferScanFiles <- function(from, to, askBeforeContinue = TRUE) {
  pathsFrom <- list.dirs(from)[-1]
  whereToBoss <- regexpr("cg[0-9]+scans", from)
  fromDrive <- substr(from, 1, whereToBoss-1)
  pathsTo <- gsub(fromDrive, to, pathsFrom)
  
  for (i in 1:length(pathsFrom)) {
    transferFiles(pathsFrom[i], pathsTo[i])
    if (askBeforeContinue & (i != length(pathsFrom))) {
      message("press enter to do next folder:")
      readline()
    }
  }
}