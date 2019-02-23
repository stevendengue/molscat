      SUBROUTINE CPL22(N,MXLAM,NPOTL,LAM,NSTATE,JSTATE,JSINDX,MVALUE,IV,
     1                 VL,IPRINT,LFIRST)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  CS COUPLING MATRIX FOR VIBRATING ROTOR-ATOM (ITYPE=22)
C  SEE (FOR EXAMPLE) EQN 30 OF MCGUIRE AND KOURI JCP (1974) 60 2488
C  S Green (MAR 94) USES IV(), I.E., IVLFL=1
C                   SAVES COUPLING MATRIX FOR MV=0,MX  IN UPPER X() ARRAY
C                   USES J3J000 ROUTINE AS PER JMH CPL21 CODE
C                   STORES ON J OR NSTATE, DEPENDING ON WHICH IS SMALLER
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE NOMEM,NL12,IXMX,ISTART,IFIRST,LOGIX,JTOP
C  SPECIFICATIONS FOR ARGUMENTS
      DIMENSION LAM(3,MXLAM),JSTATE(NSTATE),JSINDX(N),VL(1),IV(1)
      INTEGER IPRINT
      LOGICAL LFIRST
C
      LOGICAL LODD,NOMEM,LOGIX
      DATA Z0/0.D0/
C
C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C
C  STATEMENT FUNCTION DEFINITIONS
      Z(I)=DBLE(I+I+1)
      LODD(I)=I-2*(I/2).NE.0
C
C  IF LFIRST IS TRUE (FIRST CALL), DO SOME INITIALIZATION
      IF (LFIRST) THEN
        IFIRST=-1
        LFIRST=.FALSE.
        NOMEM=.FALSE.
      ENDIF
C
      XM=MVALUE
      PM=1.D0
      IF (LODD(MVALUE)) PM=-1.D0
C
      IF (IFIRST.GT.-1) GOTO 3500

C  FIRST TIME THROUGH SET UP SOME STORAGE POINTERS.
C  LOGIX=.TRUE. IF JTOP IS SMALLER THAN NSTATE (SO STORE ON J)
      JTOP=0
      DO 3400 I=1,NSTATE
 3400   JTOP=MAX(JTOP,JSTATE(I))
      LOGIX=JTOP.LT.NSTATE
      IF (LOGIX) THEN
        NL12=(JTOP+1)*(JTOP+2)/2
      ELSE
        NL12=NSTATE*(NSTATE+1)/2
      ENDIF
      IXMX=NL12*NPOTL
      ISTART=MX+1
C
 3500 MVABS=ABS(MVALUE)
C  SEE IF VALUES ARE STORED FOR THIS HIGH AN MVALUE
C  IF NOT, TRY TO STORE THEM IN XCPL().
      IF (MVABS.LE.IFIRST .OR. NOMEM) GOTO 3900

      MV=IFIRST+1
C  FIRST CHECK THAT WE STILL HAVE A CONTINUOUS BLOCK OF HI MEMORY.
 3600 IF (MX.EQ.ISTART-(IFIRST+1)*IXMX-1) GOTO 3610
      IF (IPRINT.GE.1) WRITE(6,602) MV,ISTART-1,MX,IXMX*(IFIRST+1)
  602 FORMAT(/'  CPL22 (FEB 93).  HIGH MEMORY FRAGMENTED.  CANNOT',
     1       ' STORE COUPLING COEFFS FOR MVAL =',I3/ 19X,
     2       'ORIGINAL MINUS CURRENT MEMORY LIMITS .NE. NO. USED =',
     3       3I12)
      NOMEM=.TRUE.
      GOTO 3900

C  TEST FOR AVAILABLE STORAGE; NEED IXMX FOR THIS MVAL
 3610 NAVAIL=MX-IXNEXT+1
      IF (IXMX.LE.NAVAIL) GOTO 3601

      IF (IPRINT.GE.3) WRITE(6,692) MV,IXMX,NAVAIL
  692 FORMAT(/'  CPL22 (FEB 93).   UNABLE TO STORE 3-J VALUES FOR ',
     1        'MVAL =',I3/
     2        '                    REQUIRED AND AVAILABLE STORAGE =',
     3        2I9)
C  SET NOMEM TO REFLECT INABILITY TO ADD MORE M-VALUES
      NOMEM=.TRUE.
      GOTO 3900
