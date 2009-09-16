MODULE VELO

! Module computes the velocity flux terms, baroclinic torque correction terms, and performs the CFL Check

USE PRECISION_PARAMETERS
USE GLOBAL_CONSTANTS
USE MESH_POINTERS
USE COMP_FUNCTIONS, ONLY: SECOND

IMPLICIT NONE

PRIVATE
CHARACTER(255), PARAMETER :: veloid='$Id$'
CHARACTER(255), PARAMETER :: velorev='$Revision$'
CHARACTER(255), PARAMETER :: velodate='$Date$'

PUBLIC COMPUTE_VELOCITY_FLUX,VELOCITY_PREDICTOR,VELOCITY_CORRECTOR,NO_FLUX,GET_REV_velo,MATCH_VELOCITY,VELOCITY_BC,CHECK_STABILITY
PRIVATE VELOCITY_FLUX,VELOCITY_FLUX_ISOTHERMAL,VELOCITY_FLUX_CYLINDRICAL
 
CONTAINS
 
SUBROUTINE COMPUTE_VELOCITY_FLUX(T,NM,FUNCTION_CODE)

REAL(EB), INTENT(IN) :: T
REAL(EB) :: TNOW
INTEGER, INTENT(IN) :: NM,FUNCTION_CODE

IF (SOLID_PHASE_ONLY) RETURN

TNOW = SECOND()

SELECT CASE(FUNCTION_CODE)
   CASE(1)
      IF (DNS .AND. ISOTHERMAL .AND. N_SPECIES==0) THEN
         CALL VELOCITY_FLUX_ISOTHERMAL(NM)
      ELSE
         IF (PREDICTOR .OR. COMPUTE_VISCOSITY_TWICE) CALL COMPUTE_VISCOSITY(NM)
      ENDIF
   CASE(2)
      IF (PREDICTOR .OR. COMPUTE_VISCOSITY_TWICE) CALL VISCOSITY_BC(NM)
      IF (.NOT.CYLINDRICAL) CALL VELOCITY_FLUX(T,NM)
      IF (     CYLINDRICAL) CALL VELOCITY_FLUX_CYLINDRICAL(T,NM)
END SELECT

TUSED(4,NM) = TUSED(4,NM) + SECOND() - TNOW
END SUBROUTINE COMPUTE_VELOCITY_FLUX



SUBROUTINE COMPUTE_VISCOSITY(NM)

! Compute turblent eddy viscosity from constant coefficient Smagorinsky model

USE PHYSICAL_FUNCTIONS, ONLY: GET_VISCOSITY
USE TURBULENCE, ONLY: VARDEN_DYNSMAG
INTEGER, INTENT(IN) :: NM
REAL(EB) :: DUDX,DUDY,DUDZ,DVDX,DVDY,DVDZ,DWDX,DWDY,DWDZ,SS,S12,S13,S23,DELTA,CS,YY_GET(1:N_SPECIES)
INTEGER :: I,J,K,ITMP,IIG,JJG,KKG,II,JJ,KK,IW
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW,RHOP
REAL(EB), POINTER, DIMENSION(:,:,:,:) :: YYP
 
CALL POINT_TO_MESH(NM)
 
IF (PREDICTOR) THEN
   UU => U
   VV => V
   WW => W
   RHOP => RHO
   IF (N_SPECIES > 0) YYP => YY
   IF ((DYNSMAG .AND. .NOT.EVACUATION_ONLY(NM)) .AND. (ICYC==1 .OR. MOD(ICYC,DSMAG_FREQ)==0)) CALL VARDEN_DYNSMAG(NM)
ELSE
   UU => US
   VV => VS
   WW => WS
   RHOP => RHOS
   IF (N_SPECIES > 0 .AND. .NOT.EVACUATION_ONLY(NM)) YYP => YYS
ENDIF

! Compute viscosity for DNS using primitive species/mixture fraction

!$OMP PARALLEL PRIVATE(CS) SHARED(MU,TMP,YYP)
IF (N_SPECIES == 0 .OR. EVACUATION_ONLY(NM)) THEN
   !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,ITMP)
   DO K=1,KBAR
      DO J=1,JBAR
         DO I=1,IBAR
            !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_COMPUTE_VISCOSITY_01'
            IF (SOLID(CELL_INDEX(I,J,K))) CYCLE
            ITMP = MIN(5000,NINT(TMP(I,J,K)))
            MU(I,J,K)=Y2MU_C(ITMP)*SPECIES(0)%MW
         ENDDO
      ENDDO
   ENDDO
   !$OMP END DO
ELSE
   !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,ITMP,YY_GET) 
   DO K=1,KBAR
      DO J=1,JBAR
         DO I=1,IBAR
            !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_COMPUTE_VISCOSITY_02'
            IF (SOLID(CELL_INDEX(I,J,K))) CYCLE
            ITMP = MIN(5000,NINT(TMP(I,J,K)))
            YY_GET(:) = YYP(I,J,K,:)
            CALL GET_VISCOSITY(YY_GET,MU(I,J,K),ITMP)
         ENDDO
      ENDDO
   ENDDO
   !$OMP END DO
ENDIF

! Compute eddy viscosity using Smagorinsky model

IF (LES .OR. EVACUATION_ONLY(NM)) THEN
   CS = CSMAG
   IF (EVACUATION_ONLY(NM)) CS = 0.9_EB
   !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,DELTA,DUDX,DVDY,DWDZ,DUDY,DUDZ,DVDX,DVDZ,DWDX,DWDY,S12,S13,S23,SS)
   DO K=1,KBAR
      DO J=1,JBAR
         DO I=1,IBAR
            !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_COMPUTE_VISCOSITY_03'
            IF (SOLID(CELL_INDEX(I,J,K))) CYCLE
            IF (TWO_D) THEN
               DELTA = SQRT(DX(I)*DZ(K))
            ELSE
               DELTA = (DX(I)*DY(J)*DZ(K))**ONTH
            ENDIF
            DUDX = RDX(I)*(UU(I,J,K)-UU(I-1,J,K))
            DVDY = RDY(J)*(VV(I,J,K)-VV(I,J-1,K))
            DWDZ = RDZ(K)*(WW(I,J,K)-WW(I,J,K-1))
            DUDY = 0.25_EB*RDY(J)*(UU(I,J+1,K)-UU(I,J-1,K)+UU(I-1,J+1,K)-UU(I-1,J-1,K))
            DUDZ = 0.25_EB*RDZ(K)*(UU(I,J,K+1)-UU(I,J,K-1)+UU(I-1,J,K+1)-UU(I-1,J,K-1)) 
            DVDX = 0.25_EB*RDX(I)*(VV(I+1,J,K)-VV(I-1,J,K)+VV(I+1,J-1,K)-VV(I-1,J-1,K))
            DVDZ = 0.25_EB*RDZ(K)*(VV(I,J,K+1)-VV(I,J,K-1)+VV(I,J-1,K+1)-VV(I,J-1,K-1))
            DWDX = 0.25_EB*RDX(I)*(WW(I+1,J,K)-WW(I-1,J,K)+WW(I+1,J,K-1)-WW(I-1,J,K-1))
            DWDY = 0.25_EB*RDY(J)*(WW(I,J+1,K)-WW(I,J-1,K)+WW(I,J+1,K-1)-WW(I,J-1,K-1))
            S12 = 0.5_EB*(DUDY+DVDX)
            S13 = 0.5_EB*(DUDZ+DWDX)
            S23 = 0.5_EB*(DVDZ+DWDY)
            SS = SQRT(2._EB*(DUDX**2 + DVDY**2 + DWDZ**2 + 2._EB*(S12**2 + S13**2 + S23**2)))
            
            IF (DYNSMAG) CS = C_DYNSMAG(I,J,K)
            MU(I,J,K) = MU(I,J,K) + RHOP(I,J,K)*(CS*DELTA)**2*SS
         ENDDO
      ENDDO
   ENDDO
   !$OMP END DO
ENDIF

! Mirror viscosity into solids and exterior boundary cells
 
