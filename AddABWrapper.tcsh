#! /bin/tcsh -f 

set wrapperDir = $PWD
set startTime = `date +"%Y%m%d_%H%M%S"`
echo 
echo Wrapper Started at:
echo $startTime
echo
echo Version 1.1 
echo
echo This Wrapper will wrap around and run:
echo 1\) do-add-ab_flags
#TODO extensive testing 
#6 tiles to test

#check hyphenated argument
@ i = 0
set rsyncSet = "false"
while ($i < $# + 1)
     #user input nameslist -nl argument
      if("$argv[$i]" == "-rsync") then
        echo Argument "-rsync" detected. Will rsync Tyto, Otus, and Athene.
        set rsyncSet = "true"
      endif
      @ i +=  1
end

#check mode and input arguments 
if ($# != 5) then
        #Error handling
        #Too many or too little arguments       
        echo ""
        echo "ERROR: not enough arguments:"
        echo Mode 2 call:
        echo AddABWrapper.tcsh 2 inputList.txt \<versionID\> \<InputPath\> \<OutputPath\>
        echo Mode 3 call:
        echo AddABWrapper.tcsh 3 TileName \<versionID\> \<InputPath\> \<OutputPath\>
        echo
        echo Exiting...
        exit
#Mode2 List Mode
#TODO *** priority ***
#this list functionality is most important
# output is important
else if ($1 == 2) then
	set InputsList = $2
	set versionID = $3
        set InputPath = $4
        set OutputPath = $5
        echo Inputs list ==  $InputsList
	echo versionID == $versionID
        echo Input Path == $InputPath
        echo Output Path == $OutputPath
        echo
        #if directories dont exist, throw error
        if(! -f $InputsList) then
                echo ERROR: Input List file $InputsList does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $InputPath) then
                echo ERROR: Input Path directory $InputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $OutputPath) then
                echo ERROR: Output Path directory $OutputPath does not exist.
                echo
                echo Exiting...
                exit
        endif

	echo
	echo Going to Mode2
	echo
	goto Mode2
#Mode3 Single Tile Mode
else if ($1 == 3) then
        set InputTable = $2
	set versionID = $3
        set InputPath = $4
        set OutputPath = $5
        echo Input Table == $InputTable
        echo Input Path == $InputPath
        echo Output Path == $OutputPath
        #if directories dont exist, throw error
        if(! -f $InputTable) then
		echo
                echo ERROR: $InputTable doest not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $InputPath) then
                echo ERROR: Input Path directory $InputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $OutputPath) then
                echo ERROR: Output Path directory $OutputPath does not exist.
                echo
                echo Exiting...
                exit
        endif

	echo
	echo Going to Mode3
	echo
        goto Mode3
else
        #Error handling
        #option 2/3 not second parameter. program exits.
	echo
        echo ERROR mode 2, or 3 not selected
        echo Mode 2 call:
        echo AddABWrapper.tcsh 2 inputList.txt \<InputPath\> \<OutputPath\>
        echo Mode 3 call:
        echo AddABWrapper.tcsh 3 TileName \<InputPath\> \<OutputPath\>
	echo
        echo Exiting...
	exit
endif

#==============================================================================================================================

Mode2:
    
    foreach table (`cat $InputsList`)    
        echo ===================================== - START AddABWrapper wrapper loop iteration - ======================================
     
        set mdexTable = `echo $table`

        echo "Current input MDEXTable == "$mdexTable
        echo Calling AddABWrapper.tcsh Mode3 on $table 
	if($rsyncSet == "true") then
		(echo y | /Volumes/CatWISE1/ejmarchese/Dev/AddABWrapper/AddABWrapper.tcsh 3 $table $versionID $InputPath $OutputPath -rsync) &
	else
		(echo y | /Volumes/CatWISE1/ejmarchese/Dev/AddABWrapper/AddABWrapper.tcsh 3 $table $versionID $InputPath $OutputPath) &
	endif
	
	set maxInParallel = 12
        if(`ps -ef | grep AddABWrapper | wc -l` > $maxInParallel + 1) then
                echo  More than $maxInParallel AddABWrapper processes, waiting...
                while(`ps -ef | grep AddABWrapper | wc -l` > $maxInParallel + 1)
                        sleep 1
                        #echo IM WATING
                        #do nothing
                end
                echo  Done waiting
        endif
		echo
                echo AddABWrapper for $table  done
            
            echo ====================================== - END AddABWrapper wrapper loop iteration - =======================================
    end

    #===============================================================================================================================================================

    #wait for background processes to finish
    wait
    echo AddABWrapper wrapper finished
    echo
    goto Done

