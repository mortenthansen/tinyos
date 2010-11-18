import sys

from tinyos.tossim.TossimHelp import *
from TOSSIM import *

t = Tossim([])
sf = SerialForwarder(9003)
throttle = Throttle(t, 10)

nodes = loadLinkModel(t, "topo.txt")
loadNoiseModel(t, "meyer.txt", nodes)

# Set debug channels
print "Setting debug channels..."
t.addChannel("App", sys.stdout);

t.addChannel("Debug.debug", sys.stdout);
t.addChannel("Debug.error", sys.stdout);

#t.addChannel("DebugSender.debug", sys.stdout);
t.addChannel("DebugSender.error", sys.stdout);

initializeNodes(t, nodes)
sf.process();
throttle.initialize();

print "Running simulation (press Ctrl-c to stop)..."
try:    
    while True:
#    for i in range(100):
        throttle.checkThrottle();
        t.runNextEvent();
        sf.process();

except KeyboardInterrupt:
  print "Closing down simulation!"
#  throttle.printStatistics() 
