      SUBROUTINE PRBR3(N,SREAL,SIMAG,JTOT,NSTATE,NQN,JSTATE,NBASIS,
     1                 JSINDX,L,NPACK,LINE,NLVAL,IC,IL,SR,SI,
     2                 TR,JBAR,ISTB,NBLK,LVAL)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  PRBR3 IS AN INTERFACE ROUTINE WHICH TRANSFORMS ITYPE=3 S-MATRICES
C  INTO FORMAT NECESSARY FOR PRESSURE BROADENING CALC..
C  THIS NECESSITATES TRANSFORM FROM J1,J2(J12)L,JTOT TO
C  J1(J2,L)JBAR,JTOT REPRESENTATION.  IC, IL MADE COMPATIBLE.
C
C  SREAL, SIMAG ARE STORED TEMPORARILY IN SR, SI WHICH MUST BE
C  RESTORED (VIA ENTRY PRBR3R) BEFORE RETURNING CONTROL FROM PRBR.
C  4 JUN 93: REMOVE LIMITS ON INTERNALLY DEFINED WORKING STORAGE
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION SREAL(N,N),SIMAG(N,N)
      DIMENSION SR(N,N),SI(N,N),TR(N,N),JBAR(N),ISTB(N),NBLK(N),LVAL(N)
      INTEGER JSTATE(NSTATE,NQN),NBASIS(N),JSINDX(N),L(N),IC(N),IL(N)
C
      DATA ZERO/0.D0/
C
C  STATEMENT FUNCTION DEFINITION.
      Z(I)=I+I+1
C
C  SAVE SREAL, SIMAG IN SR, SI AND CLEAR SREAL, SIMAG.
 1000 DO 1100 I1=1,N
      DO 1100 I2=1,N
        SR(I1,I2)=SREAL(I1,I2)
        SREAL(I1,I2)=0.D0
        SI(I1,I2)=SIMAG(I1,I2)
 1100   SIMAG(I1,I2)=0.D0
C
C  PICK OUT ROWS OF S WHICH CORRESPOND TO 'LINE' AND GROUP INTO
C  BLOCKS WITH SAME L-VALUE.
C  NB IS NO. OF BLOCKS, IC IS TABLE OF ALL
C  (NLVAL) ROWS, IL HAS J12 VALUES, ISTB HAS (START-1) IN IC OF
C  EACH BLOCK, NBLK HAS NO. IN EACH BLOCK.
      NB=0
      NLVAL=0
      DO 2000 II=1,N
        JJ=NBASIS(II)
        IF (JSTATE(JSINDX(JJ),NQN).NE.LINE) GOTO 2000
C  CHECK TO SEE THAT THIS ISN'T ALREADY IN IC. . .
        IM=NLVAL
 2100   IF (IM.LE.0) GOTO 2200
        IF (II.EQ.IC(IM)) GOTO 2000
        IM=IM-1
        GOTO 2100
C  IF NOT, START A NEW BLOCK. . .
 2200   NB=NB+1
        ISTB(NB)=NLVAL
        NBLK(NB)=1
        LVAL(NB)=L(JJ)
        NLVAL=NLVAL+1
        IC(NLVAL)=II
        IL(NLVAL)=JSTATE(JSINDX(JJ),3)
C  PROCESS REMAINING TO FIND OTHER WITH SAME L-VALUE. . .
        II1=II+1
        IF (II1.GT.N) GOTO 2000
        DO 2500 II2=II1,N
          JJ=NBASIS(II2)
          IF (JSTATE(JSINDX(JJ),NQN).NE.LINE) GOTO 2500
          IF (L(JJ).NE.LVAL(NB)) GOTO 2500
          NBLK(NB)=NBLK(NB)+1
          NLVAL=NLVAL+1
          IC(NLVAL)=II2
          IL(NLVAL)=JSTATE(JSINDX(JJ),3)
 2500   CONTINUE
 2000 CONTINUE

      IF (NLVAL.LE.0) RETURN
