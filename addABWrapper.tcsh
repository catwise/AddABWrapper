#! /bin/tcsh -f 

set wrapperDir = $PWD
set startTime = `date +"%Y%m%d_%H%M%S"`
echo 
echo Wrapper Started at:
echo $startTime
echo
echo Version 1.71 Fixed Output paths
echo
echo This Wrapper will wrap around and run:
echo 1\) do-add-ab_flags
#TODO: Extensive Testing 
#6 tiles to test
#TODO: Fix mode to to parse out the input path per each tile
#TODO: change MDEX table to _af table

#check hyphenated argument
@ i = 0
set rsyncSet = "false"
set gsaSet = "false"
set withinMode2 = "false"  # Used to determine if mode 3 is being called within mode 2
while ($i < $# + 1)
     #user input nameslist -nl argument
      if("$argv[$i]" == "-rsync") then
        echo Argument "-rsync" detected. Will rsync Tyto, Otus, and Athene.
        set rsyncSet = "true"
      endif
      if("$argv[$i]" == "-gsa") then
        echo Argument "-gsa" detected. Will call gsa in do-ab_gsa.tcsh
        set gsaSet = "true"
      endif
      if("$argv[$i]" == "-withinMode2") then
        echo Argument "-withinMode2" detected. 
        set withinMode2 = "true"
	echo $withinMode2
      endif
      @ i +=  1
end

#check mode and input arguments 
if ($# < 7) then
        #Error handling
        #Too many or too little arguments       
        echo ""
        echo "ERROR: not enough arguments:"
        echo Mode 2 call:
        echo ./addABWrapper.tcsh 2 input_afList.txt \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>
        echo Mode 3 call:
        echo ./addABWrapper.tcsh 3 _afTile-file \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>
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
        set mdexInputPath = $4
        set af_InputPath = $5
        set msk_InputPath = $6
        set OutputPath = $7

        echo Inputs list ==  $InputsList
	echo versionID == $versionID
        echo Mdex Input Path == $mdexInputPath
        echo af Input Path == $af_InputPath
        echo msk Input Path == $msk_InputPath
        echo Output Path == $OutputPath
        echo

        #if directories dont exist, throw error
        if(! -f $InputsList) then
                echo ERROR: Input List file $InputsList does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $mdexInputPath) then
                echo ERROR: Input Path directory $mdexInputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $af_InputPath) then
                echo ERROR: Input Path directory $af_InputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $msk_InputPath) then
                echo ERROR: Input Path directory $msk_InputPath does not exist.
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
        set mdexInputPath = $4
        set af_InputPath = $5
        set msk_InputPath = $6
        set OutputPath = $7
	

        echo Input _af Table name == $InputTable  # This is the input _af table name
        echo versionID == $versionID
        echo Mdex Input Path == $mdexInputPath
        echo af Input Path == $af_InputPath
        echo msk Input Path == $msk_InputPath
        echo Output Path == $OutputPath

        #if directories dont exist, throw error
        if(! -d $af_InputPath) then
                echo ERROR: Input Path directory $af_InputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
	if($withinMode2 == "true") then
	echo "-withinMode2 set, running"
	echo $withinMode2
        	if(! -f $InputTable) then
			echo
                	echo ERROR: $InputTable doest not exist.
                	echo
                	echo Exiting...
                	exit
        	endif
	else
	echo "-withinMode2 NOT set, NOT running"
        	if(! -f $af_InputPath/$InputTable) then
			echo
                	echo ERROR: $af_InputPath/$InputTable doest not exist.
                	echo
                	echo Exiting...
                	exit
        	else
			set InputTable = $af_InputPath/$InputTable
			echo NEW Input _af Table name == $InputTable
		endif

	endif
        if(! -d $mdexInputPath) then
                echo ERROR: Input Path directory $mdexInputPath does not exist.
                echo
                echo Exiting...
                exit
        endif
        if(! -d $msk_InputPath) then
                echo ERROR: Input Path directory $msk_InputPath does not exist.
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
        echo ./addABWrapper.tcsh 2 inputList.txt \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>
        echo Mode 3 call:
        echo ./addABWrapper.tcsh 3 _afTile-file \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>
	echo
        echo Exiting...
	exit
endif

#==============================================================================================================================

