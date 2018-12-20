#! /bin/tcsh -f

set ra = `echo $1 | awk '{print substr($0,0,3)}'`
echo ra == $ra
#example call: 
#./do-ab.tcsh ${RadecID} ${RestOfTablename} ${versionID} ${mdexInputPath} ${af_InputPath} ${msk_InputPath} ${OutputPath} ${n_m_path} ${temp2_path}


gunzip -f -c -k $6/$ra/unwise-$1-msk.fits.gz > $7/unwise-$1-msk.fits 
gunzip -f -c -k $8/unwise-$1-w1-n-m.fits.gz > $7/unwise-$1-w1-n-m.fits 
gunzip -f -c -k $8/unwise-$1-w2-n-m.fits.gz > $7/unwise-$1-w2-n-m.fits
gunzip -f -c -k $9/$1-temp2.tbl.gz > $9/$1$2-temp2.tbl

echo NOTICE: SKIPPING gsa call!

mkdir -p $7/add-ab_flags_stdout/
echo "/Users/CatWISE/AddABflags/Add-ab_flags/add-ab_flags -i $9/$1$2-temp2.tbl -m $7/unwise-$1-msk.fits -o $7/$1$2_ab_$3.tbl -n1 $8/unwise-$1-w1-n-m.fits -n2 $8/unwise-$1-w2-n-m.fits > $7/add-ab_flags_stdout/ab-$1$2_$3.txt"
/Users/CatWISE/AddABflags/Add-ab_flags/add-ab_flags -i $9/$1$2-temp2.tbl -m $7/unwise-$1-msk.fits -o $7/$1$2_ab_$3.tbl -n1 $7/unwise-$1-w1-n-m.fits -n2 $7/unwise-$1-w2-n-m.fits > $7/add-ab_flags_stdout/ab-$1$2_$3.txt

 
rm $9/$1$2-temp2.tbl
rm $7/$1$2-header-tmp.txt
rm $7/unwise-$1-msk.fits
rm $7/unwise-$1-w1-n-m.fits
rm $7/unwise-$1-w2-n-m.fits
gzip -f $7/$1$2_ab_$3.tbl
