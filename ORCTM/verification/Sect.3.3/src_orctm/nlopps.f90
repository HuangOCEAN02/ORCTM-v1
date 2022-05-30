      SUBROUTINE NLOPPS(TA,SA,DZ,DP,PRES,KDEPCON,DTTS)
!---------------------------------------------------------
!
!     NLOPPS:   MODIFIED FROM LOPPS BY E. SKYLLINGSTAD AND T. PALUSZKIEWICZ
!
!     VERSION: DECEMBER 11, 1996
!
!     NLOPPS:  THIS VERSION OF LOPPS IS SIGNIFICANTLY DIFFERENT FROM
!     THE ORIGINAL CODE DEVELOPED BY R. ROMEA AND T. PALUSKIEWICZ.  THE
!     CODE USES A FLUX CONSTRAINT TO CONTROL THE CHANGE IN T AND S AT
!     EACH GRID LEVEL.  FIRST, A PLUME PROFILE OF T,S, AND W ARE
!     DETERMINED USING THE STANDARD PLUME MODEL, BUT WITH A DETRAINING
!     MASS INSTEAD OF ENTRAINING.  THUS, THE T AND S PLUME
!     CHARACTERISTICS STILL CHANGE, BUT THE PLUME CONTRACTS IN SIZE
!     RATHER THAN EXPANDING ALA CLASSICAL ENTRAINING PLUMES.  THIS
!     IS HEURISTICALLY MORE IN LINE WITH LARGE EDDY SIMULATION RESULTS.
!     AT EACH GRID LEVEL, THE CONVERGENCE OF PLUME VELOCITY DETERMINES
!     THE FLUX OF T AND S, WHICH IS CONSERVED BY USING AN UPSTREAM
!     ADVECTION.  THE VERTICAL VELOCITY IS BALANCED SO THAT THE AREA
!     WEIGHTED UPWARD VELOCITY EQUALS THE AREA WEIGHTED DOWNDRAFT
!     VELOCITY, ENSURING MASS CONSERVATION. THE PRESENT IMPLEMENTATION
!     ADJUSTS THE PLUME FOR A TIME PERIOD EQUAL TO THE TIME FOR 1/2 OF
!     THE MASS OF THE FASTEST MOVING LEVEL TO MOVE DOWNWARD.  AS A
!     CONSEQUENCE, THE MODEL DOES NOT COMPLETELY ADJUST THE PROFILE AT
!     EACH MODEL TIME STEP, BUT PROVIDES A SMOOTH ADJUSTMENT OVER TIME.
!
!
!---------------------------------------------------------
!
      USE MO_PARAM1
!
      REAL TA(IE,JE,KE),SA(IE,JE,KE),DP(IE,JE,KE)
      REAL GCMDZ(KE),DZ(KE),PRES(KE)
      REAL THELP(KE),SHELP(KE),THELP1(KE),SHELP1(KE)
      REAL THELP2(KE),SHELP2(KE)
!
      REAL TTEMP(KE),STEMP(KE),TAA(KE),SAA(KE)
      REAL WDA(KE),TDA(KE),SDA(KE),MDA(KE)
      REAL AD(KE),SD(KE),TD(KE),WD(KE),MD(KE)
      REAL SE(KE),TE(KE),WE(KE),DE(KE),DD(KE)
      REAL PLUMEENTRAINMENT(KE)
      REAL GRIDTHICKNESS(KE)
!
      REAL WSQR,RADIUS
      REAL SMIX,THMIX
      REAL D1,D2
      REAL DZ1,DZ2
      REAL STARTINGFLUX,OLDFLUX,NEWFLUX,ENTRAINRATE
      REAL DTTS,DT
      INTEGER NTIME,NN,KMX,IC
      INTEGER KDEPCON(IE,JE) !SJM DEPTH OF CONVECTION
!
!
! INPUT THE VARIABLES THROUGH A COMMON
!
!
!      LOGICAL DEBUG,DONE,PROBLEM
      INTEGER MAX_ABE_ITERATIONS
      PARAMETER(MAX_ABE_ITERATIONS=1)
      REAL PLUMERADIUS
      REAL STABILITY_THRESHOLD
      REAL FRACTIONAL_AREA
      REAL VERTICAL_VELOCITY
      REAL ENTRAINMENT_RATE
      REAL E2
      PARAMETER ( PLUMERADIUS          =  500.E0   )
