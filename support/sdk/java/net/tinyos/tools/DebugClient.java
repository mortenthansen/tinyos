/*
 * Copyright (c) 2010 Aarhus University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Aarhus University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL AARHUS
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Morten Tranberg Hansen
 * @date   September 14 2010
 */

package net.tinyos.tools;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.io.*;
import java.util.*;
import java.lang.reflect.*;
import java.math.BigInteger;

public class DebugClient {

  private static final int OFFSET_SEQNO = 0;
  private static final int OFFSET_TIMESTAMP = 1;
  private static final int OFFSET_UID = 5;
  private static final int OFFSET_ARGS = 6;

  private static final String MISSING_ARG = "<missing arg>";

  private DebugProgram program;
  private boolean printer;
  private boolean showOther;

  public DebugClient() {

    ClassLoader classLoader = DebugClient.class.getClassLoader();

    try {
      Class debugClass = classLoader.loadClass("Debug");
      program = (DebugProgram) debugClass.newInstance();
    } catch (Exception e) {
      System.err.println("Could not load Debug.class: make sure its to be found in classpath which can be set with the -cp option.");
      //e.printStackTrace();
      System.exit(2);
    }

    printer = false;

  }

  public void setPrinter(boolean printer) {
    this.printer = printer;
  }

  public void setShowOther(boolean showOther) {
    this.showOther = showOther;
  }

  synchronized public void newPacket(int from, byte[] packet) {
    String seqno;
    String timestamp;
    String uid;
    String id;
    String format;

    /*for(int i=0; i<packet.length; i++) {
      System.out.print(" "+((int)packet[i]&0xFF));
      }
      System.out.println();*/

    try {
      seqno = getU8(packet, OFFSET_SEQNO);
      timestamp = getU32(packet, OFFSET_TIMESTAMP);

      uid = getU8(packet,OFFSET_UID);
      id = program.getChannelMap().get(uid);
      if(id==null) {
        System.err.println("ID for " + uid + " could not be found in Debug.class.");
        return;
      }
      id = id.replaceAll(",","__");

      format = program.getFormatMap().get(uid);
      if(format==null) {
        System.err.println("Format for " + uid + " could not be found in Debug.class.");
        return;
      }

      String[] data = getDebugData(format, packet, OFFSET_ARGS);

      //System.out.println("debug " + timestamp + " type " + type + " format " + format);

      if(printer) {
        System.out.print(data[0]);
      } else {
        System.out.print(""+(System.currentTimeMillis()-Long.valueOf(timestamp))+","+from+","+seqno+","+id);
        for(int i=1; i<data.length; i++) {
          System.out.print(","+data[i]);
        }
        System.out.println("");
      }

    } catch(IllegalArgumentException e) {
      System.err.println("illegal debug message format");
      e.printStackTrace();
    }

    //Dump.dump(System.out, "" + System.currentTimeMillis() + ":" + from, packet);
    /*} else if(showOther) {
    // Other message
    System.out.print("" + System.currentTimeMillis() + "," + from + ",");
    Dump.printPacket(System.out, packet);
    System.out.println();
    }*/
  }

