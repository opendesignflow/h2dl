package edu.kit.ipe.adl.h2dl.tool

import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.io.File

import scala.collection.JavaConversions._

import com.idyria.osi.tea.thread.ThreadLanguage

import edu.kit.ipe.adl.indesign.core.harvest.HarvestedResource

abstract class ExternalTool(val startPath: File) extends HarvestedResource {

  def getId = startPath.getAbsolutePath

  def isValid = this.startPath.exists()

  // Start/Stop, Process output
  //------------

  def createToolProcess(args: Array[String],runFolder : File = new File("")) : ToolProcess= {
    var cmd = List(startPath.getAbsolutePath) ++ args
    var pb = new ProcessBuilder(cmd)
    pb.directory(runFolder.getCanonicalFile)
    var tp = new ToolProcess(pb)
    
    tp
  }
  
  def createToolProcess(args: String*): ToolProcess = {
    
    var cmd = List(startPath.getAbsolutePath) ++ args
    var pb = new ProcessBuilder(cmd)
    var tp = new ToolProcess(pb)
    
    tp
  }

  /*var process: Option[Process] = None
  def runTool(args: String*) = process match {
    case None =>
      var cmd = List(startPath.getAbsolutePath) ++ args
      var pb = new ProcessBuilder(cmd)
      pb.inheritIO()
      try {
        process = Some(pb.start())

      } catch {
        case e: Throwable => e.printStackTrace()
      }

    case Some(process) => throw new RuntimeException("Tool Already Started")
  }

  def killTool = process match {
    case None =>
      throw new RuntimeException("Cannot kill non started tool")

    case Some(p) =>
      p.destroyForcibly()
      process = None
  }*/

}

class ToolProcess(val processBuilder: ProcessBuilder) extends HarvestedResource with ThreadLanguage {

  def getId = process match {
    case None => "0"
    case Some(p) => p.toString()
  }
  
  // IO
  //-------------
  def inheritIO = process match {
    case None => 
      processBuilder.inheritIO()
    case _ => throw new RuntimeException("Process Already Started")
  }
  
  var outputBufferThread : Option[Thread] = None
  var outputBuffer : Option [ByteArrayOutputStream] = None
  
  def outputToBuffer = process match {
    case None => 
      
      var th = createThread {
      
        // Started when the process starts
        var br = new BufferedInputStream(process.get.getInputStream)
        
        // Output buffer
        outputBuffer = Some(new ByteArrayOutputStream(4096))
        
        // Read
        var bytes = new Array[Byte](4096)
        var read = br.read(bytes)
        while(read>=0) {
          outputBuffer.get.write(bytes, 0, read)
          read = br.read(bytes)
        }
        
        // Finish
        this.outputBufferThread = None
        
      }
      this.outputBufferThread = Some(th)
      
      //-- Redirect Error Stream to stdout
      processBuilder.redirectErrorStream(true)
      
      
    case _ => throw new RuntimeException("Process Already Started")
  }
  
  def getOutputBuffer = outputBuffer match {
    case Some(ob) => ob
    case None => 
      throw new RuntimeException("No Output Buffer Available, maybe process was not started using outputToBuffer")
  }
  
  def getOutputString = new String(getOutputBuffer.toByteArray())
  

  
  // Start/Stop
  //-----------------
  var process: Option[Process] = None

  def startProcess = process match {
    case po if(po.isEmpty || !po.get.isAlive ) =>
      processBuilder.redirectErrorStream(true)
      var p = processBuilder.start
      this.process = Some(p)
      
      // Output buffer start ?
      this.outputBufferThread match {
        case Some(th) => th.start 
        case None => 
      }
      
    case Some(p) => throw new RuntimeException("Process Already Started")
  }
  
  /**
   * Returns return code
   */
  def startProcessAndWait = {
    this.startProcess
    this.process.get.waitFor()
  }
  
  def killProcess = process match {
    case None =>
      throw new RuntimeException("Cannot kill non started tool")

    case Some(p) =>
      p.destroyForcibly()
      process = None
  }
  
  // Cleaning
  //----------------
  
  def clean = process match {
    case Some(p) =>
      throw new RuntimeException("Cannot clean during tool run")

    case None =>
      this.outputBuffer = None
      this.outputBufferThread = None
      System.gc
  }
}