!$OMP DO PRIVATE(IW,II,JJ,KK,IIG,JJG,KKG)
WALL_LOOP: DO IW=1,NWC
   !!$ IF ((IW == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VISCOSITY_BC'
   IF (BOUNDARY_TYPE(IW)==NULL_BOUNDARY .OR. BOUNDARY_TYPE(IW)==POROUS_BOUNDARY) CYCLE WALL_LOOP
   II  = IJKW(1,IW)
   JJ  = IJKW(2,IW)
   KK  = IJKW(3,IW)
   IIG = IJKW(6,IW)
   JJG = IJKW(7,IW)
   KKG = IJKW(8,IW)
   SELECT CASE(BOUNDARY_TYPE(IW))
      CASE(SOLID_BOUNDARY)
         MU(IIG,JJG,KKG) = MU(IIG,JJG,KKG)
         MU(II,JJ,KK) = MU(IIG,JJG,KKG)
      CASE(OPEN_BOUNDARY,MIRROR_BOUNDARY)
         MU(II,JJ,KK) = MU(IIG,JJG,KKG)
   END SELECT
ENDDO WALL_LOOP
!$OMP END DO

!$OMP WORKSHARE
MU(   0,0:JBP1,   0) = MU(   1,0:JBP1,1)
MU(IBP1,0:JBP1,   0) = MU(IBAR,0:JBP1,1)
MU(IBP1,0:JBP1,KBP1) = MU(IBAR,0:JBP1,KBAR)
MU(   0,0:JBP1,KBP1) = MU(   1,0:JBP1,KBAR)
MU(0:IBP1,   0,   0) = MU(0:IBP1,   1,1)
MU(0:IBP1,JBP1,0)    = MU(0:IBP1,JBAR,1)
MU(0:IBP1,JBP1,KBP1) = MU(0:IBP1,JBAR,KBAR)
MU(0:IBP1,0,KBP1)    = MU(0:IBP1,   1,KBAR)
MU(0,   0,0:KBP1)    = MU(   1,   1,0:KBP1)
MU(IBP1,0,0:KBP1)    = MU(IBAR,   1,0:KBP1)
MU(IBP1,JBP1,0:KBP1) = MU(IBAR,JBAR,0:KBP1)
MU(0,JBP1,0:KBP1)    = MU(   1,JBAR,0:KBP1)
!$OMP END WORKSHARE

IF (FISHPAK_BC(1)==0) THEN
   !$OMP WORKSHARE
   MU(0,:,:) = MU(IBAR,:,:)
   MU(IBP1,:,:) = MU(1,:,:)
   !$OMP END WORKSHARE
ENDIF
IF (FISHPAK_BC(2)==0) THEN
   !$OMP WORKSHARE
   MU(:,0,:) = MU(:,JBAR,:)
   MU(:,JBP1,:) = MU(:,1,:)
   !$OMP END WORKSHARE
ENDIF
IF (FISHPAK_BC(3)==0) THEN
   !$OMP WORKSHARE
   MU(:,:,0) = MU(:,:,KBAR)
   MU(:,:,KBP1) = MU(:,:,1)
   !$OMP END WORKSHARE
ENDIF
!$OMP END PARALLEL

END SUBROUTINE COMPUTE_VISCOSITY



SUBROUTINE VISCOSITY_BC(NM)

! Specify ghost cell values of the viscosity array MU

INTEGER, INTENT(IN) :: NM
REAL(EB) :: MU_OTHER,DP_OTHER
INTEGER :: IIG,JJG,KKG,II,JJ,KK,IW,IIO,JJO,KKO,NOM,N_INT_CELLS

CALL POINT_TO_MESH(NM)

! Mirror viscosity into solids and exterior boundary cells
 
!$OMP PARALLEL DO PRIVATE(IW,II,JJ,KK,IIG,JJG,KKG,NOM,MU_OTHER,DP_OTHER,KKO,JJO,IIO,N_INT_CELLS)
WALL_LOOP: DO IW=1,NWC
   !!$ IF ((IW == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VISCOSITY_BC'
   IF (IJKW(9,IW)==0) CYCLE WALL_LOOP
   II  = IJKW(1,IW)
   JJ  = IJKW(2,IW)
   KK  = IJKW(3,IW)
   IIG = IJKW(6,IW)
   JJG = IJKW(7,IW)
   KKG = IJKW(8,IW)
   NOM = IJKW(9,IW)
   MU_OTHER = 0._EB
   DP_OTHER = 0._EB
   DO KKO=IJKW(12,IW),IJKW(15,IW)
      DO JJO=IJKW(11,IW),IJKW(14,IW)
         DO IIO=IJKW(10,IW),IJKW(13,IW)
            MU_OTHER = MU_OTHER + OMESH(NOM)%MU(IIO,JJO,KKO)
            IF (PREDICTOR) THEN
               DP_OTHER = DP_OTHER + OMESH(NOM)%D(IIO,JJO,KKO)
            ELSE
               DP_OTHER = DP_OTHER + OMESH(NOM)%DS(IIO,JJO,KKO)
            ENDIF
         ENDDO
      ENDDO
   ENDDO
   N_INT_CELLS = (IJKW(13,IW)-IJKW(10,IW)+1) * (IJKW(14,IW)-IJKW(11,IW)+1) * (IJKW(15,IW)-IJKW(12,IW)+1)
   MU_OTHER = MU_OTHER/REAL(N_INT_CELLS,EB)
   DP_OTHER = DP_OTHER/REAL(N_INT_CELLS,EB)
   MU(II,JJ,KK) = MU_OTHER
   IF (PREDICTOR) THEN
      D(II,JJ,KK) = DP_OTHER
   ELSE
      DS(II,JJ,KK) = DP_OTHER
   ENDIF
ENDDO WALL_LOOP
!$OMP END PARALLEL DO
    
END SUBROUTINE VISCOSITY_BC



SUBROUTINE VELOCITY_FLUX(T,NM)

! Compute convective and diffusive terms of the momentum equations

USE MATH_FUNCTIONS, ONLY: EVALUATE_RAMP
INTEGER, INTENT(IN) :: NM
REAL(EB) :: T,MUX,MUY,MUZ,UP,UM,VP,VM,WP,WM,VTRM,OMXP,OMXM,OMYP,OMYM,OMZP,OMZM,TXYP,TXYM,TXZP,TXZM,TYZP,TYZM, &
            DTXYDY,DTXZDZ,DTYZDZ,DTXYDX,DTXZDX,DTYZDY, &
            DUDX,DVDY,DWDZ,DUDY,DUDZ,DVDX,DVDZ,DWDX,DWDY, &
            VOMZ,WOMY,UOMY,VOMX,UOMZ,WOMX,PMDT,MPDT, &
            AH,RRHO,GX(0:IBAR_MAX),GY(0:IBAR_MAX),GZ(0:IBAR_MAX),TXXP,TXXM,TYYP,TYYM,TZZP,TZZM,DTXXDX,DTYYDY,DTZZDZ, &
            EPSUP,EPSUM,EPSVP,EPSVM,EPSWP,EPSWM,DUMMY=0._EB
INTEGER :: I,J,K,IEXP,IEXM,IEYP,IEYM,IEZP,IEZM,IC
REAL(EB), POINTER, DIMENSION(:,:,:) :: TXY,TXZ,TYZ,OMX,OMY,OMZ,UU,VV,WW,RHOP,DP
 
CALL POINT_TO_MESH(NM)
 
IF (PREDICTOR) THEN
   UU => U
   VV => V
   WW => W
   DP => D  
   RHOP => RHO
ELSE
   UU => US
   VV => VS
   WW => WS
   DP => DS
   RHOP => RHOS
ENDIF

TXY => WORK1
TXZ => WORK2
TYZ => WORK3
OMX => WORK4
OMY => WORK5
OMZ => WORK6

! Compute vorticity and stress tensor components

!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,DUDY,DVDX,DUDZ,DWDX,DVDZ,DWDY,MUX,MUY,MUZ)
DO K=0,KBAR
   DO J=0,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELOCITY_FLUX_01'
         DUDY = RDYN(J)*(UU(I,J+1,K)-UU(I,J,K))
         DVDX = RDXN(I)*(VV(I+1,J,K)-VV(I,J,K))
         DUDZ = RDZN(K)*(UU(I,J,K+1)-UU(I,J,K))
         DWDX = RDXN(I)*(WW(I+1,J,K)-WW(I,J,K))
         DVDZ = RDZN(K)*(VV(I,J,K+1)-VV(I,J,K))
         DWDY = RDYN(J)*(WW(I,J+1,K)-WW(I,J,K))
         OMX(I,J,K) = DWDY - DVDZ
         OMY(I,J,K) = DUDZ - DWDX
         OMZ(I,J,K) = DVDX - DUDY
         MUX = 0.25_EB*(MU(I,J+1,K)+MU(I,J,K)+MU(I,J,K+1)+MU(I,J+1,K+1))
         MUY = 0.25_EB*(MU(I+1,J,K)+MU(I,J,K)+MU(I,J,K+1)+MU(I+1,J,K+1))
         MUZ = 0.25_EB*(MU(I+1,J,K)+MU(I,J,K)+MU(I,J+1,K)+MU(I+1,J+1,K))
         TXY(I,J,K) = MUZ*(DVDX + DUDY)
         TXZ(I,J,K) = MUY*(DUDZ + DWDX)
         TYZ(I,J,K) = MUX*(DVDZ + DWDY)
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

! Compute gravity components

!$OMP SINGLE PRIVATE(I)
IF (.NOT.SPATIAL_GRAVITY_VARIATION) THEN
   GX(0:IBAR) = EVALUATE_RAMP(T,DUMMY,I_RAMP_GX)*GVEC(1)
   GY(0:IBAR) = EVALUATE_RAMP(T,DUMMY,I_RAMP_GY)*GVEC(2)
   GZ(0:IBAR) = EVALUATE_RAMP(T,DUMMY,I_RAMP_GZ)*GVEC(3)
ELSE
   DO I=0,IBAR
      GX(I) = EVALUATE_RAMP(X(I),DUMMY,I_RAMP_GX)*GVEC(1)
      GY(I) = EVALUATE_RAMP(X(I),DUMMY,I_RAMP_GY)*GVEC(2)
      GZ(I) = EVALUATE_RAMP(X(I),DUMMY,I_RAMP_GZ)*GVEC(3)
   ENDDO
ENDIF
 
! Upwind/Downwind bias factors
 
IF (PREDICTOR) THEN
   PMDT =  0.5_EB*DT
   MPDT = -0.5_EB*DT
ELSE
   PMDT = -0.5_EB*DT
   MPDT =  0.5_EB*DT
ENDIF
!$OMP END SINGLE
 
! Compute x-direction flux term FVX

!$OMP DO COLLAPSE(3) &
!$OMP PRIVATE(K,J,I,WP,WM,VP,VM,EPSWP,EPSWM,EPSVP,EPSVM,OMYP,OMYM,OMZP,OMZM,TXZP,TXZM,TXYP,TXYM,IC,IEYP,IEYM,IEZP,IEZM) &
!$OMP PRIVATE(WOMY,VOMZ,RRHO,AH,DVDY,DWDZ,TXXP,TXXM,DTXXDX,DTXYDY,DTXZDZ,VTRM)
DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELOCITY_FLUX_03'
         WP    = WW(I,J,K)   + WW(I+1,J,K)
         WM    = WW(I,J,K-1) + WW(I+1,J,K-1)
         VP    = VV(I,J,K)   + VV(I+1,J,K)
         VM    = VV(I,J-1,K) + VV(I+1,J-1,K)
         EPSWP = 1._EB + WP*MPDT*RDZN(K)
         EPSWM = 1._EB + WM*PMDT*RDZN(K-1)
         EPSVP = 1._EB + VP*MPDT*RDYN(J)
         EPSVM = 1._EB + VM*PMDT*RDYN(J-1)
         OMYP  = OMY(I,J,K)
         OMYM  = OMY(I,J,K-1)
         OMZP  = OMZ(I,J,K)
         OMZM  = OMZ(I,J-1,K)
         TXZP  = TXZ(I,J,K)
         TXZM  = TXZ(I,J,K-1)
         TXYP  = TXY(I,J,K)
         TXYM  = TXY(I,J-1,K)
         IC    = CELL_INDEX(I,J,K)
         IEYP  = EDGE_INDEX(IC,8)
         IEYM  = EDGE_INDEX(IC,6)
         IEZP  = EDGE_INDEX(IC,12)
         IEZM  = EDGE_INDEX(IC,10)
         IF (OME_E(IEYP,-1)>-1.E5_EB) OMYP = OME_E(IEYP,-1)
         IF (OME_E(IEYM, 1)>-1.E5_EB) OMYM = OME_E(IEYM, 1)
         IF (OME_E(IEZP,-2)>-1.E5_EB) OMZP = OME_E(IEZP,-2)
         IF (OME_E(IEZM, 2)>-1.E5_EB) OMZM = OME_E(IEZM, 2)
         IF (TAU_E(IEYP,-1)>-1.E5_EB) TXZP = TAU_E(IEYP,-1)
         IF (TAU_E(IEYM, 1)>-1.E5_EB) TXZM = TAU_E(IEYM, 1)
         IF (TAU_E(IEZP,-2)>-1.E5_EB) TXYP = TAU_E(IEZP,-2)
         IF (TAU_E(IEZM, 2)>-1.E5_EB) TXYM = TAU_E(IEZM, 2)
         WOMY  = EPSWP*WP*OMYP + EPSWM*WM*OMYM
         VOMZ  = EPSVP*VP*OMZP + EPSVM*VM*OMZM
         RRHO  = 2._EB/(RHOP(I,J,K)+RHOP(I+1,J,K))
         AH    = RHO_0(K)*RRHO - 1._EB   
         DVDY  = (VV(I+1,J,K)-VV(I+1,J-1,K))*RDY(J)
         DWDZ  = (WW(I+1,J,K)-WW(I+1,J,K-1))*RDZ(K)
         TXXP  = MU(I+1,J,K)*( FOTH*DP(I+1,J,K) - 2._EB*(DVDY+DWDZ) )
         DVDY  = (VV(I,J,K)-VV(I,J-1,K))*RDY(J)
         DWDZ  = (WW(I,J,K)-WW(I,J,K-1))*RDZ(K)
         TXXM  = MU(I,J,K)  *( FOTH*DP(I,J,K)   - 2._EB*(DVDY+DWDZ) )
         DTXXDX= RDXN(I)*(TXXP-TXXM)
         DTXYDY= RDY(J) *(TXYP-TXYM)
         DTXZDZ= RDZ(K) *(TXZP-TXZM)
         VTRM  = RRHO*(DTXXDX + DTXYDY + DTXZDZ)
         FVX(I,J,K) = 0.25_EB*(WOMY - VOMZ) + GX(I)*AH - VTRM - RRHO*FVEC(1)
      ENDDO 
   ENDDO   
ENDDO
!$OMP END DO NOWAIT
 
! Compute y-direction flux term FVY

!$OMP DO COLLAPSE(3) &
!$OMP PRIVATE(K,J,I,UP,UM,WP,WM,EPSUP,EPSUM,EPSWP,EPSWM,OMXP,OMXM,OMZP,OMZM,TYZP,TYZM,TXYP,TXYM,IC,IEXP,IEXM,IEZP,IEZM) &
!$OMP PRIVATE(WOMX,UOMZ,RRHO,AH,DUDX,DWDZ,TYYP,TYYM,DTXYDX,DTYYDY,DTYZDZ,VTRM)
DO K=1,KBAR
   DO J=0,JBAR
      DO I=1,IBAR
         UP    = UU(I,J,K)   + UU(I,J+1,K)
         UM    = UU(I-1,J,K) + UU(I-1,J+1,K)
         WP    = WW(I,J,K)   + WW(I,J+1,K)
         WM    = WW(I,J,K-1) + WW(I,J+1,K-1)
         EPSUP = 1._EB + UP*MPDT*RDXN(I)
         EPSUM = 1._EB + UM*PMDT*RDXN(I-1)
         EPSWP = 1._EB + WP*MPDT*RDZN(K)
         EPSWM = 1._EB + WM*PMDT*RDZN(K-1)
         OMXP  = OMX(I,J,K)
         OMXM  = OMX(I,J,K-1)
         OMZP  = OMZ(I,J,K)
         OMZM  = OMZ(I-1,J,K)
         TYZP  = TYZ(I,J,K)
         TYZM  = TYZ(I,J,K-1)
         TXYP  = TXY(I,J,K)
         TXYM  = TXY(I-1,J,K)
         IC    = CELL_INDEX(I,J,K)
         IEXP  = EDGE_INDEX(IC,4)
         IEXM  = EDGE_INDEX(IC,2)
         IEZP  = EDGE_INDEX(IC,12)
         IEZM  = EDGE_INDEX(IC,11)
         IF (OME_E(IEXP,-2)>-1.E5_EB) OMXP = OME_E(IEXP,-2)
         IF (OME_E(IEXM, 2)>-1.E5_EB) OMXM = OME_E(IEXM, 2)
         IF (OME_E(IEZP,-1)>-1.E5_EB) OMZP = OME_E(IEZP,-1)
         IF (OME_E(IEZM, 1)>-1.E5_EB) OMZM = OME_E(IEZM, 1)
         IF (TAU_E(IEXP,-2)>-1.E5_EB) TYZP = TAU_E(IEXP,-2)
         IF (TAU_E(IEXM, 2)>-1.E5_EB) TYZM = TAU_E(IEXM, 2)
         IF (TAU_E(IEZP,-1)>-1.E5_EB) TXYP = TAU_E(IEZP,-1)
         IF (TAU_E(IEZM, 1)>-1.E5_EB) TXYM = TAU_E(IEZM, 1)
         WOMX  = EPSWP*WP*OMXP + EPSWM*WM*OMXM
         UOMZ  = EPSUP*UP*OMZP + EPSUM*UM*OMZM
         RRHO  = 2._EB/(RHOP(I,J,K)+RHOP(I,J+1,K))
         AH    = RHO_0(K)*RRHO - 1._EB
         DUDX  = (UU(I,J+1,K)-UU(I-1,J+1,K))*RDX(I)
         DWDZ  = (WW(I,J+1,K)-WW(I,J+1,K-1))*RDZ(K)
         TYYP  = MU(I,J+1,K)*( FOTH*DP(I,J+1,K) - 2._EB*(DUDX+DWDZ) )
         DUDX  = (UU(I,J,K)-UU(I-1,J,K))*RDX(I)
         DWDZ  = (WW(I,J,K)-WW(I,J,K-1))*RDZ(K)
         TYYM  = MU(I,J,K)  *( FOTH*DP(I,J,K)   - 2._EB*(DUDX+DWDZ) )
         DTXYDX= RDX(I) *(TXYP-TXYM)
         DTYYDY= RDYN(J)*(TYYP-TYYM)
         DTYZDZ= RDZ(K) *(TYZP-TYZM)
         VTRM  = RRHO*(DTXYDX + DTYYDY + DTYZDZ)
         FVY(I,J,K) = 0.25_EB*(UOMZ - WOMX) + GY(I)*AH - VTRM - RRHO*FVEC(2)
      ENDDO
   ENDDO   
ENDDO
!$OMP END DO NOWAIT
 
! Compute z-direction flux term FVZ

!$OMP DO COLLAPSE(3) &
!$OMP PRIVATE(K,J,I,UP,UM,VP,VM,EPSUP,EPSUM,EPSVP,EPSVM,OMYP,OMYM,OMXP,OMXM,TXZP,TXZM,TYZP,TYZM,IC,IEXP,IEXM,IEYP,IEYM) &
!$OMP PRIVATE(UOMY,VOMX,RRHO,AH,DUDX,DVDY,TZZP,TZZM,DTXZDX,DTYZDY,DTZZDZ,VTRM) 
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         UP    = UU(I,J,K)   + UU(I,J,K+1)
         UM    = UU(I-1,J,K) + UU(I-1,J,K+1)
         VP    = VV(I,J,K)   + VV(I,J,K+1)
         VM    = VV(I,J-1,K) + VV(I,J-1,K+1)
         EPSUP = 1._EB + UP*MPDT*RDXN(I)
         EPSUM = 1._EB + UM*PMDT*RDXN(I-1)
         EPSVP = 1._EB + VP*MPDT*RDYN(J)
         EPSVM = 1._EB + VM*PMDT*RDYN(J-1)
         OMYP  = OMY(I,J,K)
         OMYM  = OMY(I-1,J,K)
         OMXP  = OMX(I,J,K)
         OMXM  = OMX(I,J-1,K)
         TXZP  = TXZ(I,J,K)
         TXZM  = TXZ(I-1,J,K)
         TYZP  = TYZ(I,J,K)
         TYZM  = TYZ(I,J-1,K)
         IC    = CELL_INDEX(I,J,K)
         IEXP  = EDGE_INDEX(IC,4)
         IEXM  = EDGE_INDEX(IC,3)
         IEYP  = EDGE_INDEX(IC,8)
         IEYM  = EDGE_INDEX(IC,7)
         IF (OME_E(IEXP,-1)>-1.E5_EB) OMXP = OME_E(IEXP,-1)
         IF (OME_E(IEXM, 1)>-1.E5_EB) OMXM = OME_E(IEXM, 1)
         IF (OME_E(IEYP,-2)>-1.E5_EB) OMYP = OME_E(IEYP,-2)
         IF (OME_E(IEYM, 2)>-1.E5_EB) OMYM = OME_E(IEYM, 2)
         IF (TAU_E(IEXP,-1)>-1.E5_EB) TYZP = TAU_E(IEXP,-1)
         IF (TAU_E(IEXM, 1)>-1.E5_EB) TYZM = TAU_E(IEXM, 1)
         IF (TAU_E(IEYP,-2)>-1.E5_EB) TXZP = TAU_E(IEYP,-2)
         IF (TAU_E(IEYM, 2)>-1.E5_EB) TXZM = TAU_E(IEYM, 2)
         UOMY  = EPSUP*UP*OMYP + EPSUM*UM*OMYM
         VOMX  = EPSVP*VP*OMXP + EPSVM*VM*OMXM
         RRHO  = 2._EB/(RHOP(I,J,K)+RHOP(I,J,K+1))
         AH    = 0.5_EB*(RHO_0(K)+RHO_0(K+1))*RRHO - 1._EB
         DUDX  = (UU(I,J,K+1)-UU(I-1,J,K+1))*RDX(I)
         DVDY  = (VV(I,J,K+1)-VV(I,J-1,K+1))*RDY(J)
         TZZP  = MU(I,J,K+1)*( FOTH*DP(I,J,K+1) - 2._EB*(DUDX+DVDY) )
         DUDX  = (UU(I,J,K)-UU(I-1,J,K))*RDX(I)
         DVDY  = (VV(I,J,K)-VV(I,J-1,K))*RDY(J)
         TZZM  = MU(I,J,K)  *( FOTH*DP(I,J,K)   - 2._EB*(DUDX+DVDY) )
         DTXZDX= RDX(I) *(TXZP-TXZM)
         DTYZDY= RDY(J) *(TYZP-TYZM)
         DTZZDZ= RDZN(K)*(TZZP-TZZM)
         VTRM  = RRHO*(DTXZDX + DTYZDY + DTZZDZ)
         FVZ(I,J,K) = 0.25_EB*(VOMX - UOMY) + GZ(I)*AH - VTRM - RRHO*FVEC(3)       
      ENDDO
   ENDDO   
ENDDO
!$OMP END DO NOWAIT
!$OMP END PARALLEL
 
! Baroclinic torque correction
 
IF (BAROCLINIC .AND. .NOT.EVACUATION_ONLY(NM)) CALL BAROCLINIC_CORRECTION

! Adjust FVX, FVY and FVZ at solid, internal obstructions for no flux
 
CALL NO_FLUX
IF (EVACUATION_ONLY(NM)) FVZ = 0._EB

END SUBROUTINE VELOCITY_FLUX



SUBROUTINE VELOCITY_FLUX_ISOTHERMAL(NM)
 
! Compute the velocity flux at cell edges (ISOTHERMAL DNS ONLY)
 
REAL(EB) :: UP,UM,VP,VM,WP,WM,VTRM,VOMZ,WOMY,UOMY,VOMX,UOMZ,WOMX, &
            DVDZ,DVDX,DWDY,DWDX,DUDZ,DUDY,PMDT,MPDT, &
            EPSUP,EPSUM,EPSVP,EPSVM,EPSWP,EPSWM
INTEGER :: I,J,K
REAL(EB), POINTER, DIMENSION(:,:,:) :: OMX,OMY,OMZ,UU,VV,WW
INTEGER, INTENT(IN) :: NM
 
CALL POINT_TO_MESH(NM)
 
IF (PREDICTOR) THEN
   UU => U
   VV => V
   WW => W
ELSE
   UU => US
   VV => VS
   WW => WS
ENDIF
 
OMX => WORK4
OMY => WORK5
OMZ => WORK6


! Compute vorticity and stress tensor components
!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,DUDY,DVDX,DUDZ,DWDX,DVDZ,DWDY)  
DO K=0,KBAR
   DO J=0,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_FLUX_ISOTHERMAL_01'
         DUDY = RDYN(J)*(UU(I,J+1,K)-UU(I,J,K))
         DVDX = RDXN(I)*(VV(I+1,J,K)-VV(I,J,K))
         DUDZ = RDZN(K)*(UU(I,J,K+1)-UU(I,J,K))
         DWDX = RDXN(I)*(WW(I+1,J,K)-WW(I,J,K))
         DVDZ = RDZN(K)*(VV(I,J,K+1)-VV(I,J,K))
         DWDY = RDYN(J)*(WW(I,J+1,K)-WW(I,J,K))
         OMX(I,J,K) = DWDY - DVDZ
         OMY(I,J,K) = DUDZ - DWDX
         OMZ(I,J,K) = DVDX - DUDY
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
 
! Upwind/Downwind bias factors

!$OMP SINGLE
IF (PREDICTOR) THEN
   PMDT =  0.5_EB*DT
   MPDT = -0.5_EB*DT
ELSE
   PMDT = -0.5_EB*DT
   MPDT =  0.5_EB*DT
ENDIF
!$OMP END SINGLE
 
! Compute x-direction flux term FVX

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,WP,WM,VP,VM,EPSWP,EPSWM,EPSVP,EPSVM,WOMY,VOMZ,VTRM)
DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_FLUX_ISOTHERMAL_03'
         WP    = WW(I,J,K)   + WW(I+1,J,K)
         WM    = WW(I,J,K-1) + WW(I+1,J,K-1)
         VP    = VV(I,J,K)   + VV(I+1,J,K)
         VM    = VV(I,J-1,K) + VV(I+1,J-1,K)
         EPSWP = 1._EB + WP*MPDT*RDZN(K)
         EPSWM = 1._EB + WM*PMDT*RDZN(K-1)
         EPSVP = 1._EB + VP*MPDT*RDYN(J)
         EPSVM = 1._EB + VM*PMDT*RDYN(J-1)
         WOMY  = EPSWP*WP*OMY(I,J,K) + EPSWM*WM*OMY(I,J,K-1)
         VOMZ  = EPSVP*VP*OMZ(I,J,K) + EPSVM*VM*OMZ(I,J-1,K)
         VTRM  = RREDZ(K)*(OMY(I,J,K)-OMY(I,J,K-1)) - RREDY(J)*(OMZ(I,J,K)-OMZ(I,J-1,K))
         FVX(I,J,K) = 0.25_EB*(WOMY - VOMZ) - VTRM
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

! Compute y-direction flux term FVY

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,UP,UM,WP,WM,EPSUP,EPSUM,EPSWP,EPSWM,WOMX,UOMZ,VTRM) 
DO K=1,KBAR
   DO J=0,JBAR
      DO I=1,IBAR
         UP    = UU(I,J,K)   + UU(I,J+1,K)
         UM    = UU(I-1,J,K) + UU(I-1,J+1,K)
         WP    = WW(I,J,K)   + WW(I,J+1,K)
         WM    = WW(I,J,K-1) + WW(I,J+1,K-1)
         EPSUP = 1._EB + UP*MPDT*RDXN(I)
         EPSUM = 1._EB + UM*PMDT*RDXN(I-1)
         EPSWP = 1._EB + WP*MPDT*RDZN(K)
         EPSWM = 1._EB + WM*PMDT*RDZN(K-1)
         WOMX  = EPSWP*WP*OMX(I,J,K) + EPSWM*WM*OMX(I,J,K-1)
         UOMZ  = EPSUP*UP*OMZ(I,J,K) + EPSUM*UM*OMZ(I-1,J,K)
         VTRM  = RREDX(I)*(OMZ(I,J,K)-OMZ(I-1,J,K)) - RREDZ(K)*(OMX(I,J,K)-OMX(I,J,K-1))
         FVY(I,J,K) = 0.25_EB*(UOMZ - WOMX) - VTRM
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
! Compute z-direction flux term FVZ

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,UP,UM,VP,VM,EPSUP,EPSUM,EPSVP,EPSVM,UOMY,VOMX,VTRM) 
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         UP    = UU(I,J,K)   + UU(I,J,K+1)
         UM    = UU(I-1,J,K) + UU(I-1,J,K+1)
         VP    = VV(I,J,K)   + VV(I,J,K+1)
         VM    = VV(I,J-1,K) + VV(I,J-1,K+1)
         EPSUP = 1._EB + UP*MPDT*RDXN(I)
         EPSUM = 1._EB + UM*PMDT*RDXN(I-1)
         EPSVP = 1._EB + VP*MPDT*RDYN(J)
         EPSVM = 1._EB + VM*PMDT*RDYN(J-1)
         UOMY  = EPSUP*UP*OMY(I,J,K) + EPSUM*UM*OMY(I-1,J,K)
         VOMX  = EPSVP*VP*OMX(I,J,K) + EPSVM*VM*OMX(I,J-1,K)
         VTRM  = RREDY(J)*(OMX(I,J,K)-OMX(I,J-1,K)) - RREDX(I)*(OMY(I,J,K)-OMY(I-1,J,K))
         FVZ(I,J,K) = 0.25_EB*(VOMX - UOMY) - VTRM
      ENDDO
   ENDDO
