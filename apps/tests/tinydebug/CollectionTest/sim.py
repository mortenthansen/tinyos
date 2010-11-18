import sys
import time

from TOSSIM import *
from tinyos.tossim.TossimHelp import *

t = Tossim([])
sf = SerialForwarder(9002)
throttle = Throttle(t, 10)
#nodes = loadLinkModel(t, "topo.out")
nodes = loadLinkModel(t, "linkgain.out")
loadNoiseModel(t, "meyer.txt", nodes)

t.randomSeed(2)

# Set debug channels
print "Setting debug channels..."
#t.addChannel("App", sys.stdout);
#t.addChannel("Collection", sys.stdout);

#t.addChannel("TREE_SENT_BEACON", sys.stdout);

#t.addChannel("DebugSender.debug", sys.stdout);
t.addChannel("DebugSender.error", sys.stdout);
#t.addChannel("Debug.debug", sys.stdout);
t.addChannel("Debug.error", sys.stdout);

time.sleep(2)

initializeNodes(t, nodes)
sf.process();
throttle.initialize();

print "Running simulation (press Ctrl-c to stop)..."
try:
#    for i in range(1,500):
    while True:
#        throttle.checkThrottle();
        t.runNextEvent();
        sf.process();
except KeyboardInterrupt:
  print "Closing down simulation!"
  #throttle.printStatistics() 