!SJ***SENS.PCN: CHANGE THE PLUME RADIUS INTO 700 M
!      PARAMETER ( PLUMERADIUS          =  700.D0   )
      PARAMETER ( STABILITY_THRESHOLD  =  -1.E-4   )
      PARAMETER ( FRACTIONAL_AREA      =  .1E0    )
      PARAMETER ( VERTICAL_VELOCITY    =  .03E0   )
      PARAMETER ( ENTRAINMENT_RATE     =  -.05E0     )
      PARAMETER ( E2    =   2.E0*ENTRAINMENT_RATE  )
!
!
!-----MAY WANT TO SETUP AN OPTION TO GET THIS ONLY ON FIRST CALL
!     OTHERWISE IT IS REPETIVE
!     GRIDDZ IS INITIALIZE BY CALL TO SETUPGRID
!
!      DTTS=2400.
!SJM   DTTS = 72000.
!      DTTS=1920.   !!!CSJM
!
        DO I=1,IE
        DO J=1,JE
        KDEPCON(I,J)=0
        ENDDO
        ENDDO
!
!
!        DO K=1,KE
!          DZ(K) = 0.01*GCMDZ(K)
!          DZ(K) = GCMDZ(K)
!        ENDDO
!
        DO K=1,KE
           GRIDTHICKNESS(K) = DZ(K)
        ENDDO
!
!
! MODIFIED TO LOOP OVER SLAB
!
      DO 10 J=1,JE
!
      DO 100 I=1,IE
!
      KMAX=0
      DO K=1,KE
         EPPS = 1.E-30
         WET = MAX ( 0. , DP(I,J,K)/(DP(I,J,K) - EPPS))
         IF(WET.NE.0.) KMAX=K
      ENDDO
!
      IF(KMAX.LE.1) GOTO 100
!
      DO K=1,KMAX
         STEMP(K)=SA(I,J,K)
         TTEMP(K)=TA(I,J,K)
!       IF(I.EQ.5.AND.J.EQ.35)PRINT*,'OLD=',STEMP(K),K
         SHELP1(K)=STEMP(K)
         THELP1(K)=TTEMP(K)
      ENDDO
!
      DO K=1,KMAX-1
! INITIALIZE THE PLUME T,S,DENSITY, AND W VELOCITY
!
          SD(K)=STEMP(K)
          TD(K)=TTEMP(K)
!
          SHELP(K)=STEMP(K)
          THELP(K)=TTEMP(K)
!
          CALL ADISIT1(THELP1(K),SHELP1(K),PRES(K))
          CALL RHO2(THELP1(K),SHELP1(K),PRES(K),DD(K))
          DE(K)=DD(K)
!
          WD(K)=VERTICAL_VELOCITY
! GUESS AT INITIAL TOP GRID CELL VERTICAL VELOCITY
!
!          WD(K) = 0.03
! THESE ESTIMATES OF INITIAL PLUME VELOCITY BASED ON PLUME SIZE AND
! TOP GRID CELL WATER MASS
!          WD(K) = 0.5*DZ(K)/(DTTS*FRACTIONAL_AREA)
!          WD(K) = 0.5*DZ(K)/DTTS
!
          WSQR=WD(K)*WD(K)
          PLUMEENTRAINMENT(K) = 0.0
!
          RADIUS=PLUMERADIUS
          STARTINGFLUX=RADIUS*RADIUS*WD(K)*DD(K)
          OLDFLUX=STARTINGFLUX
!
          DZ2=GRIDTHICKNESS(K)
!
          DO K2=K,KMAX-1
!  CALCULATE DENSITY FOR UPPER LAYER
            CALL ADISIT1(THELP(K2),SHELP(K2),PRES(K2+1))
            CALL RHO2(THELP(K2),SHELP(K2),PRES(K2+1),D1)
!  CALCULATE DENSITY FOR LOWER LAYER
            CALL ADISIT1(THELP1(K2+1),SHELP1(K2+1),PRES(K2+1))
            CALL RHO2(THELP1(K2+1),SHELP1(K2+1),PRES(K2+1),D2)
!
            DE(K2+1)=D2
!
! TO START DOWNWARD, PARCEL HAS TO INITIALLY BE HEAVIER THAN ENVIRONMENT
! BUT AFTER IT HAS STARTED MOVING, WE CONTINUE PLUME UNTIL PLUME TKE OR
! FLUX GOES NEGATIVE
!
!SJ***SENS.CONV_NS:
!          IF(J.GE.34) STABILITY_THRESHOLD = -1.E-5
!
            IF (D2-D1 .LT. STABILITY_THRESHOLD.OR.K2.NE.K) THEN
                 DZ1=DZ2
                 DZ2=GRIDTHICKNESS(K2+1)
