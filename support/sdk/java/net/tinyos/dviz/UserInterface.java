package net.tinyos.dviz;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.Timer;
import javax.swing.table.TableColumn;
import javax.swing.table.AbstractTableModel;

import java.util.Collection;

import org.apache.log4j.Logger;

import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.decorators.ToStringLabeller;
import edu.uci.ics.jung.graph.impl.DirectedSparseGraph;
import edu.uci.ics.jung.visualization.DefaultVisualizationModel;
import edu.uci.ics.jung.visualization.FRLayout;
import edu.uci.ics.jung.visualization.GraphZoomScrollPane;
import edu.uci.ics.jung.visualization.Layout;
import edu.uci.ics.jung.visualization.PluggableRenderer;
import edu.uci.ics.jung.visualization.ShapePickSupport;
import edu.uci.ics.jung.visualization.VisualizationModel;
import edu.uci.ics.jung.visualization.VisualizationViewer;
import edu.uci.ics.jung.visualization.control.CrossoverScalingControl;
import edu.uci.ics.jung.visualization.control.DefaultModalGraphMouse;
import edu.uci.ics.jung.visualization.control.ModalGraphMouse;
import edu.uci.ics.jung.visualization.control.SatelliteVisualizationViewer;
import edu.uci.ics.jung.visualization.control.ScalingControl;

public class UserInterface {

	private static Logger log = Logger.getLogger("net.tinyos.tools.debug.gui.UserInterface");
	private static final int UPDATE_DELAY = 1000;
	
	private Driver driver;
	private HashMap<Mote,GraphMote> graphMotes;
	boolean running;
	
	private Graph graph;
	private VisualizationViewer viewer;
	private MoteTable moteTable;
    private JTable table;
	private JButton updateButton;
	private JCheckBox autoUpdateBox;
	
	private Timer updateTimer;
	
	public UserInterface(Driver d) {
		driver = d;
		graphMotes = new HashMap<Mote,GraphMote>();
		running = false;
	}
	
