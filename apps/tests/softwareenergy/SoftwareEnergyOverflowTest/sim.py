import sys

from TOSSIM import *
from tinyos.tossim.TossimHelp import *

t = Tossim([])

nodes = loadLinkModel(t, "topo.txt")
loadNoiseModel(t, "meyer.txt", nodes)

# Set debug channels
print "Setting debug channels..."
t.addChannel("App", sys.stdout);
t.addChannel("SoftwareEnergy.debug", sys.stdout);
t.addChannel("SoftwareEnergy.error", sys.stdout);

initializeNodes(t, nodes)

print "Running simulation (press Ctrl-c to stop)..."
try:    
#    while True:
    for i in range(200):
        t.runNextEvent();

except KeyboardInterrupt:
  print "Closing down simulation!"