!
! DEFINE MASS FLUX ACCORDING TO EQ. 4 FROM PAPER
                 NEWFLUX=OLDFLUX+E2*RADIUS*WD(K2)*DD(K2)*0.50*          &
     &              (DZ1+DZ2)
!
                 PLUMEENTRAINMENT(K2+1) = NEWFLUX/STARTINGFLUX
!
!SJ***SENS.CONV_NS: MODIFIED BY SJKIM
                 IF(NEWFLUX.LT.1000.0) THEN
                     MAXDEPTH = K2
                     IF(MAXDEPTH.EQ.K) GOTO 1000
                     GOTO 1
                 ENDIF
!
! ENTRAINMENT RATE IS BASICALLY A SCALED MASS FLUX DM/M
!
                 ENTRAINRATE = (NEWFLUX - OLDFLUX)/NEWFLUX
                 OLDFLUX = NEWFLUX
!
!
! MIX VAR'S ARE THE AVERAGE ENVIRONMENTAL VALUES OVER THE TWO GRID LEVELS
!
                 SMIX=(DZ1*STEMP(K2)+DZ2*STEMP(K2+1))/(DZ1+DZ2)
                 THMIX=(DZ1*TTEMP(K2)+DZ2*TTEMP(K2+1))/(DZ1+DZ2)
!
! FIRST COMPUTE THE NEW SALINITY AND TEMPERATURE FOR THIS LEVEL
! USING EQUATIONS 3.6 AND 3.7 FROM THE PAPER
!
!
!
                  SD(K2+1)=SD(K2) - ENTRAINRATE*(SMIX - SD(K2))
                  TD(K2+1)=TD(K2) - ENTRAINRATE*(THMIX - TD(K2))
!
        IF(SD(K2+1).LE.0.)PRINT*,I,J,K,K2,ENTRAINRATE,NEWFLUX
!
                  SHELP2(K2+1)=SD(K2+1)
                  THELP2(K2+1)=TD(K2+1)
!
!
! COMPUTE THE DENSITY AT THIS LEVEL FOR THE BUOYANCY TERM IN THE
! VERTICAL K.E. EQUATION
!
!
           CALL ADISIT1(THELP2(K2+1),SHELP2(K2+1),PRES(K2+1))
           CALL RHO2(THELP2(K2+1),SHELP2(K2+1),PRES(K2+1),DD(K2+1))
!
! NEXT, SOLVE FOR THE VERTICAL VELOCITY K.E. USING COMBINED EQ. 4
! AND EQ 5 FROM THE PAPER
!
!
                 WSQR = WSQR - WSQR*ABS(ENTRAINRATE)+ 9.806*            &
     &             (DZ1*(DD(K2)-DE(K2))/DE(K2)                          &
     &             +DZ2*(DD(K2+1)-DE(K2+1))/DE(K2+1))
!
! IF NEGATIVE K.E. THEN PLUME HAS REACHED MAX DEPTH, GET OUT OF LOOP
!
                 IF(WSQR.LT.0.0)THEN
                     MAXDEPTH = K2
                     IF(MAXDEPTH.EQ.K) GOTO 1000
                     GOTO 1
                 ENDIF
                 WD(K2+1)=SQRT(WSQR)
!
! COMPUTE A NEW RADIUS BASED ON THE NEW MASS FLUX AT THIS GRID LEVEL
                 RADIUS=SQRT(NEWFLUX/(WD(K2)*DD(K2)))
              ELSE
                 MAXDEPTH=K2
                 IF(MAXDEPTH.EQ.K) GOTO 1000
                 GOTO 1
              ENDIF
          ENDDO
!
! PLUME HAS REACHED THE BOTTOM
!
          MAXDEPTH=KMAX
!
 1         CONTINUE
!
          AD(K)=FRACTIONAL_AREA
          IC=0
!
! START ITERATION ON FRACTIONAL AREA, NOT USED IN OGCM IMPLEMENTATION
!
!
!
          DO IC=1,MAX_ABE_ITERATIONS
!
!
! NEXT COMPUTE THE MASS FLUX BETWEEN EACH GRID BOX USING THE ENTRAINMENT
!
             MD(K)=WD(K)*AD(K)
!
             DO K2=K+1,MAXDEPTH
               MD(K2)=MD(K)*PLUMEENTRAINMENT(K2)
             ENDDO
