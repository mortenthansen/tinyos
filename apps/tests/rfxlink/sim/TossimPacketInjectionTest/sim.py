import sys

from TOSSIM import *
from tinyos.tossim.TossimHelp import *
from InjectionMsg import *
from array import *

t = Tossim([])

nodes = loadLinkModel(t, "topo.txt")
loadNoiseModel(t, "meyer.txt", nodes)

# Set debug channels
print "Setting debug channels..."
t.addChannel("App", sys.stdout);

initializeNodes(t, nodes)

print DEFAULT_MESSAGE_SIZE

dest = 2
data = []
for d in range(DEFAULT_MESSAGE_SIZE):
    data.append(d)

print "Running simulation (press Ctrl-c to stop)..."
try:
    for i in range(10):
        for j in range(200):
            t.runNextEvent();

        print "Injecting message"
        msg = InjectionMsg()
        msg.set_data(data)
        pkt = t.newPacket()
        pkt.setData(msg.data)
        pkt.setType(msg.get_amType())
        pkt.setDestination(dest)
        pkt.deliver(dest,t.time())


except KeyboardInterrupt:
  print "Closing down simulation!"
#  throttle.printStatistics() 
