package net.tinyos.dviz;

import java.awt.*;
import java.io.*;

import org.apache.log4j.Logger;

import java.util.HashMap;
import java.awt.geom.Point2D;

import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.visualization.*;

public class FixedLayout extends AbstractLayout {

	private static Logger log = Logger.getLogger("net.tinyos.dviz.gui.FixedLayout");
	HashMap<Integer,Point2D> locations; 
	double maxCoordinate;
	
	public FixedLayout(Graph graph, String topologyFile) {
		super(graph);
		locations = new HashMap<Integer,Point2D>();
		maxCoordinate = 0;
		try {
			loadTopology(topologyFile);
		} catch (IOException e) {
			log.fatal("Unable to load topology file.", e);
			System.exit(1);
		}
	}

	private void loadTopology(String file) throws IOException {
	   	BufferedReader reader = new BufferedReader(new FileReader(file));
	   	String line = reader.readLine(); 
	   	while(line != null) {
	   		String[] value = line.split("\t");
	   		if(value.length!=3) throw new IOException("Malformed database configuration file.");
	   		int id = Integer.parseInt(value[0]);
	   		double x = Double.parseDouble(value[1]);
	   		double y = Double.parseDouble(value[2]);
	   		if(x>maxCoordinate) maxCoordinate = x;
	   		if(y>maxCoordinate) maxCoordinate = y;
	   		//System.out.println("" + id + " " + x + " " + y);
	   		locations.put(id, new Point2D.Double(x,y));
	   		line = reader.readLine();
	    }
	    		
	}
	
	@Override
	protected void initializeLocation(Vertex v, Coordinates coord, Dimension d) {
		if(v instanceof GraphMote) {
			GraphMote m = (GraphMote) v;
			Point2D p = locations.get(m.getMote().getId());
			if(p!=null) {
				Point2D adjustedP = new Point2D.Double(p.getX()/maxCoordinate*d.getWidth(), p.getY()/maxCoordinate*d.getHeight());
				coord.setLocation(adjustedP);
			} else {
				log.error("Initializing location on a Mote "+m.getMote().getId()+" that was not in topology file.");
				coord.setLocation(vertex_locations.getLocation(v));
			}
		} else {
			log.error("Initializing location on a Vertex that is not a Mote");
			coord.setLocation(vertex_locations.getLocation(v));
		}
	}
	
	@Override
	public void advancePositions() {
	}

	@Override
	protected void initialize_local_vertex(Vertex v) {
	}

	public boolean incrementsAreDone() {
		return true;
	}

	public boolean isIncremental() {
		return false;
	}
}
