package edu.kit.ipe.adl.h2dl.msys

import edu.kit.ipe.adl.h2dl.tool.msys.MsysHarvester
import edu.kit.ipe.adl.h2dl.tool.msys.MsysInstall
import java.io.File

object TryMsysRun extends App {
  
  // Get Install
  //------------
  
  MsysHarvester.harvest
  var install = MsysHarvester.getResource[MsysInstall].get
  println("Install: "+install)
  
  
  // Run a command like Python
  //------------
 // install.runCommand(new File(""), "python3.exe",Array("-V"), true)
   //install.runCommand(new File(""), "/usr/bin/bash.exe",Array("-c","/usr/bin/which.exe python3.exe"), true)
  //install.runCommand(new File(""), "/usr/bin/bash.exe",Array("-i","-c","/usr/bin/id.exe"), true)
  install.runCommand(new File("""C:\Users\leysr\git\adl\lectures\dds\current\\uebung"""),Array("bash","-lc", "pwd && /usr/bin/make.exe html"), true)
  
  install.runBashCommand(new File("""C:\Users\leysr\git\adl\lectures\dds\current\\uebung"""),"pwd && /usr/bin/make.exe html", true)
}