      SUBROUTINE PROPST(RMIN,RMAX,DR,IRMSET,IRXSET,RVFAC,
     1                  INTFLG,IMGSEL,IPRINT,
     2                  EPS,EPL,POWRX,TOLHI,DRMAX,NSTAB)
C  Copyright (C) 2019 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3

C  CR Le Sueur Jan 2019
      IMPLICIT NONE

      DOUBLE PRECISION, INTENT(IN) :: RMIN,RMAX,DR,RVFAC,POWRX,TOLHI,
     1                                DRMAX
      INTEGER,          INTENT(IN) :: IRMSET,IRXSET,IPRINT,IMGSEL,NSTAB
      DOUBLE PRECISION, INTENT(IN) :: EPS,EPL
      INTEGER,          INTENT(INOUT) :: INTFLG

C  COMMON BLOCK TO DESCRIBE WHICH DRIVER IS USED
      COMMON /CNTROL/ CDRIVE
      CHARACTER(1) CDRIVE
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      INTEGER ISCRU
      DOUBLE PRECISION ESHIFT
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE
C
C  COMMON BLOCK FOR CONTROL OF PROPAGATION SEGMENTS
      COMMON /RADIAL/ RMNINT,RMXINT,RMID,RMATCH,DRS,DRL,STEPS,STEPL,
     1                POWRS,POWRL,TOLHIS,TOLHIL,CAYS,CAYL,UNSET,
     2                IPROPS,IPROPL,NSEG

      DOUBLE PRECISION RMNINT,RMXINT,RMID,RMATCH,
     1                 STEPS,STEPL,TOLHIS,TOLHIL,DRS,DRL,CAYS,CAYL,
     1                 POWRS,POWRL,UNSET
      INTEGER          IPROPS,IPROPL,NSEG

      INTEGER, PARAMETER :: MXSEG=3
      DOUBLE PRECISION STPSEG(MXSEG),TOLSEG(MXSEG),DRSEG(MXSEG),
     1                 EPSEG(MXSEG),POWSEG(MXSEG)
      INTEGER IPRSEG(MXSEG)

C  EXTRA COMMON BLOCK FOR VIVS
      COMMON /LDVVCM/ XSQMAX,ALPHA1,ALPHA2,IALPHA,IALFP,IV,IVP,IVPP,
     1                ISHIFT,IDIAG,IPERT,ISYM
      DOUBLE PRECISION XSQMAX,ALPHA1,ALPHA2
      INTEGER IALPHA
      LOGICAL IALFP,IV,IVP,IVPP,ISHIFT,IDIAG,IPERT,ISYM

C  COMMON BLOCK FOR DERIVATIVES
      LOGICAL NUMDER
      COMMON /DERIVS/ NUMDER

C  COMMON BLOCK FOR WKB INTEGRATOR
      COMMON /WKBCOM/ NGMP(3)
      INTEGER NGMP

C  COMMON BLOCK FOR CONTROL OF PROPAGATION BOUNDARY CONDITIONS
      COMMON /BCCTRL/ BCYCMN,BCYCMX,BCYOMN,BCYOMX,ADIAMN,ADIAMX,
     1                WKBMN,WKBMX
      LOGICAL ADIAMN,ADIAMX,WKBMN,WKBMX
      DOUBLE PRECISION BCYCMN,BCYCMX,BCYOMN,BCYOMX

      DOUBLE PRECISION  DRTEMP

      INTEGER           IPROP,ISEG
      DOUBLE PRECISION  DRT,TOLHIT,STEP,EP,POWR
      CHARACTER(3)      DIRNAM(MXSEG)
      CHARACTER(10)     CRMIN,CRMID,CRMTCH,CRMAX,CRMSET,CRVFAC
      CHARACTER(100)    TXT(MXSEG)
      CHARACTER(100)    RMNTXT,RMDTXT,RMTTXT,RMXTXT,RMXTX2

      INTEGER IWKB,IAIRY,IDV,IRM,IVV,ILD,IMD,IMA,IMG
      DATA IWKB,IAIRY,IDV,IRM,IVV,ILD,IMD,IMA,IMG/-1,9,2,3,4,5,6,7,8/
      CHARACTER(1) PLUR(2)
      DATA PLUR/' ','S'/