!
! NOW MOVE ON TO CALCULATE NEW TEMPERATURE USING FLUX FROM
! TD, SD, WD, TA, SA, AND WE. VALUES FOR THESE VARIABLES ARE AT
! CENTER OF GRID CELL, USE WEIGHTED AVERAGE TO GET BOUNDARY VALUES
!
! USE A TIMESTEP LIMITED BY THE GCM MODEL TIMESTEP AND THE MAXIMUM PLUME
! VELOCITY (CFL CRITERIA)
!
!
! CALCULATE THE WEIGHTED WD, TD, AND SD
!
             DT = DTTS
             DO K2=K,MAXDEPTH-1
                DT = MIN(DT,DZ(K2)/WD(K2))
!
! TIME INTEGRATION WILL BE INTEGER NUMBER OF STEPS TO GET ONE
! GCM TIME STEP
!
                NTIME = NINT(0.5*INT(DTTS/DT))
                IF(NTIME.EQ.0) THEN
                   NTIME = 1
                ENDIF
!
! MAKE SURE AREA WEIGHTED VERTICAL VELOCITIES MATCH; IN OTHER WORDS
! MAKE SURE MASS IN EQUALS MASS OUT AT THE INTERSECTION OF EACH GRID
! CELL.
!
                MDA(K2) = (MD(K2)*DZ(K2)+MD(K2+1)*DZ(K2+1))/            &
     &                    (DZ(K2)+DZ(K2+1))
!
!                WDA(K2) = (WD(K2)*DZ(K2)+WD(K2+1)*DZ(K2+1))/
!     *                    (DZ(K2)+DZ(K2+1))
!
                TDA(K2) = TD(K2)
                SDA(K2) = SD(K2)
!
                TAA(K2) = TTEMP(K2+1)
                SAA(K2) = STEMP(K2+1)
!
             ENDDO
!
             DT = MIN(DT,DTTS)
!
             TDA(MAXDEPTH) = TD(MAXDEPTH)
             SDA(MAXDEPTH) = SD(MAXDEPTH)
!
! DO TOP AND BOTTOM POINTS FIRST
!
             KMX = MAXDEPTH-1
!
             DO NN=1,NTIME
!
               TTEMP(K) =  TTEMP(K)-                                    &
     &                  (MDA(K)*(TDA(K)-TAA(K)))*DT/DZ(K)
!
               STEMP(K) =  STEMP(K)-                                    &
     &                  (MDA(K)*(SDA(K)-SAA(K)))*DT/DZ(K)
!
!
! NOW DO INNER POINTS IF THERE ARE ANY
!
               IF(MAXDEPTH-K.GT.1) THEN
                 DO K2=K+1,MAXDEPTH-1
!
                   TTEMP(K2) = TTEMP(K2) +                              &
     &              (MDA(K2-1)*(TDA(K2-1)-TAA(K2-1))-                   &
     &              MDA(K2)*(TDA(K2)-TAA(K2)))                          &
     &              *DT/DZ(K2)
!
!
                  STEMP(K2) = STEMP(K2) +                               &
     &              (MDA(K2-1)*(SDA(K2-1)-SAA(K2-1))-                   &
     &              MDA(K2)*(SDA(K2)-SAA(K2)))                          &
     &              *DT/DZ(K2)
!
                 ENDDO
               ENDIF
!
               TTEMP(KMX+1) =  TTEMP(KMX+1)+                            &
     &                  (MDA(KMX)*(TDA(KMX)-TAA(KMX)))*                 &
     &                  DT/DZ(KMX+1)
!
               STEMP(KMX+1) =  STEMP(KMX+1)+                            &
     &                  (MDA(KMX)*(SDA(KMX)-                            &
     &                  SAA(KMX)))*DT/DZ(KMX+1)
!
! SET THE ENVIRONMENTAL TEMP AND SALINITY TO EQUAL NEW FIELDS
!
                DO K2=1,MAXDEPTH-1
                  TAA(K2) = TTEMP(K2+1)
                  SAA(K2) = STEMP(K2+1)
                ENDDO
!
! END LOOP ON NUMBER OF TIME INTEGRATION STEPS
!
             ENDDO
          ENDDO
!
! ASSUME THAT IT CONVERGED, SO UPDATE THE TA AND SA WITH NEW FIELDS
!
          DO K2=K,MAXDEPTH
            SA(I,J,K2) = STEMP(K2)
            TA(I,J,K2) = TTEMP(K2)
          ENDDO
!SJM
      KDEPCON(I,J) = MAXDEPTH
!
! JUMP HERE IF K = MAXDEPTH OR IF LEVEL NOT UNSTABLE, GO TO NEXT
! PROFILE POINT
!
 1000     CONTINUE
!
! END LOOP ON K, MOVE ON TO NEXT POSSIBLE PLUME
!
      ENDDO
!
! I LOOP
!
 100  CONTINUE
!
! J LOOP
  10  CONTINUE
      RETURN
      END