  protected String[] getDebugData(String format, byte[] packet, int offset) {
    LinkedList<String> list = new LinkedList<String>();
    StringBuffer message = new StringBuffer();
    String value;

    boolean noMoreArgs = false;
    int index = 0;

    while(index<format.length()) {
      char c = format.charAt(index);
      if(c=='%') {

        if(noMoreArgs) {
          do {
            c = format.charAt(++index);
          } while(c=='l' || c=='h');
          index++;
          message.append(MISSING_ARG);
          continue;
        }

        try {
          switch(format.charAt(++index)) {
          case 'h':
            switch(format.charAt(++index)) {
            case 'h':
              switch(format.charAt(++index)) {
              case 'i':
                value = getI8(packet, offset);
                offset += 1;
                list.add(value);
                message.append(value);
                break;
              case 'u':
                value = getU8(packet, offset);
                offset += 1;
                list.add(value);
                message.append(value);
                break;
              case 'x':
                value = getH8(packet, offset);
                offset += 1;
                list.add(value);
                message.append(value);
                break;
              }
              break;
            case 'i':
              value = getI16(packet, offset);
              offset += 2;
              list.add(value);
              message.append(value);
              break;
            case 'u':
              value = getU16(packet, offset);
              offset += 2;
              list.add(value);
              message.append(value);
              break;
            case 'x':
              value = getH16(packet, offset);
              offset += 2;
              list.add(value);
              message.append(value);
              break;
            }
            break;
          case 'i':
            value = getI16(packet, offset);
            offset += 2;
            list.add(value);
            message.append(value);
            break;
          case 'u':
            value = getU16(packet, offset);
            offset += 2;
            list.add(value);
            message.append(value);
            break;
          case 'x':
            value = getH16(packet, offset);
            offset += 2;
            list.add(value);
            message.append(value);
            break;


          case 'l':
            switch(format.charAt(++index)) {
            case 'l':
              switch(format.charAt(++index)) {
              case 'i':
                value = getI64(packet, offset);
                offset += 8;
                list.add(value);
                message.append(value);
                break;
              case 'u':
                value = getU64(packet, offset);
                offset += 8;
                list.add(value);
                message.append(value);
                break;
              }
              break;
            case 'i':
              value = getI32(packet, offset);
              offset += 4;
              list.add(value);
              message.append(value);
              break;
            case 'u':
              value = getU32(packet, offset);
              offset += 4;
              list.add(value);
              message.append(value);
              break;
            case 'x':
              value = getH32(packet, offset);
              offset += 4;
              list.add(value);
              message.append(value);
              break;
            }
            break;


          case 'f':
            float f = Float.intBitsToFloat(getInt(packet, offset));
            value = Float.toString(f);
            offset += 4;
            list.add(value);
            message.append(value);
            break;

          case '%':
            message.append(c);
            break;
          }

        } catch (IllegalArgumentException e) {
          message.append(MISSING_ARG);
          noMoreArgs = true;
        }

      } else {
        message.append(c);
      }
      index++;
    }

    //              message.append("hej med dig");

    list.addFirst(message.toString());
    return list.toArray(new String[] {});
  }

  protected String getI8(byte[] packet, int offset) throws IllegalArgumentException {
    return Byte.toString(getByte(packet, offset));
  }

  protected String getU8(byte[] packet, int offset) throws IllegalArgumentException {
    return Integer.toString(getByte(packet, offset) & 0xFF);
  }

  protected String getH8(byte[] packet, int offset) throws IllegalArgumentException {
    String value = Integer.toHexString(getByte(packet, offset) & 0xFF);
    for(int i = value.length(); i<2; i++) {
      value = "0" + value;
    }
    value = "0x" + value;
    return value;
  }

  protected String getI16(byte[] packet, int offset) throws IllegalArgumentException {
    return Short.toString(getShort(packet, offset));
  }

  protected String getU16(byte[] packet, int offset) throws IllegalArgumentException {
    return Integer.toString(getShort(packet, offset) & 0xFFFF);
  }

  protected String getH16(byte[] packet, int offset) throws IllegalArgumentException {
    String value = Integer.toHexString(getShort(packet, offset) & 0xFFFF);
    for(int i = value.length(); i<4; i++) {
      value = "0" + value;
    }
    value = "0x" + value;
    return value;
  }

  protected String getI32(byte[] packet, int offset) throws IllegalArgumentException {
    return Integer.toString(getInt(packet, offset));
  }

  protected String getU32(byte[] packet, int offset) throws IllegalArgumentException {
    return Long.toString(getInt(packet, offset) & 0xFFFFFFFF);
  }

  protected String getH32(byte[] packet, int offset) throws IllegalArgumentException {
    String value = Long.toHexString(getInt(packet, offset) & 0xFFFFFFFF);
    for(int i = value.length(); i<8; i++) {
      value = "0" + value;
    }
    value = "0x" + value;
    return value;
  }

  protected String getI64(byte[] packet, int offset) throws IllegalArgumentException {
    return Long.toString(getLong(packet, offset));
  }