C
C  REDUCE 'TOP OF MEMORY' AND STORE COUPLING VALUES FOR THIS MVAL
C  START INDEX AFTER M-BLOCKS ALREADY STORED (STARTING W/ MV=0)
 3601 MX=MX-IXMX
      IX=MV*IXMX
C
C  THIS SECTION OF CODE CALCULATES THE COUPLING MATRIX ELEMENTS USING
C  THE SUBROUTINE J3J000 WHICH CALCULATES A WHOLE SET OF 3J
C  COEFFICIENTS (J1 J2 J3).  THE MATRIX ELEMENTS ARE STORED IN X
C               ( 0  0  0)
      PMV=1.D0
      IF (LODD(MV)) PMV=-1.D0
C  CODE BELOW FROM V12 (DEC 94) CPL21 CODE
C  EXCEPT LIMIT ON IL LOOP AND VALUE OF LM
      IF (LOGIX) THEN
        ITOP=JTOP+1
      ELSE
        ITOP=NSTATE
      ENDIF
      DO 3200 IL=1,NPOTL
        LM=IL-1
        JSAV=-1
        ITJ=IXNEXT
        IXNEXT=ITJ+LM+LM+1
        NUSED=0
        CALL CHKSTR(NUSED)
        DO 3201 I1=1,ITOP
          IF (LOGIX) THEN
            J1=I1-1
          ELSE
            J1=JSTATE(I1)
          ENDIF
          IF (J1.NE.JSAV) THEN
            CALL J3J000(DBLE(J1),DBLE(LM),IVALJ,X(ITJ),XJMIN)
            JMIN=ABS(J1-LM)
            JMAX=J1+LM
            JSAV=J1
          ENDIF
        DO 3201 I2=1,I1
          IF (LOGIX) THEN
            J2=I2-1
          ELSE
            J2=JSTATE(I2)
          ENDIF
          IX=IX+1
          IF (J2.LT.JMIN .OR. J2.GT.JMAX .OR. J1.LT.MV .OR.
     1        J2.LT.MV .OR. LODD(J2+JMAX)) THEN
            X(ISTART-IX)=0.D0
          ELSE
            INDJ=ITJ+(J2-JMIN)/2
            IF (MV.EQ.0) THEN
              X(ISTART-IX)=PMV*SQRT(Z(J1)*Z(J2))*X(INDJ)**2
            ELSE
              X(ISTART-IX)=PMV*SQRT(Z(J1)*Z(J2))*X(INDJ)*
     1          THRJ(DBLE(J1),DBLE(LM),DBLE(J2),-DBLE(MV),0.D0,DBLE(MV))
            ENDIF
          ENDIF
 3201   CONTINUE
 3200   IXNEXT=ITJ
C
      IF (IPRINT.GE.4) WRITE(6,693) MV,IXMX,NAVAIL
  693 FORMAT(/'  CPL22 (FEB 93).   3-J VALUES STORED FOR MVAL =',I3
     1       /'                    REQUIRED AND AVAILABLE STORAGE =',
     2       2I9)
C
C  RESET IFIRST TO REFLECT HIGHEST M-VALUE STORED.
      IFIRST=MV
C
C  SEE IF CURRENT MVALUE REQUIRES MORE STORED M-VALUES.
      MV=MV+1
      IF (MV.LE.MVABS) GOTO 3600
C
C  THIS SECTION OF CODE TRANSFERS THE COUPLING MATRIX ELEMENTS FROM THE
C  ARRAY X WHERE THEY WERE PREVIOUSLY STORED INTO THE VL ARRAY, CHANGING
C  SIGNS AS NECESSARY.
C
C  START BY ZEROING VL, IV ARRAYS
 3900 NTOP=NPOTL*N*(N+1)/2
      DO 3999 I=1,NTOP
        VL(I)=0.D0
 3999   IV(I)=0
      IF (MVABS.GT.IFIRST) GOTO 3800

      IXM=MVABS*IXMX
      NZERO=0
      DO 3513 LL=1,MXLAM
        NNZ=0
        LM=LAM(1,LL)
        NV=LAM(2,LL)
        NV1=LAM(3,LL)
C  ICR COUNTS ICOL,IROW LOOP; NEEDED FOR IXVL (VL INDEX)
        ICR=0
        DO 3503 ICOL=1,N
          I1=JSINDX(ICOL)
          J1 =JSTATE(     I1)
          NVC=JSTATE(NSTATE+I1)
        DO 3503 IROW=1,ICOL
          I2=JSINDX(IROW)
          J2 =JSTATE(     I2)
          NVR=JSTATE(NSTATE+I2)
          ICR=ICR+1
          IF ((NV.EQ.NVC .AND. NV1.EQ.NVR) .OR.
     1        (NV.EQ.NVR .AND. NV1.EQ.NVC)) THEN
