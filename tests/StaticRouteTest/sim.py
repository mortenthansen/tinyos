import sys
import time

from TOSSIM import *
from tinyos.tossim.TossimHelp import *

t = Tossim([])
sf = SerialForwarder(9002)
throttle = Throttle(t, 10)
nodes = loadLinkModel(t, "linkgain.out")
loadNoiseModel(t, "meyer.txt", nodes)

# Set debug channels
print "Setting debug channels..."
t.addChannel("App", sys.stdout);
t.addChannel("StaticRoute", sys.stdout);

#t.addChannel("DebugSender.error", sys.stdout);
t.addChannel("Debug", sys.stdout);

initializeNodes(t, nodes)
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