ENDDO
!$OMP END DO
!$OMP END PARALLEL
 
! Adjust FVX, FVY and FVZ at solid, internal obstructions for no flux
 
CALL NO_FLUX
 
END SUBROUTINE VELOCITY_FLUX_ISOTHERMAL
 
 
SUBROUTINE VELOCITY_FLUX_CYLINDRICAL(T,NM)

! Compute convective and diffusive terms for 2D axisymmetric

USE MATH_FUNCTIONS, ONLY: EVALUATE_RAMP 
REAL(EB) :: T,DMUDX
INTEGER :: I0
INTEGER, INTENT(IN) :: NM
REAL(EB) :: MUY,UP,UM,WP,WM,VTRM,DTXZDZ,DTXZDX,DUDX,DWDZ,DUDZ,DWDX,WOMY,UOMY,PMDT,MPDT,OMYP,OMYM,TXZP,TXZM, &
            AH,RRHO,GX,GZ,TXXP,TXXM,TZZP,TZZM,DTXXDX,DTZZDZ,EPSUP,EPSUM,EPSWP,EPSWM,DUMMY=0._EB
INTEGER :: I,J,K,IEYP,IEYM,IC
REAL(EB), POINTER, DIMENSION(:,:,:) :: TXZ,OMY,UU,WW,RHOP,DP
 
CALL POINT_TO_MESH(NM)
 
IF (PREDICTOR) THEN
   UU => U
   WW => W
   DP => D  
   RHOP => RHO
ELSE
   UU => US
   WW => WS
   DP => DS
   RHOP => RHOS
ENDIF
 
TXZ => WORK2
OMY => WORK5
 
! Compute vorticity and stress tensor components

!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,DUDZ,DWDX,MUY)  
DO K=0,KBAR
   DO J=0,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_FLUX_CYLINDRICAL_01'
         DUDZ = RDZN(K)*(UU(I,J,K+1)-UU(I,J,K))
         DWDX = RDXN(I)*(WW(I+1,J,K)-WW(I,J,K))
         OMY(I,J,K) = DUDZ - DWDX
         MUY = 0.25_EB*(MU(I+1,J,K)+MU(I,J,K)+MU(I,J,K+1)+MU(I+1,J,K+1))
         TXZ(I,J,K) = MUY*(DUDZ + DWDX)
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
 
! Compute gravity components

!$OMP SINGLE
GX  = 0._EB
GZ  = EVALUATE_RAMP(T,DUMMY,I_RAMP_GZ)*GVEC(3)
 
! Upwind/Downwind bias factors
 
IF (PREDICTOR) THEN
   PMDT =  0.5_EB*DT
   MPDT = -0.5_EB*DT
ELSE
   PMDT = -0.5_EB*DT
   MPDT =  0.5_EB*DT
ENDIF
 
! Compute r-direction flux term FVX
 
IF (XS==0) THEN 
   I0 = 1
ELSE
   I0 = 0
ENDIF
 
J = 1
!$OMP END SINGLE


