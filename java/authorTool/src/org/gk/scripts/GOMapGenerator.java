/*
 * Created on Nov 14, 2004
 *
 */
package org.gk.scripts;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Collection;
import java.util.Iterator;

import org.gk.model.GKInstance;
import org.gk.persistence.MySQLAdaptor;
import org.gk.schema.SchemaAttribute;
import org.gk.schema.SchemaClass;


/**
 * A utility for creating a map from Reactome CatalystActivity instances to GO MF terms
 * and from Events to GO Molecular BP.
 * @author wgm
 */
public class GOMapGenerator {
  // The output file name
  private String outputFileName;
  // A flag to control if molecular function is needed
  private boolean needMF;
  // A flag to control if biological process is needed
  private boolean needBP;
  
  public GOMapGenerator(String outputFileName,
                        boolean needMF,
                        boolean needBP) {
    this.outputFileName = outputFileName;
    this.needMF = needMF;
    this.needBP = needBP;
  }
  
  public void map(String dbHost,
                  String dbName,
                  String dbUser,
                  String pwd) {
    try {
      MySQLAdaptor dba = new MySQLAdaptor(dbHost, dbName, dbUser, pwd, 3306);
      StringBuffer buffer = new StringBuffer();
      GKInstance instance = null;
      GKInstance goInstance = null;
      String identity = null;
      if (needMF) {
          SchemaClass cls = dba.getSchema().getClassByName("CatalystActivity");
          SchemaAttribute att = cls.getAttribute("activity");
          Collection ca = dba.fetchInstancesByClass(cls);
          //Do batch loading to increase the speed
          dba.loadInstanceAttributeValues(ca, att);
          cls = dba.getSchema().getClassByName("GO_MolecularFunction");
          att = cls.getAttribute("accession");
          Collection mf = dba.fetchInstancesByClass(cls);
          dba.loadInstanceAttributeValues(mf, att);
          for (Iterator it = ca.iterator(); it.hasNext();) {
              instance = (GKInstance) it.next();
              goInstance = (GKInstance) instance.getAttributeValue("activity");
              if (goInstance != null) {
                  outputGOInstance(instance, goInstance, buffer);
              }
          }
          //          Collection mf = dba.fetchInstancesByClass("GO_MolecularFunction");
          //          SchemaAttribute att = dba.getSchema().getClassByName("GO_MolecularFunction").getAttribute("accession");
          //          dba.loadInstanceAttributeValues(mf, att);
          //          for (Iterator it = mf.iterator(); it.hasNext();) {
          //              instance = (GKInstance) it.next();
          //              outputGOInstance(instance, buffer);
          //          }
      }
      if (needBP) {
        Collection event = dba.fetchInstancesByClass("Event");
        SchemaAttribute att = dba.getSchema().getClassByName("Event").getAttribute("goBiologicalProcess");
        dba.loadInstanceAttributeValues(event, att);
        Collection goBPs = dba.fetchInstancesByClass("GO_BiologicalProcess");
        att = dba.getSchema().getClassByName("GO_BiologicalProcess").getAttribute("accession");
        dba.loadInstanceAttributeValues(goBPs, att);
        for (Iterator it = event.iterator(); it.hasNext();) {
          instance = (GKInstance) it.next();
          goInstance = (GKInstance) instance.getAttributeValue("goBiologicalProcess");
          if (goInstance != null) {
            outputGOInstance(instance, goInstance, buffer);
          }
        }
      }
      // Output the buffer
      outputBuffer(buffer);
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
  
  private void outputBuffer(StringBuffer buffer) throws IOException {
    FileWriter writer = new FileWriter(outputFileName);
    BufferedWriter bw = new BufferedWriter(writer, 100 * 1024);
    bw.write(buffer.toString());
    bw.flush();
    bw.close();
    writer.close();
  }
  
  //private void outputGOInstance(GKInstance goInstance,
  //                              StringBuffer buffer) throws Exception {
  //    String identity = (String) goInstance.getAttributeValue("accession");
  //    if (identity == null) {
  //        System.err.println("GO Instance " + goInstance.getDBID() + " has null identity");
  //        return;
  //    }
  //    outputGOInstance(goInstance.getDBID(),
  //                     goInstance.getDisplayName(),
  //                     goInstance.getDisplayName(),
  //                     identity,
  //                     species,
  //                     buffer);
  //}
  
  private void outputGOInstance(GKInstance instance,
                                GKInstance goInstance, 
                                StringBuffer buffer) throws Exception {
    String identity = (String) goInstance.getAttributeValue("accession");
    String species = (String) instance.getAttributeValue("species");
    if (identity == null) {
      System.err.println("GO Instance " + goInstance.getDBID() + " has null identity");
      return;
    }
    outputGOInstance(instance.getDBID(),
                     instance.getDisplayName(),
                     goInstance.getDisplayName(),
                     identity,
                     species,
                     buffer);
  }
  
  private void outputGOInstance(Long reactomeID, 
                                String reactomeName, 
                                String goTermName, 
                                String goID,
                                String species,
                                StringBuffer buffer) {
      buffer.append("Reactome:");
      buffer.append(reactomeID).append(" ");
      buffer.append(reactomeName);
      buffer.append(" > ");
      buffer.append("GO:");
      buffer.append(goTermName).append(" ; ");
      buffer.append("GO:").append(goID);
      buffer.append("Species: ");
      buffer.append(species);
      buffer.append("\n");      
  }
  
  public static void main(String[] args) {
    if (args.length < 5) {
      System.err.println("Please input arguments for: dbhost dbname dbuser dbpwd outputFileName.");
      System.exit(1);
    }
    GOMapGenerator map = new GOMapGenerator(args[4], true, true);
    System.out.println("---- Starting mapping ......");
    map.map(args[0], args[1], args[2], args[3]);
    System.out.println("---- Mapping is done. The result " +
                      "is in the file \"" + args[4] + "\".");
    
  }
  
}
