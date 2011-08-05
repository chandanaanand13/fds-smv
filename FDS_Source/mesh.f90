MODULE MESH_VARIABLES
 
! Data structure for mesh-dependent variables
 
USE PRECISION_PARAMETERS
USE TYPES
IMPLICIT NONE

CHARACTER(255), PARAMETER :: meshid='$Id$'
CHARACTER(255), PARAMETER :: meshrev='$Revision$'
CHARACTER(255), PARAMETER :: meshdate='$Date$'
 
TYPE MESH_TYPE
 
   REAL(EB), POINTER, DIMENSION(:,:,:) :: &
            U,V,W,US,VS,WS,DDDT,D,DS,H,HS,KRES,FVX,FVY,FVZ,RHO,RHOS, &
            MU,TMP,Q,FRHO,KAPPA,QR,QR_W,UII,RSUM,D_LAGRANGIAN,D_REACTION, &
            CSD2,MTR,MSR,WEM,MIX_TIME, &
            E,ES,ENTHALPY_SOURCE,STRAIN_RATE
 
   REAL(EB), POINTER, DIMENSION(:,:,:,:) :: ZZ,ZZS,DEL_RHO_D_DEL_Z,DFX,DFY,DFZ
   REAL(EB), POINTER, DIMENSION(:,:,:,:) :: AVG_DROP_DEN,AVG_DROP_TMP,AVG_DROP_RAD,AVG_DROP_AREA
   REAL(EB), POINTER, DIMENSION(:,:) :: UVW_GHOST
 
   REAL(EB) :: POIS_PTB,POIS_ERR
   REAL(EB), POINTER, DIMENSION(:) :: SAVE1,SAVE2,WORK
   REAL(EB), POINTER, DIMENSION(:,:,:) :: PRHS
   REAL(EB), POINTER, DIMENSION(:,:) :: BXS,BXF,BYS,BYF,BZS,BZF, BXST,BXFT,BYST,BYFT,BZST,BZFT
   INTEGER :: LSAVE,LWORK,LBC,MBC,NBC,ITRN,JTRN,KTRN,IPS
   REAL(EB), POINTER, DIMENSION(:) :: P_0,RHO_0,TMP_0,D_PBAR_DT,D_PBAR_S_DT,U_LEAK,U_DUCT
   REAL(EB), POINTER, DIMENSION(:,:) :: PBAR,PBAR_S,R_PBAR
   INTEGER, POINTER, DIMENSION(:,:,:) :: PRESSURE_ZONE 
   INTEGER, POINTER, DIMENSION(:) :: PRESSURE_ZONE_WALL,PRESSURE_BC_INDEX
   REAL(EB), POINTER, DIMENSION(:,:,:) :: WORK1,WORK2,WORK3,WORK4,WORK5,WORK6,WORK7,WORK8
   
   REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK1,TURB_WORK2,TURB_WORK3,TURB_WORK4
   REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK5,TURB_WORK6,TURB_WORK7,TURB_WORK8
   REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK9,TURB_WORK10
   REAL(EB), POINTER, DIMENSION(:) :: TURB_WORK11,TURB_WORK12
   
   REAL(EB), POINTER, DIMENSION(:,:,:) :: IBM_SAVE1,IBM_SAVE2,IBM_SAVE3,IBM_SAVE4,IBM_SAVE5,IBM_SAVE6
   INTEGER, POINTER, DIMENSION(:,:,:) :: U_MASK,V_MASK,W_MASK,P_MASK
   
   REAL(EB), POINTER, DIMENSION(:) :: WALL_WORK1,WALL_WORK2
   REAL(FB), POINTER, DIMENSION(:,:,:,:) :: QQ
   REAL(FB), POINTER, DIMENSION(:,:) :: PP,PPN
   INTEGER, POINTER, DIMENSION(:,:) :: IBK
   INTEGER, POINTER, DIMENSION(:,:,:) :: IBLK
 
   REAL(EB) :: DT,DT_PREV,DT_NEXT,DT_INIT
   REAL(EB) :: CFL,DIVMX,DIVMN,VN,RESMAX,PART_CFL
   INTEGER  :: ICFL,JCFL,KCFL,IMX,JMX,KMX,IMN,JMN,KMN, I_VN,J_VN,K_VN,IRM,JRM,KRM
 
   INTEGER :: N_EDGES
   INTEGER, POINTER, DIMENSION(:,:) :: IJKE,EDGE_INDEX
   REAL(EB), POINTER, DIMENSION(:,:) :: TAU_E,OME_E
   INTEGER, POINTER, DIMENSION(:,:) :: EDGE_TYPE
   
   INTEGER :: MESH_LEVEL
   INTEGER :: IBAR,JBAR,KBAR,IBM1,JBM1,KBM1,IBP1,JBP1,KBP1
   INTEGER, POINTER, DIMENSION(:) :: RGB
   REAL(EB) :: DXI,DETA,DZETA,RDXI,RDETA,RDZETA, &
      DXMIN,DXMAX,DYMIN,DYMAX,DZMIN,DZMAX, &
      XS,XF,YS,YF,ZS,ZF,RDXINT,RDYINT,RDZINT,CELL_SIZE
   REAL(EB), POINTER, DIMENSION(:) :: R,RC,X,Y,Z,XC,YC,ZC,HX,HY,HZ, &
            DX,RDX,DXN,RDXN,DY,RDY,DYN,RDYN,DZ,RDZ,DZN,RDZN, &
            CELLSI,CELLSJ,CELLSK,RRN
   REAL(FB), POINTER, DIMENSION(:) :: XPLT,YPLT,ZPLT
 
   INTEGER :: N_OBST
   TYPE(OBSTRUCTION_TYPE), POINTER, DIMENSION(:) :: OBSTRUCTION
 
   INTEGER :: N_VENT
   TYPE(VENTS_TYPE), POINTER, DIMENSION(:) :: VENTS
 
   INTEGER, POINTER, DIMENSION(:,:,:) :: CELL_INDEX
   INTEGER, POINTER, DIMENSION(:) :: I_CELL,J_CELL,K_CELL,OBST_INDEX_C
   INTEGER, POINTER, DIMENSION(:,:) :: WALL_INDEX
   LOGICAL, POINTER, DIMENSION(:) :: SOLID,EXTERIOR
 
   INTEGER :: N_INTERNAL_WALL_CELLS,N_EXTERNAL_WALL_CELLS,N_VIRTUAL_WALL_CELLS,N_GHOST_WALL_CELLS, &
              CELL_COUNT,WALL_COUNTER
   REAL(EB) :: BC_CLOCK
   REAL(EB), POINTER, DIMENSION(:,:) :: MASSFLUX,MASSFLUX_ACTUAL,AWMPUA,WMPUA,WCPUA
   REAL(EB), POINTER, DIMENSION(:,:) :: RHODW,ZZ_F,EDGE_INTERPOLATION_FACTOR,FW,AWM_AEROSOL
   REAL(EB), POINTER, DIMENSION(:)   :: XW,YW,ZW,TW,AW,RAW,UW0,DUWDT,RDN, &
            QRADIN,QRADOUT,EW,KW,QCONF,AREA_ADJUST,RHO_F, &
            TMP_F,TMP_B,HEAT_TRANS_COEF,D_CORR,DS_CORR,UVW_SAVE,U_TAU
   REAL(EB), POINTER, DIMENSION(:) :: E_WALL
   REAL(EB), POINTER, DIMENSION(:) :: UW,UWS
   INTEGER, POINTER, DIMENSION(:,:) :: IJKW
   INTEGER, POINTER, DIMENSION(:) :: BOUNDARY_TYPE,NPPCW,OBST_INDEX_W,WALL_INDEX_BACK,VENT_INDEX,IBC_ORIG
 
   TYPE(WALL_TYPE), POINTER, DIMENSION(:) :: WALL
   TYPE(OMESH_TYPE), POINTER, DIMENSION(:) :: OMESH
   TYPE(DROPLET_TYPE), POINTER, DIMENSION(:) :: DROPLET
   INTEGER :: NLP,NLPDIM
   TYPE(HUMAN_TYPE), POINTER, DIMENSION(:) :: HUMAN
   INTEGER :: N_HUMANS,N_HUMANS_DIM
   TYPE(HUMAN_GRID_TYPE), POINTER, DIMENSION(:,:) :: HUMAN_GRID
 
   INTEGER :: N_SLCF
   TYPE(SLICE_TYPE), POINTER, DIMENSION(:) :: SLICE
 
   INTEGER, POINTER, DIMENSION(:,:) :: INC
   INTEGER :: NPATCH
 
   REAL(EB), POINTER, DIMENSION(:,:,:,:) :: UIID
   INTEGER :: RAD_CALL_COUNTER,ANGLE_INC_COUNTER
 
   INTEGER, POINTER, DIMENSION(:,:,:) :: INTERPOLATED_MESH
 
   CHARACTER(80), POINTER, DIMENSION(:) :: STRING
   INTEGER :: N_STRINGS,N_STRINGS_MAX

