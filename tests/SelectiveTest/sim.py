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
#t.addChannel("MoteStats", sys.stdout);
#t.addChannel("SoftwareEnergy.debug", sys.stdout);

t.addChannel("Selective", sys.stdout);
#t.addChannel("RadioSoftware", sys.stdout);
#t.addChannel("StaticRoute", sys.stdout);

t.addChannel("Debug.error", sys.stdout);

t.addChannel("LOCALTIME", sys.stdout);

initializeNodes(t, nodes)
sf.process();
throttle.initialize();

time.sleep(2)

print "Running simulation (press Ctrl-c to stop)..."
try:
    while True:
#    for i in range(1,5000):
#        throttle.checkThrottle();
        t.runNextEvent();
        sf.process();
except (KeyboardInterrupt, SystemExit):
  print "Closing down simulation!"
  #throttle.printStatistics() 
