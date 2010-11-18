package net.tinyos.dviz;

import edu.uci.ics.jung.graph.*;
import edu.uci.ics.jung.graph.impl.*;
import edu.uci.ics.jung.utils.*;

public class GraphMote extends DirectedSparseVertex {

	private Mote mote;
	private Graph graph;
	private GraphMote parent;
	private Edge parentEdge;
	
	public GraphMote(Mote m, Graph g) {
		mote = m;
		graph = g;
		graph.addVertex(this);
		parent = null;
		parentEdge = null;
	}
	
	public void setParent(GraphMote p) {
        if(parentEdge!=null) {
            graph.removeEdge(parentEdge);
        }
        parent = p;
        parentEdge = graph.addEdge(new DirectedSparseEdge(this,parent));
        // TODO: add etx as edge label to graph
        //parentEdge.setUserDatum("label", mote.getParentEtx(), new UserDataContainer.CopyAction.Clone());
	}
	
	public Mote getMote() {
		return mote;
	}
	
	public String toString() {
		return "" + mote.getId();
	}
	
}