!rm ->
!  REAL(EB), POINTER, DIMENSION(:,:,:,:) :: DMPVDT_FM_VEG
   INTEGER, POINTER, DIMENSION(:,:,:) :: K_AGL_SLICE
   REAL(EB),POINTER, DIMENSION(:,:) :: LS_Z_TERRAIN,VEG_DRAG
   INTEGER :: N_TERRAIN_SLCF
   REAL(EB) :: VEG_CLOCK_BC !surf veg
!rm <-
 
END TYPE MESH_TYPE
 
TYPE (MESH_TYPE), SAVE, DIMENSION(:), ALLOCATABLE, TARGET :: MESHES
 
END MODULE MESH_VARIABLES
 
 
MODULE MESH_POINTERS
 
USE PRECISION_PARAMETERS
USE MESH_VARIABLES
USE GLOBAL_CONSTANTS, ONLY: PERIODIC_TEST,DYNSMAG,FLUX_LIMITER,CHECK_KINETIC_ENERGY,IMMERSED_BOUNDARY_METHOD
IMPLICIT NONE
 
REAL(EB), POINTER, DIMENSION(:,:,:) :: &
          U,V,W,US,VS,WS,DDDT,D,DS,H,HS,KRES,FVX,FVY,FVZ,RHO,RHOS, &
          MU,TMP,Q,FRHO,KAPPA,QR,QR_W,UII,RSUM,D_LAGRANGIAN,D_REACTION, &
          CSD2,MTR,MSR,WEM,MIX_TIME, &
          E,ES,ENTHALPY_SOURCE,STRAIN_RATE