  protected String getU64(byte[] packet, int offset) throws IllegalArgumentException {
    return getBigInteger(packet, offset).toString();
  }

  protected byte getByte(byte[] packet, int offset) throws IllegalArgumentException {

    if( packet.length < offset + 1) {
      throw new IllegalArgumentException("illegal message format when getting byte from "+offset+" out of "+packet.length);
    }

    return packet[offset];
  }

  protected short getShort(byte[] packet, int offset) throws IllegalArgumentException {

    if( packet.length < offset + 2) {
      throw new IllegalArgumentException("illegal message format when getting short from "+offset+" out of "+packet.length);
    }

    short result = 0;
    result |= ((short)packet[offset+1] & 0x00FF);
    result |= ((short)packet[offset]   & 0x00FF) << 8;

    return result;
  }

  protected int getInt(byte[] packet, int offset) throws IllegalArgumentException {

    if( packet.length < offset + 4) {
      throw new IllegalArgumentException("illegal message format when getting int from "+offset+" out of "+packet.length);
    }

    int result = 0;

    result |= ((int)packet[offset+3] & 0x000000FF);
    result |= ((int)packet[offset+2] & 0x000000FF) << 8;
    result |= ((int)packet[offset+1] & 0x000000FF) << 16;
    result |= ((int)packet[offset]   & 0x000000FF) << 24;

    return result;
  }

  protected long getLong(byte[] packet, int offset) throws IllegalArgumentException {

    if( packet.length < offset + 8) {
      throw new IllegalArgumentException("illegal message format when getting long from offset "+offset+" out of "+packet.length);
    }

    long result = 0;
    result |= ((long)packet[offset+7]);
    result |= ((long)packet[offset+6] & 0x00000000000000FF) << 8;
    result |= ((long)packet[offset+5] & 0x00000000000000FF) << 16;
    result |= ((long)packet[offset+4] & 0x00000000000000FF) << 24;
    result |= ((long)packet[offset+3] & 0x00000000000000FF) << 32;
    result |= ((long)packet[offset+2] & 0x00000000000000FF) << 40;
    result |= ((long)packet[offset+1] & 0x00000000000000FF) << 48;
    result |= ((long)packet[offset]   & 0x00000000000000FF) << 56;
    return result;
  }

  protected BigInteger getBigInteger(byte[] packet, int offset) throws IllegalArgumentException {

    if( packet.length < offset + 8) {
      throw new IllegalArgumentException("illegal message format when getting long from offset "+offset+" out of "+packet.length);
    }

    byte[] b = new byte[9];
    for(int i=0; i<8; i++) {
      b[i+1] = packet[offset+i];
    }

    return new BigInteger(b);
  }

  /**
   * Forwarder class listenes for packets on a channel and notifies
   * the client whenever a full packet is received.
   */

  private static abstract class Forwarder extends Thread implements PacketListenerIF {

    public static final int RESSURRECTION_INTERVAL = 1;

    protected String source;
    protected DebugClient client;
    protected PhoenixSource psource;

    public Forwarder(String source, DebugClient client) {
      this.source = source;
      this.client = client;
    }

    public void run() {
      psource  = BuildSource.makePhoenix(source, net.tinyos.util.PrintStreamMessenger.err);
      if(psource==null) {
        System.err.println("Source " + source + " is not a valid.");
        System.exit(2);
      }
      psource.setResurrection();
      psource.setPacketErrorHandler(new PhoenixError() {
          public void error(IOException e) {
            System.err.println(psource.getPacketSource().getName() + " died - restarting");
            try {
              Thread.sleep(RESSURRECTION_INTERVAL);
            } catch (InterruptedException ie) { }
          }
        });

      psource.start();
      psource.registerPacketListener(this);
    }

  }

  private static class AMForwarder extends Forwarder {

    private static final byte AM_DEBUG_MSG = (byte)0xFE;
    private static final int HEADER_LENGTH = 9;
    private static final int OFFSET_SOURCE1 = 3;
    private static final int OFFSET_SOURCE2 = 4;
    private static final int OFFSET_AM = 7;
    private static final int OFFSET_FRAGMENT = 8;
    private static final int OFFSET_DATA = 9;

