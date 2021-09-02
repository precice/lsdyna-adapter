# preCICE Adapter for LS-DYNA
Author: Stefan Scheiblhofer, Stephan Jäger ([LKR Leichtmetallkompetenzzentrum Ranshofen GmbH](https://www.ait.ac.at/lkr))   
Contact: <matthias.hartmann@ait.ac.at>

This is the readme to develop a preCICE adapter for LS-DYNA.
The readme is based on preCICE V1.3.0 and LS-DYNA R9.3.0 in the
double SMP Version.

## Getting started

### LS-DYNA

The typical field of application for LS-DYNA is crash simulation and
rather oriented towards the explicit, mechanical solver. However, 
the finite element method based solver is often exhausted to its limits
in the case of the thermal solver. This is especially true with casting 
process simulations.  Thereby, the fluid
flow in the melt of the casting component has a significant impact
on the thermal field. This also depends on the components dimensions and process
parameters. However, this fluid flow cannot be considered with the FEM based LS-DYNA solver.
Consequently, the main idea behind the adapter for LS-DYNA is to import and use the
temperature field of an external solver. This should help to improve the
accuracy of the temperature field in the melt section, while still being able
to calculate the resulting strain and stress fields.  

### Prerequisites

preCICE is written in C++. However, preCICE also provides
APIs or bindings for non C++ codes. A list and current overview can be seen
[here](https://github.com/precice/precice/wiki/Non%E2%80%93standard-APIs).
In order to use preCICE within LS-DYNA there are some prerequisites,
which have to be met before implementing preCICE in LS-DYNA. 
After successful [installation](https://github.com/precice/precice/wiki/Building:-Using-CMake)
of preCICE it is necessary to link the preCICE library to LS-DYNA.
There are basically two ways to link preCICE to LS-DYNA: the first is linking
the static library; the second is linking the shared object library of preCICE to LS-DYNA.

#### Linking the static library

One of the simplest ways is to use the static library. The first step is to copy the static
library of preCICE *libprecice.a* to the LS-DYNA usermat package
directory. Second step is the implementation in LS-DYNA 
to change the Makefile for the LS-DYNA executable. This
starts by adding the dependencies of preCICE to the compiler flag *LF*:
```bash
LF= -i-static  -openmp -lrt -lstdc++ -lpthread -lboost_system -lboost_log -lboost_log_setup -lboost_thread -lboost_filesystem -lboost_program_options -lpython2.7 -lxml2
```
The next necessary adaption of the Makefile is adding *libprecice.a* at
the end of the the compiler flag `LIBS`.

#### Linking the shared object library

The recommended approach is to build preCICE as a shared object library.
Following the installation instructions on how to build preCICE, the default
install location for the shared object library is `/usr/local`. 
In contrast to [linking the static library](#linking-the-static-library), the
necessary changes to the Makefile are reduced to the compiler flag `LF`.
For linking the shared object library of preCICE change `LF` to the following:
```bash
LF= -i-static  -openmp -lrt -lstdc++ -lpthread -lboost_system -lboost_log -lboost_log_setup -lboost_thread -lboost_filesystem -lboost_program_options -lpython2.7 -lxml2 -I/usr/local/include -L/usr/local/lib -lprecice
```
The detailed description on how to edit the Make-file can be in the [precice wiki](https://github.com/precice/precice/wiki/Linking-to-preCICE#linking-from-make-or-other-scripts).

## Adapter design

LS-DYNA enables the user to define *user defined loads* via the keywords
`*USER_LOADING` and `*USER_LOADING_SET`. These keywords automatically
invoke the call of the subroutines *loadud* and *loadsetud* respectively.
The keyword `*USER_LOADING` defines parameters, which can then
be used by the keyword `*USER_LOADING_SET` and its subroutine *loadsetud*.
The loadings defined with the keyword `*USER_LOADING_SET` 
can be nodal forces, body forces, temperature distribution and pressure
on segments or beams. For the complete description of the keyword
please refer to the [LS-DYNA keyword manual Volume 1](http://ftp.lstc.com/anonymous/outgoing/jday/manuals/DRAFT_Vol_I.pdf).
Within the called subroutine *loadsetud*, which can be found
in the *dyn21.f*-file of the usermat-version of LS-DYNA,
it is possible to define the user-defined loads. The original
*dyn21.f*-file returns some examples on how to do that.

The subroutine *loadsetud* also enables the implementation of analytical
equations and/or import of externally solved data. With that in mind
and the capabilities of preCICE, it should then be possible to
couple an external solver to LS-DYNA.

The key issue, while designing an adapter for a proprietary code
as LS-DYNA, is finding the correct placement of the preCICE functions
within the available user interfaces. The placement of the preCICE 
functions has to be tested, to call the functions appropriatly relative 
to the placement of the subroutines within the source code of LS-DYNA.

The current development status of the preCICE adapter within LS-DYNA
uses two subroutines of LS-DYNA, which are *uctrl1* and *loadsetud*.
The subroutine *loadsetud* is called before calculating the
time step while *uctrl1* is called after each (mechanical) time step.
As the function calls are separated between two subroutines the
variable definitions for all (preCICE) relevant variables are located
in a general module. In this way, both subroutines can access the variables with
the same content.

For the goal of coupling temperature fields into LS-DYNA through the
keyword `*USER_LOADING_SET` and preCICE, *loadsetud* is called before
*uctrl1*. Consequently, the initialisation of preCICE
is realised within *loadsetud*. This is done once at the first call of the subroutine. 

The subroutine
*loadsetud* is also called before actually calculating the current
timestep. It is mandatory to read the vector
or scalar in here. In order to read the data
for the current timestep it is necessary to call
the precice function *advance*. This function call transfers the data between the solvers.   

While *loadsetud* intialises preCICE and reads data, *uctrl1* writes
vector or scalar data after the present timestep has been calculated.
Finally, preCICE is finalised in *uctrl1* which also includes the
termination of LS-DYNA.

The work flow of the preCICE adapter within LS-DYNA can be summmarised
with the following two flow chart diagrams. The blue boxes show the
functions and routines called in the subroutine *loadsetud*, while the
green boxes represent the subroutine *uctrl1*. White boxes are functions and
processes which are called by LS-DYNA. These cannot be interfered by the user.

![Work flow preCICE Adapter: Main](images/FlowChart_preCICE_LSDYNA_Adapter_Main.pdf)
![Work flow precice Adapter: Start preCICE](images/FlowChart_preCICE_LSDYNA_Adapter_start_precice.pdf)

The following code lines show the schematic overview of the 
the subroutines and the general module for the definition of the preCICE
relevant variables considering the blocks introduced by the flow
chart diagrams.

```fortran
      module common_data

      character*50 config
      character*50 participantName
      character*50 meshName

c     parameters for implicit coupling
      character*50 writeInitialData
      character*50 readItCheckp
      character*50 writeItCheckp

      integer rank
      integer commSize
      integer ongoing
      integer dimensions
      integer meshID
      integer tempID
      integer dummyID
      integer,save :: bool = 0

      real dtLimit

      integer, dimension(:), allocatable :: vertexIDs
      integer, dimension(:), allocatable :: nodeIDs

      double precision, dimension(:), allocatable :: coords
      double precision, dimension(:), allocatable :: temps
      double precision, dimension(:), allocatable :: dummyItCheckp
      double precision, dimension(:), allocatable :: dummy

      end module common_data 



      subroutine loadsetud(time,lft,llt,crv,iduls,parm,nod,nnm1)
	  
	  use common_data

      if (time.eq.0) then
c _____________________________________________________________________
c|                                                                     |
c|      Initialise variables                                           |
c|_____________________________________________________________________|
        config='precice-config.xml'
        participantName='solverMech'
        meshName='meshMech'
        rank=0
        commSize=1
c       number of nodes in current set should be given in parameter 1
c       which is equal to the first variable in keyword `*USER_LOADING`
        numNodesInSet=parm(1)
        writeInitialData=                                               &
     &'                                                  '
        reatItCheckp=                                                   &
     &'                                                  '
        writeItCheckp=                                                  &
     &'                                                  '

c _____________________________________________________________________
c|                                                                     |
c|      Create preCICE                                                 |
c|_____________________________________________________________________|

        call precicef_create(participantName,config,rank,commSize)

c _____________________________________________________________________
c|                                                                     |
c|      Initialise constants for implicit coupling                     |
c|_____________________________________________________________________|

        call precicef_action_write_initial_data(writeInitialData)
        call precicef_action_read_iter_checkp(readItCheckp)
        call precicef_action_write_iter_checkp(writeItCheckp)

c _____________________________________________________________________
c|                                                                     |
c|      Get dimensions of preCICE config file                          |
c|_____________________________________________________________________|

        call precicef_get_dims(dimensions)
c
c       After the variable dimensions was set, all arrays can be allocated
c
        allocate(vertexIDs(numNodesInSet))
        allocate(nodeIDs(numNodesInSet))
        allocate(temps(numNodesInSet))
        allocate(dummy(numNodesInSet))
        allocate(dummyItCheckp(numNodesInSet))
        allocate(coords(numNodesInSet*dimensions))

c _____________________________________________________________________
c|                                                                     |
c|      Get mesh ID from preCICE                                       |
c|_____________________________________________________________________|

        call precicef_get_mesh_id(meshName, meshID)

c _____________________________________________________________________
c|                                                                     |
c|      Get data ID(s) from preCICE                                    |
c|_____________________________________________________________________|

        call precicef_get_data_id('Temperature', meshID, tempID)
        call precicef_get_data_id('Dummy', meshID, dummyID)

c _____________________________________________________________________
c|                                                                     |
c|      Set vertices for preCICE                                       |
c|_____________________________________________________________________|

        call precicef_set_vertices(meshID, numNodesInSet, coords,vertexIDs)

c _____________________________________________________________________
c|                                                                     |
c|      Initialise preCICE                                             |
c|_____________________________________________________________________|

        call precicef_initialize(dtLimit)

c _____________________________________________________________________
c|                                                                     |
c|      Write initial data                                             |
c|_____________________________________________________________________|

        call precicef_is_action_required(writeInitialData, bool)
        if (bool.eq.1) then
          call precicef_write_bsdata(dummyID, numNodesInSet,vertexIDs, dummy)
          call precicef_fulfilled_action(writeInitialData)
        endif

c _____________________________________________________________________
c|                                                                     |
c|      Get initial data from preCICE                                  |
c|_____________________________________________________________________|

        call precicef_initialize_data()

c _____________________________________________________________________
c|                                                                     |
c|      Read initial data                                              |
c|_____________________________________________________________________|

        call precicef_read_bsdata(tempID, numNodesInSet, vertexIDs,temps)

c       save data for current timestep
        call precicef_is_action_required(writeItCheckp, bool)
        if (bool.eq.1) then
          dummyItCheckp=dummy
          call precicef_fulfilled_action(writeItCheckp)
        endif
      endif

      if (time.gt.0.AND.time.le.endtim) then

c _____________________________________________________________________
c|                                                                     |
c|      Advance to the next time step                                  |
c|_____________________________________________________________________|

        call precicef_advance(dtLimit)

c _____________________________________________________________________
c|                                                                     |
c|      Read data                                                      |
c|_____________________________________________________________________|

        call precicef_read_bsdata(tempID,numNodesInSet,vertexIDs,temps)
  
      endif

c     set temperatures for current block
      do i=lft,llt
        udl(i)=temps(i)
      enddo

      return
      end



      subroutine uctrl1 (numnp,ndof,time,dt1,dt2,prtc,pltc,frci,prto,
     . plto,frco,vt,vr,at,ar,ut,ur,xmst,xmsr,irbody,rbdyn,usrhv,
     . messag,totalm,cycle,idrint,mtype,mxrb,nrba,rbcor,x,rbv,nrbn,
     . nrb,xrb,yrb,zrb,axrb,ayrb,azrb,dtx,nmmat,rba,fvalnew,fvalold,
     . fvalmid,fvalnxt)

	  use common_data
c _____________________________________________________________________
c|                                                                     |
c|    Write data                                                       |
c|_____________________________________________________________________|

      call precicef_write_bsdata(dummyID, numNodesInSet,vertexIDs, dummy)

c _____________________________________________________________________
c|                                                                     |
c|    Check if ongoing                                                 |
c|_____________________________________________________________________|

      call precicef_is_coupling_ongoing(ongoing)

      if (ongoing.eq.0) then

c _____________________________________________________________________
c|                                                                     |
c|      Finalise preCICE                                               |
c|_____________________________________________________________________|

        call precicef_finalize()

c _____________________________________________________________________
c|                                                                     |
c|      Deallocate memory of arrays                                    |
c|_____________________________________________________________________|

        if (allocated (vertexIDs)) deallocate(vertexIDs)
        if (allocated (nodeIDs)) deallocate(nodeIDs)
        if (allocated (coords)) deallocate(coords)
        if (allocated (temps)) deallocate(temps)
        if (allocated (dummy)) deallocate(dummy)
        if (allocated (dummyItCheckp)) deallocate(dummyItCheckp)

c _____________________________________________________________________
c|                                                                     |
c|      Terminate LS-DYNA                                              |
c|_____________________________________________________________________|

        call adios(1)

      endif

      return
      end
```

## Limits and remarks

The developments of the adapter inside LS-DYNA have been tested and
promoted against the available OpenFOAM adapater. The results of the
developed test case have been published in the ECCOMAS Coupled
Problems 2019 [Proceedings](https://congress.cimne.com/coupled2019/frontal/doc/EbookCoupled2019.pdf).   
The presented preCICE adapter for LS-DYNA is based on an
implicit, two-way-coupling. The
two-way-coupling was the more beneficial way to receive correct values for the
data initialisation at *time = 0* and at the end of the simulation at
*time = endtime*. As a result, the present adapter writes dummy values as a second variable.  
The participant's name, configuration file name, mesh name, as well as 
data names are hard-coded within the subroutines. A more general approach
would be nice, but have not been the goal of these developments
for the LS-DYNA adapter.
