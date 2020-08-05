library(exifr)
# Also needed to install Perl from http://strawberryperl.com/ and ExifTool from https://exiftool.org/#
library(dplyr)

# This script will recurisvely read files from a directroy, read the image/video metadata, and then save a copy of those files in an output location, orgainsed by year

# Folder that we want to read our files from
myDir <- 'C:/Users/david/OneDrive/Pictures/SharedPictures'

# Location where we will save the organised photos and videos
myOutputFolder <- 'C:/Users/david/Pictures/Organised'

# Function to save files to new location
saveMyFile <- function(originalFile, originalFileName, year,newFileName){
  
  fileOutputLocation <- paste(myOutputFolder,'/',year,'/',newFileName, sep = "")
  #print(paste("Copying", originalFile, "to", fileOutputLocation))
  file.copy(originalFile,fileOutputLocation)
  
}

# Read the files we are interested in
myFiles <- list.files(path = myDir, full.names = TRUE, include.dirs = FALSE, recursive = TRUE)
# Get rid of any directories from the results (not sure why these are still in there since I used 'include.dirs = FALSE' in list.files )
myFiles <- myFiles[!dir.exists(myFiles)]

# Just test on a short extract of the files first
#myFiles <- myFiles[1:100]

# Now try getting the image metadata for those files
myMetadata <- read_exif(myFiles,tags=c("SourceFile","FileName", "Directory","CreateDate","DateTimeOriginal","FileModifyDate","MIMEType","FileType","FileTypeExtension"))
#myMetadata <- read_exif(myFiles)

# Now lets find the year the photo was taken
myMetadata$myDate <-  coalesce(myMetadata$CreateDate, myMetadata$DateTimeOriginal,myMetadata$FileModifyDate)
myMetadata$myDateAsDate <- as.Date(myMetadata$myDate, '%Y:%m:%d')
myMetadata$myYear <- as.numeric(format(myMetadata$myDateAsDate,'%Y'))

# Now see if its an image or video
myMetadata$myFileType <- ''
myMetadata[grepl('image',myMetadata$MIMEType),'myFileType'] <- 'Image'
myMetadata[grepl('video',myMetadata$MIMEType),'myFileType'] <- 'Video'
myMetadata[myMetadata$myFileType == '','myFileType'] <- NA

# save the metadata to csv
write.csv(myMetadata,"myMetadata.csv")

# Create a directory for each year (if required)
for (aYear in myMetadata$myYear){
  outputLocation <- paste(myOutputFolder,'/',aYear, sep = "")
  ifelse(!dir.exists(file.path(outputLocation)), dir.create(file.path(outputLocation)), FALSE)
}

myFilesToSave <- myMetadata[!is.na(myMetadata$myFileType),]

myFilesToSave$myNewFileName <- paste(row.names(myFilesToSave),'_',myFilesToSave$FileName,sep="")

# Use a small subset for testing
#myFilesToSave <- myFilesToSave[1:2,]

# Copy the files to our new folders
mySaveResults <- saveMyFile(myFilesToSave$SourceFile, myFilesToSave$FileName,myFilesToSave$myYear,myFilesToSave$myNewFileName)

# save mySaveResults to csv
write.csv(mySaveResults,"mySaveResults.csv")

# See how many files copied successfully
print(paste(length(mySaveResults[mySaveResults == TRUE]),"files copied successfully, ", length(mySaveResults[mySaveResults == FALSE]),"files failed (includes pre-existing files that weren't over-written)"))

