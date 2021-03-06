      SUBROUTINE OUTMAT(TMAT, EIGOLD, HP, ESHIFT, DRNOW, RNOW,
     1                  N, NMAX, ITWO, ISCRU)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  AUTHOR:  MILLARD ALEXANDER
C  CURRENT REVISION DATE: 14-FEB-91
C
C  SUBROUTINE TO EITHER WRITE OR READ TRANSFORMATION MATRIX AND
C  RELEVANT INFORMATION FROM FILE ISCRU
C  ---------------------------------------------------------------------
C  VARIABLES IN CALL LIST:
C    TMAT:     N X N MATRIX TO CONTAIN TRANSFORMATION MATRIX
C    EIGOLD:   ARRAY OF DIMENSION N WHICH CONTAINS LOCAL WAVEVECTORS
C    HP:       ARRAY OF DIMENSION N WHICH CONTAINS DERIVATIVES OF
C              HAMILTONIAN MATRIX.  THIS IS JUST THE NEGATIVE OF THE
C              DERIVATIVES OF THE WAVEVECTOR MATRIX
C    ESHIFT:   AMOUNT LOCAL WAVEVECTORS WILL BE SHIFTED IN SECOND ENERGY
C              CALCULATION:  2         2
C                           K (NEW) = K (OLD) + ESHIFT
C    DRNOW:    WIDTH OF CURRENT INTERVAL
C    RNOW:     MIDPOINT OF CURRENT INTERVAL
C    N:        NUMBER OF CHANNELS
C    NMAX:     MAXIMUM ROW DIMENSION OF MATRIX TMAT
C    ITWO:     IF = 0, THEN SUBROUTINE CALLED AT FIRST ENERGY OF
C              MULTIPLE ENERGY CALCULATION, SO TRANSFORMATION MATRIX
C              AND RELEVANT INFORMATION WILL BE WRITTEN
C              IF > 0, THEN SUBROUTINE CALLED AT SUBSEQUENT ENERGY OF
C              MULTIPLE ENERGY CALCULATION, SO TRANSFORMATION MATRIX AND
C              RELEVANT INFORMATION WILL BE READ
C  ---------------------------------------------------------------------
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION EIGOLD(1), HP(1), TMAT(1)
C
C  IF FIRST      ENERGY CALCULATION, ITWO = 0: ISCRU WILL BE WRITTEN TO
C  IF SUBSEQUENT ENERGY CALCULATION, ITWO = 1: ISCRU WILL BE READ FROM
C
C  READ/WRITE RNOW, DRNOW, DIAGONAL ELEMENTS OF TRANSFORMED DW/DR MATRIX
C  AND DIAGONAL ELEMENTS OF TRANSFORMED W MATRIX
C
      NSQ = NMAX * NMAX
      IF (ITWO.GT.0) THEN
        READ(ISCRU) RNOW, DRNOW, (HP(I) , I = 1, N),
     1              (EIGOLD(I) , I = 1, N), (TMAT(I), I=1, NSQ)
        DO  30   I = 1, N
          EIGOLD(I) = EIGOLD(I) + ESHIFT
30      CONTINUE
      ELSE
        WRITE(ISCRU) RNOW, DRNOW, (HP(I) , I = 1, N),
     1               (EIGOLD(I) , I = 1, N), (TMAT(I), I=1, NSQ)
      ENDIF
      RETURN
      END
