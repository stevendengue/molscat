      SUBROUTINE LOCHAN(EINT,L,N,CINT,EREF,IREF,IPRINT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  THIS SUBROUTINE LOCATES CHANNELS WHICH HAVE THRESHOLDS CLOSE TO EREF
C  AND SETS IREF TO BE THE INDEX OF THE CLOSEST ONE
C
C  WRITTEN BY JM Hutson 21-04-15
C
C  NOTE THAT IT WILL NOT WORK FOR ODD L AS IT STANDS
C
C  ON ENTRY: EINT IS THE ARRAY OF THRESHOLDS
C            L IS THE ARRAY OF VALUES OF L FOR THE CHANNELS
C            N IS THE SIZE OF THE BASIS
C            CINT IS THE CONVERSION FACTOR FROM 1/RM^2 TO RECIPROCAL CM
C            EREF IS THE REFERENCE ENERGY
C            IPRINT CONTROLS THE LEVEL OF OUTPUT
C  ON EXIT:  IREF IS THE INDEX OF THE L=0 CHANNEL CLOSEST TO EREF
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION EINT(N),L(N)
C
      NCLOSE=0
      IF (IPRINT.GE.12) WRITE(6,601) EREF/CINT
  601 FORMAT(/2X,'INDICES OF UNSORTED CHANNELS WITH THRESHOLDS CLOSE ',
     1           'TO EREF =',F19.12,' CM-1:'/3X,'IND',3X,'L',8X,'DIFF',
     2           13X,'ENERGY')

      DIFMIN=1.D30
      DO 100 I=1,N
        DIF=EINT(I)/CINT-EREF
        IF (ABS(DIF).LT.1.D-10) NCLOSE=NCLOSE+1
        IF (IPRINT.GE.15 .OR. (IPRINT.GE.12 .AND. ABS(DIF).LT.1.D-10))
     1     WRITE(6,602) I,L(I),DIF,EINT(I)/CINT
  602   FORMAT(2I5,1PE15.5,0PF19.12)
        IF (L(I).EQ.0 .AND. ABS(DIF).LT.DIFMIN) THEN
          DIFMIN=ABS(DIF)
          IREF=I
        ENDIF
  100 CONTINUE

      IF (NCLOSE.GT.0) THEN
        IF (IPRINT.GE.10) WRITE(6,603) NCLOSE,IREF,L(IREF),
     1    EINT(IREF)/CINT-EREF
  603   FORMAT(/'  THERE ARE',I3,' CHANNELS WITH THRESHOLDS VERY ',
     1          ' CLOSE TO EREF'/'  THE CLOSEST IS CHANNEL',I5,
     2          ' WITH L =',I5/'  WHICH IS ',1PG17.8,' CM-1 FROM EREF')
      ELSE
        WRITE(6,*) ' *** WARNING: NO THRESHOLDS FOR THIS BASIS SET '//
     1             ' THAT ARE CLOSE TO EREF'
      ENDIF
      RETURN
      END
