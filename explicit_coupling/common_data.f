      ! this module can be copied to the start of the `dyn21.f` file
      module common_data

      character*50 config
      character*50 participantName
      character*50 meshName

      character*50 readDataName
      character*50 writeDataName

      integer rank
      integer commSize
      integer ongoing
      integer dimensions
      integer meshID
      integer readDataID
      integer writeDataID
      integer,save :: bool = 0

      real dt

      integer, dimension(:), allocatable :: vertexIDs

      double precision, dimension(:), allocatable :: vertices
      double precision, dimension(:), allocatable :: readData
      double precision, dimension(:), allocatable :: writeData

      end module common_data 
