#include <iostream>
#include <sstream>
#include "precice/SolverInterface.hpp"

int main(int argc, char **argv)
{
  int commRank = 0;
  int commSize = 1;

  using namespace precice;
  using namespace precice::constants;

  if (argc != 4) {
    std::cout << "Usage: ./solverdummy configFile solverName meshName\n\n";
    std::cout << "Parameter description\n";
    std::cout << "  configurationFile: Path and filename of preCICE configuration\n";
    std::cout << "  solverName:        SolverDummy participant name in preCICE configuration\n";
    std::cout << "  meshName:          Mesh in preCICE configuration that carries read and write data\n";
    return 1;
  }

  std::string configFileName(argv[1]);
  std::string solverName(argv[2]);
  std::string meshName(argv[3]);

  std::cout << "DUMMY: Running solver dummy with preCICE config file \"" << configFileName << "\", participant name \"" << solverName << "\", and mesh name \"" << meshName << "\".\n";

  SolverInterface interface(solverName, configFileName, commRank, commSize);

  int         meshID     = interface.getMeshID(meshName);
  int         dimensions = interface.getDimensions();
  std::string dataWriteName;
  std::string dataReadName;
  int         numberOfVertices = 1;

  if (solverName == "SolverOne") {
    dataWriteName = "dataOne";
    dataReadName  = "dataTwo";
  }
  if (solverName == "SolverTwo") {
    dataReadName  = "dataOne";
    dataWriteName = "dataTwo";
  }
  const int readDataID  = interface.getDataID(dataReadName, meshID);
  const int writeDataID = interface.getDataID(dataWriteName, meshID);

  double readData{1};
  double writeData{2};
  std::vector<double> vertices(numberOfVertices * dimensions);
  std::vector<int>    vertexIDs(numberOfVertices);


  interface.setMeshVertices(meshID, numberOfVertices, vertices.data(), vertexIDs.data());

  double dt = interface.initialize();

  while (interface.isCouplingOngoing()) {

    if (interface.isActionRequired(actionWriteIterationCheckpoint())) {
      std::cout << "DUMMY: Writing iteration checkpoint\n";
      interface.markActionFulfilled(actionWriteIterationCheckpoint());
    }

    if (interface.isReadDataAvailable()) {
      interface.readBlockScalarData(readDataID, numberOfVertices, vertexIDs.data(), &readData);
      std::cout << "read: " << readData << "\n";
    }

    writeData = readData + 1;
    std::cout << "writeData: " << writeData << "\n";
    std::cout << "readData: " << readData << "\n";

    if (interface.isWriteDataRequired(dt)) {
      interface.writeBlockScalarData(writeDataID, numberOfVertices, vertexIDs.data(), &writeData);
      std::cout << "wrote:" << writeData << "\n";
    }

    dt = interface.advance(dt);

    if (interface.isActionRequired(actionReadIterationCheckpoint())) {
      std::cout << "DUMMY: Reading iteration checkpoint\n";
      interface.markActionFulfilled(actionReadIterationCheckpoint());
    } else {
      std::cout << "DUMMY: Advancing in time\n";
    }
  }

  interface.finalize();
  std::cout << "DUMMY: Closing C++ solver dummy...\n";

  return 0;
}