Mode3:	
       ###Given mdexTable == 1497p015_opt1_20180609_083107.tbl.gz,
        set mdexTable = $InputTable 
	set tempSize = `basename $mdexTable  | awk '{print length($0)}'`
        @ tempIndex = ($tempSize - 3 - 4) 
       ### tempIndex = filesize - sizeof(".gz") - sizeof(".tbl")

       ###Given mdexTable == 1497p015_opt1_20180609_083107.tbl.gz,
       ###  edited_mdexTable == 1497p015_opt1_20180609_083107
       ###  edited_mdexTablePATH is the path that the mdexTable resides in
       ###  RadecID == 1497015
       ###  RestOfTablename == _opt1_20180609_083107
        set edited_mdexTable = `basename $mdexTable | awk -v endIndex=$tempIndex '{print substr($0,0,endIndex)}'`
        set edit_mdexTablePATH = `dirname $mdexTable`
	set edited_mdexTablePATH = `cd $edit_mdexTablePATH && pwd`
	set RadecID = `echo $edited_mdexTable | awk '{print substr($0,0,8)}'`
	@ tempIndex = ($tempIndex - 8 - 3)
       ### tempIndex = tempIndex - sizeof($RadecID) - sizeof("_af")
	set RestOfTablename = `basename $mdexTable | awk -v endIndex=$tempIndex '{print substr($0,9,endIndex)}'` 

	echo "__________________________________________________________________________________________________"
        echo "Current input MDEXTable == "$mdexTable
        echo "Edited_Current input MDEXTable == "${edited_mdexTablePATH}//${edited_mdexTable}.tbl
        echo "RadecID == "$RadecID
	echo "RestOfTablename == "$RestOfTablename
	echo "versionID == "${versionID}
	echo "InputPath == "${InputPath}
	echo "OutputPath  == "${OutputPath}
	echo "__________________________________________________________________________________________________"
	echo 
	
	echo Unzipping $mdexTable to ${edited_mdexTablePATH}/${edited_mdexTable}.tbl
	gunzip -f -c -k $mdexTable > ${edited_mdexTablePATH}/${edited_mdexTable}.tbl 
	set saved_status = $? #Error Checking
       ### check exit status
        echo gunzip saved_status == ${saved_status}
        if($saved_status != 0) then #if program failed, status != 0
                echo Failure detected on tile ${RadecID}
                set failedProgram = "gunzip"
                goto Failed
        endif
	echo

       ### John Fowler's Single Tile proram
       ###Program call
	#appending v0,  _ab_v0
	#TODO add version 
###	#/Users/CatWISE/do-add-ab_flags.tcsh ${RadecID} ${RestOfTablename} v0 
###	#/Users/CatWISE/do-add-ab_flags.tcsh 1497p015 _opt1_20180609_083107 v0 
###     echo "/Users/CatWISE/do-add-ab_flags.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${InputPath} ${OutputPath}" 
	echo John Fowler Program call:
        echo "/Volumes/CatWISE1/ejmarchese/Dev/AddABWrapper/do-ab.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${InputPath} ${OutputPath}" 
	echo
	/Volumes/CatWISE1/ejmarchese/Dev/AddABWrapper/do-ab.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${InputPath} ${OutputPath}
	set saved_status = $? 
	#check exit status
	echo stils saved_status == $saved_status 
	if($saved_status != 0) then #if program failed, status != 0
		echo Failure detected on tile $RadecID
		set failedProgram = "do-add-ab_flags.tcsh"
		goto Failed
	endif
	echo

	#echo DONE. Output: ${edited_mdexTablePATH}/${edited_mdexTable}_af.tbl 
	goto Mode3_Done #gzip_done

Done:
echo AddABWrapper Mode: ${1} Done
set endTime = `date '+%m/%d/%Y %H:%M:%S'`
echo
echo Wrapper Mode: ${1} Ended at:
echo $endTime
exit

