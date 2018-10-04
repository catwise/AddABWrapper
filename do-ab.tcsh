#! /bin/tcsh -f

set ra = `echo $1 | awk '{print substr($0,0,3)}'`
echo ra == $ra
gunzip -f -c -k $6/$ra/unwise-$1-msk.fits.gz > $7/unwise-$1-msk.fits 
/Users/CatWISE/GSAdir/GSA/gsa -t $4/$1$2.tbl -t $5/$1$2_af.tbl -ra1 ra -ra2 ra_1 -dec1 dec -dec2 dec_1 -r 1.00 -aa -o $7/$1-temp1.tbl -cw -nm2 > $7/gsa-$1-af.txt
 
head -25 $5/$1$2_af.tbl > $7/$1-header-tmp.txt
 
cat $7/$1-header-tmp.txt $7/$1-temp1.tbl > $7/$1-temp2.tbl
 
/Users/CatWISE/AddABflags/Add-ab_flags/add-ab_flags -i $7/$1-temp2.tbl -m $7/unwise-$1-msk.fits -o $7/$1$2_ab_$3.tbl > $7/ab-$1_$3.txt
 
rm $7/$1-temp1.tbl
rm $7/$1-temp2.tbl
rm $7/$1-header-tmp.txt
rm $7/unwise-$1-msk.fits
gzip -f $7/$1$2_ab_$3.tbl