C  FIRST GET INDEX IN VL, IV
            IXVL=(ICR-1)*NPOTL+LM+1
C  THEN GET INDEX OF STORED COUPLING COEFFICIENT, DEPENDING ON LOGIX
            IF (LOGIX) THEN
              IF (J1.GT.J2) THEN
                IX12=(J1+1)*J1/2+J2+1
              ELSE
                IX12=(J2+1)*J2/2+J1+1
              ENDIF
            ELSE
              IF (I1.GT.I2) THEN
                IX12=I1*(I1-1)/2+I2
              ELSE
                IX12=I2*(I2-1)/2+I1
              ENDIF
            ENDIF
            IX=IXM+LM*NL12+IX12
            IV(IXVL)=LL
            VL(IXVL)=X(ISTART-IX)
            IF (VL(IXVL).NE.0.D0) NNZ=NNZ+1
C  WE HAVE STORED COUPLING FOR POSITIVE MVALUES; CORRECT IF NEC
            IF (MVALUE.LT.0 .AND. LODD(J1+J2+LM)) VL(IXVL)=-VL(IXVL)
          ENDIF
 3503   CONTINUE
        IF (NNZ.LE.0) THEN
          NZERO=NZERO+1
          IF (IPRINT.GE.14) WRITE(6,612) MVALUE,LL
        ENDIF
  612   FORMAT('  * * * NOTE.  FOR MVALUE =',I4,',  ALL COUPLING '
     1         'COEFFICIENTS ARE 0.0 FOR EXPANSION TERM',I4)
 3513 CONTINUE

      IF (NZERO.GT.0 .AND. IPRINT.GE.10 .AND. IPRINT.LT.14)
     1  WRITE(6,620) MVALUE,NZERO
  620 FORMAT('  * * * NOTE.  FOR MVALUE =',I4,',  ALL COUPLING ',
     1       'COEFFICIENTS ARE 0.0 FOR',I5,' POTENTIAL EXPANSION TERMS')

      RETURN
C
C  THIS SECTION OF CODE CALCULATES COUPLING MATRIX ELEMENTS USING
C  FUNCTION THREEJ WHICH PRODUCES A SINGLE 3J COEFFICIENT (J1 J2 J3)
C                                                         ( 0  0  0).
C  MV.GT.IFIRST ==> VALUES NOT STORED.  CALCULATE THEM
 3800 NZERO=0
      DO 1511 LL=1,MXLAM
        LM=LAM(1,LL)
        NV=LAM(2,LL)
        NV1=LAM(3,LL)
        XLM=LM
        NNZ=0
C  ICR COUNTS ICOL,IROW LOOP; NEEDED FOR IXVL (VL INDEX)
        ICR=0
        DO 1501 ICOL=1,N
          JCOL=JSTATE(     JSINDX(ICOL))
          XJCOL=JCOL
          NVC =JSTATE(NSTATE+JSINDX(ICOL))
        DO 1501 IROW=1,ICOL
          JROW=JSTATE(     JSINDX(IROW))
          XJROW=JROW
          NVR =JSTATE(NSTATE+JSINDX(IROW))
          ICR=ICR+1
          IF ((NV.EQ.NVC .AND. NV1.EQ.NVR) .OR.
     1        (NV.EQ.NVR .AND. NV1.EQ.NVC)) THEN
            IXVL=(ICR-1)*NPOTL+LM+1
            IV(IXVL)=LL
            VL(IXVL)=PM*SQRT(Z(JROW)*Z(JCOL))*THREEJ(JROW,LM,JCOL)*
     &                                   THRJ(XJROW,XLM,XJCOL,-XM,Z0,XM)
            IF (VL(IXVL).NE.0.D0) NNZ=NNZ+1
          ENDIF
 1501   CONTINUE
        IF (NNZ.LE.0) THEN
          NZERO=NZERO+1
          IF (IPRINT.GE.14) WRITE(6,612) MVALUE,LL
        ENDIF
 1511 CONTINUE

      IF (NZERO.GT.0 .AND. IPRINT.GE.10 .AND. IPRINT.LT.14)
     1  WRITE(6,620) MVALUE,NZERO

      RETURN
      END