C  SPECIAL VALUES OF INTFLG
      IF (INTFLG.EQ.8) THEN
        IPROPS=IMD
        IPROPL=IAIRY
        INTFLG=0
      ELSEIF (INTFLG.EQ.4) THEN
        IPROPS=ILD
        IPROPL=IVV
        INTFLG=0
      ENDIF

C  IF INTFLG SET AND IPROPS NOT SET, COPY INTFLG INTO IPROPS
      IF (INTFLG.NE.0 .AND. IPROPS.EQ.0) IPROPS=MOD(INTFLG,10)

C  LONG RANGE VALUES DEFAULT TO SHORT RANGE VALUES IF NOT SET
      IF (TOLHIL.EQ.UNSET) TOLHIL=TOLHIS

C  DEFAULT PROPAGATOR FOR SHORT RANGE IS LDMD
C     IF (IPROPS.EQ.0) IPROPS=IMD

C  IF LONG RANGE PROPAGATOR NOT SET THEN IF LONG AND SHORT RANGE VALUES
C  OF CONTROLS ARE DIFFERENT, COPY SHORT RANGE PROPAGATOR TO LONG RANGE
      IF (IPROPL.EQ.0) THEN
        IF (TOLHIS.NE.TOLHIL) IPROPL=IPROPS
        IF (MAX(STEPS,STEPL).GT.0.D0 .AND. STEPS.NE.STEPL) IPROPL=IPROPS
        IF (MAX(STEPS,STEPL).LE.0.D0 .AND. DRS.NE.DRL) IPROPL=IPROPS
        IF (EPL.NE.EPS .AND. MAX(STEPS,STEPL).GT.0.D0) IPROPL=IPROPS
      ENDIF

      IF (IRMSET.GT.0) THEN
C  RMNINT WILL BE CALCULATED BY FINDRM
        RMNINT=UNSET
      ELSE
        RMNINT=RMIN
      ENDIF

      IF (IRXSET.EQ.1) THEN
C  RMXINT WILL BE CALCULATED BY FINDRX
        RMXINT=UNSET
      ELSE
        RMXINT=RMAX
      ENDIF

C  THIS SUBROUTINE IS DIFFERENT FOR MOLSCAT AND BOUND/FIELD
      CALL PRPINI(RMIN,RMAX,DR,RVFAC,IRMSET,IRXSET,
     1            EPS,EPL,DRSEG,EPSEG,IPRSEG,STPSEG,TOLSEG,
     2            POWSEG,DIRNAM,POWRX,TOLHI)

      IF (IPROPL.NE.0) THEN
        IF (IPRINT.GE.1) WRITE(6,200) IPROPS,IPROPL
  200   FORMAT(/'  PROPAGATION METHODS FOR COUPLED EQUATIONS '
     1          'SPECIFIED BY IPROPS = ',I2,' AND IPROPL = ',I2)
      ELSE
        IF (IPRINT.GE.1) WRITE(6,201) IPROPS
  201   FORMAT(/'  PROPAGATION METHODS FOR COUPLED EQUATIONS '
     1          'SPECIFIED BY IPROPS = ',I2)
      ENDIF
      CALL MGISEL(IMGSEL)

C  THE REMAINDER OF THIS ROUTINE JUST PREPARES AND OUTPUTS MESSAGES
C  ABOUT THE PROPAGATION SEGMENTS
      IF (IPRINT.LT.1) RETURN

C  CONSTRUCT TEXT FOR HOW RMIN IS OBTAINED
      IF (IRMSET.EQ.0) THEN
        WRITE(CRMIN,'(F9.2)') RMNINT
        RMNTXT='RMIN = '//CRMIN
      ELSE
        WRITE(CRMSET,'(I2)') IRMSET
        RMNTXT='RMIN CHOSEN USING IRMSET = '//CRMSET
      ENDIF