REAL(EB), POINTER, DIMENSION(:,:,:,:) :: ZZ,ZZS,DEL_RHO_D_DEL_Z,DFX,DFY,DFZ
REAL(EB), POINTER, DIMENSION(:,:,:,:) :: AVG_DROP_DEN,AVG_DROP_TMP,AVG_DROP_RAD,AVG_DROP_AREA
REAL(EB), POINTER, DIMENSION(:,:) :: UVW_GHOST
REAL(EB), POINTER :: POIS_PTB,POIS_ERR
REAL(EB), POINTER, DIMENSION(:) :: SAVE1,SAVE2,WORK
REAL(EB), POINTER, DIMENSION(:,:,:) :: PRHS
REAL(EB), POINTER, DIMENSION(:,:) :: BXS,BXF,BYS,BYF,BZS,BZF, BXST,BXFT,BYST,BYFT,BZST,BZFT
INTEGER, POINTER :: LSAVE,LWORK,LBC,MBC,NBC,ITRN,JTRN,KTRN,IPS
REAL(EB), POINTER, DIMENSION(:) :: P_0,RHO_0,TMP_0,D_PBAR_DT,D_PBAR_S_DT,U_LEAK,U_DUCT
REAL(EB), POINTER, DIMENSION(:,:) :: PBAR,PBAR_S,R_PBAR
INTEGER, POINTER, DIMENSION(:,:,:) :: PRESSURE_ZONE
INTEGER, POINTER, DIMENSION(:) :: PRESSURE_ZONE_WALL,PRESSURE_BC_INDEX
REAL(EB), POINTER, DIMENSION(:,:,:) :: WORK1,WORK2,WORK3,WORK4,WORK5,WORK6,WORK7,WORK8

REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK1,TURB_WORK2,TURB_WORK3,TURB_WORK4
REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK5,TURB_WORK6,TURB_WORK7,TURB_WORK8
REAL(EB), POINTER, DIMENSION(:,:,:) :: TURB_WORK9,TURB_WORK10
REAL(EB), POINTER, DIMENSION(:) :: TURB_WORK11,TURB_WORK12

REAL(EB), POINTER, DIMENSION(:,:,:) :: IBM_SAVE1,IBM_SAVE2,IBM_SAVE3,IBM_SAVE4,IBM_SAVE5,IBM_SAVE6
INTEGER, POINTER, DIMENSION(:,:,:) :: U_MASK,V_MASK,W_MASK,P_MASK

REAL(EB), POINTER, DIMENSION(:) :: WALL_WORK1,WALL_WORK2
REAL(FB), POINTER, DIMENSION(:,:,:,:) :: QQ
REAL(FB), POINTER, DIMENSION(:,:) :: PP,PPN
INTEGER, POINTER, DIMENSION(:,:) :: IBK
INTEGER, POINTER, DIMENSION(:,:,:) :: IBLK
REAL(EB), POINTER :: DT,DT_PREV,DT_NEXT,DT_INIT
REAL(EB), POINTER :: CFL,DIVMX,DIVMN,VN,RESMAX,PART_CFL
INTEGER, POINTER :: ICFL,JCFL,KCFL,IMX,JMX,KMX,IMN,JMN,KMN,I_VN,J_VN,K_VN,IRM,JRM,KRM
INTEGER, POINTER :: N_EDGES
INTEGER, POINTER, DIMENSION(:,:) :: IJKE,EDGE_INDEX
REAL(EB), POINTER, DIMENSION(:,:) :: TAU_E,OME_E
INTEGER, POINTER, DIMENSION(:,:) :: EDGE_TYPE

INTEGER, POINTER :: MESH_LEVEL
INTEGER, POINTER :: IBAR,JBAR,KBAR,IBM1,JBM1,KBM1,IBP1,JBP1,KBP1
INTEGER, POINTER, DIMENSION(:) :: RGB
REAL(EB), POINTER :: DXI,DETA,DZETA,RDXI,RDETA,RDZETA, &
   DXMIN,DXMAX,DYMIN,DYMAX,DZMIN,DZMAX, &
   XS,XF,YS,YF,ZS,ZF,RDXINT,RDYINT,RDZINT,CELL_SIZE
REAL(EB), POINTER, DIMENSION(:) :: R,RC,X,Y,Z,XC,YC,ZC,HX,HY,HZ, &
           DX,RDX,DXN,RDXN,DY,RDY,DYN,RDYN,DZ,RDZ,DZN,RDZN, &
           CELLSI,CELLSJ,CELLSK,RRN
REAL(FB), POINTER, DIMENSION(:) :: XPLT,YPLT,ZPLT
INTEGER, POINTER :: N_OBST
TYPE(OBSTRUCTION_TYPE), POINTER, DIMENSION(:) :: OBSTRUCTION
INTEGER, POINTER :: N_VENT
TYPE(VENTS_TYPE), POINTER, DIMENSION(:) :: VENTS
INTEGER, POINTER, DIMENSION(:,:,:) :: CELL_INDEX
INTEGER, POINTER, DIMENSION(:) :: I_CELL,J_CELL,K_CELL,OBST_INDEX_C
INTEGER, POINTER, DIMENSION(:,:) :: WALL_INDEX
LOGICAL, POINTER, DIMENSION(:) :: SOLID,EXTERIOR
INTEGER, POINTER :: N_INTERNAL_WALL_CELLS,N_EXTERNAL_WALL_CELLS,N_VIRTUAL_WALL_CELLS,N_GHOST_WALL_CELLS, &
                    CELL_COUNT,WALL_COUNTER
