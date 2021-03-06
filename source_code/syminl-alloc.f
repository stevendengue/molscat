      SUBROUTINE SYMINL(A, IA, N, INERT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  SIMULATES SYMINV SYMMETRIC MATRIX INVERTER WITH LAPACK CALLS
C  THIS VERSION USES ONLY THE UPPER TRIANGLE OF A:
C  NOT COMPATIBLE WITH MOLSCAT VERSION 11.
C  JM Hutson MAY 93
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
      ALLOCATABLE::IPIV(:),WORK(:)
      DIMENSION A(IA,N)
C
C  ILAENV WITH FIRST VARIABLE 1 RETURNS OPTIMAL BLOCKSIZE FOR ROUTINE
C  NAMED IN VARIABLE 2 AND PARAMETERS AS NAMED IN OTHER VARIABLES
      NB=ILAENV(1,'DSYTRF','L',N,-1,-1,-1)
      LWORK=N*NB
      ALLOCATE (IPIV(N),WORK(LWORK))
C  DSYTRF FACTORISES A AS LDL^T.  IT USES ONLY THE LOWER PART OF A
      CALL DSYTRF('L',N,A,IA,IPIV,WORK,LWORK,INFO)
C
      IF (INFO.NE.0) THEN
        WRITE(6,120) INFO
120     FORMAT(' *** ERROR IN DSYTRF: INFO =',I3)
        STOP
      ENDIF
C
C  DSYNEG (IN-HOUSE ROUTINE) FINDS THE NUMBER OF NEGATIVE EIGENVALUES OF A
      INERT=0
      CALL DSYNEG('L',A,IPIV,N,INERT)
C
C  DSYTRI COMPUTES THE INVERSE OF A WHICH HAS BEEN DECOMPOSED AS A=LDL^T
      CALL DSYTRI('L',N,A,IA,IPIV,WORK,INFO)
      DEALLOCATE(IPIV,WORK)
C
      IF (INFO.NE.0) THEN
        WRITE(6,130) INFO
130     FORMAT(' *** ERROR IN DSYTRI: INFO =',I3)
        STOP
      ENDIF
      RETURN
      END
