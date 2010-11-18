package net.tinyos.dviz;

import java.util.LinkedList;
import java.util.Collection;
import java.util.List;

import java.awt.*;
import javax.swing.*;
import javax.swing.table.*;
import javax.swing.event.*;

import org.apache.log4j.Logger;

import java.awt.Component;
import java.io.File;
import java.io.IOException;

public class MoteTable extends AbstractTableModel implements TableCellRenderer { //implements TableModel, TableCellRenderer {
    
    private static Logger log = Logger.getLogger("net.tinyos.dviz.MoteTable");

    UserInterface ui;
    List<String> headers;
    List<Mote> motes;

    /*private Color[] getColorArray() {
        Color[] c = new Color[headers.size()];
        for(int i=0; i<headers.size(); i++) {
            c[i] = Color.CYAN;
        }
        return c;
        }*/
    
	public MoteTable(UserInterface ui) {
        this.ui = ui;
        this.headers = new LinkedList<String>();
        this.motes = new LinkedList<Mote>();
	}
	
    public void setHeaders(List<String> h) {
        if(h.size()!=headers.size()) {
            headers = h;
            fireTableStructureChanged();
        }
    }

    public void addMote(Mote m) {
        if(!motes.contains(m)) {
            motes.add(m);
        }
    }

    public void removeMote(Mote m) {
        motes.remove(m);
    }

	/********* Table Model Methods **********/
	
	public Class<?> getColumnClass(int columnIndex) { 
		return Double.class;
	}
	
	public int getColumnCount() { 
		return headers.size() + 1;
	}
	public String getColumnName(int columnIndex) { 
        if(columnIndex==0) {
            return "ID";
        } else {
          String[] s = headers.get(columnIndex-1).split("__");
          return s[s.length-1];
        }
	}
	
	public int getRowCount() { 
			//return motes.size()+1; 
			return motes.size(); 
	}
	
	public Object getValueAt(int rowIndex, int columnIndex) {
        Mote m = motes.get(rowIndex);
        if(columnIndex==0) {
            return m.getId();
        } else {
            return m.getStatus().get(headers.get(columnIndex-1));
        }
	}
	
	public boolean isCellEditable(int rowIndex, int columnIndex) {
		return false; 
	}
	
	public void setValueAt(Object aValue, int rowIndex, int columnIndex) {
		
	}

	/********* Table Cell Renderer Methods **********/

	public static final DefaultTableCellRenderer DEFAULT_RENDERER = new DefaultTableCellRenderer();

	public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column) {
		Component renderer = DEFAULT_RENDERER.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
		//((JLabel) renderer).setOpaque(true);
		//Color background = getColorArray()[column];
		//	renderer.setForeground(foreground);
		//renderer.setBackground(background);
        //log.debug("setting background");
		return renderer;
	}
}