REAL(EB),POINTER :: BC_CLOCK
REAL(EB), POINTER, DIMENSION(:,:) :: MASSFLUX,MASSFLUX_ACTUAL,AWMPUA,WMPUA,WCPUA
REAL(EB), POINTER, DIMENSION(:,:) :: RHODW,ZZ_F,EDGE_INTERPOLATION_FACTOR,FW,AWM_AEROSOL
REAL(EB), POINTER, DIMENSION(:)   :: XW,YW,ZW,TW,AW,RAW,UW0,DUWDT,RDN, &
           QRADIN,QRADOUT,EW,KW,QCONF,AREA_ADJUST,RHO_F, &
           TMP_F,TMP_B,HEAT_TRANS_COEF,D_CORR,DS_CORR,UVW_SAVE,U_TAU
REAL(EB), POINTER, DIMENSION(:) :: E_WALL
REAL(EB), POINTER, DIMENSION(:) :: UW,UWS
INTEGER, POINTER, DIMENSION(:,:) :: IJKW
INTEGER, POINTER, DIMENSION(:) :: BOUNDARY_TYPE,NPPCW,OBST_INDEX_W,WALL_INDEX_BACK,VENT_INDEX,IBC_ORIG
TYPE(WALL_TYPE), POINTER, DIMENSION(:) :: WALL
TYPE(OMESH_TYPE), POINTER, DIMENSION(:) :: OMESH
TYPE(DROPLET_TYPE), POINTER, DIMENSION(:) :: DROPLET
INTEGER, POINTER :: NLP,NLPDIM
TYPE(HUMAN_TYPE), POINTER, DIMENSION(:) :: HUMAN
INTEGER, POINTER :: N_HUMANS,N_HUMANS_DIM
TYPE(HUMAN_GRID_TYPE), POINTER, DIMENSION(:,:) :: HUMAN_GRID
INTEGER, POINTER :: N_SLCF
TYPE(SLICE_TYPE), POINTER, DIMENSION(:) :: SLICE
INTEGER, POINTER, DIMENSION(:,:) :: INC
INTEGER, POINTER :: NPATCH
REAL(EB), POINTER, DIMENSION(:,:,:,:) :: UIID
INTEGER,  POINTER :: RAD_CALL_COUNTER,ANGLE_INC_COUNTER
INTEGER, POINTER, DIMENSION(:,:,:) :: INTERPOLATED_MESH
CHARACTER(80), POINTER, DIMENSION(:) :: STRING
INTEGER, POINTER :: N_STRINGS,N_STRINGS_MAX
!rm ->
!REAL(EB), POINTER, DIMENSION(:,:,:,:) :: DMPVDT_FM_VEG
INTEGER, POINTER, DIMENSION(:,:,:) :: K_AGL_SLICE
REAL(EB), POINTER,DIMENSION(:,:) :: LS_Z_TERRAIN,VEG_DRAG
INTEGER, POINTER :: N_TERRAIN_SLCF
REAL(EB), POINTER :: VEG_CLOCK_BC  !surf veg
!rm <-

CONTAINS
 
 
SUBROUTINE POINT_TO_MESH(NM)

! Local names for MESH variables point to Global names
 
INTEGER, INTENT(IN) ::  NM
TYPE (MESH_TYPE), POINTER :: M
 
