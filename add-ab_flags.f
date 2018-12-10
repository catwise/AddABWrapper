c   add-ab_flags  cloned from add-msk-col
c   add-msk-col - cloned from SampleCols & add-opt1-cols
c                 add msk column to an mdex filelumns for PowerSpectrum
c
c vsn 1.0  B80810: initial version
c     1.1  B80813: switched to 32-bit mask image (from 16-bit)
c     1.2  B80814: added processing of bits 21 and 22
c     1.3  B80816: added translation of mask bits to cc_flags;
c                  changed name to add-cc_flags
c     1.4  B80822: changed initial tagging from DPHO to dpho
c     1.5  B80824: added halo bits tot he processing
c     1.6  B80904: changed name to add-ab_flags; added special
c                  processing for the "_af" mdex format
c     1.6  B80913: added command-line flags
c     1.6  B80914: added multi-match processing
c     1.6  B80916: fixed cc_flags symbol priority
c     1.6  B80920: separated parent-star-pixel bit clearing by band
c     1.7  B80925: added geometric diffraction spike bits
c     1.8  B80926: major changes to accommodate mrgad not averaging
c                  w?x and w?y
c     1.8  B80930: added file output to warn if nSrc mismatch
c     1.9  B81005: added alarm/band-aid fix for NaNs in w?mpro &c.
c     1.91 B81005: added counters for NaN combinations
c     1.92 B81101: added option to recompute magnitudes from fluxes
c     1.93 B81103: addedmany debug checkpoints to trace NaNs
c     1.94 B81105: removed NaN debugging and band0aid NaN fix
c     1.95 B81106: added "pipe" table header conversion to "double" for
c                  ra, dec, MJDs, elon, & elat
c     1.96 B81120: installed mag upper limit logic
c     1.97 B81207: restored 4-band cc_flags; added w?sat processing and
c                  w?mcor values
c     1.98 B81210: installed w?sat & w?cov processing
c
c=======================================================================
c
                     Integer*4  MaxFld
                     Parameter (MaxFld = 1000)
c
      character*150000 Hfits
      Character*5000 Line, HdrLine
      Character*500  InFNam, MskNam, OutFNam, NLNam, Cov1Nam, Cov2Nam
      Character*50   w1cc_map_str, w2cc_map_str, cc_flags, w1cc_map,
     +               w2cc_map, dist_str
      Character*25   Field(MaxFld)
      Character*13   w1ab_map_str, w2ab_map_str
      Character*11   Vsn, NumStr
      Character*9    ab_flags, w1ab_map, w2ab_map
      Character*8    CDate, CTime
      Character*5    nAWstr
      Character*3    Flag, Flag0
      Character*1    w3cc, w4cc, w3cc2, w4cc2
      Real *8        ra, dec, x8, y8, flux, sigflux, mag, sigmag,
     +               w1m0, w2m0, CoefMag, wsnr
      Real*4         w1x, w2x, w1y, w2y, dist, dist2, w1mcor, w2mcor,
     +               wsat, wcov
      Integer*4      IArgC, LNBlnk, FileID1, nHead, MskBitHist(32), msk,
     +               NPlanes, NRows, NCols, I, J, N, IStat, NpixPL, k,
     +               NPix, status, nSrc, IFa(MaxFld), IFb(MaxFld), NF,
     +               w1abmap, w2abmap, w1ccmap, w2ccmap, notZero, nMag,
     +               nSrcHdr, nAW, w1ccmap2, w2ccmap2, IOr, nArg, nArgs,
     +               nw394, nw395, nw396, nw397, nw398, nw385, wcs,
     +               offscl, nNaN, nn11, nn12, nn21, nn22, kBadw3,
     +               kBadw4, kBad2w3, kBad2w4, kBadness, i1PSF, j1PSF,
     +               iPix, jPix, nPSF, i2PSF, j2PSF, n1Sat, n2Sat,
     +               n1Cov, n2Cov
      Logical*4      NeedHelp, anynull, SanityChk, GoodXY1, GoodXY2,
     +               BitSet, dbg, OKhdr, useWCS, NaNwarn, NaNstat1,
     +               NaNpm1, NaNstat2, NaNpm2, doMags, doCov, GotN1,
     +               GotN2
      Integer*4      nullval
      Integer*4, allocatable :: array1(:,:)
      Integer*2      cov1(2048,2048), cov2(2048,2048)
c
      Data Vsn/'1.98 B81210'/, nSrc/0/, nHead/0/, SanityChk/.true./,
     +     doMags/.true./, useWCS/.true./, NaNwarn/.false./,
     +     nn11,nn12,nn21,nn22/4*0/, w1m0,w2m0/2*22.5/, nPSF/2/,
     +     NeedHelp/.False./, MskBitHist/32*0/, dbg/.false./,
     +     notZero/0/, CoefMag/1.085736205d0/, w1mcor/0.145/,
     +     w2mcor/0.177/, kBadw3,kBadw4,kBad2w3,kBad2w4/4*0/,
     +     doCov/.true./, GotN1,GotN2/2*.false./
c
      Common / VDT / CDate, CTime, Vsn
c
      namelist / abflagin / doCov, doMags, nPSF, w1m0, w1mcor,
     +                      w2m0, w2mcor
c
c=======================================================================
c
      nArgs = IArgc()
      NeedHelp = (nArgs .lt. 6)
1     If (NeedHelp) then
        print *,'add-ab_flags vsn ', Vsn
        print *

        print *,'Usage: add-ab_flags <flags specifications>'
        print *
        print *,'Where the REQUIRED flags and specifications are:'
        print *,
     +   '    -i  name of a gsa-matched mdex/CatWISE-IRSA-matched file'
        print *,'    -m  name of a CatWISE mask FITS file'
        print *,
     +   '    -o  name of the output CatWISE mdex file with ab_flags'
     +             //' columns'
        print *,'        appended; this file must not already exist'
        print *
        print *,'The OPTIONAL flags are:'
        print *,'    -n1 name of a W1 "-n-" coverage image'
        print *,'    -n2 name of a W2 "-n-" coverage image'
        print *,'    -n  name of an abflagin namelist file'
        print *,'    -d  (enable debug mode)'
        Print *
        print *,
     +  'If either "-n1" or "-n2" is specified, the other must also be.'
        stop
      end if
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
      call signon('add-ab_flags')
c
      NArg = 0
2     NArg = NArg + 1
      call GetArg(NArg,Flag)
      Flag0 = Flag
      call UpCase(Flag)