C  CONSTRUCT TEXT FOR HOW RMID IS OBTAINED
      IF (RVFAC.GT.0.D0) THEN
        WRITE(CRVFAC,'(F7.2)') RVFAC
        RMDTXT='VALUE OF RMID CHOSEN USING RVFAC = '//CRVFAC
      ELSE
        WRITE(CRMID,'(F9.2)') RMID
        RMDTXT='RMID = '//CRMID
      ENDIF

C  CONSTRUCT TEXT FOR HOW RMAX IS OBTAINED
      WRITE(CRMAX,'(F9.2)') RMAX
      IF (IRXSET.EQ.1) THEN
        RMXTXT='WHICHEVER IS LARGER OF '
        RMXTX2='OUTERMOST CENTRIFUGAL TURNING '//
     1         'POINT IN OPEN CHANNELS, AND RMAX, WHICH = '//CRMAX
      ELSE
        RMXTXT='RMAX = '//CRMAX
        RMXTX2=' '
      ENDIF

C  CONSTRUCT TEXT FOR HOW RMATCH IS OBTAINED (NOT USED IN MOLSCAT)
      IF (CDRIVE.NE.'M') THEN
        WRITE(CRMTCH,'(F9.2)') RMATCH
        RMTTXT='RMATCH = '//CRMTCH
      ENDIF

      IF (NSEG.EQ.1) THEN
C  1 SEGMENT:  RMIN -> RMAX
        TXT(1)='FROM '//TRIM(RMNTXT)//' TO '//TRIM(RMXTXT)

      ELSEIF (NSEG.EQ.2 .AND. CDRIVE.EQ.'M') THEN
C  2 SEGMENTS: RMIN -> RMID; RMID -> RMAX
        TXT(1)='FROM '//TRIM(RMNTXT)//' TO '//TRIM(RMDTXT)
        TXT(2)='FROM '//TRIM(RMDTXT)//' TO '//TRIM(RMXTXT)

      ELSEIF (NSEG.EQ.2 .AND. CDRIVE.NE.'M') THEN
C  2 SEGMENTS: RMIN -> RMATCH; RMATCH <- RMAX
        TXT(1)='FROM '//TRIM(RMNTXT)//' TO '//TRIM(RMTTXT)
        TXT(2)='TO '//TRIM(RMTTXT)//' FROM '//TRIM(RMXTXT)

      ELSEIF (NSEG.EQ.3 .AND. RMID.LT.RMATCH) THEN
C  3 SEGMENTS: RMIN -> RMID; RMID -> RMATCH; RMATCH <- RMAX
C              1ST           2ND             3RD
        TXT(1)='FROM '//TRIM(RMNTXT)//' TO '//TRIM(RMDTXT)
        TXT(2)='FROM '//TRIM(RMDTXT)//' TO '//TRIM(RMTTXT)
        TXT(3)='TO '//TRIM(RMTTXT)//' FROM '//TRIM(RMXTXT)

      ELSEIF (NSEG.EQ.3 .AND. RMID.GT.RMATCH) THEN
C  3 SEGMENTS: RMIN -> RMATCH; RMATCH <- RMID; RMID <- RMAX
C              1ST             3RD             2ND
        TXT(1)='FROM '//TRIM(RMNTXT)//' TO '//TRIM(RMTTXT)
        TXT(2)='TO '//TRIM(RMDTXT)//' FROM '//TRIM(RMXTXT)
        TXT(3)='TO '//TRIM(RMTTXT)//' FROM '//TRIM(RMDTXT)
      ENDIF

C  FOR MOLSCAT, ALL PROPAGATIONS ARE TOWARDS RMAX
      IF (CDRIVE.EQ.'M' .AND. IPRINT.GE.1) THEN
        WRITE(6,1000) 'COUPLED EQUATIONS WILL BE PROPAGATED OUTWARDS ',
     1                'IN',NSEG,'SEGMENT',PLUR(MIN(NSEG,2))
        WRITE(6,*)
        IF (NSEG.EQ.1) THEN
          WRITE(6,'(A)') '  PROPAGATION RANGE IS CONTROLLED BY '//
     1                   'VARIABLES RMIN AND RMAX, WITH INPUT VALUES'
          WRITE(6,1010) ' RMIN = ',RMIN,' RMAX = ',RMAX
        ELSE
          WRITE(6,'(A)') '  PROPAGATION RANGES ARE CONTROLLED BY '//
     1                   'VARIABLES RMIN, RMID AND RMAX, WITH '//
     2                   'INPUT VALUES'
          WRITE(6,1010) ' RMIN = ',RMIN,' RMID = ',RMID,' RMAX = ',RMAX
        ENDIF
