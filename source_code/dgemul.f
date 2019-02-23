      SUBROUTINE DGEMUL(A,LDA,TRANSA,B,LDB,TRANSB,C,LDC,
     1                  L,M,N)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  THIS SUBROUTINE CALCULATES THE LXN MATRIX C
C  C = A^TRANSA * B^TRANSB,
C  (TRANSA/TRANSB CAN BE 'N' FOR NORMAL, OR 'T' FOR TRANSPOSE)
C
C  WHERE A^TRANSA HAS FIRST DIMENSION L AND SECOND DIMENSION M
C  AND   B^TRANSB HAS FIRST DIMENSION M AND SECOND DIMENSION N
C
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      CHARACTER(1) TRANSA,TRANSB
      DIMENSION A(LDA,*),B(LDB,*),C(LDC,*)

C  IT USES THE MORE GENERAL ROUTINE DGEMM WHICH (AS USED HERE) CALCULATES
C  C = 1.D0*A^TRANSA * B^TRANSB + 0.D0*C
      CALL DGEMM(TRANSA,TRANSB,L,N,M,1.D0,A,LDA,B,LDB,0.D0,C,LDC)
      RETURN
      END
