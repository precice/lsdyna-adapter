      ! The subroutine should start with this
      use common_data

      ! Here leave the include, common and dimension commands from LS-DYNA
      ! You have to use the endtim variable, therefore the command for using it can be copied from uctrl1 where it is already in place

      ! The following could e.g. replace the long comment in the `dyn21.f` file
c
c     Initial setup of preCICE at the start of the simulation
c

      if (time.eq.0) then

        config='../precice-config.xml'
        participantName='SolverOne'
        meshName='MeshOne'

        if(participantName .eq. 'SolverOne') then
              writeDataName = 'dataOne'
              readDataName = 'dataTwo'
        endif
        if(participantName .eq. 'SolverTwo') then
              writeDataName = 'dataTwo'
              readDataName = 'dataOne'
        endif

        rank=0
        commSize=1
c       number of nodes in current set should be given in parameter 1
c       which is equal to the first variable in keyword `*USER_LOADING`
        numberOfVertices=parm(1)

c       Create preCICE                                                 

        call precicef_create(participantName,config,rank,commSize)


        call precicef_get_dims(dimensions)


        allocate(vertices(numberOfVertices*dimensions))
        allocate(vertexIDs(numberOfVertices))
        allocate(readData(numberOfVertices))
        allocate(writeData(numberOfVertices))



        call precicef_get_mesh_id(meshName,meshID)

        ! make sure all line breaks continue in column 6
        call precicef_set_vertices(meshID,numberOfVertices,
     1 vertices,vertexIDs)
        

        call precicef_get_data_id(readDataName,meshID,readDataID)

        call precicef_get_data_id(writeDataName,meshID,writeDataID)

c       initialize preCICE
 
        call precicef_initialize(dt)
        ! here, does there need to be a differentiation between
        ! precice and lsdyna timesteps?


        call precicef_read_bsdata(readDataID,numberOfVertices,
     1 vertexIDs,readData)



      endif

c
c     The following code is executed *before* each time step
c
      
        if (time.gt.0.AND.time.le.endtim) then

        call precicef_read_bsdata(readDataID,numberOfVertices,
     1 vertexIDs,readData)




        call precicef_advance(dt)
      endif

      ! in the following loop the load can be applied to the model in LS-DYNA