package net.tinyos.dviz;

import org.apache.log4j.*;
import java.util.*;
import java.io.*;

public class Driver {

    private static String TYPE_PROPERTIES = "type.properties";
	private static Logger log = Logger.getLogger("net.tinyos.dviz.Driver");
	
	private Map<Integer,Mote> motes;
    private List<String> ids;
    private Properties types;
    private String parentId;
    private int parentArg;

	public Driver(String parentId, int parentArg) {
		motes = new HashMap<Integer,Mote>();
        ids = new LinkedList<String>();
        types = new Properties();
        this.parentId = parentId;
        this.parentArg = parentArg;
	}

    public void loadTypes() {
        try {
            FileInputStream in = new FileInputStream(TYPE_PROPERTIES);
            types.load(in);
            in.close();
        } catch(IOException e) {
            log.error("Could not load types from " + TYPE_PROPERTIES);
        }
    }

    public void setType(String id, IdType type) {
        types.setProperty(id, type.toString());
        try {
            FileOutputStream out = new FileOutputStream(TYPE_PROPERTIES);
            types.store(out, "DVIZ type properties on the form <TYPE>:<ARG>");
            out.close();        
        } catch(IOException e) {
            log.error("Could not save types to " + TYPE_PROPERTIES);
        }
    }
	
    public IdType getType(String id) {
        return IdType.fromString(types.getProperty(id, "COUNT"));
    }

	public void readInput() {
		Thread t = new Thread(new Runnable() {
			public void run() {
				BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
				try {
					String line;
					while((line=in.readLine())!=null) {
						StringTokenizer t = new StringTokenizer(line, ",");
                        LinkedList<Double> args = new LinkedList<Double>();
						
						if(!t.hasMoreTokens()) 
							continue;
						Long timestamp = Long.parseLong(t.nextToken());
                        
						if(!t.hasMoreTokens())
							continue;
						int moteid = Integer.parseInt(t.nextToken());
                                                
						if(!t.hasMoreTokens()) 
							continue;

						int seqno = Integer.parseInt(t.nextToken());

                        if(!t.hasMoreTokens()) 
							continue;
                        String id = t.nextToken();
                        
                        while(t.hasMoreTokens()) {
                            String a = t.nextToken();
                            int h = a.indexOf('x');
                            if(h>=0) {
                                args.add(Double.valueOf(""+Long.parseLong(a.substring(h+1,a.length()-1), 16)));
                            } else {
                                args.add(Double.valueOf(a));
                            }
                        }

						//log.debug("" + timestamp + " " + moteid + " " + seqno + " " + id + " " + args);

                        if(getType(id)!=IdType.IGNORE) {

                            if(!ids.contains(id)) {
                                ids.add(id);
                                Collections.sort(ids);
                            }

                            getMote(moteid).newMessage(timestamp, id, args);
                        }

					}
					
				} catch (Exception e) {
					log.error("Error reading input.", e);
					System.exit(2);
				}
			}
		});
		t.start();
	}

	public Mote getMote(int id) {
		if(motes.containsKey(id)) {
			return motes.get(id);
		} else {
			Mote m = new Mote(this, id);
			motes.put(id, m);
			log.trace("Creating new mote " + id);
			return m;
		}
	}

	public Collection<Mote> getMotes() {
		return Collections.unmodifiableCollection(new LinkedList<Mote>(motes.values()));		
	}

    public List<String> getIds() {
        return Collections.unmodifiableList(new LinkedList<String>(ids));
    }
    
    public String getParentId() {
        return parentId;
    }

    public int getParentArg() {
        return parentArg;
    }

	public static void main(String args[]) {
		BasicConfigurator.configure();
		Logger.getRootLogger().setLevel(Level.DEBUG);

		String topology = null;
        String parentId = "Collection__FE_SENT_MSG";
        int parentArg = 2;
		for(int i=0; i<args.length; i++) {
            if(args[i].equals("-topology")) {
                i++;
                if(i==args.length) {
                    log.error("Expected file argument to -topology");
                    return;
                }
                topology = args[i];
            } else if(args[i].equals("-parent")) {
                i++;
                if(i==args.length) {
                    log.error("Expected argument to -parent");
                    return;
                }
                String[] p = args[i].split(":");
                if(p.length!=2) {
                    log.error("Expected -parent argument to be of the form <ID>:<ARG>");
                    return;
                }
                
                parentId = p[0];
                try {
                    parentArg = Integer.valueOf(p[1]);
                } catch(NumberFormatException e) {
                    log.error("Parent argumenet needs to be an integer instead of: " + p[1]);
                    return;
                }
            }
            i++;
		}
        log.debug("parentId: " + parentId + ", arg: " + parentArg);
		Driver driver = new Driver(parentId, parentArg);
        driver.loadTypes();
		driver.readInput();		

        /*System.out.println(driver.getType("test"));
        driver.setType("test", IdType.LATEST);
        System.out.println(driver.getType("test"));
        driver.saveTypes();
        
        System.exit(2);*/

        UserInterface gui = new UserInterface(driver);
        gui.init(topology);


		
	}
	
}