#Done section for gzipping rsyncing
Mode3_Done:
echo AddABWrapper on ${RadecID} Mode: ${1} Done
set endTime = `date '+%m/%d/%Y %H:%M:%S'`
echo
	######TODO: reduce redundencies in code
	#echo NOT!!!Gzipping and rm ${edited_mdexTablePATH}/${edited_mdexTable}_af.tbl
	#gzip -f ${edited_mdexTablePATH}/${edited_mdexTable}_af.tbl
	#rm -f ${edited_mdexTablePATH}/${edited_mdexTable}_af.tbl
	#echo Done gzip on ${edited_mdexTablePATH}/${edited_mdexTable}_af.tbl
       #rsync step
	if($rsyncSet == "true") then
       #rsync
	set CatWISEDir = ${edited_mdexTablePATH}
        echo running rsync on tile $RadecID
        set currIP = `dig +short myip.opendns.com @resolver1.opendns.com`
        echo current IP = $currIP
        if($currIP == "137.78.30.21") then #Tyto
                set otus_CatWISEDir = `echo $CatWISEDir | sed 's/CatWISE1/otus1/g'`
                set athene_CatWISEDir = `echo $CatWISEDir | sed 's/CatWISE1/athene1/g'`
                set otus_CatWISEDir = `echo $otus_CatWISEDir | sed 's/tyto/otus/g'`
                set athene_CatWISEDir = `echo $athene_CatWISEDir | sed 's/tyto/athene/g'`
                set otus_CatWISEDir = `echo $otus_CatWISEDir | sed 's/CatWISE3/otus3/g'`
                set athene_CatWISEDir = `echo $athene_CatWISEDir | sed 's/CatWISE3/athene3/g'`
                echo You are on Tyto!

               #Transfer Tyto CatWISE/ dir to Otus
                echo rsync Tyto\'s $CatWISEDir/${edited_mdexTable}_af.tbl.gz to Otus $otus_CatWISEDir
                ssh ${user}@137.78.80.75 "mkdir -p $otus_CatWISEDir"
                #rsync -avu $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.80.75:$otus_CatWISEDir

               #Transfer Tyto CatWISE/ dir to Athene
                echo rsync Tyto\'s $CatWISEDir/${edited_mdexTable}_af.tbl.gz to Athene $athene_CatWISEDir
                ssh ${user}@137.78.80.72 "mkdir -p $athene_CatWISEDir"
                #rsync -avu  $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.80.72:$athene_CatWISEDir
        else if($currIP == "137.78.80.75") then  #Otus
                set tyto_CatWISEDir = `echo $CatWISEDir | sed 's/otus3/CatWISE3/g'`
                set tyto_CatWISEDir = `echo $tyto_CatWISEDir | sed 's/otus/tyto/g'`
                set athene_CatWISEDir = `echo $CatWISEDir | sed 's/otus/athene/g'`
                echo You are on Otus!

               #Transfer Otus CatWISE/ dir to Tyto
                echo rsync Otus\'s $CatWISEDir/${edited_mdexTable}_af.tbl.gz to Tyto $tyto_CatWISEDir
                ssh ${user}@137.78.30.21 "mkdir -p $tyto_CatWISEDir"
                #rsync -avu $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.30.21:$tyto_CatWISEDir

               #Transfer Otus CatWISE/ to Athene
                echo rsync Otus\'s $CatWISEDir/${edited_mdexTable}_af.tbl.gz to Athene $athene_CatWISEDir
                ssh ${user}@137.78.80.72 "mkdir -p $athene_CatWISEDir"
                #rsync -avu  $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.80.72:$athene_CatWISEDir
        else if($currIP == "137.78.80.72") then #Athene
                set tyto_CatWISEDir = `echo $CatWISEDir | sed 's/athene3/CatWISE3/g'`
                set tyto_CatWISEDir = `echo $tyto_CatWISEDir | sed 's/athene/tyto/g'`
                set otus_CatWISEDir = `echo $CatWISEDir | sed 's/athene/otus/g'`
                echo You are on Athene!
               
	       #Transfer to Tyto
                echo rsync Athene\'s $CatWISEDir/${edited_mdexTable}_af.tbl to Tyto $tyto_CatWISEDir
		ssh ${user}@137.78.30.21 "mkdir -p $tyto_CatWISEDir"
                #rsync -avu $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.30.21:$tyto_CatWISEDir

               #Transfer to Otus
                echo rsync Athene\'s $CatWISEDir/${edited_mdexTable}_af.tbl.gz to Otus $otus_CatWISEDir
                ssh ${user}@137.78.80.75 "mkdir -p $otus_CatWISEDir"
                #rsync -avu $CatWISEDir/${edited_mdexTable}_af.tbl.gz ${user}@137.78.80.75:$otus_CatWISEDir
        endif
        endif


echo
echo Wrapper Mode: ${1} Ended at:
echo $endTime
exit


