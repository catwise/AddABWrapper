#! /bin/tcsh -f
#/Volumes/CatWISE1/jwf/bin/gsa -t $4/$1$2.tbl -t $4/$1$2_af.tbl -ra1 ra -ra2 ra_1 -dec1 dec -dec2 dec_1 -r 1 -aa -o $5/$1-temp1.tbl -cw > $5/gsa-$1-af.txt
echo "/Volumes/CatWISE1/jwf/bin/gsa -t $4/$1$2.tbl -t $4/$1$2_af.tbl -ra1 ra -ra2 ra_1 -dec1 dec -dec2 dec_1 -r 1 -aa -o $5/$1-temp1.tbl -cw > $5/gsa-$1-af.txt"

#head -25 $4/$1$2_af.tbl > $5/$1-header-tmp.txt
echo "head -25 $4/$1$2_af.tbl > $5/$1-header-tmp.txt"

#cat $5/$1-header-tmp.txt $5/$1-temp1.tbl > $5/$1-temp2.tbl
echo "cat $5/$1-header-tmp.txt $5/$1-temp1.tbl > $5/$1-temp2.tbl"

#/Volumes/CatWISE1/jwf/bin/add-ab_flags -i $5/$1-temp2.tbl -m $4/unwise-$1-msk.fits -o $5/$1$2_ab_$3.tbl -d > $5/ab-$1_$3.txt
echo "/Volumes/CatWISE1/jwf/bin/add-ab_flags -i $5/$1-temp2.tbl -m $4/unwise-$1-msk.fits -o $5/$1$2_ab_$3.tbl -d > $5/ab-$1_$3.txt"

#rm $5/$1-temp1.tbl
#rm $5/$1-temp2.tbl
#rm $5/$1-header-tmp.txt
echo "rm $5/$1-temp1.tbl"
echo "rm $5/$1-temp2.tbl"
echo "rm $5/$1-header-tmp.txt"
