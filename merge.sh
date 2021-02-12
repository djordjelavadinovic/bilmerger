#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2021 Djordje Lavadinovic
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

function Usage {
clear
cat <<TOEND


NAME

	$0 - Utility script for merging multiple bulitens into a single one

SYNOPSIS
	
	$0 path

OPTIONS

	path	Relative or absoulte path to folder with archive (zip) files

DESCRIPTION

	$0 process zip archives in the folder "path". For each file, unzips file in the folder named in<PROCESS_NUMBER>, creates
	output folder out<PROCESS_NUMBER>/NEW and subfolders and for each archive puts the latest version of an object found in archives.
	After the last archive, renames folder NEW to match last archive name and creates zip file from the folder.


TOEND
exit 1
}


# Test input parameter (path)
if [ "${1}x" = "x" ]
then
  Usage
fi

if [ -d $1 ]
then
  SOURCEDIR=$( cd $1; pwd)
else
  echo "Directory does not exist: $1"
  exit 1
fi

# Creating folder structure
CURRDIR=$(pwd)
INPUTDIR=$CURRDIR/in$$
mkdir -p $INPUTDIR

OUTPUTDIR=$CURRDIR/out$$
mkdir -p $OUTPUTDIR/NEW/LANG2
mkdir -p $OUTPUTDIR/NEW/OPIS2
mkdir -p $OUTPUTDIR/NEW/PATCH2/single
mkdir -p $OUTPUTDIR/NEW/POST2
mkdir -p $OUTPUTDIR/NEW/PROC2
mkdir -p $OUTPUTDIR/NEW/PROCGK2
mkdir -p $OUTPUTDIR/NEW/PROG2/Linux
mkdir -p $OUTPUTDIR/NEW/PROG2/Solaris
mkdir -p $OUTPUTDIR/NEW/PROG2/Windows
mkdir -p $OUTPUTDIR/NEW/PROGQUE2
mkdir -p $OUTPUTDIR/NEW/SORS2
mkdir -p $OUTPUTDIR/NEW/UPUT2

# Placeholder for the name of the merged archive
ARCHIVENAME=EMPTY

cd $INPUTDIR

# At the moment, function only copy files from a single archive to the merged archive
# Future development shuld include some traces of job done
function CopyFiles {

  echo -n $(basename $1) ""

  for files in $(ls $1/$2 2>/dev/null)
  do
    cp -f $files $3
    # TODO Make some record of the action
  done

}


# Main loop
for i in $(ls $SOURCEDIR/*.zip 2>/dev/null)
do

  echo -n "Processing $i >>> "
  unzip -qq $i
  FILENAME=$(basename $i)
  ARCHIVENAME=${FILENAME%.zip}

  # Skip LANG2
  # Skip OPIS2

  # Process PATCH2
  # Splits bi.rmk into multiple .rmk files
  # Each table from bi.rmk is written into separate <TABLE_NAME>.rmk file
  # Then .rmk files are moved to destination folder.
  # New .rmk file overwrites old .rmk, so only the latest table descripton is preserved

  if [ -f $INPUTDIR/$ARCHIVENAME/PATCH2/bi.rmk ]
  then
    awk '$1=="TABLE" {currfname = $2} {print $0 >>currfname".rmk";}' $INPUTDIR/$ARCHIVENAME/PATCH2/bi.rmk 
    mv $INPUTDIR/*.rmk $OUTPUTDIR/NEW/PATCH2/single
  fi
  echo -n "PATCH2 "

  # Process POST2
  # Ignores .sql file
  CopyFiles $INPUTDIR/$ARCHIVENAME/POST2 'sifre*' $OUTPUTDIR/NEW/POST2/

  #Process PROC2
  CopyFiles $INPUTDIR/$ARCHIVENAME/PROC2 '*.pls' $OUTPUTDIR/NEW/PROC2/

  #Process PROCGK2
  CopyFiles $INPUTDIR/$ARCHIVENAME/PROCGK2 '*.plg' $OUTPUTDIR/NEW/PROC2/

  #Skip PROG2
  #Skip PROGQUE2

  #Process SORS2
  CopyFiles $INPUTDIR/$ARCHIVENAME/SORS2 '*' $OUTPUTDIR/NEW/SORS2/

  #Process UPUT2
  CopyFiles $INPUTDIR/$ARCHIVENAME/UPUT2 '*' $OUTPUTDIR/NEW/UPUT2/

  #Process root folder (README.txt)
  cat $INPUTDIR/$ARCHIVENAME/README.txt >>$OUTPUTDIR/NEW/README.txt
  echo "README.txt"

done

# Housekeeping
# Creates single bi.rmk file

for i in $(ls $OUTPUTDIR/NEW/PATCH2/single/*.rmk 2>/dev/null)
do
  cat $i >> $OUTPUTDIR/NEW/PATCH2/bi.rmk
done

# Renaming merged archive. The new name is equal to the name of the last processed archive
# TODO Maybee adidtional parameter (outputarchive) should be better solution?
mv $OUTPUTDIR/NEW/ $OUTPUTDIR/$ARCHIVENAME
cd $OUTPUTDIR
zip -rq ${ARCHIVENAME}.zip $ARCHIVENAME
echo "Created: $OUTPUTDIR/${ARCHIVENAME}.zip"

# Cleaning
rm -r $INPUTDIR
#rm -r $OUTPUTDIR
