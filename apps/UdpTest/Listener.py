
import socket
import re
import sys
import struct

port = 7000

def pack(data):
    pdata = ''
    for i in range(len(data)):
        pdata += struct.pack("!l", data[i])
    return pdata

def unpack(pdata):
    data = []
    l = len(pdata)/4
    for i in range(l):
        data.append(struct.unpack("!l", pdata[i*4:i*4+4])[0])
    return data

if __name__ == '__main__':

    rsock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    ssock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    rsock.bind(('', port))

    while True:
        pdata, addr = rsock.recvfrom(1024)
        if (len(pdata) > 0):
            
            data = unpack(pdata)

            print addr
            print "incomming:", pdata
            print "data:", data
            if data[0]==42:
                print "Responding..."
                ssock.sendto(pack([51, 52]),("fec0::3", 7000))

            
            
            