Mode2:
    
    foreach table (`cat $InputsList`)    
        echo ===================================== - START AddABWrapper wrapper loop iteration - ======================================
     
        echo "Current input MDEXTable == "${table}
        echo Calling addABWrapper.tcsh Mode3 on ${table}\: 
	if($gsaSet == "true") then
		if($rsyncSet == "true") then
			echo "${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -rsync -gsa -withinMode2"
			(echo y | ${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -rsync -gsa \
				-withinMode2) &
		else
			echo "${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -gsa -withinMode2"
			(echo y | ${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -gsa -withinMode2) &
		endif
	else
		if($rsyncSet == "true") then
			echo "${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -rsync -withinMode2"
			(echo y | ${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -rsync -withinMode2) &
		else
			echo "${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -withinMode2"
			(echo y | ${wrapperDir}/addABWrapper.tcsh 3 $af_InputPath/$table $versionID $mdexInputPath $af_InputPath $msk_InputPath $OutputPath -withinMode2) &
		endif
	
	endif
	
	set maxInParallel = 12
        if(`ps -ef | grep addABWrapper | wc -l` > $maxInParallel + 1) then
                echo  More than $maxInParallel AddABWrapper processes, waiting...
                while(`ps -ef | grep addABWrapper | wc -l` > $maxInParallel + 1)
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
       ###Given afTableName == /path/1497p015_opt1_20180609_083107.tbl.gz,
        set afTableName = $InputTable 
	set tempSize = `basename $afTableName  | awk '{print length($0)}'`
        @ tempIndex = ($tempSize - 3 - 4) 
       ### tempIndex = filesize - sizeof(".gz") - sizeof(".tbl")

       ### Given afTableName = 		1497p015_opt1_20180609_083107.tbl.gz,
       ###  edited_afTableName = 	1497p015_opt1_20180609_083107
       ###  edited_afTableNamePATH =	# full path that the afTable resides in
       ###  RadecID = 			1497015
       ###  RestOfTablename = 		_opt1_20180609_083107
        set edited_afTableName = `basename $afTableName | awk -v endIndex=$tempIndex '{print substr($0,0,endIndex)}'`
        set edit_afTableNamePATH = $af_InputPath
	set edited_afTableNamePATH = `cd $edit_afTableNamePATH && pwd`
	set RadecID = `basename $afTableName | awk '{print substr($0,0,8)}'`
        ### tempIndex = tempIndex - sizeof($RadecID) - sizeof("_af")
	@ tempIndex = ($tempIndex - 8 - 3)
	set RestOfTablename = `basename $afTableName | awk -v endIndex=$tempIndex '{print substr($0,9,endIndex)}'` 


	set originalMdexTable = ${OutputPath}/${RadecID}${RestOfTablename}.tbl
	set originalafTable = ${OutputPath}/${edited_afTableName}.tbl 
	echo "__________________________________________________________________________________________________"
        echo "Current input afTable = "$afTableName
        echo "Edited_Current input afTable = "$originalafTable
        echo "RadecID = "$RadecID
	echo "RestOfTablename = "$RestOfTablename
	echo "versionID = "${versionID}
	echo "mdexInputPath = "${mdexInputPath}
	echo "af_InputPath = "${af_InputPath}
	echo "msk_InputPath = "${msk_InputPath}
	echo "OutputPath  = "${OutputPath}
	echo "originalMdexTable = ${originalMdexTable}"
	echo "__________________________________________________________________________________________________\n"
	
	#TODO December 20 11:18 look at the mdex logic
	#TODO rename afTableName to afTable
	echo Unzipping ${afTableName} to ${originalafTable}
	gunzip -f -c -k ${afTableName} > ${originalafTable}  # Unzip _af file

	echo Unzipping ${mdexInputPath}/${RadecID}${RestOfTablename}.tbl.gz to ${originalMdexTable}
	gunzip -f -c -k ${mdexInputPath}/${RadecID}${RestOfTablename}.tbl.gz > ${originalMdexTable}  # Unzip mdex file
	set saved_status = $? #Error Checking
       ### check exit status
        echo gunzip saved_status == ${saved_status}
        if($saved_status != 0) then #if program failed, status != 0
                echo Failure detected on tile ${RadecID}
                set failedProgram = "gunzip"
                goto Failed
        endif
	echo


       ### John Fowler's Single Tile program
	echo Preparing inputs \$8 \(-n-m files path\) and \$9\(temp2 files path\) for do-ab.tcsh
	set ra = `echo ${RadecID} | awk '{print substr($0,0,3)}'`
	echo ra == $ra

	set n_m_path = ""
	set temp2_path = ""  
	set currIP = `dig +short myip.opendns.com @resolver1.opendns.com`
        echo current IP = $currIP
        if($currIP == "137.78.30.21") then #Tyto
        	set n_m_path = "/Volumes/tyto2/UnWISE/${ra}/${RadecID}"
		set temp2_path = "/Volumes/tyto1/Ab_files_v1"
        else if($currIP == "137.78.80.75") then  #Otus
        	set n_m_path = "/Volumes/otus1/UnWISE/${ra}/${RadecID}"
		set temp2_path = "/Volumes/otus5/Ab_files_v1"
	else if($currIP == "137.78.80.72") then #Athene
        	set n_m_path = "/Volumes/athene3/UnWISE/${ra}/${RadecID}"
		set temp2_path = "/Volumes/athene5/Ab_files_v1"
	endif
	echo "n_m_path = "${n_m_path}
	echo "temp2_path ="${temp2_path}

	if($gsaSet == "true") then

        	### Program call
		echo John Fowler Program call:
      		echo "${wrapperDir}/do-ab_gsa.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path} \n" 
		${wrapperDir}/do-ab_gsa.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path}
	else
        	### Program call
		echo John Fowler Program call:
      		echo "${wrapperDir}/do-ab_NOgsa.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path} \n" 
		${wrapperDir}/do-ab_NOgsa.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path}
	endif
	set saved_status = $? 
	#check exit status
	echo stils saved_status == $saved_status 
	if($saved_status != 0) then #if program failed, status != 0
		echo Failure detected on tile $RadecID
		set failedProgram = "do-add-ab_flags.tcsh"
		goto Failed
	endif
	echo

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
echo DONE. Output: ${edited_afTableNamePATH}/${edited_afTableName}_ab.tbl 
echo AddABWrapper on ${RadecID} Mode: ${1} Done
set endTime = `date '+%m/%d/%Y %H:%M:%S'`
echo "rm  ${originalafTable}"
echo "rm  ${originalMdexTable}"
#rm af file and rm original mdex table
rm  ${originalafTable}
rm  ${originalMdexTable}
#TODO:
# change arguments to 3 input directories:
# ab_masks, af, mdex tables,
# these 3 types of tiles in different directories
# ab, af, mdex
echo
       #rsync step
	if($rsyncSet == "true") then
       #rsync output dir from Current server to other 2 servers (Tyto, Otus, Athene)
	set CatWISEDir = ${OutputPath}
        echo running rsync on tile $RadecID
        set currIP = `dig +short myip.opendns.com @resolver1.opendns.com`
        echo current IP = $currIP
        if($currIP == "137.78.30.21") then #Tyto
                set otus_CatWISEDir = `echo $CatWISEDir | sed 's/tyto1/otus5/g'`
                set athene_CatWISEDir = `echo $CatWISEDir | sed 's/tyto1/athene5/g'`
                echo You are on Tyto!

               #Transfer Tyto CatWISE/ dir to Otus
                echo rsync Tyto\'s $CatWISEDir ${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Otus $otus_CatWISEDir
                ssh ${user}@137.78.80.75 "mkdir -p $otus_CatWISEDir"
                rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$otus_CatWISEDir

               #Transfer Tyto CatWISE/ dir to Athene
                echo rsync Tyto\'s $CatWISEDir ${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Athene $athene_CatWISEDir
                ssh ${user}@137.78.80.72 "mkdir -p $athene_CatWISEDir"
                rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$athene_CatWISEDir


        else if($currIP == "137.78.80.75") then  #Otus
                set tyto_CatWISEDir = `echo $CatWISEDir | sed 's/otus5/tyto1/g'`
                set athene_CatWISEDir = `echo $CatWISEDir | sed 's/otus5/athene5/g'`
                echo You are on Otus!

               #Transfer Otus CatWISE/ dir to Tyto
                echo rsync Otus\'s $CatWISEDir${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Tyto $tyto_CatWISEDir
                ssh ${user}@137.78.30.21 "mkdir -p $tyto_CatWISEDir"
                rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$tyto_CatWISEDir

               #Transfer Otus CatWISE/ to Athene
                echo rsync Otus\'s $CatWISEDir ${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Athene $athene_CatWISEDir
                ssh ${user}@137.78.80.72 "mkdir -p $athene_CatWISEDir"
                rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$athene_CatWISEDir


        else if($currIP == "137.78.80.72") then #Athene
                set tyto_CatWISEDir = `echo $CatWISEDir | sed 's/athene5/tyto1/g'`
                set otus_CatWISEDir = `echo $CatWISEDir | sed 's/athene5/otus5/g'`
                echo You are on Athene!
               
	       #Transfer to Tyto
                echo rsync Athene\'s $CatWISEDir ${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Tyto $tyto_CatWISEDir
		ssh ${user}@137.78.30.21 "mkdir -p $tyto_CatWISEDir"
		rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$tyto_CatWISEDir

               #Transfer to Otus
                echo rsync Athene\'s $CatWISEDir ${RadecID}${RestOfTablename}_ab.tbl.gz, gsa-${RadecID}-af.txt, unwise-${RadecID}-msk.fit to Otus $otus_CatWISEDir
                ssh ${user}@137.78.80.75 "mkdir -p $otus_CatWISEDir"
                rsync -avur $CatWISEDir/ ${user}@137.78.80.75:$otus_CatWISEDir
        endif
        endif


echo
echo Wrapper Mode: ${1} Ended at:
echo $endTime
exit


#TODO save some lines! Simply set a variable == WARNING or ERROR. Then just do the same for both case (theres no need for that huge repeat) 
#program jumps here if a program returns an exit status 32(Warning) or 64(Error)
	######TODO: reduce redundencies in code
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