M=>MESHES(NM)
U=>M%U
V=>M%V
W=>M%W
US=>M%US
VS=>M%VS
WS=>M%WS
DDDT=>M%DDDT
D=>M%D
DS=>M%DS
H=>M%H 
HS=>M%HS
E=>M%E
ES=>M%ES
ENTHALPY_SOURCE=>M%ENTHALPY_SOURCE
KRES=>M%KRES
FVX=>M%FVX
FVY=>M%FVY
FVZ=>M%FVZ  
RHO=>M%RHO
RHOS=>M%RHOS
TMP=>M%TMP
FRHO=>M%FRHO
MU=>M%MU
CSD2=>M%CSD2
STRAIN_RATE=>M%STRAIN_RATE
MIX_TIME=>M%MIX_TIME
Q=>M%Q
QR=>M%QR
QR_W=>M%QR_W
KAPPA=>M%KAPPA 
UII=>M%UII 
AVG_DROP_DEN=>M%AVG_DROP_DEN
AVG_DROP_AREA=>M%AVG_DROP_AREA
AVG_DROP_TMP=>M%AVG_DROP_TMP
AVG_DROP_RAD=>M%AVG_DROP_RAD
D_LAGRANGIAN=>M%D_LAGRANGIAN
D_REACTION=>M%D_REACTION
RSUM=>M%RSUM
ZZ=>M%ZZ
ZZS=>M%ZZS
DEL_RHO_D_DEL_Z=>M%DEL_RHO_D_DEL_Z
DFX=>M%DFX
DFY=>M%DFY
DFZ=>M%DFZ
UVW_GHOST=>M%UVW_GHOST
POIS_PTB=>M%POIS_PTB
POIS_ERR=>M%POIS_ERR
SAVE1=>M%SAVE1
SAVE2=>M%SAVE2
WORK=>M%WORK
LSAVE=>M%LSAVE
LWORK=>M%LWORK
PRHS=>M%PRHS
BXS=>M%BXS
BXF=>M%BXF 
BYS=>M%BYS
BYF=>M%BYF 
BZS=>M%BZS
BZF=>M%BZF 
BXST=>M%BXST
BXFT=>M%BXFT 
BYST=>M%BYST
BYFT=>M%BYFT 
BZST=>M%BZST
BZFT=>M%BZFT 
LBC=>M%LBC
MBC=>M%MBC
NBC=>M%NBC 
ITRN=>M%ITRN
JTRN=>M%JTRN
KTRN=>M%KTRN
IPS=>M%IPS
U_LEAK=>M%U_LEAK
U_DUCT=>M%U_DUCT
D_PBAR_DT=>M%D_PBAR_DT
D_PBAR_S_DT=>M%D_PBAR_S_DT
PBAR=>M%PBAR
PBAR_S=>M%PBAR_S
R_PBAR=>M%R_PBAR
P_0=>M%P_0
RHO_0=>M%RHO_0
TMP_0=>M%TMP_0
PRESSURE_ZONE=>M%PRESSURE_ZONE
PRESSURE_ZONE_WALL=>M%PRESSURE_ZONE_WALL
PRESSURE_BC_INDEX=>M%PRESSURE_BC_INDEX
WORK1=>M%WORK1
WORK2=>M%WORK2
WORK3=>M%WORK3 
WORK4=>M%WORK4
WORK5=>M%WORK5
WORK6=>M%WORK6 
WORK7=>M%WORK7
WORK8=>M%WORK8

IF (PERIODIC_TEST==2 .OR. DYNSMAG) THEN
   TURB_WORK1=>M%TURB_WORK1
   TURB_WORK2=>M%TURB_WORK2
   TURB_WORK3=>M%TURB_WORK3 
   TURB_WORK4=>M%TURB_WORK4
ENDIF

IF (DYNSMAG) THEN
   TURB_WORK5=>M%TURB_WORK5
   TURB_WORK6=>M%TURB_WORK6
   TURB_WORK7=>M%TURB_WORK7
   TURB_WORK8=>M%TURB_WORK8
   TURB_WORK9=>M%TURB_WORK9
   TURB_WORK10=>M%TURB_WORK10
ENDIF
   
IF (DYNSMAG .OR. CHECK_KINETIC_ENERGY) THEN
   TURB_WORK11=>M%TURB_WORK11
   TURB_WORK12=>M%TURB_WORK12
ENDIF

IF (IMMERSED_BOUNDARY_METHOD==2) THEN
   IBM_SAVE1=>M%IBM_SAVE1
   IBM_SAVE2=>M%IBM_SAVE2
   IBM_SAVE3=>M%IBM_SAVE3
   IBM_SAVE4=>M%IBM_SAVE4
   IBM_SAVE5=>M%IBM_SAVE5
   IBM_SAVE6=>M%IBM_SAVE6
ENDIF

IF (IMMERSED_BOUNDARY_METHOD>=0) THEN
   U_MASK=>M%U_MASK
   V_MASK=>M%V_MASK
   W_MASK=>M%W_MASK
   P_MASK=>M%P_MASK
ENDIF

MESH_LEVEL=>M%MESH_LEVEL

MTR=>M%MTR
MSR=>M%MSR
WEM=>M%WEM