c                                      ! input CatWISE/IRSA file
      If (Flag .eq. '-I') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,InFNam)
        if (Access(InFNam(1:LNBlnk(InFNam)),' ') .ne. 0) then
          print *
          print *,'ERROR: file not found: ', InFNam(1:LNBlnk(InFNam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
c                                      ! Turn debug prints on
      else if (Flag .eq. '-D') then
        dbg = .true.
        print *,'Debug prints enabled'
c
      else if (Flag .eq. '-M') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,MskNam)
        if (Index(MskNam,'.fits') .eq. 0)
     +    MskNam = MskNam(1:LNBlnk(MskNam))//'.fits'
        if (Access(MskNam(1:LNBlnk(MskNam)),' ') .ne. 0) then
          print *
          print *,'ERROR: File not found: ', MskNam(1:LNBlnk(MskNam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
c
      else if (Flag .eq. '-N1') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,Cov1Nam)
        if (Index(Cov1Nam,'.fits') .eq. 0)
     +    Cov1Nam = Cov1Nam(1:LNBlnk(Cov1Nam))//'.fits'
        if (Access(Cov1Nam(1:LNBlnk(Cov1Nam)),' ') .ne. 0) then
          print *
          print *,'ERROR: File not found: ', Cov1Nam(1:LNBlnk(Cov1Nam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
        GotN1 = .true.
c
      else if (Flag .eq. '-N2') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,Cov2Nam)
        if (Index(Cov2Nam,'.fits') .eq. 0)
     +    Cov2Nam = Cov2Nam(1:LNBlnk(Cov2Nam))//'.fits'
        if (Access(Cov2Nam(1:LNBlnk(Cov2Nam)),' ') .ne. 0) then
          print *
          print *,'ERROR: File not found: ', Cov2Nam(1:LNBlnk(Cov2Nam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
        GotN2 = .true.
      else if (Flag .eq. '-O') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,OutFNam)
        if (Index(OutFNam,'.tbl') .eq. 0)
     +    OutFNam = OutFNam(1:LNBlnk(OutFNam))//'.tbl'
        if (Access(OutFNam(1:LNBlnk(OutFNam)),' ') .eq. 0) then
          print *
          print *,'ERROR: Output file already exists: ', 
     +             OutFNam(1:LNBlnk(OutFNam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
      else if (Flag .eq. '-N') then
        call NextNarg(NArg,Nargs)
        Call GetArg(NArg,NLNam)
        if (Access(NLNam(1:LNBlnk(NLNam)),' ') .ne. 0) then
          print *
          print *,'ERROR: File not found: ', NLNam(1:LNBlnk(NLNam))
          print *
          NeedHelp = .True.
          Go to 1
        end if
        open(10, file = NLnam)
        read(10, abflagin, end = 3017, err = 3018)
        write (6, abflagin)
        close(10)
      Else
        print *,'ERROR: unrecognized command-line specification: '
     +          //Flag0
      end if
c 
      If (NArg .lt. NArgs) Go to 2
      DoCov = DoCov .and. GotN1 .and. GotN2
      if ((GotN1 .or. GotN2) .and. .not.DoCov) then
        print *,
     +   'WARNING: "-n1" and/or "-n2" specified, but either DoCov = F'
        print *,
     +   'in namelist or only one coverage image specified;'
        print *,'coverage image(s) ignored.'
      end if
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! open the mask file and read in
      call readFhead(MskNam,Hfits)
      Call GetNAX(MskNam,NCols,NRows,NPlanes,1,FileID1)
      if (dbg) print *,'GetNAX returned NCols,NRows,NPlanes,FileID1:',
     +         NCols,NRows,NPlanes,FileID1 ! dbg
      if (NPlanes .ne. 1) then
         print *,'ERROR: this program handles only 2-dimensional images'
         stop
      end if 
c      
      wcs = -1
      call wcsinit(Hfits,WCS)
c     if (wcs .le. 0) then
c       print *,'ERROR: file has no usable WCS - ',
c    +           MskNam(1:lnblnk(MskNam))
c       useWCS = .false.
c     end if
c
      allocate(array1(NCols,NRows))
      if (.not.allocated(array1)) then
        print *,'ERROR: allocation of array1 failed for NAXIS1 = ',NCols,
     +           ', NAXIS2 = ',NRows
        call exit(64)
      end if
c     print *,'array1 allocated successfully'        ! dbg
      NPixpL = NCols*NRows
c        
      NPix = NPixpL*NPlanes
      status = 0
      call ftgpvj(FileID1,1,1,NPix,nullval,array1,anynull,status)
      if (status .ne. 0) then
        print *,'ERROR reading file1; status = ',status
        stop
      end if
c     print *,'ftgpvj returned ',NPix,' pixels for file1'              ! dbg
      status = 0
c
C  The FITS file must always be closed before exiting the program. 
C  Any unit numbers allocated with FTGIOU must be freed with FTFIOU.
      call ftclos(FileID1, status)
      call ftfiou(FileID1, status)
      if (dbg) then
        do 4 j = 1, 2048
          do 3 i = 1, 2048
            if (array1(i,j) .ne. 0) notZero = notZero + 1
3         continue
4       continue
        print *,'No. of nonzero mask pixels: ',notZero,
     +          '; fraction = ',float(notZero)/16793604.0
      end if
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! read in the W1 coverage file
      call readFhead(Cov1Nam,Hfits)
      Call GetNAX(Cov1Nam,NCols,NRows,NPlanes,1,FileID1)
      if (dbg) print *,
     +        'Cov1 - GetNAX returned NCols,NRows,NPlanes,FileID1:',
     +         NCols,NRows,NPlanes,FileID1 ! dbg
      if (NPlanes .ne. 1) then
         print *,'ERROR: this program handles only 2-dimensional images'
         stop
      end if 
c
      NPix = NCols*NRows
      status = 0
      call ftgpvi(FileID1,1,1,NPix,nullval,Cov1,anynull,status)
      if (status .ne. 0) then
        print *,'ERROR reading Cov1; status = ',status
        stop
      end if
      status = 0
      call ftclos(FileID1, status)
      call ftfiou(FileID1, status)
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! read in the W2 coverage file
      call readFhead(Cov2Nam,Hfits)
      Call GetNAX(Cov2Nam,NCols,NRows,NPlanes,1,FileID1)
      if (dbg) print *,
     +        'Cov2 - GetNAX returned NCols,NRows,NPlanes,FileID1:',
     +         NCols,NRows,NPlanes,FileID1 ! dbg
      if (NPlanes .ne. 1) then
         print *,'ERROR: this program handles only 2-dimensional images'
         stop
      end if 
c
      NPix = NCols*NRows
      status = 0
      call ftgpvi(FileID1,1,1,NPix,nullval,Cov2,anynull,status)
      if (status .ne. 0) then
        print *,'ERROR reading Cov2; status = ',status
        stop
      end if
      status = 0
      call ftclos(FileID1, status)
      call ftfiou(FileID1, status)
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! Sanity Check
      open (10, file = InFNam)
5     read (10,'(a)', end = 3000) Line
      if (Line(1:1) .eq. '\') go to 5
      call GetFlds(Line,Field,IFa,IFb,NF)
      HdrLine = Line
      rewind(10)
c
      if (SanityChk) then
        if (NF .ne. 401) then
          print *,'ERROR: input is not a two-band wphot mdex file'
          print *,'       no. of fields =', NF,'; should be 401'
          call exit(64)
        end if
c                                      ! verify some fields in mdex file
        call ChkFld(Field(3), 'ra',3)
        call ChkFld(Field(4), 'dec',4)
        call ChkFld(Field(5), 'sigra',5)
        call ChkFld(Field(6), 'sigdec',6)
        call ChkFld(Field(7), 'sigradec',7)
        call ChkFld(Field(8), 'w1x',8)
        call ChkFld(Field(9), 'w1y',9)
        call ChkFld(Field(10),'w2x',10)
        call ChkFld(Field(11),'w2y',11)
      end if
c
      open(20, file = OutFNam)
      nw385 = IFb(385) - IFa(385) + 1  ! dist_x
      nw394 = IFb(394) - IFa(394) + 1  ! cc_flags
      nw395 = IFb(395) - IFa(395) + 1  ! w1cc_map
      nw396 = IFb(396) - IFa(396) + 1  ! w1cc_map_str
      nw397 = IFb(397) - IFa(397) + 1  ! w2cc_map
      nw398 = IFb(398) - IFa(398) + 1  ! w2cc_map_str
      if (dbg) then
        print *,'dist_x       field width:', nw385
        print *,'cc_flags     field width:', nw394
        print *,'w1cc_map     field width:', nw395
        print *,'w1cc_map_str field width:', nw396
        print *,'w2cc_map     field width:', nw397
        print *,'w2cc_map_str field width:', nw398
      end if
c                                      ! filter out unwanted header lines
10    read (10, '(a)', end=1000) Line
      if (Line(1:1) .eq. '\') then
        if (OKhdr(Line)) write(20,'(a)') Line(1:lnblnk(Line))
        if (index(Line,'\Nsrc =') .gt. 0) then
          n = index(Line,'=') + 1
          read (Line(n:lnblnk(Line)), *, err = 3002) nSrcHdr
        end if
        if (index(Line,'\DATETIME =') .gt. 0) then
          n = index(Line,'"') + 1
          Line = '\ AllWISE flags retrieved from IRSA using 2.75'
     +         //' arcsec radius on '//Line(n:n+18)
          write(20,'(a)') Line(1:lnblnk(Line))
        end if
        go to 10
      end if
      if (Line(1:1) .eq. '|') then
        Line =    Line(1:Ifb(191))//Line(IFa(385):IFb(385))
     +   //Line(IFa(394):IFb(398))//'|'
        nHead = nHead + 1
        if (nHead .eq. 1) then
          Line = Line(1:lnblnk(Line))
     +   //'n_aw|ab_flags|w1ab_map|w1ab_map_str|w2ab_map|w2ab_map_str|'
          write(20,'(a)') Line(1:lnblnk(Line))
          HdrLine = Line
        end if
        if (nHead .eq. 2) write(20,'(a)') '|       char             '
     +   //'|   i  |  double   |  double   |   r    |   r    |    r   '
     +   //'|   r    |  r     |   r    |  r     |     r   |    r  '
     +   //'|   r   |     r   |    r  |    r  |   r  |   r  |   r  '
     +   //'|   r  |     r     |     r       |     r     |     r       '
     +   //'|   r  |     r   |      r   |   r  |     r   |      r   '
     +   //'|       r  | i | i |   c   |   c   |   r   |   r   | char '
     +   //'|  r   |    r |  i  |   r   |  r   |  r   |    r |  i  '
     +   //'|   r   |   r  |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |    r    |    r    |   i   |    r    '
     +   //'|    r    |   i   |  i   |  i  |   r   |  r    |   r   '
     +   //'|    r      |   i |  r  |      double     '
     +   //'|      double     |       double    |   i  |  i  |   r   '
     +   //'|  r    |   r   |    r      |  i  |  r  |      double     '
     +   //'|      double     |       double    |  i  |  i  |   r   '
     +   //'|   r   |   r  |   r  |   r   |   r   |  i   |   r   '
     +   //'|   r  |   r  |   r   |   r   |  i   |   i  |   i  |   i  '
     +   //'|    r    |    r    |   double   |   double  |   double  '
     +   //'|   r    |    r    |     r     |    r    |    r    '
     +   //'|    r   |    r   |    r   |    r   |    r      '
     +   //'|     r       |     r     |     r       |     r   '
     +   //'|      r     |      r   |    r    |      r     |      r   '
     +   //'|       r  |   c  |     i   |     i   |  real  |   r  '
     +   //'|   r  |   r  |   r  |  double  |     r    |  double  '
     +   //'|    r    |    r     |     r    |     r    |    r    '
     +   //'|    r     |     r    |    r    |     r   | i| i| i| i|c'
     +   //'|    r     |     r    |    r     |     r    | double     '
     +   //'| char          | int        | char              '
     +   //'| int        | char              | int|  char  |  int   '
     +   //'|    char    |   int  |    char    |'
        if (nHead .eq. 3) write(20,'(a)') Line(1:lnblnk(Line))
     + //'    |        |        |            |        |            |'
        if (nHead .eq. 4) write(20,'(a)') Line(1:lnblnk(Line))
     + //'null|  null  |  null  |    null    |  null  |    null    |'
        go to 10
      end if
c
      nSrc = nSrc + 1
      nNaN = index(Line,' NaN')
      if (nNaN .gt. 0) NaNwarn = .true.
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! check for multi-matches
15    if (index(Line(IFa(401):IFb(401)),'null') .gt. 0) then   ! not multi
        if (index(Line(IFa(385):IFb(385)),'null') .gt. 0) then ! no match
          nAWstr = '    0'
        else                                                   ! solo match
          nAWstr = '    1'
        end if
        dist_str     = AdjustL(Line(IFa(385):IFb(385)))
        cc_flags     = AdjustL(Line(Ifa(394):IFb(394)))
        w1cc_map     = AdjustL(Line(Ifa(395):IFb(395)))
        w1cc_map_str = AdjustL(Line(Ifa(396):IFb(396)))
        w2cc_map     = AdjustL(Line(Ifa(397):IFb(397)))
        w2cc_map_str = AdjustL(Line(Ifa(398):IFb(398)))
        if (dbg .and. (nSrc .lt. 5)) then
          print *,'nSrc:', nSrc
          print *,
     +    'dist_str     = |'//dist_str(1:lnblnk(dist_str))//'|'
          print *,
     +    'cc_flags     = |'//cc_flags(1:lnblnk(cc_flags))//'|'
          print *,
     +    'w1cc_map     = |'//w1cc_map(1:lnblnk(w1cc_map))//'|'
          print *,
     +    'w1cc_map_str = |'//w1cc_map_str(1:lnblnk(w1cc_map_str))//'|'
          print *,
     +    'w2cc_map     = |'//w2cc_map(1:lnblnk(w2cc_map))//'|'
          print *,
     +    'w2cc_map_str = |'//w2cc_map_str(1:lnblnk(w2cc_map_str))//'|'
        end if
        go to 100
      end if
c                                 ! process multi-matches
      read (Line(IFa(401):IFb(401)), *, err = 3003) nAW
      write (nAWstr,'(i5)') nAW         ! note that w1cc_map and w2cc_map
      read (Line(IFa(395):Ifb(395)), *, err = 3004) w1ccmap  ! should never
      read (Line(IFa(397):Ifb(397)), *, err = 3005) w2ccmap  ! be null for
      read (Line(IFa(385):Ifb(385)), *, err = 3006) dist     ! matched srcs.
      n = IFa(394) + lnblnk(Line(IFa(394):Ifb(394))) - 2     ! monitor W3
      w3cc = Line(n:n)                                       ! & W4 cc_flags
      w4cc = Line(n+1:n+1)
      kBadw3 = kBadness(w3cc)
      kBadw4 = kBadness(w4cc)
c
      do 20 n = 2, nAW
        nSrc = nSrc + 1                ! increment for error msg only
        read (10, '(a)', end=3006) Line
        read (Line(IFa(395):Ifb(395)), *, err = 3004) w1ccmap2
        read (Line(IFa(397):Ifb(397)), *, err = 3005) w2ccmap2
        w1ccmap = IOr(w1ccmap, w1ccmap2)
        w2ccmap = IOr(w2ccmap, w2ccmap2)
        read (Line(IFa(385):Ifb(385)), *, err = 3006) dist2
        if (dist2 .gt. dist) dist = dist2
        kBad2w3 = 0
        kBad2w4 = 0
        k = IFa(394) + lnblnk(Line(IFa(394):Ifb(394))) - 2   ! monitor W3
        w3cc2 = Line(k:k)                                    ! & W4 cc_flags
        w4cc2 = Line(k+1:k+1)
        kBad2w3 = kBadness(w3cc2)
        kBad2w4 = kBadness(w4cc2)
        if (kBad2w3 .gt. kBadw3) then
          w3cc   = w3cc2
          kBadw3 = kBad2w3
        end if
        if (kBad2w4 .gt. kBadw4) then
          w4cc   = w4cc2
          kBadw4 = kBad2w4
        end if
20    continue
      nSrc = nSrc - nAW + 1
      write (dist_str,'(f8.5)') dist
30    if (lnblnk(dist_str) .lt. nw385) then
        dist_str = ' '//dist_str
        go to 30
      end if
c
c| cc_flags      | w1cc_map   | w1cc_map_str      | w2cc_map   | w2cc_map_str      |
c1234567890123456123456789012312345678901234567890123456789012312345678901234567890
cc________1______c________1___c________1_________2c________1___c________1_________2
c
c     O  H  -  P  D  -  -  o  h  -  p  d
c    11 10 09 08 07 06 05 04 03 02 01 00
c
c   flag priority: D,P,H,O,d,p,h,o   for cc_flags
c   flag priority: D,d,P,p,H,h,O,o   for w?cc_map_str
c
40    if (w1ccmap .eq. 0) then
        cc_flags     = '.0'
        w1cc_map     = '0'
        w1cc_map_str = '.null'
      else
        if (dbg) then
          print *,'-------------------------'
          print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                             ', w1ccmap: ', w1ccmap
        end if
        cc_flags     = '.'
        write(w1cc_map,'(i9)') w1ccmap
        if (BitSet(w1ccmap,7)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'D'
        else if (BitSet(w1ccmap,8)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'P'
        else if (BitSet(w1ccmap,10)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'H'
        else if (BitSet(w1ccmap,11)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'O'
        else if (BitSet(w1ccmap,0)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'d'
        else if (BitSet(w1ccmap,1)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'p'
        else if (BitSet(w1ccmap,3)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'h'
        else if (BitSet(w1ccmap,4)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'o'
        end if
        if (dbg) print *,'cc_flags: ',cc_flags(1:lnblnk(cc_flags))
        w1cc_map_str = '.'
        if (BitSet(w1ccmap,7))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'D'
        if (BitSet(w1ccmap,0) .and. .not.BitSet(w1ccmap,7))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'d'
        if (BitSet(w1ccmap,8))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'P'
        if (BitSet(w1ccmap,1) .and. .not.BitSet(w1ccmap,8))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'p'
        if (BitSet(w1ccmap,10))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'H'
        if (BitSet(w1ccmap,3) .and. .not.BitSet(w1ccmap,10))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'h'
        if (BitSet(w1ccmap,11))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'O'
        if (BitSet(w1ccmap,4) .and. .not.BitSet(w1ccmap,11))
     +      w1cc_map_str = w1cc_map_str(1:lnblnk(w1cc_map_str))//'o'
        if (dbg) print *,'w1cc_map_str: ',w1cc_map_str(1:lnblnk(w1cc_map_str))
      end if
c
      if (w2ccmap .eq. 0) then
        cc_flags     = cc_flags(1:lnblnk(cc_flags))//'0'
        w2cc_map     = '0'
        w2cc_map_str = '.null'
      else
        if (dbg) then
          print *,'-------------------------'
          print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                             ', w2ccmap: ', w2ccmap
        end if
        write(w2cc_map,'(i9)') w2ccmap
        if (BitSet(w2ccmap,7)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'D'
        else if (BitSet(w2ccmap,8)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'P'
        else if (BitSet(w2ccmap,10)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'H'
        else if (BitSet(w2ccmap,11)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'O'
        else if (BitSet(w2ccmap,0)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'d'
        else if (BitSet(w2ccmap,1)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'p'
        else if (BitSet(w2ccmap,3)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'h'
        else if (BitSet(w2ccmap,4)) then
          cc_flags = cc_flags(1:lnblnk(cc_flags))//'o'
        end if
        if (dbg) print *,'cc_flags: ',cc_flags(1:lnblnk(cc_flags))
        w2cc_map_str = '.'
        if (BitSet(w2ccmap,7))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'D'
        if (BitSet(w2ccmap,0) .and. .not.BitSet(w2ccmap,7))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'d'
        if (BitSet(w2ccmap,8))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'P'
        if (BitSet(w2ccmap,1) .and. .not.BitSet(w2ccmap,8))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'p'
        if (BitSet(w2ccmap,10))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'H'
        if (BitSet(w2ccmap,3) .and. .not.BitSet(w2ccmap,10))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'h'
        if (BitSet(w2ccmap,11))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'O'
        if (BitSet(w2ccmap,4) .and. .not.BitSet(w2ccmap,11))
     +      w2cc_map_str = w2cc_map_str(1:lnblnk(w2cc_map_str))//'o'
        if (dbg) print *,'w2cc_map_str: ',w2cc_map_str(1:lnblnk(w2cc_map_str))
      end if
c
      cc_flags = cc_flags(1:lnblnk(cc_flags))//w3cc//w4cc
      cc_flags(1:1)     = ' '          ! remove sentinel character
      w1cc_map_str(1:1) = ' '
      w2cc_map_str(1:1) = ' '
c
100   if (lnblnk(cc_flags) .lt. nw394) then
        cc_flags = ' '//cc_flags
        go to 100
      end if
110   if (lnblnk(w1cc_map_str) .lt. nw396) then
        w1cc_map_str = ' '//w1cc_map_str
        go to 110
      end if
120   if (lnblnk(w2cc_map_str) .lt. nw398) then
        w2cc_map_str = ' '//w2cc_map_str
        go to 120
      end if      
130   if (lnblnk(w1cc_map) .lt. nw395) then
        w1cc_map = ' '//w1cc_map
        go to 130
      end if
140   if (lnblnk(w2cc_map) .lt. nw397) then
        w2cc_map = ' '//w2cc_map
        go to 140
      end if
150   if (lnblnk(dist_str) .lt. nw385) then
        dist_str = ' '//dist_str
        go to 150
      end if
c
      Line(IFa(385):IFb(385)) = dist_str
      Line(Ifa(394):IFb(394)) = cc_flags
      Line(Ifa(395):IFb(395)) = w1cc_map
      Line(Ifa(396):IFb(396)) = w1cc_map_str
      Line(Ifa(397):IFb(397)) = w2cc_map
      Line(Ifa(398):IFb(398)) = w2cc_map_str
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! recompute mags if requested
      if (doMags) then
c
        if (index(Line(IFa(22):IFb(23)),'null') .eq. 0) then ! w1flux
          nMag = 1
          read (Line(Ifa(22):Ifb(22)), *, err=333) flux
          read (Line(Ifa(23):Ifb(23)), *, err=333) sigflux
          wsnr = flux/sigflux
          if (wsnr .gt. 9999.0) wsnr = 9999.0
          write (Line(IFA(20):IFB(20)), '(F7.1)') wsnr
          if ((flux .gt. 0.0d0) .and. (wsnr .ge. 2.0d0)) then
            mag    = w1m0 - 2.5*dlog10(flux)
            sigmag = CoefMag*sigflux/flux
            write (Line(Ifa(26):Ifb(26)),'(f7.3)') mag
            write (Line(Ifa(27):Ifb(27)),'(f10.3)') sigmag
          else
            if (flux .gt. 0.0d0) then
              mag = w1m0 - 2.5*dlog10(flux+2.0d0*sigflux)
            else
              mag = w1m0 - 2.5*dlog10(2.0d0*sigflux)
            end if
            write (Line(Ifa(26):Ifb(26)),'(f7.3)') mag
            Line(Ifa(27):Ifb(27)) = '      9.99'
          end if
          if (index(Line(IFa(26):IFb(26)),'NaN') .ne. 0) then
            print *, 'ERROR: NaN produced for w1mpro on row no.', nSrc
            print *,'        w1flux, w1sigflux:', flux, sigflux
            NaNwarn = .true.
            nn11 = nn11 + 1
          end if
        end if
c
        if (index(Line(IFa(24):IFb(25)),'null') .eq. 0) then ! w2flux
          nMag = 2
          read (Line(Ifa(24):Ifb(24)), *, err=333) flux
          read (Line(Ifa(25):Ifb(25)), *, err=333) sigflux
          wsnr = flux/sigflux
          if (wsnr .gt. 9999.0) wsnr = 9999.0
          write (Line(IFA(21):IFB(21)), '(F7.1)') wsnr
          if ((flux .gt. 0.0d0) .and. (wsnr .ge. 2.0d0)) then
            mag    = w2m0 - 2.5*dlog10(flux)
            sigmag = CoefMag*sigflux/flux
            write (Line(Ifa(29):Ifb(29)),'(f7.3)') mag
            write (Line(Ifa(30):Ifb(30)),'(f10.3)') sigmag
          else
            if (flux .gt. 0.0d0) then
              mag = w2m0 - 2.5*dlog10(flux+2.0d0*sigflux)
            else
              mag = w2m0 - 2.5*dlog10(2.0d0*sigflux)
            end if
            write (Line(Ifa(29):Ifb(29)),'(f7.3)') mag
            Line(Ifa(30):Ifb(30)) = '      9.99'
          end if
          if (index(Line(IFa(29):IFb(29)),'NaN') .ne. 0) then
            print *, 'ERROR: NaN produced for w2mpro on row no.', nSrc
            print *,'        w2flux, w2sigflux:', flux, sigflux
            NaNwarn = .true.
            nn21 = nn21 + 1
          end if
        end if
c
        if (index(Line(IFa(152):IFb(153)),'null') .eq. 0) then ! w1flux_pm
          nMag = 3
          read (Line(Ifa(152):Ifb(152)), *, err=333) flux
          read (Line(Ifa(153):Ifb(153)), *, err=333) sigflux
          wsnr = flux/sigflux
          if (wsnr .gt. 9999.0) wsnr = 9999.0
          write (Line(IFA(150):IFB(150)), '(f9.1)') wsnr
          if ((flux .gt. 0.0d0) .and. (wsnr .ge. 2.0d0)) then
            mag    = w1m0 - 2.5*dlog10(flux)
            sigmag = CoefMag*sigflux/flux
            write (Line(Ifa(156):Ifb(156)),'(f10.3)') mag
            write (Line(Ifa(157):Ifb(157)),'(f13.3)') sigmag
          else
            if (flux .gt. 0.0d0) then
              mag = w1m0 - 2.5*dlog10(flux+2.0d0*sigflux)
            else
              mag = w1m0 - 2.5*dlog10(2.0d0*sigflux)
            end if
            write (Line(Ifa(156):Ifb(156)),'(f10.3)') mag
            Line(Ifa(157):Ifb(157)) = '         9.99'
          end if
          if (index(Line(IFa(156):IFb(156)),'NaN') .ne. 0) then
            print *,'ERROR: NaN produced for w1mpro_pm on row no.', nSrc
            print *,'       w1flux_pm, w1sigflux_pm:', flux, sigflux
            NaNwarn = .true.
            nn12 = nn12 + 1
          end if
        end if
c
        if (index(Line(IFa(154):IFb(155)),'null') .eq. 0) then ! w2flux_pm
          nMag = 4
          read (Line(Ifa(154):Ifb(154)), *, err=333) flux
          read (Line(Ifa(155):Ifb(155)), *, err=333) sigflux
          wsnr = flux/sigflux
          if (wsnr .gt. 9999.0) wsnr = 9999.0
          write (Line(IFA(151):IFB(151)), '(F9.1)') wsnr
          if ((flux .gt. 0.0d0) .and. (wsnr .ge. 2.0d0)) then
            mag    = w2m0 - 2.5*dlog10(flux)
            sigmag = CoefMag*sigflux/flux
            write (Line(Ifa(159):Ifb(159)),'(f10.3)') mag
            write (Line(Ifa(160):Ifb(160)),'(f13.3)') sigmag
          else
            if (flux .gt. 0.0d0) then
              mag = w2m0 - 2.5*dlog10(flux+2.0d0*sigflux)
            else
              mag = w2m0 - 2.5*dlog10(2.0d0*sigflux)
            end if
            write (Line(Ifa(159):Ifb(159)),'(f10.3)') mag
            Line(Ifa(160):Ifb(160)) = '         9.99'
          end if
          if (index(Line(IFa(159):IFb(159)),'NaN') .ne. 0) then
            print *,'ERROR: NaN produced for w2mpro_pm on row no.', nSrc
            print *,'       w2flux_pm, w2sigflux_pm:', flux, sigflux
            NaNwarn = .true.
            nn22 = nn22 + 1
          end if
        end if
c
      end if
c
      go to 400
c
333   print *,'ERROR: read error on flux information group #',
     +         nMag,', data row #',nSrc
      print *,
     + '       magnitude recomputation terminated for this source'
c
c - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c                                      ! process CatWISE mask bits
400   if (useWCS) then
        read(Line(IFa(3):Ifb(3)), *, err = 3008) ra
        read(Line(IFa(4):Ifb(4)), *, err = 3009) dec
        offscl = -1
        call wcs2pix(wcs, ra, dec, x8, y8, offscl)
        if (offscl .ne. 0) then
	  	  w1x = 1.
		  w1y = 1.
        else
		  w1x = x8
		  w1y = y8
		endif
c       iPix = NInt(w1x)               ! don't round off; RA & Dec of
c       jPix = NInt(w1y)               ! a pixel are at its center
        iPix = w1x
        jPix = w1y
        write(Line(IFa(8):IFb(8)),  '(f9.3)') w1x
        write(Line(IFa(9):IFb(9)),  '(f9.3)') w1y
        write(Line(IFa(10):IFb(10)),'(f9.3)') w1x
        write(Line(IFa(11):IFb(11)),'(f9.3)') w1y
        if (dbg .and. (nSrc .le. 10)) then
          print *,'-------------------------'
          print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                          ', ra & dec: ', ra, dec
          print *,'        w1x & w1y: ', w1x, w1y
        end if
        go to 500
      end if
c
      GoodXY1 = index(Line(IFA(8):IFB(8)),  'null') .eq. 0
      GoodXY2 = index(Line(IFA(10):IFB(10)),'null') .eq. 0
      if (GoodXY1 .and. GoodXY2) then
        k = 8
        read (Line(IFa(k):IFb(k)), *, err = 3001) w1x
        k = 10
        read (Line(IFa(k):IFb(k)), *, err = 3001) w2x
        iPix = (w1x+w2x)/2.0
      else if (GoodXY1) then
        k = 8
        read (Line(IFa(k):IFb(k)), *, err = 3001) w1x
        iPix = w1x
      else if (GoodXY2) then
        k = 10
        read (Line(IFa(k):IFb(k)), *, err = 3001) w2x
        iPix = w2x
      else
        ab_flags     = '     null'
        w1ab_map     = '     null'
        w1ab_map_str = '         null'
        w2ab_map     = '     null'
        w2ab_map_str = '         null'
        go to 900
      end if
c
      GoodXY1 = index(Line(IFA(9):IFB(9)),  'null') .eq. 0
      GoodXY2 = index(Line(IFA(11):IFB(11)),'null') .eq. 0
      if (GoodXY1 .and. GoodXY2) then
        k = 9
        read (Line(IFa(k):IFb(k)), *, err = 3001) w1y
        k = 11
        read (Line(IFa(k):IFb(k)), *, err = 3001) w2y
        jPix = (w1y+w2y)/2.0
      else if (GoodXY1) then
        k = 9
        read (Line(IFa(k):IFb(k)), *, err = 3001) w1y
        jPix = w1y
      else if (GoodXY2) then
        k = 11
        read (Line(IFa(k):IFb(k)), *, err = 3001) w2y
        jPix = w2y
      else
        ab_flags     = '     null'
        w1ab_map     = '     null'
        w1ab_map_str = '         null'
        w2ab_map     = '     null'
        w2ab_map_str = '         null'
        go to 900
      end if
c
500   msk = array1(iPix,jPix)
      if (dbg .and. (msk .gt. 0)) then
        if (.not.BitSet(msk,6) .and. .not.BitSet(msk,21) .and.
     +      .not.BitSet(msk,9) .and. .not.BitSet(msk,10) .and.
     +      .not.BitSet(msk,22)) then
          print *,'-------------------------'
          print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                          ', msk: ', msk
        end if
      end if
      call DoHist(msk,MskBitHist)
c
      if (BitSet(msk,21)) then                     ! don't flag the source
        call ClrBit(msk,0)                         ! that caused the
        call ClrBit(msk,1)                         ! diffraction spikes
        call ClrBit(msk,7)
        call ClrBit(msk,21)
        call ClrBit(msk,23)
        call ClrBit(msk,27)
        call ClrBit(msk,29)
      end if
      if (BitSet(msk,22)) then
        call ClrBit(msk,2)
        call ClrBit(msk,3)
        call ClrBit(msk,8)
        call ClrBit(msk,22)
        call ClrBit(msk,24)
        call ClrBit(msk,28)
        call ClrBit(msk,30)
      end if
c
      w1abmap = 0      !  O  H  -  P  D  -  -  o  h  -  p  d
      w2abmap = 0      ! 11 10 09 08 07 06 05 04 03 02 01 00
c
      if (BitSet(msk,17) .or. BitSet(msk,18))
     +    call SetBit(w1abmap,1)        ! 'p' for W1
      if (BitSet(msk,19) .or. BitSet(msk,20))
     +    call SetBit(w2abmap,1)        ! 'p' for W2
      if (BitSet(msk,13) .or. BitSet(msk,14))
     +    call SetBit(w1abmap,1)        ! 'p' for W1
      if (BitSet(msk,15) .or. BitSet(msk,16))
     +    call SetBit(w2abmap,1)        ! 'p' for W2
      if (BitSet(msk,25) .or. BitSet(msk,26))
     +    call SetBit(w1abmap,4)        ! 'o' for W1
      if (BitSet(msk,11) .or. BitSet(msk,12))
     +    call SetBit(w2abmap,4)        ! 'o' for W2
      if (BitSet(msk, 0) .or. BitSet(msk, 1) .or. BitSet(msk, 29)
     +                   .or. BitSet(msk, 7) .or. BitSet(msk, 27))
     +    call SetBit(w1abmap,0)        ! 'd' for W1
      if (BitSet(msk, 2) .or. BitSet(msk, 3) .or. BitSet(msk, 30)
     +                   .or. BitSet(msk, 8) .or. BitSet(msk, 28))
     +    call SetBit(w2abmap,0)        ! 'd' for W2
      if (BitSet(msk, 23))
     +    call SetBit(w1abmap,3)        ! 'h' for W1
      if (BitSet(msk, 24))
     +    call SetBit(w2abmap,3)        ! 'h' for W2
c
c   flag priority: D,d,P,p,H,h,O,o
c
      if (w1abmap .eq. 0) then
        ab_flags     = '.0       '
        w1ab_map     = '        0'
        w1ab_map_str = '.null        '
      else
        if (dbg) print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                          ', w1abmap: ', w1abmap
        ab_flags     = '.        '
        write(w1ab_map,'(i9)') w1abmap
        if (BitSet(w1abmap,7)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'D'
        else if (BitSet(w1abmap,8)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'P'
        else if (BitSet(w1abmap,10)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'H'
        else if (BitSet(w1abmap,11)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'O'
        else if (BitSet(w1abmap,0)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'d'
        else if (BitSet(w1abmap,1)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'p'
        else if (BitSet(w1abmap,3)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'h'
        else if (BitSet(w1abmap,4)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'o'
        end if
        if (dbg) print *,'ab_flags: ',ab_flags
        w1ab_map_str = '.        '
        if (BitSet(w1abmap,7))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'D'
        if (BitSet(w1abmap,0) .and. .not.BitSet(w1abmap,7))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'d'
        if (BitSet(w1abmap,8))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'P'
        if (BitSet(w1abmap,1) .and. .not.BitSet(w1abmap,8))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'p'
        if (BitSet(w1abmap,10))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'H'
        if (BitSet(w1abmap,3) .and. .not.BitSet(w1abmap,10))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'h'
        if (BitSet(w1abmap,11))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'O'
        if (BitSet(w1abmap,4) .and. .not.BitSet(w1abmap,11))
     +      w1ab_map_str = w1ab_map_str(1:lnblnk(w1ab_map_str))//'o'
        if (dbg) print *,'w1ab_map_str: ',w1ab_map_str
      end if
c
      if (w2abmap .eq. 0) then
        ab_flags     = ab_flags(1:lnblnk(ab_flags))//'0'
        w2ab_map     = '        0'
        w2ab_map_str = '.null        '
      else
        if (dbg) print *,'nSrc: ', nSrc,' ',trim(Line(IFa(1):IFb(1))),
     +                          ', w2abmap: ', w2abmap
        write(w2ab_map,'(i9)') w2abmap
        if (BitSet(w2abmap,7)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'D'
        else if (BitSet(w2abmap,8)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'P'
        else if (BitSet(w2abmap,10)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'H'
        else if (BitSet(w2abmap,11)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'O'
        else if (BitSet(w2abmap,0)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'d'
        else if (BitSet(w2abmap,1)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'p'
        else if (BitSet(w2abmap,3)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'h'
        else if (BitSet(w2abmap,4)) then
          ab_flags = ab_flags(1:lnblnk(ab_flags))//'o'
        end if
        if (dbg) print *,'ab_flags: ',ab_flags
        w2ab_map_str = '.        '
        if (BitSet(w2abmap,7))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'D'
        if (BitSet(w2abmap,0) .and. .not.BitSet(w2abmap,7))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'d'
        if (BitSet(w2abmap,8))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'P'
        if (BitSet(w2abmap,1) .and. .not.BitSet(w2abmap,8))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'p'
        if (BitSet(w2abmap,10))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'H'
        if (BitSet(w2abmap,3) .and. .not.BitSet(w2abmap,10))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'h'
        if (BitSet(w2abmap,11))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'O'
        if (BitSet(w2abmap,4) .and. .not.BitSet(w2abmap,11))
     +      w2ab_map_str = w2ab_map_str(1:lnblnk(w2ab_map_str))//'o'
        if (dbg) print *,'w2ab_map_str: ',w2ab_map_str
      end if
c
      ab_flags(1:1)     = ' '          ! remove sentinel character
      w1ab_map_str(1:1) = ' '
      w2ab_map_str(1:1) = ' '
c
800   if (lnblnk(ab_flags) .lt. 9) then
        ab_flags = ' '//ab_flags
        go to 800
      end if
810   if (lnblnk(w1ab_map_str) .lt. 13) then
        w1ab_map_str = ' '//w1ab_map_str
        go to 810
      end if
820   if (lnblnk(w2ab_map_str) .lt. 13) then
        w2ab_map_str = ' '//w2ab_map_str
        go to 820
      end if
c
900   Line =  Line(1:Ifb(191))//Line(IFa(385):IFb(385))
     +  //Line(IFa(394):IFb(398))//nAWstr//ab_flags
     +  //w1ab_map//w1ab_map_str//w2ab_map//w2ab_map_str
510   nNaN = index(Line,' NaN')
      if (nNaN .gt. 0) then
        print *, 'ERROR: NaN detected on output line #',
     +  nSrc, ' at position', nNaN
        print *, HdrLine(1:lnblnk(HdrLine))
        print *,Line(1:lnblnk(Line))
        Line(nNaN:nNaN+3) = 'null'
        print *,'replaced with null'
        print *,Line(1:lnblnk(Line))
        go to 510        
      end if
c                                      ! plug in canonical w1mcor & w2mcor
      write(Line(IFa(44):IFb(44)),'(f7.3)') w1mcor
      write(Line(IFa(49):IFb(49)),'(f7.3)') w2mcor
c                                      ! compute w?cov and w?sat
      i1PSF = iPix - nPSF
      i2PSF = iPix + nPSF
      j1PSF = jPix - nPSF
      j2PSF = jPix + nPSF
      if (i1PSF .lt. 1)    i1PSF = 1
      if (i2PSF .gt. 2048) i2PSF = 2048
      if (j1PSF .lt. 1)    j1PSF = 1
      if (j2PSF .gt. 2048) j2PSF = 2048
      nPix  = 0
      n1Sat = 0
      n2Sat = 0
      n1Cov = 0
      n2Cov = 0
      do 610 j = j1PSF, j2PSF
        do 600 i = i1PSF, i2PSF
          nPix = nPix + 1
          if (BitSet(array1(i,j),4)) n1Sat = n1Sat + 1
          if (BitSet(array1(i,j),5)) n2Sat = n2Sat + 1
          if (doCov) then
            n1Cov = n1Cov + cov1(i,j)
            n2Cov = n2Cov + cov2(i,j)      
          end if
600     continue
610   continue
      wsat = float(n1Sat)/float(nPix)
      write(Line(IFA(37):IFb(37)),'(f8.5)') wsat
      wsat = float(n2Sat)/float(nPix)
      write(Line(IFA(38):IFb(38)),'(f8.5)') wsat
      if (doCov) then
        wcov = float(n1Cov)/float(nPix)
        write(Line(IFA(43):IFb(43)),'(f8.2)') wcov
        wcov = float(n2Cov)/float(nPix)
        write(Line(IFA(48):IFb(48)),'(f8.2)') wcov
      end if
c
      write(20,'(a)') Line(1:lnblnk(line))
      go to 10
c
1000  print *,' No. data rows processed:', nSrc
c
      if (nSrc .ne. nSrcHdr) then
        print *,
     + 'ERROR: this does not match the header "\nSrc" value: ',nSrcHdr
1001    n = index(InFNam,'/')
        if (n .gt. 0) then
          do 1002 i = 1, n
          InFNam(i:i) = ' '
1002      continue
          go to 1001
        end if
        InFNam = AdjustL(InFNam)
        open (33, file = 'ERROR_MESSAGE-'
     +                  //InFNam(1:lnblnk(InFNam))//'.txt')
        write (33,'(a)') 'ERROR: source count mismatch'
        write (33,'(a,i9)') 'header "\nSrc" value:', nSrcHdr
        write (33,'(a,i9)') 'actual source count: ', nSrc
      end if
c
      if (NaNwarn) then
        print *,'WARNING: NaNs were encountered in this mdex input file'
1003    n = index(InFNam,'/')
        if (n .gt. 0) then
          do 1004 i = 1, n
          InFNam(i:i) = ' '
1004      continue
          go to 1003
        end if
        InFNam = AdjustL(InFNam)
        open (34, file = 'WARNING_MESSAGE-'
     +                  //InFNam(1:lnblnk(InFNam))//'.txt')
        write (34,'(a)')
     +  'WARNING: NaNs were encountered in this mdex input file'
        write (34,'(a)')
     +  '         NaNs in output mdex:'
        write (34,'(a,i5)') 'no. w1mpro NaNs:               ', nn11
        write (34,'(a,i5)') 'no. w1mpro_pm NaNs:            ', nn12
        write (34,'(a,i5)') 'no. w2mpro NaNs:               ', nn21
        write (34,'(a,i5)') 'no. w2mpro_pm NaNs:            ', nn22
      end if
c
      print *
      print *,'Mask Bit Counters:'
      do 1010 n = 1, 32
        write (6, '(i2,'':'',i6)') n-1, MskBitHist(n)
1010  continue
      print *
      call signoff('add-ab_flags')
      stop
c
3000  print *,'ERROR: end-of-file encountered during sanity check'
      call exit(64)
c
3001  print *,'ERROR: read error on mdex column ', k,', source #', nSrc
      call exit(64)
c
3002  print *,'ERROR: read error on "\nSrc" in header:'
      print *,'       ',Line 
      call exit(64)
c
3003  print *,'ERROR: read error on GroupSize for source #', nSrc
      print *,'       GroupSize field: "'//Line(IFa(401):IFb(401))//'"'
      call exit(64)
c
3004  print *,'ERROR: read error on w1cc_map for source #', nSrc
      print *,'       w1cc_map field: "'//Line(IFa(395):IFb(395))//'"'
      call exit(64)
c
3005  print *,'ERROR: read error on w2cc_map for source #', nSrc
      print *,'       w2cc_map field: "'//Line(IFa(397):IFb(397))//'"'
      call exit(64)
c
3006  print *,'ERROR: end-of-file encountered while seeking w?cc_map'
      print *,'       information for multi-matched source #', nSrc
      call exit(64)
c
3007  print *,'ERROR: read error on dist_x for source #', nSrc
      print *,'       dist_x field: "'//Line(IFa(385):IFb(385))//'"'
      call exit(64)
c
3008  print *,'ERROR: read error on ra for source #', nSrc
      print *,'       ra field: "'//Line(IFa(3):IFb(3))//'"'
      call exit(64)
c
3009  print *,'ERROR: read error on dec for source #', nSrc
      print *,'       dec field: "'//Line(IFa(4):IFb(4))//'"'
      call exit(64)
c
3017  print *,'ERROR: EoF encountered in ssoidin namelist file'
      call exit(64)
c
3018  print *,'ERROR: read error encountered in ssoidin namelist file'
      call exit(64)
c
      stop
      end
c
c=======================================================================
c
      Subroutine GetNAX(FilNam,NAXIS1,NAXIS2,NAXIS3,IDOp,FileID)
c-----------------------------------------------------------------------
c
c    Gets the dimensions of the file named FilNam; if IDOp = 0, the
c    file is closed, otherwise it's left open with handle FileID
c
c-----------------------------------------------------------------------
c
      Character*200 FilNam
      Integer*4     NAXIS, NAXIS1, NAXIS2, NAXIS3, IStat, ImOpen,
     +              ImRKeyI, FileID, IDOp, LNBlnk, ImClose
      integer status,readwrite,blocksize,naxes(3)
c
c-----------------------------------------------------------------------
c
C  The STATUS parameter must always be initialized.
      status=0
C  Get an unused Logical Unit Number to use to open the FITS file.
      call ftgiou(FileID,status)
c     print *,'GetNAX: FileID, status:',fileid,status ! dbg
C  Open the FITS file 
      readwrite=0
      call ftopen(FileID,FilNam,readwrite,blocksize,status)
      if (status /= 0) then
          write(6,'(a)') 'GetNAX: Could not read '//trim(FilNam)
          istat = 3
          return
      endif
c
C  Determine the size of the image.
      call ftgknj(FileID,'NAXIS',1,2,naxes,NAXIS,status)
c     print *,'GetNAX: naxes, naxis, status:',naxes, naxis, status ! dbg
c
C  Check that it found both NAXIS1 and NAXIS2 keywords.
      if (NAXIS .lt. 2)then
          print *,'GetNAX: Failed to read the NAXISn keywords.'
        istat = 4
          return
       end if
c
      NAXIS1 = naxes(1)
      NAXIS2 = naxes(2)
c
      If (NAXIS .gt. 2) then
        NAXIS3 = naxes(3)
      Else
        NAXIS3 = 1
      End If
c
      If (IDOp .eq. 0) then
        call ftclos(FileID, status)
        call ftfiou(FileID, status)
      end if
c
      return
c
      end
c      
c=======================================================================
c
      subroutine SignOn(pgmnam)
c
c *** signon- routine which provides sign-on and sign-off messages
c             (orig by John Fowler- mod by Howard McCallon-041214-SIRTF)
c
c     inputs:  pgmnam = program name                          [call arg]
c
c     outputs: message to stdout
c
      character*(*) pgmnam
      character vsn*11,cdate*8,ctime*8,Fmt*11,FLen*4
      integer*4 onoff,jdate(3),jtime(3),lnblnk
      real*4    dummyt,second(2),etime
c
      common /vdt/ cdate,ctime,vsn
c##
      onoff = 1
c
c         i. obtain date
c
100   cdate = '00-00-00'
      call idate(jdate)    ! Linux call
c
      jdate(3) = mod(jdate(3), 100)
      write(cdate(1:2), '(i2)') jdate(2)
      write(cdate(4:5), '(i2)') jdate(1)
      write(cdate(7:8), '(i2)') jdate(3)
c
      if(cdate(4:4) .eq. ' ') cdate(4:4) = '0'
      if(cdate(7:7) .eq. ' ') cdate(7:7) = '0'
c
c         ii. obtain time
c
      ctime = '00:00:00'
      call itime(jtime)
      write(ctime(1:2), '(i2)') jtime(1)
      write(ctime(4:5), '(i2)') jtime(2)
      write(ctime(7:8), '(i2)') jtime(3)
c
      if(ctime(4:4) .eq. ' ') ctime(4:4) = '0'
      if(ctime(7:7) .eq. ' ') ctime(7:7) = '0'
c
c         iii. set up format for pgmnam
c
      write(Flen,'(I4)') lnblnk(pgmnam)
      Fmt = '(A'//Flen//'$)'
c
c         iv. write out results
c
      write(*,Fmt) pgmnam
      if(onoff .eq. 1) then                      ! sign on
        write(*,301) vsn,cdate,ctime
      else                                       ! sign off
        dummyt = etime(second)
        write(*,302) vsn,cdate,ctime,second
      endif
  301 format(' version: ',a11,' - execution begun on ',a8,' at ',a8)
  302 format(' version: ',a11,' - execution ended on ',a8,' at ',a8
     *    /1x,f9.2,' cpu seconds used;',f8.2,' system seconds used.')
c
      return
c
      entry SignOff(pgmnam)
      OnOff = 2
      go to 100
c
      end
c
c=======================================================================
c
      subroutine ChkFld(Fld1, Fld2, k)
c      
      character*(*) Fld1, Fld2
      integer*4     k, lnblnk      
c
      if (Fld1 .ne. Fld2) then
        print *,'ERROR: input field no.',k,' expected to be ',
     +           Fld2(1:lnblnk(Fld2)),'; got ',Fld1(1:lnblnk(Fld2))
        call exit(64)
      end if
c      
      return
c      
      end
c      
c=======================================================================
c
      subroutine GetFlds(ColNam,Field,IFa,IFb,NF)
c-----------------------------------------------------------------------
c
c  Get fields in a table-file header line
c
c-----------------------------------------------------------------------
                     Integer*4  MaxFld
                     Parameter (MaxFld = 1000)
c
      character*5000 ColNam
      Character*300  Line
      character*25   Field(MaxFld)
      integer*4      IFa(MaxFld), IFb(MaxFld), NF, N, M, L, K, LNBlnk,
     +               LastErr
c
c-----------------------------------------------------------------------
c
      N = 0
      K = 0
      LastErr = 0
      do 100 M = 1, LNBlnk(ColNam)
        if (ColNam(M:M) .eq. '|') then
          N = N + 1
          NF = N - 1
          if (N .gt. 1) IFb(N-1) = M-1
          if (N .gt. MaxFld) return
          IFa(N) = M
          do 10 L = 1, 25
            Field(N)(L:L) = ' '
10        continue
          K = 0
        else
          if (ColNam(M:M) .ne. ' ') then
            K = K + 1
            if (K .le. 25) then
              Field(N)(K:K) = ColNam(M:M)
            else
              if (LastErr .ne. N) then
                write(Line,*) N
                Line = 'GetFlds - Table column name no. '
     +               //Line(1:lnblnk(Line))//' longer than 25 '
     +               //'characters: '//Field(N)//'....; excess ignored'
                print *,Line(1:lnblnk(line))
                LastErr = N
              end if
            end if
          end if
        end if
100   continue
c
      return
      end
c      
c=======================================================================
c
      subroutine DoHist(msk,MskBitHist)
c
      integer*4 msk, MskBitHist(32), n
      logical*4 BitSet
c
c-----------------------------------------------------------------------
c
      do 10 n = 1, 32
        if (BitSet(msk,n-1)) MskBitHist(n) = MskBitHist(n) + 1
10    continue
c
      return
      end
c      
c=======================================================================
c
      Logical*4 Function BitSet(I4Var,NBit)
C-----------------------------------------------------------------------
C     Returns .TRUE. iff Bit no. "NBit" in "I4Var" is set (turned on)
C     LSB = bit no. 0, MSB = bit no. 30, Sign Bit = bit no. 31
C-----------------------------------------------------------------------
      Integer*4 NBit,NWarns,IAnd
      Integer*4 I4Var,Power(32)
      Data NWarns/0/
      Data Power/1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,
     + 16384,32768,65536,131072,262144,524288,1048576,2097152,
     + 4194304,8388608,16777216,33554432,67108864,134217728,
     + 268435456,536870912,1073741824,-2147483648/
C-----------------------------------------------------------------------
C
      If ((NBit .lt. 0) .or. (NBit .gt. 31)) Then
        NWarns = NWarns + 1
        If (NWarns .le. 10) Write(6, 6000) NBit
        If (NWarns .eq. 10) Write(6, 6001)
        BitSet = .False.
        Return
      End If
C
      BitSet = IAnd(I4Var, Power(NBit+1)) .ne. 0
C
      Return
C-----------------------------------------------------------------------
6000  Format(' BitSet: Warning! bit number outside range (0 - 31), ',
     + I21)
6001  Format('         This is the last warning that will be printed')
C-----------------------------------------------------------------------
      End
c      
c=======================================================================
c
      Subroutine ClrBit(I4Var,NBit)
C-----------------------------------------------------------------------
C     Clear Bit no. "NBit" in "I4Var"
C     LSB = bit no. 0, MSB = bit no. 30, Sign Bit = bit no. 31
C-----------------------------------------------------------------------
      Integer*4 NBit,NWarns
      Integer*4 I4Var,Power(32)
      Data NWarns/0/
      Data Power/-2,-3,-5,-9,-17,-33,-65,-129,-257,-513,-1025,-2049,
     +           -4097,-8193,-16385,-32769,-65537,-131073,-262145,
     +           -524289,-1048577,-2097153,-4194305,-8388609,-16777217,
     +           -33554433,-67108865,-134217729,-268435457,-536870913,
     +           -1073741825,2147483647/
C-----------------------------------------------------------------------
C
      If ((NBit .lt. 0) .or. (NBit .gt. 31)) Then
        NWarns = NWarns + 1
        If (NWarns .le. 10) Write(6, 6000) NBit
        If (NWarns .eq. 10) Write(6, 6001)
        Return
      End If
C
      I4Var = IAnd(I4Var,Power(NBit+1))
C
      Return
C-----------------------------------------------------------------------
6000  Format(' ClrBit: Warning! bit number outside range (0 - 31), ',
     + I21)
6001  Format('         This is the last warning that will be printed')
C-----------------------------------------------------------------------
      End
c      
c=======================================================================
c
      Subroutine SetBit(I4Var,NBit)
C-----------------------------------------------------------------------
C     Set Bit no. "NBit" in "I4Var"
C     LSB = bit no. 0, MSB = bit no. 30, Sign Bit = bit no. 31
C-----------------------------------------------------------------------
      Integer*4 NBit,NWarns, IOr
      Integer*4 Power(32),I4Var
      Data NWarns/0/
      Data Power/1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,
     + 16384,32768,65536,131072,262144,524288,1048576,2097152,
     + 4194304,8388608,16777216,33554432,67108864,134217728,
     + 268435456,536870912,1073741824,-2147483648/
C-----------------------------------------------------------------------
C
      If ((NBit .lt. 0) .or. (NBit .gt. 31)) Then
        NWarns = NWarns + 1
        If (NWarns .le. 10) Write(6, 6000) NBit
        If (NWarns .eq. 10) Write(6, 6001)
        Return
      End If
C
      I4Var = IOr(I4Var, Power(NBit+1))
C
      Return
C-----------------------------------------------------------------------
6000  Format(' SetBit: Warning! bit number outside range (0 - 31), ',
     + I21)
6001  Format('         This is the last warning that will be printed')
C-----------------------------------------------------------------------
      End
c
c=======================================================================
c
      function OKhdr(Line)
c
      Character*5000 Line
      logical*4 OKhdr
c
c-----------------------------------------------------------------------
c
      if (index(Line,'\Nsrc =')                       .gt. 0) go to 100
      if (index(Line,'\ number of unWISE epochs eng') .gt. 0) go to 100
      if (index(Line,'\ bands engaged:   1  1  0  0') .gt. 0) go to 100     
      if (index(Line,'\ zero mags(band):  22.500 22') .gt. 0) go to 100 
      if (index(Line,'\ band =  1  standard Rap(ban') .gt. 0) go to 100 
      if (index(Line,'\ band =  2  standard Rap(ban') .gt. 0) go to 100 
      if (index(Line,'\ band =  1  circ apertures R') .gt. 0) go to 100 
      if (index(Line,'\ band =  2  circ apertures R') .gt. 0) go to 100 
      if (index(Line,'\ MJD0 = ')                     .gt. 0) go to 100
      if (index(Line,'\ cleanup vsn')                 .gt. 0) go to 100
      if (index(Line,'\EQUINOX = "J2000"')            .gt. 0) go to 100
c
      OKhdr = .false.
      return
c
100   OKhdr = .true.
      return
c
      end
c
c=======================================================================
c
      Subroutine NextNarg(NArg,NArgs)
c
      integer NArg, NArgs
c
c-----------------------------------------------------------------------
c
      if (NArg .lt. NArgs) then
        NArg = NArg + 1
        return
      else
        print *,'ERROR: expected another argument but none found'
        call exit(64)
      end if
      return
      end
c
c=======================================================================
c
      subroutine upcase(string)
      character*(*) string
      integer*4 j, lnblnk
c
      do 10 j = 1,lnblnk(string)
         if(string(j:j) .ge. "a" .and. string(j:j) .le. "z") then
            string(j:j) = achar(iachar(string(j:j)) - 32)
         end if
10    continue
      return
      end      
c
c=======================================================================
c
	subroutine readFhead(fname,Hdr)

	implicit integer (i-n)
        implicit real*4 (a-h)
        implicit real*4 (o-z)

C  Print out all the header keywords in all extensions of a FITS file

	character*(*) fname,Hdr
	real*4 cdelt1, cdelt2
      integer status,unit,readwrite,blocksize,nkeys,nspace,hdutype,i,j
      integer L,numchar,nl,nh
      character record*80
      character*80 comment


C  The STATUS parameter must always be initialized.
      status=0
C     open the FITS file, with read-only access.  The returned BLOCKSIZE
C     parameter is obsolete and should be ignored.

	call ftgiou(unit,status)

	L = numchar(fname)
c	write (6,'(a)') ' '
c	write (6,'(a)') fname(1:L)

	status = 0
      readwrite=0
      call ftopen(unit,fname(1:L),readwrite,blocksize,status)

	if (status.ne.0) then
		write (6,*) 'problem reading header ',status
		write (6,'(a)') fname(1:L)
	endif


c	cdelt1 = 0.
c        cdelt2 = 0.
c        call ftgkye(unit, 'CDELT1', cdelt1, comment, status)
c        if (status.gt.0) status=0
c
c        call ftgkye(unit, 'CDELT2', cdelt2, comment, status)
c        if (status.gt.0) status=0

cwrite (6,*) status

C  The FTGHSP subroutine returns the number of existing keywords in the
C  current header data unit (CHDU), not counting the required END keyword,
      call ftghsp(unit,nkeys,nspace,status)

c	write (6,*) status,nkeys
	Hdr = ''

C  Read each 80-character keyword record, and print it out.
	nl = 1
      do i = 1, nkeys
          call ftgrec(unit,i,record,status)
c         write (6,'(a)') record

	  nh = nl + 79

	  if (nh.gt.150000) goto 47

c	write (6,*) nl,nh
	  Hdr (nl:nh) = record
	  nl = nh + 1

      end do

 47 	call ftclos(unit, status)
        call ftfiou(unit, status)


	return
	end
c
c=======================================================================
c
        INTEGER FUNCTION NUMCHAR(CSTRING)

C       This function determines the length of the character string
C       in cstring.

C       Author: Richard J. Stover
C       Added strong typing: D. Van Buren, T. Jarrett

      implicit integer (i-n)
        implicit real(4) (a-h)
        implicit real(4) (o-z)

        CHARACTER*(*) CSTRING
c       Integer*4     I
        Integer(4)    I                     !NRG B60616

        IF(CSTRING .EQ. ' ') THEN
          NUMCHAR = 0
        ELSE
        DO 8701 I=LEN(CSTRING),1,-1

        IF (CSTRING(I:I) .NE. ' ' .AND. ICHAR(CSTRING(I:I)) .NE. 0)
     &        GOTO 50
        IF (ICHAR(CSTRING(I:I)) .EQ. 0) CSTRING(I:I) = ' '
 8701      CONTINUE
 50        NUMCHAR=I
         END IF

         RETURN
         END
c
c=======================================================================
c
      function kBadness(ccflag)
      
      integer*4   kBadness, k
      Character*1 ccflag, ccflags(9)
      data ccflags/'D','P','H','O','d','p','h','o','0'/
c
      do 10 k = 1, 9
        if (ccflag .eq. ccflags(k)) then
          kBadness = 10 - k
          return
        end if
10    continue
c
      kBadness = 0
      return
      end
      
