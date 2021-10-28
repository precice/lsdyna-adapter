      use common_data

      ! Here leave the include, common and dimension commands from LS-DYNA

      ! The following code should begin directly after the last declaration of variables
      ! It gets executed after every ls-dyna time step
      call precicef_write_bsdata(writeDataID, numberOfVertices,
     1 vertexIDs, writeData) ! make sure the `1` is in column 6


c _____________________________________________________________________
c|                                                                     |
c|    Check if ongoing                                                 |
c|_____________________________________________________________________|
      print *,'checkongoing'
      call precicef_is_coupling_ongoing(ongoing)
      print *,ongoing
      if (ongoing.eq.0) then

c _____________________________________________________________________
c|                                                                     |
c|      If coupling is over, finalise preCICE                          |
c|_____________________________________________________________________|
        print *,'finalize'
        call precicef_finalize()

c _____________________________________________________________________
c|                                                                     |
c|      Deallocate memory of arrays                                    |
c|_____________________________________________________________________|

        if (allocated (vertexIDs)) deallocate(vertexIDs)
        if (allocated (vertices)) deallocate(vertices)
        if (allocated (readData)) deallocate(readData)
        if (allocated (writeData)) deallocate(writeData)

c _____________________________________________________________________
c|                                                                     |
c|      Terminate LS-DYNA                                              |
c|_____________________________________________________________________|

        call adios(1)

      endif

      ! here the lsdyna function continues but everything until the next `end` can be removed