C
C  FOR BOUND/FIELD, ALL PROPAGATIONS ARE TOWARDS RMATCH
      ELSEIF (IPRINT.GE.1) THEN
        WRITE(6,1000) 'COUPLED EQUATIONS WILL BE PROPAGATED TOWARDS ',
     1                'RMATCH IN',NSEG,'SEGMENTS'
        WRITE(6,*)
        IF (NSEG.EQ.2) THEN
          WRITE(6,'(A)') '  PROPAGATION RANGES ARE CONTROLLED BY '//
     1                   'VARIABLES RMIN, RMATCH AND RMAX, WITH '//
     2                   'INPUT VALUES'
          WRITE(6,1010) ' RMIN = ',RMIN,' RMATCH = ',RMATCH,
     1                 ' RMAX = ',RMAX
        ELSE
          WRITE(6,*) ' PROPAGATION RANGES ARE CONTROLLED BY '//
     1               'VARIABLES RMIN, RMID, RMATCH AND RMAX, WITH '//
     2               'INPUT VALUES'
          WRITE(6,1010) ' RMIN = ',RMIN,'RMID = ',RMID,
     1                 ' RMATCH = ',RMATCH,' RMAX = ',RMAX
        ENDIF
      ENDIF
 1000 FORMAT(/2X,A,A,1X,I1,1X,A:,A)
 1010 FORMAT(1X,A,1PG11.4,A,G11.4:,A,G11.4:,A,G11.4)

      DO ISEG=1,NSEG

        WRITE(6,1020) ' SEGMENT ',ISEG,' WILL BE PROPAGATED ',
     1                TRIM(DIRNAM(ISEG)),'WARDS'
 1020   FORMAT(2X,118('+')/1X,A,I1,A,A3,A/)

        WRITE(6,'(2X,A)') TRIM(TXT(ISEG))
        IF (CDRIVE.EQ.'M' .AND. ISEG.EQ.NSEG .AND. RMXTX2.NE.' ') THEN
          WRITE(6,'(2X,A/)') TRIM(RMXTX2)
        ELSE
          WRITE(6,*)
        ENDIF

        TOLHIT=TOLSEG(ISEG)
        DRT=DRSEG(ISEG)
        IPROP=IPRSEG(ISEG)
        EP=EPSEG(ISEG)
        STEP=STPSEG(ISEG)
        POWR=POWSEG(ISEG)

        IF (IPROP.EQ.IWKB) THEN
          WRITE(6,299) TOLHIT,NGMP
  299     FORMAT(/'  PHASE SHIFT CALCULATED IN WKB APPROXIMATION BY ',
     1           'GAUSS-MEHLER QUADRATURE.  SEE R. T PACK, ',
     2           'JCP 60, 633 (1974).'//
!'  NOTE THAT THIS IS IMPLEMENTED ONLY FOR ONE CHANNEL CASES, E.G., IOS CALCULATIONS.'//
     5           '  WITH CONVERGENCE CONTROLLED BY:',5X,
     6           'TOLHI =',E14.4/38X,'NGMP  =',I6,' (',I2,')',I3)

        ELSEIF (IPROP.EQ.IDV) THEN
          WRITE(6,320) TOLHIT,NSTAB
  320     FORMAT(/'  COUPLED EQUATIONS SOLVED BY PROPAGATOR OF ',
     1           'DE VOGELAERE'/'  PROPAGATION PARAMETERS ARE: ',3X,
     2           'TOLHI  =',E9.2/33X,'NSTAB =',I3,
     4           '  (STEPS PER STABILIZATION)')

        ELSEIF (IPROP.EQ.IRM) THEN
          WRITE(6,330)
  330     FORMAT(/'  COUPLED EQUATIONS SOLVED BY WALKER-LIGHT R-MATRIX',
     1         ' PROPAGATOR')

        ELSEIF (IPROP.EQ.IVV) THEN
          WRITE(6,340) DRMAX,XSQMAX,ALPHA1,ALPHA2,IALPHA,
     1                 ISHIFT,IV,IPERT,IVP,IALFP,IVPP,
     2                 ISYM,NUMDER
  340     FORMAT(/'  USING VARIABLE INTERVAL / VARIABLE ',
     1           'STEP (VIVS) PROPAGATOR'//'  PROPAGATION ',
     2           'PARAMETERS ARE:    DRMAX  = ',F8.2,8X,
     3                              'XSQMAX =  ',1PG9.2/
     5           33X,'ALPHA1 =  ',0PF7.2,8X,'ALPHA2 =  ',F7.2/
     6           33X,'IALPHA = ',I8/
     7           33X,'ISHIFT =',L9,8X,'IV     = ',L8/
     8           33X,'IPERT  =',L9,8X,'IVP    = ',L8/
     9           33X,'IALFP  =',L9,8X,'IVPP   = ',L8/
     A           33X,'ISYM   =',L9,8X,'NUMDER = ',L8)

        ELSEIF (IPROP.EQ.ILD) THEN
          WRITE(6,350)
  350     FORMAT('  COUPLED EQUATIONS SOLVED BY LOG-DERIVATIVE ',
     1           'PROPAGATOR OF JOHNSON')

        ELSEIF (IPROP.EQ.IMD) THEN
          WRITE(6,360)
  360     FORMAT('  COUPLED EQUATIONS SOLVED BY DIABATIC ',
     1           'MODIFIED LOG-DERIVATIVE PROPAGATOR OF MANOLOPOULOS')

        ELSEIF (IPROP.EQ.IMA) THEN
          WRITE(6,370)
  370     FORMAT('  COUPLED EQUATIONS SOLVED BY QUASIADIABATIC ',
     1           'MODIFIED LOG-DERIVATIVE PROPAGATOR OF MANOLOPOULOS')

        ELSEIF (IPROP.EQ.IMG) THEN
          WRITE(6,380)
  380     FORMAT('  COUPLED EQUATIONS SOLVED BY SYMPLECTIC LOG-',
     1           'DERIVATIVE PROPAGATOR OF MANOLOPOULOS AND GRAY')
          IF (IMGSEL.EQ.4) THEN
            WRITE(6,381)
          ELSEIF (IMGSEL.EQ.5) THEN
            WRITE(6,382)
          ENDIF
  381     FORMAT('  USING THE FIVE-STEP FOURTH-ORDER METHOD OF CALVO ',
     1           'AND SANZ-SERNA')
  382     FORMAT('  USING THE SIX-STEP FIFTH-ORDER METHOD OF ',
     1           'MCLACHLAN AND ATELA')

        ELSEIF (IPROP.EQ.IAIRY) THEN
          WRITE(6,390)
  390     FORMAT('  COUPLED EQUATIONS SOLVED BY VARIABLE-STEP ',
     1           'AIRY PROPAGATOR.'/'  PUBLICATIONS RESULTING FROM ',
     2           'THE USE OF THIS PROPAGATOR SHOULD REFERENCE'/
     3           '  M. H. ALEXANDER AND D. E. MANOLOPOULOS,  ',
     4           'J. CHEM. PHYS. 86, 2044 (1987).')

        ENDIF

