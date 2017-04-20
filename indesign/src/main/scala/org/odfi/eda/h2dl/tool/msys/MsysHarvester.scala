package org.odfi.eda.h2dl.tool.msys

import java.io.File

import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.core.module.process.IDCommand
import org.odfi.indesign.core.module.process.IDProcess

object MsysHarvester extends Harvester {

  override def doHarvest = {

    // Look in obvious paths
    //-------------
    var stdInstall = new File("""C:\msys64\""").getCanonicalFile
    stdInstall.exists() match {
      case true =>
        gather(new MsysInstall(stdInstall))
      case false =>
    }

  }

}

class MsysInstall(f: File) extends HarvestedFile(f.toPath) {

  /*var mingw64Path = new File(f, "mingw64.exe")

  var mgw64Command = new IDCommand(mingw64Path)*/

  val searchPaths = List("/usr/bin", "/mingw64/bin")

  // Command Find
  //----------------
  def cleanCommandName(c: String) = c.endsWith(".exe") match {
    case true => c
    case false => c + ".exe"
  }

  def findCommand(command: String) = {

    // Find Real path
    command.startsWith("/") match {
      case true =>

        var commandFile = new File(path.toFile(), command.replace("/", File.separator))
        commandFile.exists() match {
          case true => Some(commandFile)
          case false => None
        }

      case false =>

        //var cleanedCommandName = cleanCommandName(command)
        searchPaths.map {
          sp => new File(path.toFile, sp.replace("/", File.separator))
        } collectFirst {
          case spFile if (new File(spFile, command).exists()) => new File(spFile, command)
           case spFile if (new File(spFile, command+".exe").exists()) => new File(spFile, command+".exe")
        }
       /* searchPaths.find {
          sp =>
            var spFile = new File(path.toFile, sp.replace("/", File.separator))
            var commandFile = new File(spFile, command)
            commandFile.exists match {
            
              //-- Try with ".exe"
              case false if(command.endsWith(".exe")==false) =>
                commandFile = new File(spFile, command + ".exe")
                commandFile.exists
              case other => true
            }
        } match {
          case Some(sp) =>
            Some(new File(path.toFile(), sp.replace("/", File.separator) + File.separator + command))
          case None => None
        }*/
    }

  }

  // Command Run
  //-----------------

  def folderToMsysPath(folder: File) = {

    folder.getCanonicalPath.replace(File.separator, "/").replaceAll("([A-Z]):", "/$1")
  }

  def runBashCommand(command: String, inheritIO: Boolean)  : IDProcess =  {
    runBashCommand(new File(""),command,inheritIO)

  }

  
  def runBashCommand(runFolder: File, command: String, inheritIO: Boolean = true) : IDProcess = {

    var commandArgs = Array("bash", "-lc", s"cd ${folderToMsysPath(runFolder)} && $command")
    runCommand(runFolder, commandArgs, inheritIO)

  }

  def runCommand(runFolder: File, args: Array[String], inheritIO: Boolean = true) = {

    var command = args(0)
    var arguments = args.drop(1)

    findCommand(command) match {
      case Some(commandFile) =>

        var realCommand = new IDCommand(commandFile)

        
        
        var process = realCommand.createToolProcess(arguments, runFolder)
        
        process.processBuilder.environment().put("MSYSTEM", "MINGW64")
        
        inheritIO match {
          case true =>
            process.inheritIO
          case false =>
        }

        process.startProcess
        process
      case None =>
        sys.error(s"Cannot run command '$command' , not found")
    }

  }

}