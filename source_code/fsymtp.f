      FUNCTION FSYMTP(J1,K1,L1,J2,K2,L2,JT,LAM,MU)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  CALCULATES MATRIX ELEMENT FOR SYMMETRIC TOP FUNCTIONS
C       <J1 K1 L1, JTOT | Y(LAM,MU) | J2 K2 L2, JTOT>.
C  USES SUBROUTINES -
C       THRJ(XJ1,XJ2,XJ3,XM1,XM2,XM3)
C       THREEJ(J1,J2,J3) WHICH IS FOR M1=M2=M3=0
C       SIXJ(J1,L1,J2,L2,JTOT,LAM)
C
C  THIS FUNCTION IS USED FOR CLOSE-COUPLED CALCULATIONS ON INTERACTIONS
C  BETWEEN AN ATOM AND A NON-LINEAR ROTOR (ITYP=5/6)
C
      DATA PI/3.14159265358979289D0/
C  STATEMENT FUNCTION DEFINITION . . .
      Z(Y) = 2.D0 * Y + 1.D0
C
      IF (K1-K2+MU.NE.0) GOTO 9000

      F=THREEJ(L1,L2,LAM)
      IF (F.EQ.0.D0) GOTO 9000

      XJ1=J1
      XJ2=J2
      XK1=K1
      XK2= - K2
      XL1=L1
      XL2=L2
      XLAM=LAM
      XMU=MU
      F=F * THRJ(XJ1,XJ2,XLAM,XK1,XK2,XMU)
      IF (F.EQ.0.D0) GOTO 9000

      F=F * SIXJ(J1,L1,J2,L2,JT,LAM)
      IF (F.EQ.0.D0) GOTO 9000

      PH=PARSGN(J1+J2+K2-JT)
      F=F*PH*SQRT(Z(XJ1)*Z(XJ2)*Z(XL1)*Z(XL2)*Z(XLAM)/(4.D0*PI))
      FSYMTP=F
      RETURN

 9000 FSYMTP=0.D0
      RETURN
      END