!$OMP DO COLLAPSE(2) &
!$OMP PRIVATE(K,I,WP,WM,EPSWP,EPSWM,OMYP,OMYM,TXZP,TXZM,IC,IEYP,IEYM,WOMY,RRHO,AH,DWDZ,TXXP,TXXM,DTXXDX,DTXZDZ,DMUDX,VTRM) 
DO K= 1,KBAR
   DO I=I0,IBAR
      !!$ IF ((K == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_FLUX_CYLINDRICAL_03' 
      WP    = WW(I,J,K)   + WW(I+1,J,K)
      WM    = WW(I,J,K-1) + WW(I+1,J,K-1)
      EPSWP = 1._EB + WP*MPDT*RDZN(K)
      EPSWM = 1._EB + WM*PMDT*RDZN(K-1)
      OMYP  = OMY(I,J,K)
      OMYM  = OMY(I,J,K-1)
      TXZP  = TXZ(I,J,K)
      TXZM  = TXZ(I,J,K-1)
      IC    = CELL_INDEX(I,J,K)
      IEYP  = EDGE_INDEX(IC,8)
      IEYM  = EDGE_INDEX(IC,6)
      IF (OME_E(IEYP,-1)>-1.E5_EB) OMYP = OME_E(IEYP,-1)
      IF (OME_E(IEYM, 1)>-1.E5_EB) OMYM = OME_E(IEYM, 1)
      IF (TAU_E(IEYP,-1)>-1.E5_EB) TXZP = TAU_E(IEYP,-1)
      IF (TAU_E(IEYM, 1)>-1.E5_EB) TXZM = TAU_E(IEYM, 1)
      WOMY  = EPSWP*WP*OMYP + EPSWM*WM*OMYM
      RRHO  = 2._EB/(RHOP(I,J,K)+RHOP(I+1,J,K))
      AH    = RHO_0(K)*RRHO - 1._EB   
      DWDZ  = (WW(I+1,J,K)-WW(I+1,J,K-1))*RDZ(K)
      TXXP  = MU(I+1,J,K)*( FOTH*DP(I+1,J,K) - 2._EB*DWDZ )
      DWDZ  = (WW(I,J,K)-WW(I,J,K-1))*RDZ(K)
      TXXM  = MU(I,J,K)  *( FOTH*DP(I,J,K) -2._EB*DWDZ )
      DTXXDX= RDXN(I)*(TXXP-TXXM)
      DTXZDZ= RDZ(K) *(TXZP-TXZM)
      DMUDX = (MU(I+1,J,K)-MU(I,J,K))*RDXN(I)
      VTRM  = RRHO*( DTXXDX + DTXZDZ - 2._EB*UU(I,J,K)*DMUDX/R(I) ) 
      FVX(I,J,K) = 0.25_EB*WOMY + GX*AH - VTRM 
   ENDDO
ENDDO
!$OMP END DO NOWAIT
! Compute z-direction flux term FVZ
 
!J = 1 !not needed, J = 1 is declared before FVX-calculation

!$OMP DO COLLAPSE(2) &
!$OMP PRIVATE(K,I,UP,UM,EPSUP,EPSUM,OMYP,OMYM,TXZP,TXZM,IC,IEYP,IEYM,UOMY,RRHO,AH,DUDX,TZZP,TZZM,DTXZDX,DTZZDZ,VTRM)
DO K=0,KBAR
   DO I=1,IBAR
      UP    = UU(I,J,K)   + UU(I,J,K+1)
      UM    = UU(I-1,J,K) + UU(I-1,J,K+1)
      EPSUP = 1._EB + UP*MPDT*RDXN(I)
      EPSUM = 1._EB + UM*PMDT*RDXN(I-1)
      OMYP  = OMY(I,J,K)
      OMYM  = OMY(I-1,J,K)
      TXZP  = TXZ(I,J,K)
      TXZM  = TXZ(I-1,J,K)
      IC    = CELL_INDEX(I,J,K)
      IEYP  = EDGE_INDEX(IC,8)
      IEYM  = EDGE_INDEX(IC,7)
      IF (OME_E(IEYP,-2)>-1.E5_EB) OMYP = OME_E(IEYP,-2)
      IF (OME_E(IEYM, 2)>-1.E5_EB) OMYM = OME_E(IEYM, 2)
      IF (TAU_E(IEYP,-2)>-1.E5_EB) TXZP = TAU_E(IEYP,-2)
      IF (TAU_E(IEYM, 2)>-1.E5_EB) TXZM = TAU_E(IEYM, 2)
      UOMY  = EPSUP*UP*OMYP + EPSUM*UM*OMYM
      RRHO  = 2._EB/(RHOP(I,J,K)+RHOP(I,J,K+1))
      AH    = 0.5_EB*(RHO_0(K)+RHO_0(K+1))*RRHO - 1._EB
      DUDX  = (R(I)*UU(I,J,K+1)-R(I-1)*UU(I-1,J,K+1))*RDX(I)*RRN(I)
      TZZP  = MU(I,J,K+1)*( FOTH*DP(I,J,K+1) - 2._EB*DUDX )
      DUDX  = (R(I)*UU(I,J,K)-R(I-1)*UU(I-1,J,K))*RDX(I)*RRN(I)
      TZZM  = MU(I,J,K)  *( FOTH*DP(I,J,K)   - 2._EB*DUDX )
      DTXZDX= RDX(I) *(R(I)*TXZP-R(I-1)*TXZM)*RRN(I)
      DTZZDZ= RDZN(K)*(     TZZP       -TZZM)
      VTRM  = RRHO*(DTXZDX + DTZZDZ)
      FVZ(I,J,K) = -0.25_EB*UOMY + GZ*AH - VTRM 
   ENDDO
ENDDO
!$OMP END DO
!$OMP END PARALLEL   
 
! Baroclinic torque correction terms
 
IF (BAROCLINIC) CALL BAROCLINIC_CORRECTION
 
! Adjust FVX and FVZ at solid, internal obstructions for no flux
 
CALL NO_FLUX
 
END SUBROUTINE VELOCITY_FLUX_CYLINDRICAL
 
 
SUBROUTINE NO_FLUX

! Set FVX,FVY,FVZ inside internal blockages to maintain no flux

USE MATH_FUNCTIONS, ONLY: EVALUATE_RAMP 
REAL(EB) :: RFODT,H_OTHER
INTEGER  :: IC2,IC1,N,I,J,K,IW,II,JJ,KK,IOR,N_INT_CELLS,IIO,JJO,KKO,NOM
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW
TYPE (OBSTRUCTION_TYPE), POINTER :: OB
 
IF (PREDICTOR) THEN
   UU => U
   VV => V
   WW => W
ELSE
   UU => US
   VV => VS
   WW => WS
ENDIF
 
RFODT = RELAXATION_FACTOR/DT
 
! Exchange H at interpolated boundaries

!$OMP PARALLEL
!$OMP DO PRIVATE(IW,NOM,II,JJ,KK,H_OTHER,KKO,JJO,IIO,N_INT_CELLS)
DO IW=1,NEWC
   !!$ IF ((IW == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_NO_FLUX_01'
   NOM = IJKW(9,IW)
   IF (NOM==0) CYCLE
   II = IJKW(1,IW)
   JJ = IJKW(2,IW)
   KK = IJKW(3,IW)   
   H_OTHER = 0._EB
   DO KKO=IJKW(12,IW),IJKW(15,IW)
      DO JJO=IJKW(11,IW),IJKW(14,IW)
         DO IIO=IJKW(10,IW),IJKW(13,IW)
            H_OTHER = H_OTHER + OMESH(NOM)%H(IIO,JJO,KKO)
         ENDDO
      ENDDO
   ENDDO
   N_INT_CELLS = (IJKW(13,IW)-IJKW(10,IW)+1) * (IJKW(14,IW)-IJKW(11,IW)+1) * (IJKW(15,IW)-IJKW(12,IW)+1)
   H(II,JJ,KK) = H_OTHER/REAL(N_INT_CELLS,EB)
ENDDO
!$OMP END DO

! Drive velocity components inside solid obstructions towards zero


!$OMP DO PRIVATE(N,OB,K,J,I,IC1,IC2) 
OBST_LOOP: DO N=1,N_OBST
   !!$ IF ((N == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_NO_FLUX_02'
   OB=>OBSTRUCTION(N)
   DO K=OB%K1+1,OB%K2
      DO J=OB%J1+1,OB%J2
         LOOP1: DO I=OB%I1  ,OB%I2
            IC1 = CELL_INDEX(I,J,K)
            IC2 = CELL_INDEX(I+1,J,K)
            IF (SOLID(IC1) .AND. SOLID(IC2)) FVX(I,J,K) = -RDXN(I)*(H(I+1,J,K)-H(I,J,K)) + RFODT*UU(I,J,K)
         ENDDO LOOP1
      ENDDO 
   ENDDO 
   DO K=OB%K1+1,OB%K2
      DO J=OB%J1  ,OB%J2
         LOOP2: DO I=OB%I1+1,OB%I2
            IC1 = CELL_INDEX(I,J,K)
            IC2 = CELL_INDEX(I,J+1,K)
            IF (SOLID(IC1) .AND. SOLID(IC2)) FVY(I,J,K) = -RDYN(J)*(H(I,J+1,K)-H(I,J,K)) + RFODT*VV(I,J,K)
         ENDDO LOOP2
      ENDDO 
   ENDDO 
   DO K=OB%K1  ,OB%K2
      DO J=OB%J1+1,OB%J2
         LOOP3: DO I=OB%I1+1,OB%I2
            IC1 = CELL_INDEX(I,J,K)
            IC2 = CELL_INDEX(I,J,K+1)
            IF (SOLID(IC1) .AND. SOLID(IC2)) FVZ(I,J,K) = -RDZN(K)*(H(I,J,K+1)-H(I,J,K)) + RFODT*WW(I,J,K)
         ENDDO LOOP3
      ENDDO 
   ENDDO 
ENDDO OBST_LOOP
!$OMP END DO
 
! Add normal velocity to FVX, etc. for surface cells

!$OMP DO PRIVATE(IW,NOM,II,JJ,KK,IOR) 
WALL_LOOP: DO IW=1,NWC
!!$ IF ((IW == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_NO_FLUX_03' 
   IF (BOUNDARY_TYPE(IW)==OPEN_BOUNDARY)         CYCLE WALL_LOOP
   IF (BOUNDARY_TYPE(IW)==INTERPOLATED_BOUNDARY) CYCLE WALL_LOOP
   NOM = IJKW(9,IW)
   IF (BOUNDARY_TYPE(IW)==NULL_BOUNDARY .AND. NOM==0) CYCLE WALL_LOOP

   II  = IJKW(1,IW)
   JJ  = IJKW(2,IW)
   KK  = IJKW(3,IW)
   IOR = IJKW(4,IW)
    
   IF (NOM/=0 .OR. BOUNDARY_TYPE(IW)==SOLID_BOUNDARY .OR. BOUNDARY_TYPE(IW)==POROUS_BOUNDARY) THEN
      SELECT CASE(IOR)
         CASE( 1) 
            FVX(II,JJ,KK)   = -RDXN(II)  *(H(II+1,JJ,KK)-H(II,JJ,KK)) + RFODT*(UU(II,JJ,KK)   + UWS(IW))
         CASE(-1) 
            FVX(II-1,JJ,KK) = -RDXN(II-1)*(H(II,JJ,KK)-H(II-1,JJ,KK)) + RFODT*(UU(II-1,JJ,KK) - UWS(IW))
         CASE( 2) 
            FVY(II,JJ,KK)   = -RDYN(JJ)  *(H(II,JJ+1,KK)-H(II,JJ,KK)) + RFODT*(VV(II,JJ,KK)   + UWS(IW))
         CASE(-2)
            FVY(II,JJ-1,KK) = -RDYN(JJ-1)*(H(II,JJ,KK)-H(II,JJ-1,KK)) + RFODT*(VV(II,JJ-1,KK) - UWS(IW))
         CASE( 3) 
            FVZ(II,JJ,KK)   = -RDZN(KK)  *(H(II,JJ,KK+1)-H(II,JJ,KK)) + RFODT*(WW(II,JJ,KK)   + UWS(IW))
         CASE(-3) 
            FVZ(II,JJ,KK-1) = -RDZN(KK-1)*(H(II,JJ,KK)-H(II,JJ,KK-1)) + RFODT*(WW(II,JJ,KK-1) - UWS(IW))
      END SELECT
   ENDIF

   IF (BOUNDARY_TYPE(IW)==MIRROR_BOUNDARY) THEN
      SELECT CASE(IOR)
         CASE( 1)
            FVX(II  ,JJ,KK) = 0._EB
         CASE(-1)
            FVX(II-1,JJ,KK) = 0._EB
         CASE( 2)
            FVY(II  ,JJ,KK) = 0._EB
         CASE(-2)
            FVY(II,JJ-1,KK) = 0._EB
         CASE( 3)
            FVZ(II  ,JJ,KK) = 0._EB
         CASE(-3)
            FVZ(II,JJ,KK-1) = 0._EB
      END SELECT
   ENDIF
 
ENDDO WALL_LOOP
!$OMP END DO
!$OMP END PARALLEL
 
END SUBROUTINE NO_FLUX
 
 

SUBROUTINE VELOCITY_PREDICTOR(NM,STOP_STATUS)

! Estimates the velocity components at the next time step

REAL(EB) :: TNOW
INTEGER  :: STOP_STATUS,I,J,K
INTEGER, INTENT(IN) :: NM
REAL(EB), POINTER, DIMENSION(:,:,:) :: HT

IF (SOLID_PHASE_ONLY) RETURN
IF (FREEZE_VELOCITY) THEN
   CALL CHECK_STABILITY(NM,2)
   RETURN
ENDIF

TNOW=SECOND() 
CALL POINT_TO_MESH(NM)

IF (PRESSURE_CORRECTION) THEN
   HT => WORK1
   HT = H + HP
ELSE
   HT => H
ENDIF

!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELOCITY_PREDICTOR'
         US(I,J,K) = U(I,J,K) - DT*( FVX(I,J,K) + RDXN(I)*(HT(I+1,J,K)-HT(I,J,K)) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=1,KBAR
   DO J=0,JBAR
      DO I=1,IBAR
         VS(I,J,K) = V(I,J,K) - DT*( FVY(I,J,K) + RDYN(J)*(HT(I,J+1,K)-HT(I,J,K)) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         WS(I,J,K) = W(I,J,K) - DT*( FVZ(I,J,K) + RDZN(K)*(HT(I,J,K+1)-HT(I,J,K)) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
!$OMP END PARALLEL
IF (EVACUATION_ONLY(NM)) WS = 0._EB

! Check the stability criteria, and if the time step is too small, send back a signal to kill the job
 
DT_PREV = DT
CALL CHECK_STABILITY(NM,2)
 
IF (DT<DT_INIT*1.E-4) STOP_STATUS = INSTABILITY_STOP
 
TUSED(4,NM)=TUSED(4,NM)+SECOND()-TNOW
END SUBROUTINE VELOCITY_PREDICTOR
 
 

SUBROUTINE VELOCITY_CORRECTOR(NM)

USE TURBULENCE, ONLY: TURBULENT_KINETIC_ENERGY

! Correct the velocity components

REAL(EB) :: TNOW
INTEGER  :: I,J,K
INTEGER, INTENT(IN) :: NM
REAL(EB), POINTER, DIMENSION(:,:,:) :: HT
 
IF (SOLID_PHASE_ONLY) RETURN
IF (FREEZE_VELOCITY) RETURN

TNOW=SECOND() 
CALL POINT_TO_MESH(NM)

IF (PRESSURE_CORRECTION) THEN
   HT => WORK1
   HT = H + HP
ELSE
   HT => H
ENDIF

!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELOCITY_CORRECTOR'
         U(I,J,K) = .5_EB*( U(I,J,K) + US(I,J,K) - DT*(FVX(I,J,K) + RDXN(I)*(HT(I+1,J,K)-HT(I,J,K))) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=1,KBAR
   DO J=0,JBAR
      DO I=1,IBAR
         V(I,J,K) = .5_EB*( V(I,J,K) + VS(I,J,K) - DT*(FVY(I,J,K) + RDYN(J)*(HT(I,J+1,K)-HT(I,J,K))) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         W(I,J,K) = .5_EB*( W(I,J,K) + WS(I,J,K) - DT*(FVZ(I,J,K) + RDZN(K)*(HT(I,J,K+1)-HT(I,J,K))) )
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
!$OMP END PARALLEL
IF (EVACUATION_ONLY(NM)) W = 0._EB

IF (CHECK_KINETIC_ENERGY .AND. .NOT.EVACUATION_ONLY(NM)) CALL TURBULENT_KINETIC_ENERGY

TUSED(4,NM)=TUSED(4,NM)+SECOND()-TNOW
END SUBROUTINE VELOCITY_CORRECTOR
 

 
SUBROUTINE VELOCITY_BC(T,NM)

! Assert tangential velocity boundary conditions

USE MATH_FUNCTIONS, ONLY: EVALUATE_RAMP
USE TURBULENCE, ONLY: WERNER_WENGLE_WALL_MODEL
REAL(EB), INTENT(IN) :: T
REAL(EB) :: MUA,TSI,WGT,TNOW,RAMP_T,OMW,MU_WALL,RHO_WALL,SLIP_COEF,VEL_T, &
            UUP(2),UUM(2),DXX(2),MU_DUIDXJ(-2:2),DUIDXJ(-2:2),MU_DUIDXJ_0(2),DUIDXJ_0(2),PROFILE_FACTOR,VEL_GAS,VEL_GHOST, &
            MU_DUIDXJ_USE(2),DUIDXJ_USE(2)
INTEGER  :: I,J,K,NOM(2),IIO(2),JJO(2),KKO(2),IE,II,JJ,KK,IEC,IOR,IWM,IWP,ICMM,ICMP,ICPM,ICPP,IC,ICD,ICDO,IVL,I_SGN,IS, &
            VELOCITY_BC_INDEX,IIGM,JJGM,KKGM,IIGP,JJGP,KKGP,IBCM,IBCP,ITMP,ICD_SGN,ICDO_SGN
LOGICAL :: ALTERED_GRADIENT(-2:2),PROCESS_EDGE
INTEGER, INTENT(IN) :: NM
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW,U_Y,U_Z,V_X,V_Z,W_X,W_Y,RHOP,VEL_OTHER
TYPE (SURFACE_TYPE), POINTER :: SF
TYPE (OMESH_TYPE), POINTER :: OM

IF (SOLID_PHASE_ONLY) RETURN

TNOW = SECOND()

! Assign local names to variables

CALL POINT_TO_MESH(NM)

! Point to the appropriate velocity field

IF (PREDICTOR) THEN
   UU => US
   VV => VS
   WW => WS
   RHOP => RHOS
ELSE
   UU => U
   VV => V
   WW => W
   RHOP => RHO
ENDIF


! Set the boundary velocity place holder to some large negative number

IF (CORRECTOR) THEN
   
   U_Y => WORK1
   U_Z => WORK2
   V_X => WORK3
   V_Z => WORK4
   W_X => WORK5
   W_Y => WORK6
   !$OMP PARALLEL WORKSHARE
   U_Y = -1.E6_EB
   U_Z = -1.E6_EB
   V_X = -1.E6_EB
   V_Z = -1.E6_EB
   W_X = -1.E6_EB
   W_Y = -1.E6_EB
   UVW_GHOST = -1.E6_EB
   !$OMP END PARALLEL WORKSHARE
ENDIF

!$OMP PARALLEL

! Set OME_E and TAU_E to very negative number

!$OMP WORKSHARE
TAU_E = -1.E6_EB
OME_E = -1.E6_EB
!$OMP END WORKSHARE

! Loop over all cell edges and determine the appropriate velocity BCs

!$OMP DO PRIVATE(IE,II,JJ,KK,IEC,ICMM,ICPM,ICMP,ICPP,NOM,IIO,JJO,KKO,UUP,UUM,DXX,MUA,I_SGN,IS,IOR,ICD,IVL,ICD_SGN,IBCM,IBCP,ITMP) &
!$OMP PRIVATE(VEL_GAS,VEL_GHOST,IWP,IWM,SF,VELOCITY_BC_INDEX,TSI,PROFILE_FACTOR,RAMP_T,VEL_T,IIGM,JJGM,KKGM,IIGP,JJGP,KKGP) &
!$OMP PRIVATE(RHO_WALL,MU_WALL,OM,VEL_OTHER,WGT,OMW,ICDO,MU_DUIDXJ,DUIDXJ,DUIDXJ_0,MU_DUIDXJ_0,MU_DUIDXJ_USE,DUIDXJ_USE) &
!$OMP PRIVATE(PROCESS_EDGE,ALTERED_GRADIENT,SLIP_COEF,ICDO_SGN)
EDGE_LOOP: DO IE=1,N_EDGES

   IF (EDGE_TYPE(IE,1)==NULL_EDGE .AND. EDGE_TYPE(IE,2)==NULL_EDGE) CYCLE EDGE_LOOP

   ! Throw out edges that are completely surrounded by blockages or the exterior of the domain

   PROCESS_EDGE = .FALSE.
   DO IS=5,8
      IF (.NOT.EXTERIOR(IJKE(IS,IE)) .AND. .NOT.SOLID(IJKE(IS,IE))) THEN
         PROCESS_EDGE = .TRUE.
         EXIT
      ENDIF
   ENDDO
   IF (.NOT.PROCESS_EDGE) CYCLE EDGE_LOOP

   ! If the edge is to be "smoothed," set tau and omega to zero and cycle

   IF (EDGE_TYPE(IE,1)==SMOOTH_EDGE) THEN
      OME_E(IE,:) = 0._EB
      TAU_E(IE,:) = 0._EB
      CYCLE EDGE_LOOP
   ENDIF

   ! Unpack indices for the edge

   II     = IJKE( 1,IE)
   JJ     = IJKE( 2,IE)
   KK     = IJKE( 3,IE)
   IEC    = IJKE( 4,IE)
   ICMM   = IJKE( 5,IE)
   ICPM   = IJKE( 6,IE)
   ICMP   = IJKE( 7,IE)
   ICPP   = IJKE( 8,IE)
   NOM(1) = IJKE( 9,IE)
   IIO(1) = IJKE(10,IE)
   JJO(1) = IJKE(11,IE)
   KKO(1) = IJKE(12,IE)
   NOM(2) = IJKE(13,IE)
   IIO(2) = IJKE(14,IE)
   JJO(2) = IJKE(15,IE)
   KKO(2) = IJKE(16,IE)

   ! Get the velocity components at the appropriate cell faces     
 
   COMPONENT: SELECT CASE(IEC)
      CASE(1) COMPONENT    
         UUP(1)  = VV(II,JJ,KK+1)
         UUM(1)  = VV(II,JJ,KK)
         UUP(2)  = WW(II,JJ+1,KK)
         UUM(2)  = WW(II,JJ,KK)
         DXX(1)  = DY(JJ)
         DXX(2)  = DZ(KK)
         MUA      = 0.25_EB*(MU(II,JJ,KK) + MU(II,JJ+1,KK) + MU(II,JJ+1,KK+1) + MU(II,JJ,KK+1) )
      CASE(2) COMPONENT  
         UUP(1)  = WW(II+1,JJ,KK)
         UUM(1)  = WW(II,JJ,KK)
         UUP(2)  = UU(II,JJ,KK+1)
         UUM(2)  = UU(II,JJ,KK)
         DXX(1)  = DZ(KK)
         DXX(2)  = DX(II)
         MUA      = 0.25_EB*(MU(II,JJ,KK) + MU(II+1,JJ,KK) + MU(II+1,JJ,KK+1) + MU(II,JJ,KK+1) )
      CASE(3) COMPONENT 
         UUP(1)  = UU(II,JJ+1,KK)
         UUM(1)  = UU(II,JJ,KK)
         UUP(2)  = VV(II+1,JJ,KK)
         UUM(2)  = VV(II,JJ,KK)
         DXX(1)  = DX(II)
         DXX(2)  = DY(JJ)
         MUA      = 0.25_EB*(MU(II,JJ,KK) + MU(II+1,JJ,KK) + MU(II+1,JJ+1,KK) + MU(II,JJ+1,KK) )
   END SELECT COMPONENT

   ! Indicate that the velocity gradients in the two orthogonal directions have not been changed yet

   ALTERED_GRADIENT = .FALSE.

   ! Loop over all possible orientations of edge and reassign velocity gradients if appropriate

   SIGN_LOOP: DO I_SGN=-1,1,2
      ORIENTATION_LOOP: DO IS=1,3
         IF (IS==IEC) CYCLE ORIENTATION_LOOP

         IOR = I_SGN*IS

         ! Determine Index_Coordinate_Direction
         ! IEC=1, ICD=1 refers to DWDY; ICD=2 refers to DVDZ
         ! IEC=2, ICD=1 refers to DUDZ; ICD=2 refers to DWDX
         ! IEC=3, ICD=1 refers to DVDX; ICD=2 refers to DUDY

         IF (IS>IEC) ICD = IS-IEC
         IF (IS<IEC) ICD = IS-IEC+3
         IF (ICD==1) THEN ! Used to pick the appropriate velocity component
            IVL=2
         ELSE !ICD==2
            IVL=1
         ENDIF
         ICD_SGN = I_SGN * ICD   
         ! IWM and IWP are the wall cell indices of the boundary on either side of the edge.
         IF (IOR<0) THEN
            VEL_GAS   = UUM(IVL)
            VEL_GHOST = UUP(IVL)
            IWM  = WALL_INDEX(ICMM,IS)
            IIGM = I_CELL(ICMM)
            JJGM = J_CELL(ICMM)
            KKGM = K_CELL(ICMM)
            IF (ICD==1) THEN
               IWP  = WALL_INDEX(ICMP,IS)
               IIGP = I_CELL(ICMP)
               JJGP = J_CELL(ICMP)
               KKGP = K_CELL(ICMP)
            ELSE ! ICD==2
               IWP  = WALL_INDEX(ICPM,IS)
               IIGP = I_CELL(ICPM)
               JJGP = J_CELL(ICPM)
               KKGP = K_CELL(ICPM)
            ENDIF
         ELSE
            VEL_GAS   = UUP(IVL)
            VEL_GHOST = UUM(IVL)
            IF (ICD==1) THEN
               IWM  = WALL_INDEX(ICPM,-IOR)
               IIGM = I_CELL(ICPM)
               JJGM = J_CELL(ICPM)
               KKGM = K_CELL(ICPM)
            ELSE ! ICD==2
               IWM  = WALL_INDEX(ICMP,-IOR)
               IIGM = I_CELL(ICMP)
               JJGM = J_CELL(ICMP)
               KKGM = K_CELL(ICMP)
            ENDIF
            IWP  = WALL_INDEX(ICPP,-IOR)
            IIGP = I_CELL(ICPP)
            JJGP = J_CELL(ICPP)
            KKGP = K_CELL(ICPP)
         ENDIF
         ! Throw out edge orientations that need not be processed
   
         IF (BOUNDARY_TYPE(IWM)==NULL_BOUNDARY .AND. BOUNDARY_TYPE(IWP)==NULL_BOUNDARY) CYCLE ORIENTATION_LOOP

         ! Decide whether or not to process edge using data interpolated from another mesh
   
         INTERPOLATION_IF: IF (NOM(ICD)==0 .OR. &
                              (BOUNDARY_TYPE(IWM)/=INTERPOLATED_BOUNDARY .AND. BOUNDARY_TYPE(IWP)/=INTERPOLATED_BOUNDARY)) THEN

            ! Determine appropriate velocity BC by assessing each adjacent wall cell. If the BCs are different on each
            ! side of the edge, choose the one with the specified velocity, if there is one. If not, choose the max value of
            ! boundary condition index, simply for consistency.

            IBCM = 0
            IBCP = 0
            IF (IWM>0) IBCM = IJKW(5,IWM)
            IF (IWP>0) IBCP = IJKW(5,IWP)
            IF (SURFACE(IBCM)%SPECIFIED_NORMAL_VELOCITY) THEN
               SF=>SURFACE(IBCM)
            ELSEIF (SURFACE(IBCP)%SPECIFIED_NORMAL_VELOCITY) THEN
               SF=>SURFACE(IBCP)
            ELSE
               SF => SURFACE(MAX(IBCM,IBCP))
            ENDIF
            VELOCITY_BC_INDEX = SF%VELOCITY_BC_INDEX

            ! Compute the viscosity in the two adjacent gas cells

            MUA = 0.5_EB*(MU(IIGM,JJGM,KKGM) + MU(IIGP,JJGP,KKGP))

            ! Determine if there is a tangential velocity component
            IF (.NOT.SF%SPECIFIED_TANGENTIAL_VELOCITY) THEN
               VEL_T = 0._EB
            ELSE
               IF (SF%T_IGN==T_BEGIN .AND. SF%RAMP_INDEX(TIME_VELO)>=1) THEN
                  TSI = T
               ELSE
                  TSI=T-SF%T_IGN
               ENDIF
               PROFILE_FACTOR = 1._EB
               IF (SF%PROFILE==ATMOSPHERIC) PROFILE_FACTOR = (MAX(0._EB,ZC(KK)-GROUND_LEVEL)/SF%Z0)**SF%PLE
               RAMP_T = EVALUATE_RAMP(TSI,SF%TAU(TIME_VELO),SF%RAMP_INDEX(TIME_VELO))
               IF (IEC==1 .OR. (IEC==2 .AND. ICD==2)) VEL_T = SF%VEL_T(2)
               IF (IEC==3 .OR. (IEC==2 .AND. ICD==1)) VEL_T = SF%VEL_T(1)
               VEL_T = PROFILE_FACTOR*RAMP_T*VEL_T
            ENDIF
 
            ! Choose the appropriate boundary condition to apply
            BOUNDARY_CONDITION: SELECT CASE(VELOCITY_BC_INDEX)

               CASE (FREE_SLIP_BC) BOUNDARY_CONDITION
                  VEL_GHOST = VEL_GAS
                  DUIDXJ(ICD_SGN) = I_SGN*(VEL_GAS-VEL_GHOST)/DXX(ICD)
                  MU_DUIDXJ(ICD_SGN) = MUA*DUIDXJ(ICD_SGN)
                  ALTERED_GRADIENT(ICD_SGN) = .TRUE.
               CASE (NO_SLIP_BC) BOUNDARY_CONDITION

                  VEL_GHOST = 2._EB*VEL_T - VEL_GAS
                  DUIDXJ(ICD_SGN) = I_SGN*(VEL_GAS-VEL_GHOST)/DXX(ICD)
                  MU_DUIDXJ(ICD_SGN) = MUA*DUIDXJ(ICD_SGN)
                  ALTERED_GRADIENT(ICD_SGN) = .TRUE.
               CASE (WALL_MODEL) BOUNDARY_CONDITION
               
                  IF ( SOLID(CELL_INDEX(IIGM,JJGM,KKGM)) .OR. SOLID(CELL_INDEX(IIGP,JJGP,KKGP)) ) THEN
                     MU_WALL = MUA
                     SLIP_COEF=-1._EB
                  ELSE
                     ITMP = MIN(5000,NINT(0.5_EB*(TMP(IIGM,JJGM,KKGM)+TMP(IIGP,JJGP,KKGP))))
                     MU_WALL = Y2MU_C(ITMP)*SPECIES(0)%MW
                     RHO_WALL = 0.5_EB*( RHOP(IIGM,JJGM,KKGM) + RHOP(IIGP,JJGP,KKGP) )
                     CALL WERNER_WENGLE_WALL_MODEL(SLIP_COEF,VEL_GAS-VEL_T,MU_WALL/RHO_WALL,DXX(ICD),SF%ROUGHNESS)
                  ENDIF
                  VEL_GHOST = 2._EB*VEL_T - VEL_GAS
                  DUIDXJ(ICD_SGN) = I_SGN*(VEL_GAS-VEL_GHOST)/DXX(ICD)
                  MU_DUIDXJ(ICD_SGN) = MU_WALL*(VEL_GAS-VEL_T)*I_SGN*(1._EB-SLIP_COEF)/DXX(ICD)
                  ALTERED_GRADIENT(ICD_SGN) = .TRUE.

                  IF (BOUNDARY_TYPE(IWM)==SOLID_BOUNDARY .NEQV. BOUNDARY_TYPE(IWP)==SOLID_BOUNDARY) THEN
                     DUIDXJ(ICD_SGN) = 0.5_EB*DUIDXJ(ICD_SGN)
                     MU_DUIDXJ(ICD_SGN) = 0.5_EB*MU_DUIDXJ(ICD_SGN)
                  ENDIF
            END SELECT BOUNDARY_CONDITION

         ELSE INTERPOLATION_IF  ! Use data from another mesh
 
            OM => OMESH(ABS(NOM(ICD)))
   
            IF (PREDICTOR) THEN
               SELECT CASE(IEC)
                  CASE(1)
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%WS
                     ELSE
                        VEL_OTHER => OM%VS
                     ENDIF !ICD==2
                  CASE(2)
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%US
                     ELSE !ICD==2
                        VEL_OTHER => OM%WS
                     ENDIF
                  CASE(3) !ICD==2
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%VS
                     ELSE
                        VEL_OTHER => OM%US
                     ENDIF
               END SELECT
            ELSE
               SELECT CASE(IEC)
                  CASE(1) !ICD==2
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%W
                     ELSE
                        VEL_OTHER => OM%V
                     ENDIF
                  CASE(2) !ICD==2
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%U
                     ELSE !ICD==2
                        VEL_OTHER => OM%W
                     ENDIF
                  CASE(3)
                     IF (ICD==1) THEN
                        VEL_OTHER => OM%V
                     ELSE !ICD==2
                        VEL_OTHER => OM%U
                     ENDIF
               END SELECT
            ENDIF
   
            WGT = EDGE_INTERPOLATION_FACTOR(IE,ICD)
            OMW = 1._EB-WGT

            SELECT CASE(IEC)
               CASE(1)
                  IF (ICD==1) THEN
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)-1)
                  ELSE !ICD=2
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD),JJO(ICD)-1,KKO(ICD))
                  ENDIF
                  MUA = 0.25_EB*(MU(II,JJ,KK) + MU(II,JJ+1,KK) + MU(II,JJ+1,KK+1) + MU(II,JJ,KK+1) )
               CASE(2)
                  IF (ICD==1) THEN
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD)-1,JJO(ICD),KKO(ICD))
                  ELSE !ICD==2
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)-1)
                  ENDIF
                  MUA = 0.25_EB*(MU(II,JJ,KK) + MU(II+1,JJ,KK) + MU(II+1,JJ,KK+1) + MU(II,JJ,KK+1) )
               CASE(3)
                  IF (ICD==1) THEN
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD),JJO(ICD)-1,KKO(ICD))
                  ELSE !ICD==2
                     VEL_GHOST = WGT*VEL_OTHER(IIO(ICD),JJO(ICD),KKO(ICD)) + OMW*VEL_OTHER(IIO(ICD)-1,JJO(ICD),KKO(ICD))
                  ENDIF
                  MUA = 0.25_EB*(MU(II,JJ,KK) + MU(II+1,JJ,KK) + MU(II+1,JJ+1,KK) + MU(II,JJ+1,KK) )
            END SELECT
            DUIDXJ(ICD_SGN) = I_SGN*(VEL_GAS-VEL_GHOST)/DXX(ICD)
            MU_DUIDXJ(ICD_SGN) = MUA*I_SGN*(VEL_GAS-VEL_GHOST)/DXX(ICD)
            ALTERED_GRADIENT(ICD_SGN) = .TRUE.
   
         ENDIF INTERPOLATION_IF

         ! Set ghost cell values at edge of computational domain
   
         SELECT CASE(IEC)
            CASE(1)
               IF (JJ==0    .AND. IOR== 2) WW(II,JJ,KK)   = VEL_GHOST
               IF (JJ==JBAR .AND. IOR==-2) WW(II,JJ+1,KK) = VEL_GHOST
               IF (KK==0    .AND. IOR== 3) VV(II,JJ,KK)   = VEL_GHOST
               IF (KK==KBAR .AND. IOR==-3) VV(II,JJ,KK+1) = VEL_GHOST
               IF (CORRECTOR .AND. JJ>0 .AND. JJ<JBAR .AND. KK>0 .AND. KK<KBAR) THEN
                 IF (ICD==1) THEN
                    W_Y(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ELSE !ICD==2
                    V_Z(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ENDIF
               ENDIF
            CASE(2)
               IF (II==0    .AND. IOR== 1) WW(II,JJ,KK)   = VEL_GHOST
               IF (II==IBAR .AND. IOR==-1) WW(II+1,JJ,KK) = VEL_GHOST
               IF (KK==0    .AND. IOR== 3) UU(II,JJ,KK)   = VEL_GHOST
               IF (KK==KBAR .AND. IOR==-3) UU(II,JJ,KK+1) = VEL_GHOST
               IF (CORRECTOR .AND. II>0 .AND. II<IBAR .AND. KK>0 .AND. KK<KBAR) THEN
                 IF (ICD==1) THEN
                    U_Z(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ELSE !ICD==2
                    W_X(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ENDIF
               ENDIF
            CASE(3)
               IF (II==0    .AND. IOR== 1) VV(II,JJ,KK)   = VEL_GHOST
               IF (II==IBAR .AND. IOR==-1) VV(II+1,JJ,KK) = VEL_GHOST
               IF (JJ==0    .AND. IOR== 2) UU(II,JJ,KK)   = VEL_GHOST
               IF (JJ==JBAR .AND. IOR==-2) UU(II,JJ+1,KK) = VEL_GHOST
               IF (CORRECTOR .AND. II>0 .AND. II<IBAR .AND. JJ>0 .AND. JJ<JBAR) THEN
                 IF (ICD==1) THEN
                    V_X(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ELSE !ICD==2
                    U_Y(II,JJ,KK) = 0.5_EB*(VEL_GHOST+VEL_GAS)
                 ENDIF
               ENDIF
         END SELECT
      ENDDO ORIENTATION_LOOP
   
   ENDDO SIGN_LOOP
   ! Save vorticity and viscous stress for use in momentum equation
   DUIDXJ_0(1)    = (UUP(2)-UUM(2))/DXX(1)
   DUIDXJ_0(2)    = (UUP(1)-UUM(1))/DXX(2)
   MU_DUIDXJ_0(1) = MUA*DUIDXJ_0(1)
   MU_DUIDXJ_0(2) = MUA*DUIDXJ_0(2)

   SIGN_LOOP_2: DO I_SGN=-1,1,2
      ORIENTATION_LOOP_2: DO ICD=1,2
         IF (ICD==1) THEN
            ICDO=2
         ELSE !ICD==2)
            ICDO=1
         ENDIF
         ICD_SGN = I_SGN*ICD
         IF (ALTERED_GRADIENT(ICD_SGN)) THEN
               DUIDXJ_USE(ICD) =    DUIDXJ(ICD_SGN)
            MU_DUIDXJ_USE(ICD) = MU_DUIDXJ(ICD_SGN)
         ELSEIF (ALTERED_GRADIENT(-ICD_SGN)) THEN
               DUIDXJ_USE(ICD) =    DUIDXJ(-ICD_SGN)
            MU_DUIDXJ_USE(ICD) = MU_DUIDXJ(-ICD_SGN)
         ELSE
            CYCLE
         ENDIF
         ICDO_SGN = I_SGN*ICDO
         IF (ALTERED_GRADIENT(ICDO_SGN) .AND. ALTERED_GRADIENT(-ICDO_SGN)) THEN
               DUIDXJ_USE(ICDO) =    0.5_EB*(DUIDXJ(ICDO_SGN)+   DUIDXJ(-ICDO_SGN))
            MU_DUIDXJ_USE(ICDO) = 0.5_EB*(MU_DUIDXJ(ICDO_SGN)+MU_DUIDXJ(-ICDO_SGN))
         ELSEIF (ALTERED_GRADIENT(ICDO_SGN)) THEN
               DUIDXJ_USE(ICDO) =    DUIDXJ(ICDO_SGN)
            MU_DUIDXJ_USE(ICDO) = MU_DUIDXJ(ICDO_SGN)
         ELSEIF (ALTERED_GRADIENT(-ICDO_SGN)) THEN
               DUIDXJ_USE(ICDO) =    DUIDXJ(-ICDO_SGN)
            MU_DUIDXJ_USE(ICDO) = MU_DUIDXJ(-ICDO_SGN)
         ELSE
               DUIDXJ_USE(ICDO) =    DUIDXJ_0(ICDO)
            MU_DUIDXJ_USE(ICDO) = MU_DUIDXJ_0(ICDO)
         ENDIF
         OME_E(IE,ICD_SGN) =    DUIDXJ_USE(1) -    DUIDXJ_USE(2)
         TAU_E(IE,ICD_SGN) = MU_DUIDXJ_USE(1) + MU_DUIDXJ_USE(2)    
      ENDDO ORIENTATION_LOOP_2
   ENDDO SIGN_LOOP_2

ENDDO EDGE_LOOP
!$OMP END DO

! Store cell node averages of the velocity components in UVW_GHOST for use in Smokeview only

IF (CORRECTOR) THEN
   !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,IC)
   DO K=0,KBAR
      DO J=0,JBAR
         DO I=0,IBAR
            !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELOCITY_BC_02'
            IC = CELL_INDEX(I,J,K) 
            IF (IC==0) CYCLE
            IF (U_Y(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,1) = U_Y(I,J,K) 
            IF (U_Z(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,1) = U_Z(I,J,K) 
            IF (V_X(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,2) = V_X(I,J,K) 
            IF (V_Z(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,2) = V_Z(I,J,K) 
            IF (W_X(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,3) = W_X(I,J,K) 
            IF (W_Y(I,J,K)  >-1.E5_EB) UVW_GHOST(IC,3) = W_Y(I,J,K)
         ENDDO
      ENDDO
   ENDDO
   !$OMP END DO NOWAIT
ENDIF
!$OMP END PARALLEL

TUSED(4,NM)=TUSED(4,NM)+SECOND()-TNOW
END SUBROUTINE VELOCITY_BC 
 
 
 
SUBROUTINE MATCH_VELOCITY(NM)

! Force normal component of velocity to match at interpolated boundaries

INTEGER  :: NOM,II,JJ,KK,IOR,IW,IIO,JJO,KKO,IIG,JJG,KKG
INTEGER, INTENT(IN) :: NM
REAL(EB) :: UU_AVG,VV_AVG,WW_AVG,TNOW,DA_OTHER,UU_OTHER,VV_OTHER,WW_OTHER
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW,OM_UU,OM_VV,OM_WW
TYPE (OMESH_TYPE), POINTER :: OM
TYPE (MESH_TYPE), POINTER :: M2

IF (SOLID_PHASE_ONLY) RETURN
IF (NMESHES==1 .AND. PERIODIC_TEST==0) RETURN

TNOW = SECOND()

! Assign local variable names

CALL POINT_TO_MESH(NM)

! Point to the appropriate velocity field

IF (PREDICTOR) THEN
   UU => US
   VV => VS
   WW => WS
   D_CORR = 0._EB
ELSE
   UU => U
   VV => V
   WW => W
   DS_CORR = 0._EB
ENDIF

! Loop over all cell edges and determine the appropriate velocity BCs

!$OMP PARALLEL DO PRIVATE(IW,II,JJ,KK,IOR,IIG,JJG,KKG,NOM,OM,M2,DA_OTHER,OM_UU,OM_VV,OM_WW,KKO,JJO,IIO) &
!$OMP PRIVATE(UU_OTHER,VV_OTHER,WW_OTHER,UU_AVG,VV_AVG,WW_AVG)
EXTERNAL_WALL_LOOP: DO IW=1,NEWC

   !!$ IF ((IW == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_VELO_24'
   
   IF (IJKW(9,IW)==0) CYCLE EXTERNAL_WALL_LOOP

   II  = IJKW( 1,IW)
   JJ  = IJKW( 2,IW)
   KK  = IJKW( 3,IW)
   IOR = IJKW( 4,IW)
   IIG = IJKW(6,IW)
   JJG = IJKW(7,IW)
   KKG = IJKW(8,IW)
   NOM = IJKW( 9,IW)
   OM => OMESH(NOM)
   M2 => MESHES(NOM)
   
   ! Determine the area of the interpolated cell face
   
   DA_OTHER = 0._EB

   SELECT CASE(ABS(IOR))
      CASE(1)
         IF (PREDICTOR) OM_UU => OM%US
         IF (CORRECTOR) OM_UU => OM%U 
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  DA_OTHER = DA_OTHER + M2%DY(JJO)*M2%DZ(KKO)
               ENDDO
            ENDDO
         ENDDO
      CASE(2)
         IF (PREDICTOR) OM_VV => OM%VS
         IF (CORRECTOR) OM_VV => OM%V
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  DA_OTHER = DA_OTHER + M2%DX(IIO)*M2%DZ(KKO)
               ENDDO
            ENDDO
         ENDDO
      CASE(3)
         IF (PREDICTOR) OM_WW => OM%WS
         IF (CORRECTOR) OM_WW => OM%W
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  DA_OTHER = DA_OTHER + M2%DX(IIO)*M2%DY(JJO)
               ENDDO
            ENDDO
         ENDDO
   END SELECT
   
   ! Determine the normal component of velocity from the other mesh and use it for average

   SELECT CASE(IOR)
   
      CASE( 1)
      
         UU_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  UU_OTHER = UU_OTHER + OM_UU(IIO,JJO,KKO)*M2%DY(JJO)*M2%DZ(KKO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         UU_AVG = 0.5_EB*(UU(0,JJ,KK) + UU_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) + 0.5*(UU_AVG-UU(0,JJ,KK))*RDX(1)
         IF (CORRECTOR) DS_CORR(IW) = (UU_AVG-UU(0,JJ,KK))*RDX(1)
         UVW_SAVE(IW) = UU(0,JJ,KK)
         UU(0,JJ,KK)  = UU_AVG

      CASE(-1)
         
         UU_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  UU_OTHER = UU_OTHER + OM_UU(IIO-1,JJO,KKO)*M2%DY(JJO)*M2%DZ(KKO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         UU_AVG = 0.5_EB*(UU(IBAR,JJ,KK) + UU_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) - 0.5*(UU_AVG-UU(IBAR,JJ,KK))*RDX(IBAR)
         IF (CORRECTOR) DS_CORR(IW) = -(UU_AVG-UU(IBAR,JJ,KK))*RDX(IBAR)
         UVW_SAVE(IW) = UU(IBAR,JJ,KK)
         UU(IBAR,JJ,KK) = UU_AVG

      CASE( 2)
      
         VV_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  VV_OTHER = VV_OTHER + OM_VV(IIO,JJO,KKO)*M2%DX(IIO)*M2%DZ(KKO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         VV_AVG = 0.5_EB*(VV(II,0,KK) + VV_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) + 0.5*(VV_AVG-VV(II,0,KK))*RDY(1)
         IF (CORRECTOR) DS_CORR(IW) = (VV_AVG-VV(II,0,KK))*RDY(1)
         UVW_SAVE(IW) = VV(II,0,KK)
         VV(II,0,KK)  = VV_AVG

      CASE(-2)
      
         VV_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  VV_OTHER = VV_OTHER + OM_VV(IIO,JJO-1,KKO)*M2%DX(IIO)*M2%DZ(KKO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         VV_AVG = 0.5_EB*(VV(II,JBAR,KK) + VV_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) - 0.5*(VV_AVG-VV(II,JBAR,KK))*RDY(JBAR)
         IF (CORRECTOR) DS_CORR(IW) = -(VV_AVG-VV(II,JBAR,KK))*RDY(JBAR)
         UVW_SAVE(IW)   = VV(II,JBAR,KK)
         VV(II,JBAR,KK) = VV_AVG

      CASE( 3)
      
         WW_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  WW_OTHER = WW_OTHER + OM_WW(IIO,JJO,KKO)*M2%DX(IIO)*M2%DY(JJO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         WW_AVG = 0.5_EB*(WW(II,JJ,0) + WW_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) + 0.5*(WW_AVG-WW(II,JJ,0))*RDZ(1)
         IF (CORRECTOR) DS_CORR(IW) = (WW_AVG-WW(II,JJ,0))*RDZ(1)
         UVW_SAVE(IW) = WW(II,JJ,0)
         WW(II,JJ,0)  = WW_AVG

      CASE(-3)
      
         WW_OTHER = 0._EB
         DO KKO=IJKW(12,IW),IJKW(15,IW)
            DO JJO=IJKW(11,IW),IJKW(14,IW)
               DO IIO=IJKW(10,IW),IJKW(13,IW)
                  WW_OTHER = WW_OTHER + OM_WW(IIO,JJO,KKO-1)*M2%DX(IIO)*M2%DY(JJO)/DA_OTHER
               ENDDO
            ENDDO
         ENDDO
         WW_AVG = 0.5_EB*(WW(II,JJ,KBAR) + WW_OTHER)
         IF (PREDICTOR) D_CORR(IW) = DS_CORR(IW) - 0.5*(WW_AVG-WW(II,JJ,KBAR))*RDZ(KBAR)
         IF (CORRECTOR) DS_CORR(IW) = -(WW_AVG-WW(II,JJ,KBAR))*RDZ(KBAR)
         UVW_SAVE(IW)   = WW(II,JJ,KBAR)
         WW(II,JJ,KBAR) = WW_AVG
         
   END SELECT

ENDDO EXTERNAL_WALL_LOOP
!$OMP END PARALLEL DO

TUSED(4,NM)=TUSED(4,NM)+SECOND()-TNOW
END SUBROUTINE MATCH_VELOCITY


SUBROUTINE CHECK_STABILITY(NM,CODE)
 
! Checks the Courant and Von Neumann stability criteria, and if necessary, reduces the time step accordingly
 
INTEGER, INTENT(IN) :: NM,CODE
REAL(EB) :: UODX,VODY,WODZ,UVW,UVWMAX,R_DX2,MU_MAX,MUTRM,DMAX,RDMAX
INTEGER  :: I,J,K
REAL(EB) :: P_UVWMAX,P_MU_MAX !private variables for OpenMP-Code
INTEGER  :: P_ICFL,P_JCFL,P_KCFL,P_I_VN,P_J_VN,P_K_VN !private variables for OpenMP-Code
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW,RHOP,DP

SELECT CASE(CODE)
   CASE(1)
      UU => MESHES(NM)%U
      VV => MESHES(NM)%V
      WW => MESHES(NM)%W
      RHOP => MESHES(NM)%RHO
      DP => MESHES(NM)%D
   CASE(2)
      UU => MESHES(NM)%US
      VV => MESHES(NM)%VS
      WW => MESHES(NM)%WS
      RHOP => MESHES(NM)%RHOS
      DP => MESHES(NM)%DS
END SELECT
 
CHANGE_TIME_STEP(NM) = .FALSE.
UVWMAX = 0._EB
VN     = 0._EB
MUTRM  = 1.E-9_EB
R_DX2  = 1.E-9_EB

! Strategie for OpenMP version of CFL/VN number determination
! - find max CFL/VN number for each thread (P_UVWMAX/P_MU_MAX)
! - save I,J,K of each P_UVWMAX/P_MU_MAX in P_ICFL... for each thread
! - compare sequentially all P_UVWMAX/P_MU_MAX and find the global maximum
! - save P_ICFL... of the "winning" thread in the global ICFL... variable
 
! Determine max CFL number from all grid cells

SELECT_VELOCITY_NORM: SELECT CASE (CFL_VELOCITY_NORM)

   CASE(0)
      IF (USE_OPENMP) THEN
         P_UVWMAX = UVWMAX
         !$OMP PARALLEL DEFAULT(NONE) PRIVATE(P_ICFL,P_JCFL,P_KCFL) &
         !$OMP FIRSTPRIVATE(P_UVWMAX) SHARED(UVWMAX,ICFL,JCFL,KCFL,UU,VV,WW,RDXN,RDYN,RDZN,IBAR,JBAR,KBAR)
         !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,UODX,VODY,WODZ,UVW)
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UODX = ABS(UU(I,J,K))*RDXN(I)
                  VODY = ABS(VV(I,J,K))*RDYN(J)
                  WODZ = ABS(WW(I,J,K))*RDZN(K)
                  UVW  = MAX(UODX,VODY,WODZ)
                  IF (UVW>=P_UVWMAX) THEN
                     P_UVWMAX = UVW
                     P_ICFL = I
                     P_JCFL = J
                     P_KCFL = K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
         !$OMP END DO NOWAIT
         !$OMP CRITICAL
         IF (P_UVWMAX>=UVWMAX) THEN
            UVWMAX = P_UVWMAX
            ICFL=P_ICFL
            JCFL=P_JCFL
            KCFL=P_KCFL
         ENDIF
         !$OMP END CRITICAL
         !$OMP END PARALLEL
      ELSE !NO OpenMP using
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UODX = ABS(UU(I,J,K))*RDXN(I)
                  VODY = ABS(VV(I,J,K))*RDYN(J)
                  WODZ = ABS(WW(I,J,K))*RDZN(K)
                  UVW  = MAX(UODX,VODY,WODZ)
                  IF (UVW>=UVWMAX) THEN
                     UVWMAX = UVW
                     ICFL=I
                     JCFL=J
                     KCFL=K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
      ENDIF

   CASE(1)
      IF (USE_OPENMP) THEN
         P_UVWMAX = UVWMAX
         !$OMP PARALLEL DEFAULT(NONE) PRIVATE(P_ICFL,P_JCFL,P_KCFL) &
         !$OMP FIRSTPRIVATE(P_UVWMAX) SHARED(UVWMAX,ICFL,JCFL,KCFL,UU,VV,WW,RDXN,RDYN,RDZN,IBAR,JBAR,KBAR)
         !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,UVW)
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UVW = (ABS(UU(I,J,K)) + ABS(VV(I,J,K)) + ABS(WW(I,J,K)))*MAX(RDXN(I),RDYN(J),RDZN(K))
                  IF (UVW>=P_UVWMAX) THEN
                     P_UVWMAX = UVW
                     P_ICFL=I
                     P_JCFL=J
                     P_KCFL=K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
         !$OMP END DO NOWAIT
         !$OMP CRITICAL
         IF (P_UVWMAX>=UVWMAX) THEN
            UVWMAX = P_UVWMAX
            ICFL=P_ICFL
            JCFL=P_JCFL
            KCFL=P_KCFL
         ENDIF
         !$OMP END CRITICAL
         !$OMP END PARALLEL
      ELSE !No OpenMP using
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UVW = (ABS(UU(I,J,K)) + ABS(VV(I,J,K)) + ABS(WW(I,J,K)))*MAX(RDXN(I),RDYN(J),RDZN(K))
                  IF (UVW>=UVWMAX) THEN
                     UVWMAX = UVW
                     ICFL=I
                     JCFL=J
                     KCFL=K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
      ENDIF
      
   CASE(2)
      IF (USE_OPENMP) THEN
         P_UVWMAX = UVWMAX
         !$OMP PARALLEL DEFAULT(NONE) PRIVATE(P_ICFL,P_JCFL,P_KCFL) &
         !$OMP FIRSTPRIVATE(P_UVWMAX) SHARED(UVWMAX,ICFL,JCFL,KCFL,UU,VV,WW,RDXN,RDYN,RDZN,IBAR,JBAR,KBAR)
         !$OMP DO COLLAPSE(3) PRIVATE(K,J,I,UVW)
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UVW = SQRT(UU(I,J,K)**2 + VV(I,J,K)**2 + WW(I,J,K)**2)*MAX(RDXN(I),RDYN(J),RDZN(K))
                  IF (UVW>=P_UVWMAX) THEN
                     P_UVWMAX = UVW
                     P_ICFL=I
                     P_JCFL=J
                     P_KCFL=K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
         !$OMP END DO NOWAIT
         !$OMP CRITICAL
         IF (P_UVWMAX>=UVWMAX) THEN
            UVWMAX = P_UVWMAX
            ICFL=P_ICFL
            JCFL=P_JCFL
            KCFL=P_KCFL
         ENDIF
         !$OMP END CRITICAL
         !$OMP END PARALLEL
      ELSE !NO OpenMP usage
         DO K=0,KBAR
            DO J=0,JBAR
               DO I=0,IBAR
                  UVW = SQRT(UU(I,J,K)**2 + VV(I,J,K)**2 + WW(I,J,K)**2)*MAX(RDXN(I),RDYN(J),RDZN(K))
                  IF (UVW>=UVWMAX) THEN
                     UVWMAX = UVW
                     ICFL=I
                     JCFL=J
                     KCFL=K
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
      ENDIF
END SELECT SELECT_VELOCITY_NORM

CFL = DT*UVWMAX

! Find minimum time step allowed by divergence constraint

RDMAX = HUGE(1._EB)
DMAX = 0._EB
IF (CFL_VELOCITY_NORM>0) THEN
   !$OMP PARALLEL DO COLLAPSE(3) PRIVATE(K,J,I) REDUCTION(MAX:DMAX)
   DO K=1,KBAR
      DO J=1,JBAR
         DO I=1,IBAR
            DMAX = MAX(DMAX,DP(I,J,K))
         ENDDO
      ENDDO
   ENDDO
   !$OMP END PARALLEL DO
   !!DMAX = MAXVAL(D)
   IF (DMAX>0._EB) RDMAX = CFL_MAX/DMAX
ENDIF
 
! Determine max Von Neumann Number for fine grid calcs
 
PARABOLIC_IF: IF (DNS .OR. CELL_SIZE<0.005_EB .OR. DYNSMAG .OR. CFL_VELOCITY_NORM>0) THEN
 
   INCOMPRESSIBLE_IF: IF (ISOTHERMAL .AND. N_SPECIES==0) THEN
      IF (TWO_D) THEN
         R_DX2 = 1._EB/DXMIN**2 + 1._EB/DZMIN**2
      ELSE
         R_DX2 = 1._EB/DXMIN**2 + 1._EB/DYMIN**2 + 1._EB/DZMIN**2
      ENDIF
      MUTRM = MAX(RPR,RSC)*Y2MU_C(NINT(TMPA))*SPECIES(0)%MW
   ELSE INCOMPRESSIBLE_IF
      MU_MAX = 0._EB
      IF (USE_OPENMP) THEN
         P_MU_MAX = MU_MAX
         !$OMP PARALLEL PRIVATE(P_I_VN,P_J_VN,P_K_VN) FIRSTPRIVATE(P_MU_MAX)
         !$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
         DO K=1,KBAR
            DO J=1,JBAR
               IILOOP_OpenMP: DO I=1,IBAR
                  IF (SOLID(CELL_INDEX(I,J,K))) CYCLE IILOOP_OpenMP
                  IF (MU(I,J,K)/RHOP(I,J,K)>=P_MU_MAX) THEN
                     P_MU_MAX = MU(I,J,K)/RHOP(I,J,K) !! RJM
                     P_I_VN=I
                     P_J_VN=J
                     P_K_VN=K
                  ENDIF
               ENDDO IILOOP_OpenMP
            ENDDO
         ENDDO
         !$OMP END DO NOWAIT
         !$OMP CRITICAL
         IF (P_MU_MAX>=MU_MAX) THEN
            MU_MAX = P_MU_MAX
            I_VN=P_I_VN
            J_VN=P_J_VN
            K_VN=P_K_VN
         ENDIF
         !$OMP END CRITICAL
         !$OMP END PARALLEL
      ELSE !No OpenMP
         DO K=1,KBAR
            DO J=1,JBAR
               IILOOP: DO I=1,IBAR
                  IF (SOLID(CELL_INDEX(I,J,K))) CYCLE IILOOP
                  IF (MU(I,J,K)/RHOP(I,J,K)>=MU_MAX) THEN
                     MU_MAX = MU(I,J,K)/RHOP(I,J,K) !! RJM
                     I_VN=I
                     J_VN=J
                     K_VN=K
                  ENDIF
               ENDDO IILOOP
            ENDDO  
         ENDDO    
      ENDIF

      IF (TWO_D) THEN
         R_DX2 = RDX(I_VN)**2 + RDZ(K_VN)**2
      ELSE
         R_DX2 = RDX(I_VN)**2 + RDY(J_VN)**2 + RDZ(K_VN)**2
      ENDIF
      MUTRM = MAX(RPR,RSC)*MU_MAX !! /RHOS(I_VN,J_VN,K_VN) !! RJM
   ENDIF INCOMPRESSIBLE_IF
 
   VN = DT*2._EB*R_DX2*MUTRM
 
ENDIF PARABOLIC_IF
 
! Adjust time step size if necessary
 
IF ((CFL<CFL_MAX.AND.VN<VN_MAX.AND.DT<RDMAX) .OR. LOCK_TIME_STEP) THEN
   DT_NEXT = DT
   IF (CFL<=CFL_MIN .AND. VN<VN_MIN .AND. .NOT.LOCK_TIME_STEP) THEN
      IF (     RESTRICT_TIME_STEP) DT_NEXT = MIN(1.1_EB*DT,DT_INIT)
      IF (.NOT.RESTRICT_TIME_STEP) DT_NEXT =     1.1_EB*DT
   ENDIF
ELSE
   IF (UVWMAX==0._EB) UVWMAX = 1._EB
   DT = 0.9_EB*MIN( CFL_MAX/UVWMAX , VN_MAX/(2._EB*R_DX2*MUTRM), RDMAX )
   CHANGE_TIME_STEP(NM) = .TRUE.
ENDIF
 
END SUBROUTINE CHECK_STABILITY
 
 
SUBROUTINE BAROCLINIC_CORRECTION
 
REAL(EB), POINTER, DIMENSION(:,:,:) :: UU,VV,WW,HQS,RTRM,RHOP
REAL(EB) :: RHO_AVG_OLD,RRAT,U2,V2,W2
INTEGER  :: I,J,K
 
HQS  => WORK1
RTRM => WORK2
 
IF (PREDICTOR) THEN
   UU => U
   VV => V
   WW => W
   RHOP=>RHO
ELSE
   UU => US
   VV => VS
   WW => WS
   RHOP=>RHOS
ENDIF
 
RHO_AVG_OLD = RHO_AVG
RHO_AVG = 2._EB*RHO_LOWER_GLOBAL*RHO_UPPER_GLOBAL/(RHO_LOWER_GLOBAL+RHO_UPPER_GLOBAL)
IF (RHO_AVG<=0._EB) THEN
   WRITE(LU_ERR,*) 'WARNING! RHO_AVG <= 0 in BAROCLINIC_CORRECTION'
   RRAT = 1._EB
   RTRM = 0._EB
ELSE
   RRAT = RHO_AVG_OLD/RHO_AVG
   RTRM = (1._EB-RHO_AVG/RHOP)*RRAT
ENDIF

!$OMP PARALLEL
!$OMP DO COLLAPSE(3) PRIVATE(K,J,I,U2,V2,W2) 
DO K=1,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         !!$ IF ((K == 1) .AND. (J == 1) .AND. (I == 1) .AND. DEBUG_OPENMP) WRITE(*,*) 'OpenMP_BAROCLINIC'
         U2 = 0.25_EB*(UU(I,J,K)+UU(I-1,J,K))**2
         V2 = 0.25_EB*(VV(I,J,K)+VV(I,J-1,K))**2
         W2 = 0.25_EB*(WW(I,J,K)+WW(I,J,K-1))**2
         HQS(I,J,K) = 0.5_EB*(U2+V2+W2)
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT

!$OMP DO COLLAPSE(2) PRIVATE(K,J,U2,V2,W2) 
DO K=1,KBAR
   DO J=1,JBAR
      U2 = (1.5_EB*UU(0,J,K)-0.5_EB*UU(1,J,K))**2
      V2 = 0.25_EB*(VV(1,J,K)+VV(1,J-1,K))**2
      W2 = 0.25_EB*(WW(1,J,K)+WW(1,J,K-1))**2
      HQS(0,J,K) = MIN(0.5_EB*(U2+V2+W2),10._EB*DX(1)+HQS(1,J,K))
      U2 = (1.5_EB*UU(IBAR,J,K)-0.5_EB*UU(IBM1,J,K))**2
      V2 = 0.25_EB*(VV(IBAR,J,K)+VV(IBAR,J-1,K))**2
      W2 = 0.25_EB*(WW(IBAR,J,K)+WW(IBAR,J,K-1))**2
      HQS(IBP1,J,K) = MIN(0.5_EB*(U2+V2+W2),10._EB*DX(IBAR)+HQS(IBAR,J,K))
   ENDDO
ENDDO
!$OMP END DO NOWAIT
 
IF (.NOT.TWO_D) THEN
   !$OMP DO COLLAPSE(2) PRIVATE(K,I,U2,V2,W2)
   DO K=1,KBAR
      DO I=1,IBAR
         U2 = 0.25_EB*(UU(I,1,K)+UU(I-1,1,K))**2
         V2 = (1.5_EB*VV(I,0,K)-0.5_EB*VV(I,1,K))**2
         W2 = 0.25_EB*(WW(I,1,K)+WW(I,1,K-1))**2
         HQS(I,0,K) = MIN(0.5_EB*(U2+V2+W2),10._EB*DY(1)+HQS(I,1,K))
         U2 = 0.25_EB*(UU(I,JBAR,K)+UU(I-1,JBAR,K))**2
         V2 = (1.5_EB*VV(I,JBAR,K)-0.5_EB*VV(I,JBM1,K))**2
         W2 = 0.25_EB*(WW(I,JBAR,K)+WW(I,JBAR,K-1))**2
         HQS(I,JBP1,K) = MIN(0.5_EB*(U2+V2+W2),10._EB*DY(JBAR)+HQS(I,JBAR,K))
      ENDDO
   ENDDO
   !$OMP END DO NOWAIT
ENDIF

!$OMP DO COLLAPSE(2) PRIVATE(J,I,U2,V2,W2)
DO J=1,JBAR
   DO I=1,IBAR
      U2 = 0.25_EB*(UU(I,J,1)+UU(I-1,J,1))**2
      V2 = 0.25_EB*(VV(I,J,1)+VV(I,J-1,1))**2
      W2 = (1.5_EB*WW(I,J,0)-0.5_EB*WW(I,J,1))**2
      HQS(I,J,0) = MIN(0.5_EB*(U2+V2+W2),10._EB*DZ(1)+HQS(I,J,1))
      U2 = 0.25_EB*(UU(I,J,KBAR)+UU(I-1,J,KBAR))**2
      V2 = 0.25_EB*(VV(I,J,KBAR)+VV(I,J-1,KBAR))**2
      W2 = (1.5_EB*WW(I,J,KBAR)-0.5_EB*WW(I,J,KBM1))**2
      HQS(I,J,KBP1) = MIN(0.5_EB*(U2+V2+W2),10._EB*DZ(KBAR)+HQS(I,J,KBAR))
   ENDDO
ENDDO
!$OMP END DO

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
DO K=1,KBAR
   DO J=1,JBAR
      DO I=0,IBAR
         FVX(I,J,K) = FVX(I,J,K) - 0.5_EB*(RTRM(I+1,J,K)+RTRM(I,J,K))*(H(I+1,J,K)-H(I,J,K)-HQS(I+1,J,K)+HQS(I,J,K))*RDXN(I)
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
 
IF (.NOT.TWO_D) THEN
   !$OMP DO COLLAPSE(3) PRIVATE(K,J,I)
   DO K=1,KBAR
      DO J=0,JBAR
         DO I=1,IBAR
            FVY(I,J,K) = FVY(I,J,K) - 0.5_EB*(RTRM(I,J+1,K)+RTRM(I,J,K))*(H(I,J+1,K)-H(I,J,K)-HQS(I,J+1,K)+HQS(I,J,K))*RDYN(J)
         ENDDO
      ENDDO
   ENDDO
   !$OMP END DO NOWAIT
ENDIF

!$OMP DO COLLAPSE(3) PRIVATE(K,J,I) 
DO K=0,KBAR
   DO J=1,JBAR
      DO I=1,IBAR
         FVZ(I,J,K) = FVZ(I,J,K) - 0.5_EB*(RTRM(I,J,K+1)+RTRM(I,J,K))*(H(I,J,K+1)-H(I,J,K)-HQS(I,J,K+1)+HQS(I,J,K))*RDZN(K)
      ENDDO
   ENDDO
ENDDO
!$OMP END DO NOWAIT
!$OMP END PARALLEL
 
END SUBROUTINE BAROCLINIC_CORRECTION

SUBROUTINE GET_REV_velo(MODULE_REV,MODULE_DATE)
INTEGER,INTENT(INOUT) :: MODULE_REV
CHARACTER(255),INTENT(INOUT) :: MODULE_DATE

WRITE(MODULE_DATE,'(A)') velorev(INDEX(velorev,':')+1:LEN_TRIM(velorev)-2)
READ (MODULE_DATE,'(I5)') MODULE_REV
WRITE(MODULE_DATE,'(A)') velodate

END SUBROUTINE GET_REV_velo
 
END MODULE VELO