    private HashMap<Integer,LinkedList<Byte>> bufferMap;

    public AMForwarder(String source, DebugClient client) {
      super(source, client);
      bufferMap = new HashMap<Integer,LinkedList<Byte>>();
    }

    public void packetReceived(byte[] packet) {

      /*for(int i=0; i<packet.length; i++) {
        System.out.print(Integer.toString(packet[i] & 0xFF) + " ");
      }
      System.out.println();*/

      if(packet.length<HEADER_LENGTH) {
        System.err.println("AMforwarder received bad packet");
        return;
      } else if(packet[OFFSET_AM]==AM_DEBUG_MSG) {
        // Get fragment options
        int total = (packet[OFFSET_FRAGMENT] & 0xF0) >> 4;
        int current = (packet[OFFSET_FRAGMENT] & 0x0F);
        int source = (packet[OFFSET_SOURCE1] & 0xFF) << 8 | (packet[OFFSET_SOURCE2] & 0xFF);
        LinkedList<Byte> buffer = bufferMap.get(source);

        // If first packet heard from node, create buffer
        if(buffer==null) {
          buffer = new LinkedList<Byte>();
          bufferMap.put(source, buffer);
        }

        // If first fragment reset buffer
        if(current==0) {
          buffer.clear();
          // if first not received, ignore packet
        } else if(buffer.isEmpty()) {
          System.err.println("Buffer empty, but its not first fragment");
          return;
        }

        // Add packet to data.
        for(int i=OFFSET_DATA; i<packet.length; i++) {
          buffer.add(packet[i]);
        }

        // If last fragment, send to client and clear buffer/
        if(current==total-1) {
          byte[] data = new byte[buffer.size()];
          for(int i=0; i<data.length; i++) {
            data[i] = buffer.pop();
          }
          client.newPacket(source, data);
          buffer.clear();
        }
      }
    }
    
    public void extract() {
      System.out.println("Extracting..");
      // SERIAL_ID(1), DEST(2). SRC(2), LENGTH(1), GROUP(1), TYPE(1)
      byte[] packet = {0, (byte)255, (byte)255, 0, 0, 0, 0, (byte)AM_DEBUG_MSG};
      try {
        if(psource!=null) {
          psource.writePacket(packet);
        } else {
          System.err.println("Cannot extract when not connected.");
        }
      } catch(IOException e) {
        e.printStackTrace();
      }
    }

  }

  /**
   * Main method to start the debug client.
   */
  public static void main(String[] args) {
    String source = null;
    boolean print = false;
    boolean other = false;
    boolean extract = false;

    int a = 0;
    while(a<args.length) {
      if (args[a].equals("-comm")) {
        if(a+1<args.length) {
          a++;
          source = args[a];
        } else {
          usage();
          System.exit(1);
        }
      } else if(args[a].equals("-print")) {
        print = true;
      } else if(args[a].equals("-other")) {
        other = true;
      } else if(args[a].equals("-extract")) {
        extract = true;
      } else {
        usage();
        System.exit(1);
      }
      a++;
    }

    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
    String line;

    DebugClient client = new DebugClient();
    client.setPrinter(print);
    client.setShowOther(other);
    try {
      if(source!=null) {
        AMForwarder f = new AMForwarder(source, client);
        f.start();
        Thread.sleep(100);
        if(extract) {
          f.extract();
        }
      } else if(System.in.available()>0) {
        while((line=in.readLine())!=null) {
          AMForwarder f = new AMForwarder(line, client);
          f.start();
          // Delay creation of multiple threads so that
          // they can connect one at a time.
          Thread.sleep(100);
          if(extract) {
            f.extract();
          }
        };
      } else {
        AMForwarder f = new AMForwarder(Env.getenv("MOTECOM"), client);
        f.start();
        Thread.sleep(100);
        if(extract) {
          f.extract();
        }
      }
    } catch (IOException e) {
      e.printStackTrace();
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }

  private static void usage() {
    System.err.println("Usage: DebugClient [-print] [-comm <source>] [< <source-file>]");
  }


}

