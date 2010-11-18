package net.tinyos.dviz;

import java.util.LinkedList;
import java.util.HashMap;
import java.util.Date;
import org.apache.log4j.Logger;

public class Mote {
    
	private static Logger log = Logger.getLogger("net.tinyos.dviz.Mote");

	Driver driver;
	private int id;

	private Date startDate;	
	private Date lastSeenDate;
	
	private Mote parent;
    private HashMap<String,Double> status;
	
	public Mote(Driver d, int moteid) {
		driver = d;
		id = moteid;
		startDate = lastSeenDate = null;

		parent = null;
        status = new HashMap<String,Double>();
	}

    public void newMessage(long timestamp, String id, LinkedList<Double> args) {
        IdType type = driver.getType(id);

		log.trace("New debug message " + id + " with type " + type);

        if(startDate==null) {
            startDate = new Date(timestamp);;
            lastSeenDate = new Date(startDate.getTime());
        } else {
            lastSeenDate = new Date(timestamp);
        }

        if(id.equals(driver.getParentId()) && driver.getParentArg()<args.size()) {
            if(parent==null || args.get(driver.getParentArg())!=parent.getId()) {
				parent = driver.getMote(args.get(driver.getParentArg()).intValue());
			}
        }

        switch(type) {
        case COUNT:
            if(status.get(id)==null) {
                status.put(id, (double)1);
            } else {
                status.put(id, status.get(id)+1L);
            }
            break;
        case ACCUMULATE:
            if(type.getArg()>=0 && type.getArg()<args.size()) {
                if(status.get(id)==null) {
                    status.put(id, args.get(type.getArg()));
                } else {
                    status.put(id, status.get(id)+args.get(type.getArg()));
                }
            } else {
                log.error("Invalid type " + type + " for id " + id);
            }
            break;            
        case LATEST:
            if(type.getArg()>=0 && type.getArg()<args.size()) {
                status.put(id, args.get(type.getArg()));
            } else {
                log.error("Invalid type " + type + " for id " + id);
            }
            break;            
        }

            /*
            switch(message.get_type()) {
		case Debug.DEBUG_STARTED:
			nextSeqno = 0;
			clearRecent();
			initializations++;
			//if(driver.isVerbose()) log.info("Debug Started");
			break;			
		case RoutingDebug.DEBUG_SENT_MSG:
			int p = message.get_arg3();
			if(parent==null || p!=parent.getId()) {
				parent = driver.getMote(p);
				parentChanges++;
			}
			send++;
			//if(driver.isVerbose()) log.info(id + " send message to " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_RECEIVED_MSG:
			received++;
			//if(driver.isVerbose()) log.info(id + " received message from " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_FORWARD_MSG:
			forwarded++;
			//if(driver.isVerbose()) log.info(id + " forwarded message to " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_ARRIVED_MSG:
			arrived++;
			//if(driver.isVerbose()) log.info(id + " arrived message from " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_DISCARDED_MSG:
			discarded++;
			//if(driver.isVerbose()) log.info(id + " discarded message from " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_FE_SENDDONE_FAIL_ACK_FWD:
		case RoutingDebug.DEBUG_FE_SENDDONE_FAIL_ACK_SEND:
			failed_ack++;
			//if(driver.isVerbose()) log.info(id + " failed message to " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_FE_SENDDONE_WAITACK:
			wait_ack++;
			//if(driver.isVerbose()) log.info(id + " waiting ack for message to " + message.get_arg3() + " originated at " + message.get_arg2() + " with seqno " + message.get_arg1());
			break;
		case RoutingDebug.DEBUG_RECEIVED_BEACON:
			received_beacon++;
			//if(driver.isVerbose()) log.info(id + " beacon received");
			break;
		case RoutingDebug.DEBUG_SENT_BEACON:
			send_beacon++;
			//if(driver.isVerbose()) log.info(id + " beacon sent");
			break;
		case RoutingDebug.DEBUG_FE_DUPLICATE_CACHE:
			duplicateCache++;
			break;
		case RoutingDebug.DEBUG_FE_DUPLICATE_QUEUE:
			duplicateQueue++;
			
		case RoutingDebug.DEBUG_FE_SEND_BUSY:
			busy++;
			break;
		case RoutingDebug.DEBUG_FE_SENDDONE_FAIL:
			failed++;
			break;
		case RoutingDebug.DEBUG_FE_MSG_POOL_EMPTY:
			messagePoolEmpty++;
			break;
		case RoutingDebug.DEBUG_FE_SEND_QUEUE_FULL:
			sendQueueFull++;
			break;
		case RoutingDebug.DEBUG_FE_NO_ROUTE:
			noRoute++;
			break;
		case RoutingDebug.DEBUG_FE_SUBSEND_OFF:
			subSendOff++;
			break;
		case RoutingDebug.DEBUG_FE_BAD_SENDDONE:
			badSendDone++;
			break;
		case RoutingDebug.DEBUG_FE_SUBSEND_SIZE:
			subSendSize++;
			break;
		case RoutingDebug.DEBUG_FE_SUBSEND_BUSY:
			subSendBusy++;
			break;
		case RoutingDebug.DEBUG_FE_SEND_QUEUE_EMPTY:
		case RoutingDebug.DEBUG_FE_LOOP_DETECTED:
			break;
			
		case RoutingDebug.DEBUG_LINK_QUALITY:
			if(parent!=null && message.get_arg1()==parent.getId()) {
				parentMetric = message.get_arg2();
			}
			break;
		case Debug.DEBUG_BATTERY:
				batteryLevel = ((message.get_arg1()<<48) + (message.get_arg2()<<32) + (message.get_arg3()<<16) + message.get_arg4())/32768;
			//if(driver.isVerbose()) log.info("battey level for " +id+ " set to " + batteryLevel);
			break;
		case RoutingDebug.DEBUG_VALUE:
				value1 = message.get_arg1();
				value2 = message.get_arg2();
				value3 = message.get_arg3();
				value4 = message.get_arg4();

		default:
				log.debug("Unknown debug message from " + id + " with type " + message.get_type() + " and args " + message.get_arg1() + " " + message.get_arg2() + " " + message.get_arg3() + " " + message.get_arg4());
                }*/
    }
	    
	public String toString() {
		return "" + id;
	}
		
	public int getId() {
		return id;
	}
	
	public Mote getParent() {
		return parent;
	}

    public HashMap<String,Double> getStatus() {
        return status;
    }
	
	public Date getStartDate() {
		return startDate;
	}
	
	public Date getLastSeenDate() {
		return lastSeenDate;
	}
	
}
