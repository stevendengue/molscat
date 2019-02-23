      SUBROUTINE MAPROP(N,NSQ,MXLAM,NPOTL,
     1                  Y,T,U,VL,IV,EINT,CENT,P,
     2                  Q,W,EIVAL,Y1,Y2,Y3,Y4,
     3                  DIAG,
     4                  RSTART,RSTOP,NSTEP,DR,NODES,
     5                  ERED,RMLMDA,IPRINT)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  ROUTINE TO SOLVE A SET OF COUPLED EQUATIONS USING THE QUASIADIABATIC
C  LOG-DERIVATIVE ALGORITHM OF MANOLOPOULOS.
C  THE COUPLING MATRIX EVALUATED AT THE MIDPOINT OF EACH SECTOR
C  IS USED AS THE REFERENCE POTENTIAL FOR THE SECTOR.
C
C  LOG-DERIVATIVE MATRIX IS ACCEPTED IN Y IN BASIS SET DEFINED BY T
C  IF Y IS IN FREE BASIS, T SHOULD BE A UNIT MATRIX
C  Y IS ALWAYS RETURNED IN FREE BASIS
C
C  BASED ON A ROUTINE BY MANOLOPOULOS WITH MODIFICATIONS BY
C  J. M. HUTSON AND C. R. LE SUEUR
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE

      DOUBLE PRECISION, ALLOCATABLE :: WKS(:)
      DIMENSION Q(NSQ),T(NSQ),U(NSQ),W(NSQ),Y(NSQ),
     &          EIVAL(N),Y1(N),Y2(N),Y3(N),Y4(N)
      DIMENSION P(MXLAM),VL(2),IV(2),EINT(N),CENT(N),DIAG(N)
C
      NODES=0
C
C  THIS VERSION USES A CONSTANT STEP SIZE, DR, THROUGHOUT THE
C  INTEGRATION RANGE, BUT IS WRITTEN SO THAT THIS MAY BE EASILY
C  CHANGED.
C
      R=RSTART
C
C  FOR MOLSCAT, BOUND AND FIELD, Y IS PASSED IN FREE BASIS
C  SO INITIALISE T TO A UNIT MATRIX
C
      DO 80 IJ=1,NSQ
        T(IJ)=0.D0
  80  CONTINUE
      NP1=N+1
      IJ=1
      DO 90 I=1,N
        T(IJ)=1.D0
        IJ=IJ+NP1
  90  CONTINUE

      IF (.NOT.IREAD) THEN
C
C  Q MATRIX IS USED TO HOLD CORRECTION TO Y4 FROM PREVIOUS
C  SECTOR. INITIALISE IT FOR THE FIRST SECTOR.
C
        DO 110 IJ=1,NSQ
          Q(IJ)=0.D0
 110    CONTINUE