C  TEXT ABOUT HOW STEP SIZE IS CHOSEN
        IF (IPROP.GE.IDV .OR. IPROP.EQ.IAIRY) THEN
          IF (STEP.GT.0.D0) THEN
            WRITE(6,400) 'STEP',STEP,' (PER WAVELENGTH)'
            IF (EP.NE.0.D0) WRITE(6,410) EP
  410       FORMAT('  WITH WAVELENGTH EVALUATED FOR POTENTIAL DEPTH',
     1             ' EP = ',1PG9.2,' CM-1')
          ELSE
            IF (DRSEG(ISEG).NE.UNSET) THEN
              WRITE(6,400) 'DR',DRT
            ELSEIF (DRSEG(ISEG).EQ.UNSET .AND. ISEG.GT.1) THEN
              WRITE(6,*)
              IF (DIRNAM(ISEG).EQ.'OUT') THEN
                WRITE(6,*) ' INITIAL STEP SIZE TAKEN '//
     1                     'FROM SIZE OF FINAL STEP OF PREVIOUS '//
     2                     'SEGMENT'
              ELSEIF (DIRNAM(ISEG).EQ.'IN') THEN
                WRITE(6,*) ' INITIAL STEP SIZE TAKEN '//
     1                     'FROM SIZE OF FINAL STEP OF SHORT-RANGE '//
     2                     'PROPAGATION'
              ENDIF
            ENDIF
          ENDIF
        ENDIF
  400   FORMAT(/'  PROPAGATION STEP SIZE DETERMINED USING ',A,' = ',
     1         1P,G10.3:A)

        IF (IPROP.EQ.IWKB) CYCLE

        IF (IPROP.EQ.IVV .OR. (IPROP.EQ.IAIRY .AND. TOLHIT.GT.0.D0))
     1  THEN
          WRITE(6,*) ' STEP SIZES ADJUSTED TO MAINTAIN APPROXIMATE'//
     1               ' ACCURACY VIA PERTURBATION THEORY'
          IF (IPROP.EQ.IAIRY) WRITE(6,900) TOLHIT,POWR
  900     FORMAT(2X,'WITH TOLHI = ',1PG9.2:,' AND POWR = ',G9.2)
        ELSE
          IF (POWR.EQ.0.D0) THEN
            WRITE(6,*) ' STEP SIZE CONSTANT THROUGHOUT RANGE'
          ELSEIF (POWR.NE.0.D0) THEN
            WRITE(6,910) POWR
  910       FORMAT(2X,'STEP SIZE SCALES AS R**',F4.2)
          ENDIF
          WRITE(6,*) ' STEP SIZE MAY BE ADJUSTED SLIGHTLY SO THAT',
     1               ' RANGE IS A WHOLE NUMBER OF STEPS'
        ENDIF