WALL_WORK1=>M%WALL_WORK1
WALL_WORK2=>M%WALL_WORK2
QQ=>M%QQ
PP=>M%PP
PPN=>M%PPN
IBK=>M%IBK
IBLK=>M%IBLK
DT=>M%DT
DT_PREV=>M%DT_PREV
DT_NEXT=>M%DT_NEXT
DT_INIT=>M%DT_INIT
CFL=>M%CFL
DIVMX=>M%DIVMX
VN=>M%VN
PART_CFL=>M%PART_CFL
RESMAX=>M%RESMAX
DIVMN=>M%DIVMN
ICFL=>M%ICFL
JCFL=>M%JCFL
KCFL=>M%KCFL 
IMX=>M%IMX
JMX=>M%JMX
KMX=>M%KMX
IMN=>M%IMN
JMN=>M%JMN
KMN=>M%KMN
IRM=>M%IRM
JRM=>M%JRM
KRM=>M%KRM
I_VN=>M%I_VN
J_VN=>M%J_VN
K_VN=>M%K_VN
N_EDGES=>M%N_EDGES
IJKE=>M%IJKE
EDGE_INDEX=>M%EDGE_INDEX
TAU_E=>M%TAU_E
OME_E=>M%OME_E
EDGE_TYPE=>M%EDGE_TYPE
IBAR=>M%IBAR
JBAR=>M%JBAR
KBAR=>M%KBAR 
IBM1=>M%IBM1
JBM1=>M%JBM1
KBM1=>M%KBM1 
IBP1=>M%IBP1
JBP1=>M%JBP1
KBP1=>M%KBP1 
RGB=>M%RGB
DXI=>M%DXI
DETA=>M%DETA
DZETA=>M%DZETA 
RDXI=>M%RDXI
RDETA=>M%RDETA
RDZETA=>M%RDZETA 
DXMIN=>M%DXMIN
DXMAX=>M%DXMAX 
DYMIN=>M%DYMIN
DYMAX=>M%DYMAX 
DZMIN=>M%DZMIN
DZMAX=>M%DZMAX 
CELL_SIZE=>M%CELL_SIZE
XS=>M%XS 
XF=>M%XF 
YS=>M%YS
YF=>M%YF 
ZS=>M%ZS 
ZF=>M%ZF 
RDXINT=>M%RDXINT
RDYINT=>M%RDYINT
RDZINT=>M%RDZINT 
R=>M%R
RC=>M%RC
X=>M%X
Y=>M%Y
Z=>M%Z 
XC=>M%XC
YC=>M%YC
ZC=>M%ZC
HX=>M%HX
HY=>M%HY
HZ=>M%HZ
DX=>M%DX
DY=>M%DY
DZ=>M%DZ 
DXN=>M%DXN
DYN=>M%DYN
DZN=>M%DZN
RDX=>M%RDX
RDY=>M%RDY
RDZ=>M%RDZ 
RDXN=>M%RDXN
RDYN=>M%RDYN
RDZN=>M%RDZN
CELLSI=>M%CELLSI
CELLSJ=>M%CELLSJ
CELLSK=>M%CELLSK 
RRN=>M%RRN
XPLT=>M%XPLT
YPLT=>M%YPLT
ZPLT=>M%ZPLT 
N_OBST=>M%N_OBST
OBSTRUCTION=>M%OBSTRUCTION
N_VENT=>M%N_VENT
VENTS=>M%VENTS
CELL_INDEX=>M%CELL_INDEX
I_CELL=>M%I_CELL
J_CELL=>M%J_CELL
K_CELL=>M%K_CELL
OBST_INDEX_C=>M%OBST_INDEX_C
WALL_INDEX=>M%WALL_INDEX
SOLID=>M%SOLID 
EXTERIOR=>M%EXTERIOR
N_INTERNAL_WALL_CELLS=>M%N_INTERNAL_WALL_CELLS
N_EXTERNAL_WALL_CELLS=>M%N_EXTERNAL_WALL_CELLS
N_VIRTUAL_WALL_CELLS=>M%N_VIRTUAL_WALL_CELLS
N_GHOST_WALL_CELLS=>M%N_GHOST_WALL_CELLS
CELL_COUNT=>M%CELL_COUNT
WALL_COUNTER=>M%WALL_COUNTER
BC_CLOCK=>M%BC_CLOCK
MASSFLUX=>M%MASSFLUX
MASSFLUX_ACTUAL=>M%MASSFLUX_ACTUAL
RHODW=>M%RHODW
ZZ_F=>M%ZZ_F
FW=>M%FW
TMP_F=>M%TMP_F
TMP_B=>M%TMP_B 
HEAT_TRANS_COEF=>M%HEAT_TRANS_COEF
UVW_SAVE=>M%UVW_SAVE
D_CORR=>M%D_CORR
DS_CORR=>M%DS_CORR
XW=>M%XW
YW=>M%YW
ZW=>M%ZW
TW=>M%TW
AWMPUA=>M%AWMPUA 
AWM_AEROSOL=>M%AWM_AEROSOL
AW=>M%AW
WMPUA=>M%WMPUA
WCPUA=>M%WCPUA
RAW=>M%RAW
UW0=>M%UW0
DUWDT=>M%DUWDT
RDN=>M%RDN
EW=>M%EW
KW=>M%KW 
QRADIN=>M%QRADIN
QRADOUT=>M%QRADOUT
QCONF=>M%QCONF
AREA_ADJUST=>M%AREA_ADJUST
RHO_F=>M%RHO_F
U_TAU=>M%U_TAU
E_WALL=>M%E_WALL
UW=>M%UW
UWS=>M%UWS
OBST_INDEX_W=>M%OBST_INDEX_W
VENT_INDEX=>M%VENT_INDEX
IBC_ORIG=>M%IBC_ORIG
IJKW=>M%IJKW
EDGE_INTERPOLATION_FACTOR=>M%EDGE_INTERPOLATION_FACTOR
BOUNDARY_TYPE=>M%BOUNDARY_TYPE
WALL_INDEX_BACK=>M%WALL_INDEX_BACK
NPPCW=>M%NPPCW
WALL=>M%WALL
OMESH=>M%OMESH
DROPLET =>M%DROPLET  
NLP=>M%NLP 
NLPDIM=>M%NLPDIM
HUMAN =>M%HUMAN  
N_HUMANS=>M%N_HUMANS  
N_HUMANS_DIM=>M%N_HUMANS_DIM
HUMAN_GRID =>M%HUMAN_GRID
N_SLCF=>M%N_SLCF
SLICE=>M%SLICE
INC=>M%INC
NPATCH=>M%NPATCH
UIID=>M%UIID 
RAD_CALL_COUNTER=>M%RAD_CALL_COUNTER
ANGLE_INC_COUNTER=>M%ANGLE_INC_COUNTER
INTERPOLATED_MESH => M%INTERPOLATED_MESH
STRING=>M%STRING 
N_STRINGS=>M%N_STRINGS 
N_STRINGS_MAX=>M%N_STRINGS_MAX
!rm ->
!DMPVDT_FM_VEG => M%DMPVDT_FM_VEG
K_AGL_SLICE   => M%K_AGL_SLICE
N_TERRAIN_SLCF=>M%N_TERRAIN_SLCF
VEG_CLOCK_BC  =>M%VEG_CLOCK_BC !surf veg
VEG_DRAG      =>M%VEG_DRAG !bndry fuel momentum drag
LS_Z_TERRAIN    =>M%LS_Z_TERRAIN !terrain height for level set fire spread
!rm <-
 
END SUBROUTINE POINT_TO_MESH

SUBROUTINE GET_REV_mesh(MODULE_REV,MODULE_DATE)
INTEGER,INTENT(INOUT) :: MODULE_REV
CHARACTER(255),INTENT(INOUT) :: MODULE_DATE

WRITE(MODULE_DATE,'(A)') meshrev(INDEX(meshrev,':')+1:LEN_TRIM(meshrev)-2)
READ (MODULE_DATE,'(I5)') MODULE_REV
WRITE(MODULE_DATE,'(A)') meshdate

END SUBROUTINE GET_REV_mesh

 
END MODULE MESH_POINTERS