C
C  26-12-18 ADDED THIS CODE BECAUSE U NO LONGER PRESERVED BY YINIT
        CALL WAVMAT(U,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
        IF (IWRITE) WRITE(ISCRU) U
      ELSE
        READ(ISCRU) U
        DO 130 I=1,NSQ,N+1
  130     U(I)=U(I)-ESHIFT
      ENDIF
C
        IF (IPRINT.GE.19) WRITE(6,*)'  POTENTIAL COEFFICIENTS AND ',
     1   'ADIABATS PRINTED IN UNITS OF EPSIL'
        IF (IPRINT.GE.22) WRITE(6,*)'  BUT COMPLETE MATRICES OF V-E ',
     1   'PRINTED IN REDUCED UNITS 1/RUNIT**2'
C
C  PROPAGATION LOOP BEGINS HERE
C
      DO 500 KSTEP=1,NSTEP
        IF (IREAD) GOTO 180
        R=R+0.5D0*DR
        CALL WAVMAT(W,N,R,P,VL,IV,0.D0,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
C
C  CALCULATE CORRECTION TO Y1(K)
C
        DO 120 IJ=1,NSQ
          U(IJ)=U(IJ)-W(IJ)
 120    CONTINUE
        CR=DR/6.D0
        DO 140 IJ=1,NSQ
          U(IJ)=CR*U(IJ)
 140    CONTINUE
C
C  PLUS CORRECTION TO Y4(K-1)
C
        DO 160 IJ=1,NSQ
          U(IJ)=U(IJ)+Q(IJ)
 160    CONTINUE
C
C  TRANSFORM CORRECTION TO OLD BASIS
C
        CALL TRNSFM(T,U,Q,N,.FALSE.,.TRUE.)
        IF (IWRITE) WRITE(ISCRU) U
        GOTO 200

 180    READ(ISCRU) U
 200    CONTINUE
C
C  APPLY CORRECTION TO Y MATRIX IN OLD BASIS
C
        DO 220 IJ=1,NSQ
          Y(IJ)=Y(IJ)+U(IJ)
 220    CONTINUE
C
C  DIAGONALISE COUPLING MATRIX
C
        IF (IREAD) GOTO 260

        IFAIL=0
        CALL DIAGVC(W,N,N,EIVAL,U)
C
C  WRITE OUT INFO ON ADIABATS AT VERY HIGH PRINT LEVELS
C
C  NOTE THAT DIVIDING BY RMLMDA CONVERTS REDUCED ENERGIES INTO
C  UNITS OF EPSIL (FROM POTENL), WHICH IS NOT ALWAYS 1 CM-1.
C
        IF (IPRINT.GE.21) WRITE(6,'(A,F14.5,2X,9(F14.4,1X))')
     1                   'R,VLAMBDA: ', R,(P(I)/RMLMDA,I=1,MIN(9,NPOTL))
        IF (IPRINT.GE.22) CALL MATPRN(6,W,N,N,N,2,W,' RMLMDA*(V-E)',1)
        IF (IPRINT.GE.24) CALL MATPRN(6,U,N,N,N,3,W,' EIGENVECTORS',1)

        IF (IPRINT.GE.19)
     1    WRITE(6,666) 'AD: ',R,(((EIVAL(I))/RMLMDA),I=1,MIN(30,N))
        IF (IPRINT.GE.20)
     1    WRITE(6,666) 'WD: ',R,((W((I-1)*N+I))/RMLMDA,
     1                           I=1,MIN(30,N))
 666      FORMAT(2X,A4,F8.4,(9G18.8))
C
        IF (IPRINT.GE.23) THEN
C
C  CODE BY J. M. HUTSON 2017 TO CALCULATE NONADIABATIC COUPLINGS
C  (MATRIX OF D/DR BETWEEN ADIABATIC FUNCTION)
C  ARRAY Q IS FREE AT THIS POINT, SO USE IT FOR DERIVATIVES
C  AS TEMPORARY MEASURE, ALLOCATE WKS FOR WORKSPACE IN TRANSFORMATION
C
          CALL DERMAT(1,Q,N,R,P,VL,IV,CENT,RMLMDA,MXLAM,NPOTL,IPRINT)
C         CALL MATPRN(6,Q,N,N,N,2,Q,' DV/DR IN PRIMITIVE BASIS SET',1)
          ALLOCATE(WKS(NSQ))
          CALL TRNSFM(U,Q,WKS,N,.FALSE.,.TRUE.)
          DEALLOCATE(WKS)
C         CALL MATPRN(6,Q,N,N,N,2,Q,' DV/DR IN ADIABATIC BASIS SET',1)
          IJ=0
          DO 230 I=1,N
          DO 230 J=1,N
          IJ=IJ+1
          IF (ABS(EIVAL(I)-EIVAL(J)).GT.1.D-20) THEN
            Q(IJ)=Q(IJ)/(EIVAL(I)-EIVAL(J))
          ELSE
            IF (I.NE.J) WRITE(6,667) I,J
 667        FORMAT(' CHANNELS',I4,' AND',I4,' ARE DEGENERATE:',
     1      ' D/DR ELEMENT SET TO ZERO')
            Q(IJ)=0.D0
          ENDIF
 230      CONTINUE
          CALL MATPRN(6,Q,N,N,N,2,Q,' D/DR IN ADIABATIC BASIS SET',1)
        ENDIF
C
C  CALCULATE SECTOR-TO-SECTOR TRANSFORMATION MATRIX, Q.
C  OLD EIGENVECTORS ARE IN T AND NEW ONES IN U
C
        CALL DGEMUL(T,N,'T',U,N,'N',Q,N,N,N,N)
        DO 240 IJ=1,NSQ
          T(IJ)=U(IJ)
 240    CONTINUE
        IF (IWRITE) WRITE(ISCRU) DR,EIVAL,Q
        GOTO 280

 260    READ(ISCRU) DR,EIVAL,Q
 280    CONTINUE
C
C  TRANSFORM Y MATRIX TO NEW BASIS
C
        CALL TRNSFM(Q,Y,U,N,.FALSE.,.TRUE.)
C
C  CONSTRUCT FIRST ORDER MAGNUS SECTOR PROPAGATORS
C  HALF ANGLE FORMULAE ARE USED FOR MAXIMUM OPACITY.
C
        NCHECK=0
        WMAX=24.D0/(DR*DR)
        DO 300 I=1,N
          WREF=EIVAL(I)-ERED
          FLAM=0.5D0*SQRT(ABS(WREF))
          IF (WREF.LT.0.D0) THEN
            TN=TAN(FLAM*DR)
            Y1(I)=FLAM/TN-FLAM*TN
            Y2(I)=FLAM/TN+FLAM*TN
          ELSE
            IF (WREF.GT.WMAX) NCHECK=NCHECK+1
            TH=TANH(FLAM*DR)
            Y1(I)=FLAM/TH+FLAM*TH
            Y2(I)=FLAM/TH-FLAM*TH
          ENDIF
          Y3(I)=Y2(I)
          Y4(I)=Y1(I)
 300    CONTINUE
C
C  PROPAGATE Y MATRIX ACROSS THE SECTOR
C
        II=-N
        DO 320 I=1,N
          II=II+N+1
          Y(II)=Y(II)+Y1(I)
 320    CONTINUE
C
        CALL SYMINV(Y,N,N,NCOUNT)
        IF (NCOUNT.GT.N) GOTO 900
        IF (RSTART.GT.RSTOP) NCOUNT=N-NCOUNT
        IF (NCHECK.EQ.0) NODES=NODES+NCOUNT
C
        IJ=0
        DO 340 J=1,N
        DO 340 I=1,N
          IJ=IJ+1
          Y(IJ)=-Y3(I)*Y(IJ)*Y2(J)
 340    CONTINUE
        II=-N
        DO 360 I=1,N
          II=II+N+1
          Y(II)=Y(II)+Y4(I)
 360    CONTINUE
C
        IF (IREAD) GOTO 500

        R=R+0.5D0*DR
        CALL WAVMAT(U,N,R,P,VL,IV,0.D0,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
C
C  CALCULATE CORRECTION TO Y4(K)
C
        DO 380 IJ=1,NSQ
          Q(IJ)=U(IJ)-W(IJ)
 380    CONTINUE
        CR=DR/6.D0
        DO 400 IJ=1,NSQ
          Q(IJ)=CR*Q(IJ)
 400    CONTINUE
C
C *** COULD CHANGE DR HERE ***
C
 500  CONTINUE
C
C
C  PROPAGATION LOOP ENDS HERE
C
C
      IF (IWRITE) WRITE(ISCRU) T,Q
      IF (IREAD)   READ(ISCRU) T,Q
C
C  TRANSFORM Y MATRIX TO ORIGINAL BASIS
C
      CALL TRNSP(T,N)
      CALL TRNSFM(T,Y,W,N,.FALSE.,.TRUE.)
C
C  APPLY FINAL CORRECTION IN ORIGINAL BASIS
C
      DO 520 IJ=1,NSQ
        Y(IJ)=Y(IJ)+Q(IJ)
 520  CONTINUE
      RETURN
C
 900  WRITE(6,1000) KSTEP
1000  FORMAT(/' ***** MATRIX INVERSION ERROR IN MAPROP AT ',
     &       'STEP  K = ',I6,'  RUN HALTED.')
      STOP
      END
