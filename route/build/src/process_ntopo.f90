module process_ntopo

! data types
USE nrtype                             ! variable types, etc.
USE nrtype,    only : integerMissing   ! missing value for integers
USE dataTypes, only : var_ilength      ! integer type:          var(:)%dat
USE dataTypes, only : var_dlength      ! double precision type: var(:)%dat

! global vars
USE public_var                         ! public variables

! global parameters
USE globalData, only : RPARAM          ! Reach parameters
USE globalData, only : NETOPO          ! Network topology

! named variables
USE var_lookup,only:ixSEG              ! index of variables for the stream segments
USE var_lookup,only:ixNTOPO            ! index of variables for the network topology

implicit none

! privacy -- everything private unless declared explicitly
private
public::ntopo

contains

 ! *********************************************************************
 ! public subroutine: read and process river network data
 ! *********************************************************************
 subroutine ntopo(&
                  ! output: model control
                  nHRU,             & ! number of HRUs
                  nSeg,             & ! number of stream segments
                  ! output: populate data structures
                  structHRU,        & ! ancillary data for HRUs
                  structSeg,        & ! ancillary data for stream segments
                  structHRU2seg,    & ! ancillary data for mapping hru2basin
                  structNTOPO,      & ! ancillary data for network toopology
                  ! output: error control
                  ierr, message)
 ! external subroutines : I/O
 use read_streamSeg,  only:getData               ! get the ancillary data
 use write_streamSeg, only:writeData             ! write the ancillary data
 ! external subroutines : network topology
 use network_topo,    only:hru2segment           ! get the mapping between HRUs and segments
 use network_topo,    only:up2downSegment        ! get the mapping between upstream and downstream segments
 use network_topo,    only:reach_list            ! reach list
 use network_topo,    only:reach_mask            ! identify all reaches upstream of a given reach
 use network_topo,    only:reachOrder            ! define the processing order
 ! This subroutine 1) read river network data and 2) populate river network topology data strucutres
 implicit none
 ! output: model control
 integer(i4b)      , intent(out)              :: nHRU             ! number of HRUs
 integer(i4b)      , intent(out)              :: nSeg             ! number of stream segments
 ! output: populate data structures
 type(var_dlength) , intent(out), allocatable :: structHRU(:)     ! HRU properties
 type(var_dlength) , intent(out), allocatable :: structSeg(:)     ! stream segment properties
 type(var_ilength) , intent(out), allocatable :: structHRU2seg(:) ! HRU-to-segment mapping
 type(var_ilength) , intent(out), allocatable :: structNTOPO(:)   ! network topology
 ! output: error control
 integer(i4b)      , intent(out)              :: ierr             ! error code
 character(*)      , intent(out)              :: message          ! error message
 ! --------------------------------------------------------------------------------------------------------------
 ! local variables
 character(len=strLen)           :: cmessage           ! error message of downwind routine
 integer(i4b)                    :: iSeg               ! indices for stream segment
 integer(i4b)                    :: iUps               ! indices of upstream segments
 integer(i4b)                    :: nUps               ! number of immediate upstream segments
 integer(i4b)                    :: tot_upstream       ! total number of all of the upstream stream segments for all stream segments
 integer(i4b)                    :: tot_upseg          ! total number of immediate upstream segments for all  stream segments
 integer(i4b)                    :: tot_hru            ! total number of all the upstream hrus for all stream segments
 integer(i4b)   , allocatable    :: ixHRU_desired(:)   ! indices of desired hrus
 integer(i4b)   , allocatable    :: ixSeg_desired(:)   ! indices of desired reaches
 integer*8                       :: time0,time1        ! times

 ! initialize error control
 ierr=0; message='ntopo/'

 ! initialize times
 call system_clock(time0)

 ! ---------- read in the stream segment information ---------------------------------------------------------

 ! get the number of HRUs and stream segments (needed for allocate statements)
 call getData(&
              ! input
              trim(ancil_dir)//trim(fname_ntopOld), & ! input: file name
              dname_nhru,   & ! input: dimension name of the HRUs
              dname_sseg,   & ! input: dimension name of the stream segments
              ! output: model control
              nHRU,         & ! output: number of HRUs
              nSeg,         & ! output: number of stream segments
              ! output: populate data structures
              structHRU,    & ! ancillary data for HRUs
              structSeg,    & ! ancillary data for stream segments
              structHRU2seg,& ! ancillary data for mapping hru2basin
              structNTOPO,  & ! ancillary data for network topology
              ! output: error control
              ierr,cmessage) ! output: error control
 if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

 ! get timing
 call system_clock(time1)
 write(*,'(a,1x,i20)') 'after getData: time = ', time1-time0

 ! ---------- get the mapping between HRUs and segments ------------------------------------------------------

 ! check the need to compute network topology
 if(topoNetworkOption==compute)then

  ! get the mapping between HRUs and basins
  call hru2segment(&
                   ! input
                   nHRU,          & ! input: number of HRUs
                   nSeg,          & ! input: number of stream segments
                   ! input-output: data structures
                   structHRU,     & ! ancillary data for HRUs
                   structSeg,     & ! ancillary data for stream segments
                   structHRU2seg, & ! ancillary data for mapping hru2basin
                   structNTOPO,   & ! ancillary data for network toopology
                   ! output
                   tot_hru,    &   ! output: total number of all the upstream hrus for all stream segments
                   ierr, cmessage) ! output: error control

  ! get timing
  call system_clock(time1)
  write(*,'(a,1x,i20)') 'after hru2segment: time = ', time1-time0

 endif  ! if need to compute network topology

 ! ---------- get the mapping between upstream and downstream segments ---------------------------------------

 ! check the need to compute network topology
 if(topoNetworkOption==compute)then

  ! get the mapping between upstream and downstream segments
  call up2downSegment(&
                      ! input
                      nSeg,          & ! input: number of stream segments
                      ! input-output: data structures
                      structNTOPO,   & ! ancillary data for network toopology
                      ! output
                      tot_upseg,     & ! output: sum of immediate upstream segments
                      ierr, cmessage)  ! output: error control
  if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

  ! get timing
  call system_clock(time1)
  write(*,'(a,1x,i20)') 'after up2downSegment: time = ', time1-time0

 endif  ! if need to compute network topology

 ! ---------- get the list of all upstream reaches above a given reach ---------------------------------------

 ! get the list of all upstream reaches above a given reach
 call reach_list(&
                 ! input
                 nSeg,                        & ! Number of reaches
                 structNTOPO,                 & ! Network topology
                 (computeReachList==compute), & ! flag to compute the reach list
                 ! output
                 tot_upstream,                & ! Total number of upstream reaches for all reaches
                 ierr, cmessage)                ! Error control
 if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

 ! get timing
 call system_clock(time1)
 write(*,'(a,1x,i20)') 'after reach_list: time = ', time1-time0

 ! ---------- get indices of all segments above a prescribed reach ------------------------------------------

 ! identify all reaches upstream of a given reach
 call reach_mask(&
                 ! input
                 idSegOut,      &  ! input: reach index
                 structNTOPO,   &  ! input: network topology structures
                 nHRU,          &  ! input: number of HRUs
                 nSeg,          &  ! input: number of reaches
                 ! output: updated dimensions
                 tot_hru,       &  ! input+output: total number of all the upstream hrus for all stream segments
                 tot_upseg,     &  ! input+output: sum of immediate upstream segments
                 tot_upstream,  &  ! input+output: total number of upstream reaches for all reaches
                 ! output: dimension masks
                 ixHRU_desired, &  ! output: indices of desired hrus
                 ixSeg_desired, &  ! output: indices of desired reaches
                 ! output: error control
                 ierr, cmessage )  ! output: error control
 if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

 ! get timing
 call system_clock(time1)
 write(*,'(a,1x,i20)') 'after reach_mask: time = ', time1-time0

 print*, 'nDesire = ', size(ixHRU_desired)

 ! ---------- get the processing order -----------------------------------------------------------------------

 ! defines the processing order for the individual stream segments in the river network
 call REACHORDER(nSeg,         &   ! input:        number of reaches
                 structNTOPO,  &   ! input:output: network topology
                 ierr, cmessage)   ! output:       error control
 if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

 ! ---------- write network topology to a netcdf file -------------------------------------------------------

 ! check the need to compute network topology
 if(topoNetworkOption==compute .or. computeReachList==compute .or. idSegOut>0)then

  ! write data
  call writeData(&
                 ! input
                 trim(ancil_dir)//trim(fname_ntopNew), & ! input: file name
                 ! input: model control
                 tot_hru,       & ! input: total number of all the upstream hrus for all stream segments
                 tot_upseg,     & ! input: total number of immediate upstream segments for all  stream segments
                 tot_upstream,  & ! input: total number of all of the upstream stream segments for all stream segments
                 ! input: reach masks
                 ixHRU_desired, & ! input: indices of desired hrus
                 ixSeg_desired, & ! input: indices of desired reaches
                 ! input: data structures
                 structHRU,     & ! input: ancillary data for HRUs
                 structSeg,     & ! input: ancillary data for stream segments
                 structHRU2seg, & ! input: ancillary data for mapping hru2basin
                 structNTOPO,   & ! input: ancillary data for network topology
                 ! output: error control
                 ierr,cmessage) ! output: error control
  if(ierr/=0)then; message=trim(message)//trim(cmessage); return; endif

 endif  ! if writing the data

 ! ---------- temporary code: populate old data structures --------------------------------------------------

 ! allocate space
 allocate(RPARAM(nSeg), NETOPO(nSeg), stat=ierr)
 if(ierr/=0)then; message=trim(message)//'unable to allocate space for old data structures'; return; endif

 ! loop through stream segments
 do iSeg=1,nSeg

  ! ----- reach parameters -----

  ! copy data into the reach parameter structure
  RPARAM(iSeg)%RLENGTH = structSEG(iSeg)%var(ixSEG%length)%dat(1)
  RPARAM(iSeg)%R_SLOPE = structSEG(iSeg)%var(ixSEG%slope)%dat(1)
  RPARAM(iSeg)%R_MAN_N = structSEG(iSeg)%var(ixSEG%width)%dat(1)
  RPARAM(iSeg)%R_WIDTH = structSEG(iSeg)%var(ixSEG%man_n)%dat(1)

  ! compute variables
  RPARAM(iSeg)%BASAREA = sum(structSEG(iSeg)%var(ixSEG%hruArea)%dat)

  ! NOT USED: UPSAREA is not currently used, but could be useful...
  !        --> can loop through all upstream basins (in reach_list?)
  RPARAM(iSeg)%UPSAREA = realMissing  ! upstream area (zero if headwater basin)
  RPARAM(iSeg)%TOTAREA = realMissing  ! UPSAREA + BASAREA

  ! NOT USED: MINFLOW -- minimum environmental flow
  RPARAM(iSeg)%MINFLOW = structSEG(iSeg)%var(ixSEG%minFlow)%dat(1)

  ! ----- network topology -----

  ! reach indices
  NETOPO(iSeg)%REACHIX = structNTOPO(iSeg)%var(ixNTOPO%segIndex)%dat(1)     ! reach index (1, 2, 3, ..., nSeg)
  NETOPO(iSeg)%REACHID = structNTOPO(iSeg)%var(ixNTOPO%segId)%dat(1)        ! reach ID (unique reach identifier)

  ! downstream reach indices
  NETOPO(iSeg)%DREACHI = structNTOPO(iSeg)%var(ixNTOPO%downSegIndex)%dat(1) ! Immediate Downstream reach index
  NETOPO(iSeg)%DREACHK = structNTOPO(iSeg)%var(ixNTOPO%downSegId)%dat(1)    ! Immediate Downstream reach ID

  ! allocate space for upstream reach indices
  nUps = size(structNTOPO(iSeg)%var(ixNTOPO%upSegIds)%dat)
  allocate(NETOPO(iSeg)%UREACHI(nUps), NETOPO(iSeg)%UREACHK(nUps), NETOPO(iSeg)%goodBas(nUps), stat=ierr)
  if(ierr/=0)then; message=trim(message)//'unable to allocate space for upstream structures'; return; endif

  ! populate upstream data structures
  if(nUps>0)then
   do iUps=1,nUps   ! looping through upstream reaches
    NETOPO(iSeg)%UREACHI(iUps) = structNTOPO(iSeg)%var(ixNTOPO%upSegIndices)%dat(iUps)   ! Immediate Upstream reach indices
    NETOPO(iSeg)%UREACHK(iUps) = structNTOPO(iSeg)%var(ixNTOPO%upSegIds)%dat(iUps)       ! Immediate Upstream reach Ids
    NETOPO(iSeg)%goodBas(iUps) = (structNTOPO(iSeg)%var(ixNTOPO%goodBasin)%dat(iUps)==1) ! "good" basin
   end do  ! Loop through upstream reaches
  endif

  ! define the reach order
  NETOPO(iSeg)%RHORDER = structNTOPO(iSeg)%var(ixNTOPO%rchOrder)%dat(1)  ! Processing sequence

  ! NOT USED: lake parameters
  NETOPO(iSeg)%LAKE_IX = integerMissing  ! Lake index (0,1,2,...,nlak-1)
  NETOPO(iSeg)%LAKE_ID = integerMissing  ! Lake ID (REC code?)
  NETOPO(iSeg)%BASULAK = realMissing     ! Area of basin under lake
  NETOPO(iSeg)%RCHULAK = realMissing     ! Length of reach under lake
  NETOPO(iSeg)%LAKINLT = .false.         ! .TRUE. if reach is lake inlet, .FALSE. otherwise
  NETOPO(iSeg)%USRTAKE = .false.         ! .TRUE. if user takes from reach, .FALSE. otherwise

  ! NOT USED: Location (available in the input files)
  NETOPO%RCHLAT1 = realMissing ! Start latitude
  NETOPO%RCHLAT2 = realMissing ! End latitude
  NETOPO%RCHLON1 = realMissing ! Start longitude
  NETOPO%RCHLON2 = realMissing ! End longitude

  ! NOT USED: time delay histogram
  allocate(NETOPO(iSeg)%UPSLENG(0), NETOPO(iSeg)%UH(0), stat=ierr)
  if(ierr/=0)then; message=trim(message)//'unable to allocate space for time delay histogram'; return; endif

 end do  ! looping through stream segments

 end subroutine ntopo

end module process_ntopo
