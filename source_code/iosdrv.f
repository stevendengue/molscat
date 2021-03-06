      SUBROUTINE IOSDRV(NNRG,NPR,ENERGY,JTOTL,JTOTU,JSTEP,TEST,NCAC,
     1                  IFLS,LINE,LTYPE,ITYPE,LMAX,MMAX,
     2                  IPROGM,URED,LABEL,IREF,IPOT,
     3                  LAMBDA,MXLAM,NPOTL,CINT,IRMSET,IRXSET,RVFAC,
     4                  IPRINT,NVC,ISAVEU,TITIME,RM,EPSIL,RMIN,
     5                  RMAX,MONQN,IBOUND,WAVE,ERED,RMLMDA,DRMAX,NSTAB,
     6                  ILDSVU)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  INTEGRATED MOLSCAT/IOS IMPLEMENTED APR 86 CAMBRIDGE, ENGLAND.
C   -- A GUTTED VERSION OF IOS1, INTERFACED TO CCP6 MOLSCAT.
C  THIS IS A DRIVER FOR THE IOS CODE;  MOLSCAT/DRIVER CALLS
C  BASIN TO READ &BASIS, WHICH THEN CALLS IOSBIN.
C  DRIVER THEN CALLS POTENL TO GET &POTL DATA,
C  AND FINALLY CALLS IOSDRV TO SET UP AND PERFORM IOS CALCULATION.
C
      INTEGER IPRINT
      DIMENSION ENERGY(NNRG),TEST(2),LINE(*),LTYPE(*),
     1          LAMBDA(MXLAM),MONQN(*)
      LOGICAL WAVE
      CHARACTER(80) LABEL
C
C  LAST CHANGED 1/19/93.   NEW DYNAMIC MEMORY HANDLING
C  ** VERSION 6 / OCT  85/ ADDS ITYPE=6 CAPABILITY
C                        / ALSO ALLOWS "UNEXPANDED" POTL, V(R,ANGLES)
C  ** VERSION 5 / MAR  81/ ADDS INTFLG=4 (MOLSCAT V.8)
C               / JUNE 82/ REPLACES PLM WITH R. T PACK VERSION.
C  ** VERSION 4 / MAY. 78/ ADDS ITYPE=5 CODE.
C               / SEP. 78/ **TEMPORARY** ISAVEU CAPABILITY
C               / APR. 79/ CHANGED FOR ISCRU (MOLSCAT V.7) COMPATABIL
C  ** VERSION 3 / DEC. 77/ IS TOTALLY NEW ORGANIZATION TO ACCOMMODATE
C                          ITYPE=2 (VIBROTOR - ATOM)
C  ** VERSION 2 / OCT. 77/ ADDS WKB (R.T PACK) CAPABILITY **
C  ** VERSION 1 / SEP. 77/ INTERFACE HOUSTON PROGRAM W/MOLSCAT.
C

C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
      COMMON /VLFLAG/ IVLFL

C  MX,IXNEXT ARE MAX AND NEXT AVAILABLE LOCATION IN X() ARRAY
C  IVLFL FLAGS WHETHER IV() ARRAY IS USED AS POINTED W/ VL ARRAY.
C  NIPR IS NUMBER OF INTEGERS PER REAL; SHOULD BE 1 OR 2.
C
C  MUST INITIALIZE NUSED NON-NEGATIVE BEFORE CALL CHKSTR
      NUSED=0
      WRITE(6,68)
   68 FORMAT(/'  IOSDRV ENTERED.  SET-UP FOR INFINITE ORDER SUDDEN',
     1       ' CALCULATION.')
C
C  CONTINUE WITH SET-UP FOR IOS.  PROCESS &POTL LAM(MXLAM) DATA
C  SET NGPT, LMAX AND GAUSS PTS/WTS.
C  N.B. LMAX/MMAX INITIALLY CONTAIN HIGHEST L,M VALUES
C  DESIRED FOR QLM.  LMAX IS RESET TO EQUAL THE *NUMBER* OF L,M
C  VALUES IN LM,SLLR,SLLI,ETC.
      CALL IOSBGP(MXLAM,LAMBDA,MXXXXL,NGPT,LMAX,MMAX,NQL,NIXQL)
C
C     V11 CODE EXPECTED IC TO BE STORAGE USED SO FAR
      ISVMEM=IXNEXT
      IC=IXNEXT-1
      IXSR=IXNEXT            ! SR
      IXSI=IXSR+NVC*NVC      ! SI
      IXKMAT=IXSI+NVC*NVC    ! KMAT
      IXWV=IXKMAT+NVC*NVC    ! WVEC
      IXEINT=IXWV+NVC        ! EINT
      IXCENT=IXEINT+NVC      ! CENT
      IXVL=IXCENT+NVC        ! VL
      NV=NVC*(NVC+1)*NPOTL/2
      IXJIND=IXVL+NV         ! JSINDX
      IXLORB=IXJIND+NVC      ! L
      IXNB=IXLORB+NVC        ! NB
      IXIV=IXNB+NVC          ! IV
      IC=IXIV
      IF (IVLFL.GT.0) IC=IXIV+(NV+NIPR-1)/NIPR