C  WRITE MESSAGES ABOUT Y MATRIX INITIALISATION
        IF (ISEG.EQ.1) THEN
          WRITE(6,*)
          IF (ADIAMN) THEN
            IF (CDRIVE.EQ.'M') THEN
              WRITE(6,500) 'RMIN'
            ELSE
              WRITE(6,500) 'RMIN','OUTWARD'
            ENDIF
          ELSE
            WRITE(6,510) 'OUTWARD'
          ENDIF
          IF (WKBMN) THEN
            WRITE(6,520) 'CLOSED'
          ELSE
            WRITE(6,530) 'CLOSED',BCYCMN
          ENDIF
          WRITE(6,530)   ' OPEN ',BCYOMN
        ELSEIF (DIRNAM(ISEG).EQ.'IN' .AND. DIRNAM(ISEG-1).EQ.'OUT') THEN
          WRITE(6,*)
          IF (ADIAMX) THEN
            WRITE(6,500) 'RMAX','INWARD'
          ELSE
            WRITE(6,510) 'INWARD'
          ENDIF
          IF (WKBMX) THEN
            WRITE(6,520) 'CLOSED'
          ELSE
            WRITE(6,530) 'CLOSED',BCYCMX
          ENDIF
          WRITE(6,530)   ' OPEN ',BCYOMX
        ENDIF
  500   FORMAT('  LOG-DERIVATIVE MATRIX INITIALISED IN THE',
     1         ' LOCAL EIGENBASIS AT ',A,:' IN THE ',A,
     2         ' PROPAGATION PART')
  510   FORMAT('  LOG-DERIVATIVE MATRIX INITIALISED IN THE'
     1         ' PRIMITIVE BASIS AT ',A,:' IN THE ',A,
     2         ' PROPAGATION PART')
  520   FORMAT('  LOCALLY ',A,' CHANNELS INITIALISED',
     1         ' WITH A WKB BOUNDARY CONDITION')
  530   FORMAT('  LOCALLY ',A,' CHANNELS INITIALISED',
     1         ' WITH THE VALUE ',1PE10.3)
C
      ENDDO

      RETURN
      END