#TODO save some lines! Simply set a variable == WARNING or ERROR. Then just do the same for both case (theres no need for that huge repeat) 
#program jumps here if a program returns an exit status 32(Warning) or 64(Error)
Failed:
echo exit status of ${failedProgram} for tile \[${RadecID}\]\: ${saved_status}
	set currIP = `dig +short myip.opendns.com @resolver1.opendns.com`
        echo current IP = $currIP
        if($currIP == "137.78.30.21") then #Tyto
		if($saved_status <= 32) then #status <= 32, WARNING 
			echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} 	
			touch /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt
			echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}  >> /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt 	
               		echo WARNING output to error log: /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt
			if($rsyncSet == "true") then #rsync to other machines
	 	       	       #Transfer Tyto ErrorLogsTyto/ dir to Otus
               	 		echo rsync Tyto\'s /Volumes/tyto2/ErrorLogsTyto/ to Otus /Volumes/otus2/ErrorLogsTyto/
                		ssh ${user}@137.78.80.75 "mkdir -p /Volumes/otus2/ErrorLogsTyto/"
                		#rsync -avu /Volumes/tyto2/ErrorLogsTyto/ ${user}@137.78.80.75:/Volumes/otus2/ErrorLogsTyto/
	               	       #Transfer Tyto ErrorLogsTyto/ dir to Athene
        	        	echo rsync Tyto\'s /Volumes/tyto2/ErrorLogsTyto/ to Athene /Volumes/athene2/ErrorLogsTyto/ 
                		ssh ${user}@137.78.80.72 "mkdir -p /Volumes/athene2/ErrorLogsTyto/"
                		#rsync -avu  /Volumes/tyto2/ErrorLogsTyto/ ${user}@137.78.80.72:/Volumes/athene2/ErrorLogsTyto/ 
			endif
			echo Exiting wrapper...
			exit
		else if($saved_status > 32) then #status > 32, ERROR
			echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} 
			touch /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt
	                echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}  >> /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt
               		echo ERROR output to error log: /Volumes/tyto2/ErrorLogsTyto/errorlog_IRSAWrapper_${startTime}.txt
			if($rsyncSet == "true") then #rsync to other machines
	 	       	       #Transfer Tyto ErrorLogsTyto/ dir to Otus
               	 		echo rsync Tyto\'s /Volumes/tyto2/ErrorLogsTyto/ to Otus /Volumes/otus2/ErrorLogsTyto/
                		ssh ${user}@137.78.80.75 "mkdir -p /Volumes/otus2/ErrorLogsTyto/"
                		#rsync -avu /Volumes/tyto2/ErrorLogsTyto/ ${user}@137.78.80.75:/Volumes/otus2/ErrorLogsTyto/
	               	       #Transfer Tyto ErrorLogsTyto/ dir to Athene
        	        	echo rsync Tyto\'s /Volumes/tyto2/ErrorLogsTyto/ to Athene /Volumes/athene2/ErrorLogsTyto/ 
                		ssh ${user}@137.78.80.72 "mkdir -p /Volumes/athene2/ErrorLogsTyto/"
                		#rsync -avu  /Volumes/tyto2/ErrorLogsTyto/ ${user}@137.78.80.72:/Volumes/athene2/ErrorLogsTyto/ 
			endif
			echo Exiting wrapper...
			exit
		endif
	else if($currIP == "137.78.80.75") then  #Otus
		if($saved_status <= 32) then #status <= 32, WARNING
			echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} 
			touch /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
                	echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}  >> /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
               		echo WARNING output to error log: /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
	
			if($rsyncSet == "true") then #rsync to other machines
	                       #Transfer Otus ErrorLogsOtus/ dir to Tyto
       		         	echo rsync Otus\'s /Volumes/otus1/ErrorLogsOtus/ to Tyto /Volumes/tyto1/ErrorLogsOtus/
       		         	ssh ${user}@137.78.30.21 "mkdir -p /Volumes/tyto1/ErrorLogsOtus/"
               		 	#rsync -avu /Volumes/otus1/ErrorLogsOtus/ ${user}@137.78.30.21:/Volumes/tyto1/ErrorLogsOtus/
            	   	       #Transfer Otus ErrorLogsOtus/ dir to Athene
            	    		echo rsync Otus\'s /Volumes/otus1/ErrorLogsOtus/ to Athene /Volumes/athene1/ErrorLogsOtus/
               		 	ssh ${user}@137.78.80.72 "mkdir -p /Volumes/athene1/ErrorLogsOtus/"
                		#rsync -avu /Volumes/otus1/ErrorLogsOtus/ ${user}@137.78.80.72:/Volumes/athene1/ErrorLogsOtus/
			endif
			echo Exiting wrapper...
			exit
		else if($saved_status > 32) then #status > 32, ERROR
                        echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}
			touch /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
                        echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} >> /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
                        echo ERROR output to error log: /Volumes/otus1/ErrorLogsOtus/errorlog_IRSAWrapper_${startTime}.txt
			if($rsyncSet == "true") then #rsync to other machines
	                       #Transfer Otus ErrorLogsOtus/ dir to Tyto
       		         	echo rsync Otus\'s /Volumes/otus1/ErrorLogsOtus/ to Tyto /Volumes/tyto1/ErrorLogsOtus/
       		         	ssh ${user}@137.78.30.21 "mkdir -p /Volumes/tyto1/ErrorLogsOtus/"
               		 	#rsync -avu /Volumes/otus1/ErrorLogsOtus/ ${user}@137.78.30.21:/Volumes/tyto1/ErrorLogsOtus/
            	   	       #Transfer Otus ErrorLogsOtus/ dir to Athene
            	    		echo rsync Otus\'s /Volumes/otus1/ErrorLogsOtus/ to Athene /Volumes/athene1/ErrorLogsOtus/
               		 	ssh ${user}@137.78.80.72 "mkdir -p /Volumes/athene1/ErrorLogsOtus/"
                		#rsync -avu /Volumes/otus1/ErrorLogsOtus/ ${user}@137.78.80.72:/Volumes/athene1/ErrorLogsOtus/
			endif
			echo Exiting wrapper...
			exit
                endif
	else if($currIP == "137.78.80.72") then  #Athene
                if($saved_status <= 32) then #status <= 32, WARNING
                        echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}
			touch /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                        echo WARNING ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} >> /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                        echo WARNING output to error log: /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                	
			if($rsyncSet == "true") then #rsync to other machines
                 	       #Transfer Athene ErrorLogsAthene/ dir to Tyto
                      	  	echo rsync Athene\'s /Volumes/athene3/ErrorLogsAthene/ to Tyto /Volumes/CatWISE3/ErrorLogsAthene/
                        	ssh ${user}@137.78.30.21 "mkdir -p /Volumes/CatWISE3/ErrorLogsAthene/"
                        	#rsync -avu /Volumes/athene3/ErrorLogsAthene/ ${user}@137.78.30.21:/Volumes/CatWISE3/ErrorLogsAthene/
              	               #Transfer Athene ErrorLogsTyto/ dir to Otus
                        	echo rsync Athene\'s /Volumes/athene3/ErrorLogsAthene/ to Otus /Volumes/otus3/ErrorLogsAthene/
                        	ssh ${user}@137.78.80.72 "mkdir -p /Volumes/otus3/ErrorLogsAthene/"
                        	#rsync -avu /Volumes/athene3/ErrorLogsAthene/ ${user}@137.78.80.72:/Volumes/otus3/ErrorLogsAthene/
                	endif
			echo Exiting wrapper...
			exit
                else if($saved_status > 32) then #status > 32, ERROR
                        echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status}
			touch /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                        echo ERROR ${failedProgram} on tile \[$RadecID\] exited with status ${saved_status} >> /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                        echo ERROR output to error log: /Volumes/athene3/ErrorLogsAthene/errorlog_IRSAWrapper_${startTime}.txt
                	if($rsyncSet == "true") then #rsync to other machines
                 	       #Transfer Athene ErrorLogsAthene/ dir to Tyto
                      	  	echo rsync Athene\'s /Volumes/athene3/ErrorLogsAthene/ to Tyto /Volumes/CatWISE3/ErrorLogsAthene/
                        	ssh ${user}@137.78.30.21 "mkdir -p /Volumes/CatWISE3/ErrorLogsAthene/"
                        	#rsync -avu /Volumes/athene3/ErrorLogsAthene/ ${user}@137.78.30.21:/Volumes/CatWISE3/ErrorLogsAthene/
              	               #Transfer Athene ErrorLogsTyto/ dir to Otus
                        	echo rsync Athene\'s /Volumes/athene3/ErrorLogsAthene/ to Otus /Volumes/otus3/ErrorLogsAthene/
                        	ssh ${user}@137.78.80.72 "mkdir -p /Volumes/otus3/ErrorLogsAthene/"
                        	#rsync -avu /Volumes/athene3/ErrorLogsAthene/ ${user}@137.78.80.72:/Volumes/otus3/ErrorLogsAthene/
                	endif
			echo Exiting wrapper...
			exit
                endif
	endif
	goto Mode3_Done
