#!/bin/bash

DirCleanupList=('/var/motion/cam1'
		'/var/motion/cam2'
		'/var/motion/cam3'
	)

# This command generates a sorted directory listing - Oldest file first - Only files.   The grep command at the end takes out the directories.
# ls -t1r --file-type /var/motion/cam1|grep -v './$'
# To get only the single oldest file
# ls -t1r --file-type /var/motion/cam1|grep -v './$'|head -n 1

# This gets the available space on the drive
# df /dev/sda1 --output=avail|tail -n 1



#FreeSpaceThreshold determines when to start removing the oldest files in each directory

FreeSpaceThreshold=7600000

#echo $FreeSpaceDT

FoundFiles=0
NoChangeCounter=0

while true; do
  FreeSpace=$(df /dev/sda1 --output=avail|tail -n 1)
  FreeSpaceDT=$((FreeSpace - FreeSpaceThreshold))

  if [ $FreeSpaceDT -lt 0 ]; then
    for sDir in ${DirCleanupList[@]}; do
    #  echo ${sDir}
      
      OldestFile=${sDir}/$(ls -t1r --file-type ${sDir}|grep -v './$'|head -n 1)
      
      if [ "$OldestFile" != "$sDir/" ]
      then
	(( FoundFiles += 1 ))

	echo "Removing ${OldestFile}"
	rm -f ${OldestFile}
      fi

      
    done
  else
    break
  fi
  
  echo "Found" ${FoundFiles}

  FreeSpaceAfter=$(df /dev/sda1 --output=avail|tail -n 1)
  
  #Exit if no files were found to clean up
  if [ "$FoundFiles" -eq 0 ]; then
    echo "No more files found to clean"
    break
  fi
  
  FoundFiles=0
  
  #Test the freespace before & after if no change, increment the NoChangeCount - this is to avoid being stuck in an infinute loop
  if [ $FreeSpace -eq $FreeSpaceAfter ]; then
    (( NoChangeCounter += 1 ))
  else
    NoChangeCount=0
  fi
  
  #If there were no changes in the last 1000 loops, exit
  if [ $NoChangeCounter -gt 1000 ]; then
    echo "Exiting due to no change in Free Space"
    break;
  fi
  
done

