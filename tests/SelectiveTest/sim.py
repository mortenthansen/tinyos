import sys
import time

from TOSSIM import *
from TossimHelp import *

t = Tossim([])
sf = SerialForwarder(9002)
throttle = Throttle(t, 10)
nodecount = loadLinkModel(t, "linkgain.out")
loadNoiceModel(t, "meyer.txt", nodecount)

# Set debug channels
print "Setting debug channels..."
#t.addChannel("Collection.debug", sys.stdout);
t.addChannel("Collection.error", sys.stdout);
#t.addChannel("Forwarder", sys.stdout);

t.addChannel("DebugSender.error", sys.stdout);
t.addChannel("Debug", sys.stdout);

initializeNodes(t, nodecount)
sf.process();
throttle.initialize();

print "Running simulation (press Ctrl-c to stop)..."
try:
    while True:
        throttle.checkThrottle();
        t.runNextEvent();
        sf.process();
except KeyboardInterrupt:
  print "Closing down simulation!"
  #throttle.printStatistics() 