C
C  DO BOOKEEPING FOR TRANSFORMATION AND GET JBAR VALUES.
C  GET JA, J2 FROM 1ST MEMBER - SHOULD BE SAME FOR ALL.
      JJ=JSINDX(NBASIS(IC(1)))
      JA=JSTATE(JJ,1)
      J2=JSTATE(JJ,2)
      JLOW=ABS(JTOT-JA)
      JTOP=JTOT+JA
      DO 3000 II=1,NB
        LLL=LVAL(II)
        NJB=0
        JMIN=ABS(J2-LLL)
        JMAX=J2+LLL
        DO 3100 II2=JLOW,JTOP
          IF (II2.LT.JMIN) GOTO 3100
          IF (II2.GT.JMAX) GOTO 3100
C  ALL TRIANGLE INEQUALITIES SATISFIED.  INCLUDE JBAR
          NJB=NJB+1
          JBAR(ISTB(II)+NJB)=II2
 3100   CONTINUE
C  NO.(JBAR) SHOULD EQUAL NO.(J12) FOR EVERY BLOCK.
        IF (NJB.EQ.NBLK(II) ) GOTO 3000
        WRITE(6,601) NJB,NBLK(II),II
  601   FORMAT(/' * * * ERROR.  NO.(JBAR) .NE. NO.(J12)',2I6,
     1          '  FOR BLOCK =',I4)
        STOP
 3000 CONTINUE
C
C  SET UP TRANSFORM MATRIX TR(JBAR,J12)
      DO 3500 II1=1,NLVAL
      DO 3500 II2=1,NLVAL
 3500   TR(II1,II2)=0.D0
      DO 3600 II=1,NB
        LLL=LVAL(II)
        NTOP=NBLK(II)
      DO 3600 II1=1,NTOP
        JB=JBAR(ISTB(II)+II1)
      DO 3600 II2=1,NTOP
        J12=IL(ISTB(II)+II2)
 3600   TR(ISTB(II)+II1,ISTB(II)+II2)=SQRT(Z(JB)*Z(J12))
     1                                *SIXJ(JA,J2,JTOT,LLL,J12,JB)
C
C  TRANSFORM SR,SI TO SREAL, SIMAG
C  LOOP OVER L
      DO 3700 II1=1,NB
        NTOP1=NBLK(II1)
        IST1=ISTB(II1)
C  LOOP OVER L-PRIME
      DO 3700 II2=1,NB
        NTOP2=NBLK(II2)
        IST2=ISTB(II2)
C  LOOP OVER JBAR
      DO 3700 JB=1,NTOP1
        IRNEW=IC(IST1+JB)
C  LOOP OVER JBAR-PRIME
      DO 3700 JBP=1,NTOP2
        ICNEW=IC(IST2+JBP)
C  LOOP OVER J12
      DO 3700 J12=1,NTOP1
        IROLD=IC(IST1+J12)
C  LOOP OVER J12-PRIME
      DO 3700 J12P=1,NTOP2
        ICOLD=IC(IST2+J12P)
        FACTOR = TR(IST1+JB,IST1+J12) * TR(IST2+JBP,IST2+J12P)
        SREAL(IRNEW,ICNEW)=SREAL(IRNEW,ICNEW)+FACTOR*SR(IROLD,ICOLD)
        SIMAG(IRNEW,ICNEW)=SIMAG(IRNEW,ICNEW)+FACTOR*SI(IROLD,ICOLD)
 3700 CONTINUE
C
C  PACK L,JBAR INDICES INTO IL()
      II2=0
      DO 4000 II=1,NB
        NTOP=NBLK(II)
        LLL=LVAL(II)
      DO 4000 II1=1,NTOP
        II2=II2+1
 4000   IL(II2)=LLL*NPACK+JBAR(II2)
C  SREAL, SIMAG, IC, AND IL ARE NOW IN FORMAT EXPECTED BY PRBR

      RETURN
C  * * * * * * * * * * * * * * * * * * * * * * * * END OF PRBR3  * *
C
C
      ENTRY PRBR3R(N,SREAL,SIMAG,SR,SI)
C  RESTORE SIMAG,SREAL IN CASE THEY ARE NEEDED FOR FURTHER PROCESSING
      DO 5000 II1=1,N
      DO 5000 II2=1,N
        SREAL(II1,II2)=SR(II1,II2)
 5000   SIMAG(II1,II2)=SI(II1,II2)
      RETURN
C  * * * * * * * * * * * * * * * * * * * * * * * * END OF PRBR3R * *
      END
