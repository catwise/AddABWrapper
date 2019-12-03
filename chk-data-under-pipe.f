c
                     Integer*4  MaxFld
                     Parameter (MaxFld = 1000)
c
      Character*5000 Line, HdrLine
      Character*500  InFNam
      Character*25   Field(MaxFld)
      Integer*4      LNBlnk, IFa(MaxFld), IFb(MaxFld), NF, IArgC,
     +               nHead, nRow, j, nUnderPipe, nIn
c
      data nHead/0/, nRow/0/, nUnderPipe/0/, nIn/0/
c
c-----------------------------------------------------------------------
c
      if (IArgc() .ne. 1) then
        print *,'chk-data-under-pipe vsn 1.0  B91203'
        print *,'usage: chk-data-under-pipe filename'
        print *,'where: filename is the name of a table file'
        print *
        print *,'up to ten instances of non-blank characters under a'
        print *,'pipe will be echoed to stdout'
        stop
      end if
c
      Call GetArg(1,InFNam)
        if (Access(InFNam(1:LNBlnk(InFNam)),' ') .ne. 0) then
          print *
          print *,'ERROR: file not found: ', InFNam(1:LNBlnk(InFNam))
          stop
      end if
c
5     open (10, file = InFNam)
6     read (10,'(a)', end = 3000) Line
      nIn = nIn + 1
      if (Line(1:1) .eq. '\') go to 6
      if (Line(1:1) .eq. '|') then
        nHead = nHead + 1
        if (nHead .eq. 1) then
          HdrLine = Line
          call GetFlds(HdrLine,Field,IFa,IFb,NF)  ! for "under-pipe" check
        end if
        go to 5
      end if
c
100   nRow = nRow + 1
      do 200 j = 1, NF
        if (Line(IFa(j):IFa(j)) .ne. ' ') then
          nUnderPipe = nUnderPipe + 1
          if (nUnderPipe .le. 10) then
            print *,'data under pipe #',j,' on Row ',nRow,
     +            ', input line #',nIn
            print *,HdrLine(IFa(j):IFb(j))
            print *,Line(IFa(j):IFb(j))
          end if
        end if
200   continue
c
      read (10,'(a)', end = 1000) Line
      nIn = nIn + 1
      go to 100
c
1000  if (nUnderPipe .gt. 0) then
        print *,'No. of instances of non-blank character under a pipe:',
     +           nUnderPipe
      else
        print *,'No instances of non-blank character under a pipe found'
      end if
      stop
c
3000  print *,'ERROR: end-of-file encountered during sanity check'
      call exit(64)
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