	public void init(String topology) {    	
		graph = new DirectedSparseGraph();
    	
    	Layout layout;
    	if(topology==null) {
    		 layout = new FRLayout(graph);
    	} else {
    		layout = new FixedLayout(graph,topology);
    	}
    		
    	VisualizationModel model = new DefaultVisualizationModel(layout);
        
    	PluggableRenderer renderer = new PluggableRenderer();
    	renderer.setVertexStringer(ToStringLabeller.setLabellerTo(graph));
    	
    	//renderer.setEdgeStringer(arg0)
    	DefaultModalGraphMouse graphMouse = new DefaultModalGraphMouse();
    	graphMouse.setMode(ModalGraphMouse.Mode.PICKING);
    	viewer = new VisualizationViewer(model, renderer, new Dimension(800,500));
    	viewer.setDoubleBuffered(true);
    	viewer.setBackground(Color.white);
        //viewer.setToolTipFunction(new DefaultToolTipFunction());
    	viewer.setGraphMouse(graphMouse);
        viewer.setPickSupport(new ShapePickSupport());
        
        viewer.getPickedState().addItemListener(new ItemListener() {
			public void itemStateChanged(ItemEvent event) {
				if(event.getItem() instanceof GraphMote) {
					GraphMote gmote = (GraphMote) event.getItem();
					if(event.getStateChange()==ItemEvent.SELECTED) {
						moteTable.addMote(gmote.getMote());
                        update();
					} else if(event.getStateChange()==ItemEvent.DESELECTED) {
						moteTable.removeMote(gmote.getMote());
                        update();
					}
				}
			}
        });
    	
    	SatelliteVisualizationViewer satelliteViewer = new SatelliteVisualizationViewer(viewer, model, new PluggableRenderer(), new Dimension(300,300));
    	
        Container tablePanel = new JPanel(new BorderLayout());
        moteTable = new MoteTable(this);
        table = new JTable(moteTable);
        for(int i=0; i<table.getColumnModel().getColumnCount(); i++) {
        	TableColumn tc = table.getColumnModel().getColumn(i);
        	tc.setCellRenderer(moteTable);
        }
    	table.setPreferredScrollableViewportSize(new Dimension(700,150));
        table.setAutoCreateColumnsFromModel(true);

        JScrollPane tableScrollPane = new JScrollPane(table);
    	
        tablePanel.add(tableScrollPane, BorderLayout.CENTER);
    	//tablePanel.add(table.getTableHeader(), BorderLayout.NORTH);
        
    	updateButton = new JButton("Update graph");
    	updateButton.setBackground(Color.RED);
    	updateButton.addActionListener(
    			new ActionListener() {
    				public void actionPerformed(ActionEvent e) {
    					updateButton.setBackground(Color.RED);
    					viewer.restart();
    				}
    			}
    	);
    	
    	autoUpdateBox = new JCheckBox();
    	autoUpdateBox.setSelected(true);
    	
        final ScalingControl scaler = new CrossoverScalingControl();
        JButton plusButton = new JButton("+");
        plusButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                scaler.scale(viewer, 1.1f, viewer.getCenter());
            }
        });
        JButton minusButton = new JButton("-");
        minusButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                scaler.scale(viewer, 1/1.1f, viewer.getCenter());
            }
        });
        
        //JComboBox modeBox = graphMouse.getModeComboBox();
				/*Container infoControls = new JPanel(new BorderLayout());
    	infoControls.add(new JLabel("Info:"), BorderLayout.NORTH);
    	infoControls.add(info, BorderLayout.CENTER);*/
        
    	Container update = new JPanel();
    	update.add(new JLabel("Enable autoupdate "));
    	update.add(autoUpdateBox);
    	update.add(new JLabel(" or "));
    	update.add(updateButton);
    	Container updateControls = new JPanel(new BorderLayout());
    	updateControls.add(new JLabel("Update graph when a new mote is seen:"), BorderLayout.NORTH);
    	updateControls.add(update, BorderLayout.CENTER);
    	    	
    	Container zoom = new JPanel();
    	zoom.add(plusButton);
    	zoom.add(minusButton);
    	Container zoomControls = new JPanel(new BorderLayout());
    	zoomControls.add(new JLabel("Zoom on the graph:"), BorderLayout.NORTH);
    	zoomControls.add(zoom, BorderLayout.CENTER);

        /*Container types = new JPanel();
        types.add(new JLabel("HEJ"));
        Container typesControls = new JPanel(new BorderLayout());
    	typesControls.add(new JLabel("Configure:"), BorderLayout.NORTH);
    	typesControls.add(types, BorderLayout.CENTER);*/

    	Container controlPanel = new JPanel(new GridLayout(6,1));
    	//controlPanel.add(infoControls);
    	controlPanel.add(updateControls);
    	//controlPanel.add(saveControls);
    	controlPanel.add(zoomControls);
    	//controlPanel.add(typesControls);

    	Container rightPanel = new JPanel(new GridLayout(2,1));
    	//Container rightPanel = new JPanel();
    	rightPanel.add(controlPanel);
    	rightPanel.add(satelliteViewer);
    	
        GraphZoomScrollPane zoomPanel = new GraphZoomScrollPane(viewer);
    	
    	JFrame frame = new JFrame();
    	frame.setTitle("Debug Analyzer");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.getContentPane().add(zoomPanel, BorderLayout.CENTER);
        frame.getContentPane().add(rightPanel, BorderLayout.EAST);
        frame.getContentPane().add(tablePanel, BorderLayout.SOUTH);
    	frame.pack();
        frame.setVisible(true);
        
		updateTimer = new Timer(UPDATE_DELAY, new ActionListener() {
			public void actionPerformed(ActionEvent evt) {  
				update();
			}
		});
		updateTimer.start();
	}
	
	public void update() {
		Collection<Mote> motes = driver.getMotes();
		log.trace("start");
		for(Mote m : motes) {
			Mote parent = m.getParent();
			GraphMote g = getGraphMote(m);
			if(parent!=null) {
				g.setParent(getGraphMote(parent));
			}
		}
		log.trace("end");
		moteTable.setHeaders(driver.getIds());
        moteTable.fireTableDataChanged();
	}
	
	private GraphMote getGraphMote(Mote m) {
		if(graphMotes.containsKey(m)) {
			return graphMotes.get(m);
		} else {
			GraphMote g = new GraphMote(m,graph);
			graphMotes.put(m, g);
			if(autoUpdateBox.isSelected()) {
				viewer.restart();
			} else {
				updateButton.setEnabled(true);
				updateButton.setBackground(Color.GREEN);
			}
			return g;
		}
	}

    public Collection<GraphMote> getGraphMotes() {
        return graphMotes.values();
    }
	
}