C
C  IOS VARIABLES:
C    VLI(NGPT,MXXXXL),PWGHT(NGPT,LMAX),SLR(NVC,NVC,NGPT),
C    SLI(NVC,NVC,NGPT),SIGTH(NVC,NVC,NGPT),SIGAV(NVC,NVC),
C    QLS(NVC,NVC),QLT(NVC,NVC,NQL),IEC(NQL ),IXQL(NIXQL,NQL)
C    SLLR(NVC,NVC,LMAX),SLLI(NVC,NVC,LMAX),LM(3,LMAX)
C
      IXVLI=IC                          ! VLI
      IXPW=IXVLI+MXXXXL*NGPT            ! PWGHT
      IXSLR=IXPW+NGPT*LMAX              ! SLR
      IXSLI=IXSLR+NVC*NVC*NGPT          ! SLI
      IXSGTH=IXSLI+NVC*NVC*NGPT         ! SIGTH
      IXSGAV=IXSGTH+NVC*NVC*NGPT        ! SIGAV
      IXQLS=IXSGAV+NVC*NVC              ! QLS
      IXQLT=IXQLS+NVC*NVC               ! QLT
      IXSLLR=IXQLT+NVC*NVC*NQL          ! SLLR
      IXSLLI=IXSLLR+NVC*NVC*LMAX        ! SLLI
      IXIEC=IXSLLI+NVC*NVC*LMAX         ! IEC
      IXQL=IXIEC+(NQL+NIPR-1)/NIPR      ! IXQL
      IXLM=IXQL+(NIXQL*NQL+NIPR-1)/NIPR ! LM
      IC=IXLM+(3*LMAX+1)/NIPR
      WRITE(6,681) NVC,NGPT,LMAX,MXXXXL,NQL,NIXQL,IC
  681 FORMAT(/'  STORAGE ALLOCATED FOR  NVC (NO. VIB. CHANNELS) =',T60,
     1       I4/25X,'NGPT (NO. GAUSS PTS.) =',T58,I6/
     2       25X,'LMAX (NO. LEGENDRE COEFFS.) =',T60,I4/
     3       25X,'MXXXXL (NO. SYMMETRIES IN POTL) =',T60,I4/
     4       25X,'NQL (NO. QLT) =',T60,I4/
     5       25X,'NIXQL (NO. INDICES IN IXQL) =',T60,I4/
     6       25X,'NEXT LOCATION =',T54,I10)
C  IC IS NOW 'NEXT STORAGE LOCATION'
      IXNEXT=IC
      CALL CHKSTR(NUSED)
C
C  SET UP PWGHT, VLI TABLES  -  ALSO IXQL TABLE
C
      CALL IOSB1(X(IXPW),X(IXVLI),X(IXQL),X(IXLM),NGPT,LMAX,MXXXXL,
     1           NIXQL,NQL)
C
      IF (ISAVEU.LE.0)  GOTO 3000
C
C  ISAVEU OUTPUT -- MAY 92 VERSION
C
      WRITE(6,3600) ISAVEU
 3600 FORMAT(///'  QLS/QLT SAVED (MAY 92 FORMAT) ON UNIT ISAVEU =',I3)
      IPOUT=100+IPROGM
      ITOUT=100+ITYPE-100*(ITYPE/100)
      WRITE(ISAVEU,3601) LABEL,ITOUT,NVC,NQL,URED,IPOUT
 3601 FORMAT(2X,A80/3I4,F8.4,I4)
C
 3000 CALL GCLOCK(TJTIME)
      TIME=TJTIME-TITIME
      WRITE(6,640) TIME
  640 FORMAT(/'  TIME TO SET UP CALCULATION WAS',F8.2,
     1       '   SECONDS.  EXIT IOSDRV')
      WRITE(6,69)
   69 FORMAT(/30('===='))
C
C  PASS CONTROL TO IOSCLC TO DO CALCULATION.
C
      CALL IOSCLC(NNRG,ENERGY,JTOTL,JTOTU,JSTEP,IPRINT,ISAVEU,
     1            ITYPE,RMIN,RMAX,IRMSET,IRXSET,RVFAC,
     2            NCAC,TEST,RM,EPSIL,NVC,LMAX,NGPT,NQL,
     3            NIXQL,MXXXXL,LAMBDA,MXLAM,NPOTL,X(IXVLI),
     4            X(IXPW),X(IXSLR),X(IXSLI),X(IXQLT),X(IXQLS),
     5            X(IXSLLR),X(IXSLLI),X(IXQL),X(IXSGTH),X(IXSGAV),
     6            X(IXIEC),X(IXLM),IXSR,IXSI,IXKMAT,IXVL,IXIV,IXEINT,
     7            IXCENT,IXWV,IXJIND,IXLORB,IXNB,X(IXWV),X(IXNB),IREF,
     8            IFLS,LINE,LTYPE,IPOT,MONQN,IBOUND,WAVE,
     9            ERED,RMLMDA,DRMAX,NSTAB,ILDSVU)
C
C  RELEASE STORAGE USED BY IOSDRV/IOSCLC/SCCTRL
      IXNEXT=ISVMEM
      RETURN
      END
