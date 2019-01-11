#! /bin/tcsh -f

#$1 = tile ID
#$2 = option and time stamp
#$3 = input mdex table
#$4 = input af table
#$5 = version ID
#$6 = mdex input path
#$7 = af input path
#$8 = msk input path
#$9 = output path
#$10 = n-m path
#$11 = temp2 path - not needed for this version

set TileID = $1
set RestOfTablename = $2
set mdexTable = $3
set afTable = $4
set versionID = $5
set mdexInputPath = $6
set afInputPath = $7
set mskInputPath = $8
set outputPath = $9
set nmPath = $10
#set temp2Path = $11

set ra = `echo $TileID | awk '{print substr($0,0,3)}'`
echo ra == $ra
  # example call: 
  # ./do-ab.tcsh ${RadecID} ${mdexTable} ${afTable} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path}


gunzip -f -c -k $mskInputPath/$ra/unwise-$TileID-msk.fits.gz > $outputPath/unwise-$TileID-msk.fits 
gunzip -f -c -k $nmPath/unwise-$TileID-w1-n-m.fits.gz > $outputPath/unwise-$TileID-w1-n-m.fits 
gunzip -f -c -k $nmPath/unwise-$TileID-w2-n-m.fits.gz > $outputPath/unwise-$TileID-w2-n-m.fits
#gunzip -f -c -k $9/$1-temp2.tbl.gz > $9/$1$2-temp2.tbl

/Users/CatWISE/GSAdir/GSA/gsa -td $outputPath -t $mdexTable -t $afTable -ra1 ra -ra2 ra_1 -dec1 dec -dec2 dec_1 -r 20 -aa -o $outputPath/$TileID$RestOfTablename-temp1.tbl -cw -nm2 -ns2 -rf2 $outputPath/$TileID$RestOfTablename-cc-unmatched.tbl > $outputPath/gsa-$TileID$RestOfTablename-af.txt
head -25 $afTable > $outputPath/$TileID$RestOfTablename-header-tmp.txt
head -1 $mdexTable > $outputPath/$TileID$RestOfTablename-header-mdex.txt
cat $outputPath/$TileID$RestOfTablename-header-mdex.txt $outputPath/$TileID$RestOfTablename-header-tmp.txt $outputPath/$TileID$RestOfTablename-temp1.tbl > $outputPath/$TileID$RestOfTablename-temp2.tbl
 
mkdir -p $outputPath/add-ab_flags_stdout/
echo "/Users/CatWISE/AddABflags/Add-ab_flags/add-ab_flags -i $outputPath/$TileID$RestOfTablename-temp2.tbl -m $outputPath/unwise-$TileID-msk.fits -o $outputPath/$TileID${RestOfTablename}_ab_$versionID.tbl -n1 $outputPath/unwise-$TileID-w1-n-m.fits -n2 $outputPath/unwise-$TileID-w2-n-m.fits > $outputPath/add-ab_flags_stdout/ab-$TileID${RestOfTablename}_$versionID.txt"
/Users/CatWISE/AddABflags/Add-ab_flags/add-ab_flags -i $outputPath/$TileID$RestOfTablename-temp2.tbl -m $outputPath/unwise-$TileID-msk.fits -o $outputPath/$TileID${RestOfTablename}_ab_$versionID.tbl -n1 $outputPath/unwise-$TileID-w1-n-m.fits -n2 $outputPath/unwise-$TileID-w2-n-m.fits > $outputPath/add-ab_flags_stdout/ab-$TileID${RestOfTablename}_$versionID.txt

 
rm $outputPath/$TileID$RestOfTablename-temp1.tbl
rm $outputPath/$TileID$RestOfTablename-temp2.tbl
rm $outputPath/$TileID$RestOfTablename-header-tmp.txt
rm $outputPath/$TileID$RestOfTablename-header-mdex.txt
rm $outputPath/unwise-$TileID-msk.fits
rm $outputPath/unwise-$TileID-w1-n-m.fits
rm $outputPath/unwise-$TileID-w2-n-m.fits
gzip -f $outputPath/$TileID${RestOfTablename}_ab_$versionID.tbl
