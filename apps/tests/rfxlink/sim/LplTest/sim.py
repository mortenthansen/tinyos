import sys

from TOSSIM import *
from tinyos.tossim.TossimHelp import *

t = Tossim([])
#sf = SerialForwarder(9002)
#throttle = Throttle(t, 10)

nodes = loadLinkModel(t, "topo.txt")
loadNoiseModel(t, "meyer.txt", nodes)

# Set debug channels
print "Setting debug channels..."
t.addChannel("App", sys.stdout);
#t.addChannel("LplTest", sys.stdout);
#t.addChannel("Cpm", sys.stdout);

#t.addChannel("RadioAlarm.trace", sys.stdout);
#t.addChannel("RadioAlarm.debug", sys.stdout);
t.addChannel("RadioAlarm.error", sys.stdout);

#t.addChannel("Driver.trace", sys.stdout);
t.addChannel("Driver.debug", sys.stdout);
t.addChannel("Driver.error", sys.stdout);

#t.addChannel("CC2420Transmit", sys.stdout);
#t.addChannel("PowerCycle", sys.stdout);
#t.addChannel("CC2420Receive", sys.stdout);
#t.addChannel("CC2420Csma", sys.stdout);
#t.addChannel("CpmModelC", sys.stdout);


initializeNodes(t, nodes)
#sf.process();
#throttle.initialize();

print "Running simulation (press Ctrl-c to stop)..."
try:    
#    while True:
    for i in range(4000):
#        throttle.checkThrottle();
        t.runNextEvent();
#        sf.process();

except KeyboardInterrupt:
  print "Closing down simulation!"
#  throttle.printStatistics() 
