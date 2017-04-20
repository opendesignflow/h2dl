package org.odfi.eda.h2dl.tool.sphinx

import org.odfi.indesign.core.harvest.Harvester
import org.odfi.indesign.core.harvest.fs.HarvestedFile
import org.odfi.indesign.ide.core.project.BuildableProjectFolder
import org.odfi.indesign.ide.core.project.DefaultBuildableProjectFolder
import org.odfi.eda.h2dl.tool.msys.MsysHarvester
import org.odfi.eda.h2dl.tool.msys.MsysInstall
import org.odfi.indesign.core.harvest.fs.FSGlobalWatch
import java.io.File
import org.odfi.indesign.core.harvest.fs.IDAdded
import org.odfi.indesign.core.harvest.fs.IDModified
import org.odfi.indesign.ide.core.compiler.LiveCompiler
import org.odfi.indesign.core.harvest.fs.IDWatcher

object SphinxProjectHarvester extends Harvester {

  this.onDeliverFor[HarvestedFile] {

    case f if (f.hasSubFile("source", "conf.py").isDefined) =>

      gather(new SphinxProject(f))

      true

  }
}

class SphinxProject(f: HarvestedFile) extends DefaultBuildableProjectFolder(f.path) {
  deriveFrom(f)

  var forceRebuild = false

  this.onProcess {

  }

  this.onClean {
    FSGlobalWatch.watcher.cleanFor(this)
  }

  def getBuildHTMLOutput = new File(path.toFile(), "build" + File.separator + "html")

  override def buildStandard = {
    MsysHarvester.getResource[MsysInstall] match {
      case Some(install) =>

        install.findCommand("sphinx-build") match {
          case Some(ok) =>

            var makeTargets = "html"
            if (forceRebuild)
              makeTargets = "clean html"

            /* var extraArgs = List[String]()
            if (forceRebuild)
              extraArgs = extraArgs :+ "-E"*/
            //SPHINXOPTS="${extraArgs.mkString(" ")}"

            install.runBashCommand(path.toFile(), s"""make $makeTargets """, true)

          case None =>
            println("No Sphinx Build")
            logInfo[SphinxProject]("Bootstraping Sphynx for MSYS2")
            sys.error("Need to implement bootstrap")

        }

      case None =>
        println("No MSYS")
        sys.error("Msys is required to build Sphynx Project")
    }
  }

  def buildLiveCompiler = {
    this.getLiveCompiler[SphinxLiveCompiler] match {
      case None =>
        this.addLiveCompiler(new SphinxLiveCompiler(this))
      case other =>
    }
  }
}

class SphinxLiveCompiler(val project: SphinxProject) extends LiveCompiler {

  var watcher: Option[IDWatcher] = None

  this.onStart {
    watcher = Some(FSGlobalWatch.idWatcher.onRecursiveDirectoryChange(this, new File(project.path.toFile(), "source")) {
      case IDModified(f) if (f.getName.endsWith(".rst") || f.getName.endsWith(".html") || f.getName.endsWith(".py")) =>

        // if(f.getName.endsWith(".rst") || f.getName.endsWith(".html"))
        println("################# REbuild sphynx #################")
        project.runBuildStard.waitForDone
      //runBuildStard.waitForDone

      case other =>
    })
  }

  this.onStop {
    watcher match {
      case Some(w) =>
        FSGlobalWatch.idWatcher.deleteWatchingKey(w.watchKey.get)
        w.clean
      case None =>
    }

  }

  def doRunFullBuild = {
    project.buildStandard
  }
}