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

t.addChannel("App.debug", sys.stdout);
t.addChannel("App.error", sys.stdout);

#t.addChannel("AM.debug", sys.stdout);
t.addChannel("AM.error", sys.stdout);

#t.addChannel("SendResource.trace", sys.stdout);
#t.addChannel("SendResource.debug", sys.stdout);
t.addChannel("SendResource.error", sys.stdout);

#t.addChannel("DataAck.trace", sys.stdout);
t.addChannel("DataAck.debug", sys.stdout);
t.addChannel("DataAck.error", sys.stdout);

t.addChannel("SoftAck.debug", sys.stdout);
t.addChannel("SoftAck.error", sys.stdout);

#t.addChannel("Driver.debug", sys.stdout);
t.addChannel("Driver.error", sys.stdout);

initializeNodes(t, nodes)
#sf.process();
#throttle.initialize();

print "Running simulation (press Ctrl-c to stop)..."
try:    
#    while True:
    for i in range(8000):
#        throttle.checkThrottle();
        t.runNextEvent();
#        sf.process();

except KeyboardInterrupt:
  print "Closing down simulation!"
#  throttle.printStatistics() 
