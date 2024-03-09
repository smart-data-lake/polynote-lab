## Purpose

ATTENTION: this is not yet working - a Polynote build with updated Scala Versions is needed to run this 
(Java 17 needs Scala 2.12.15+, and similar Problem with outdated Scala 2.13.6). 

Polynote-lab enables you to use Polynote with your SDLB project on your computer.
This needs a metastore to share table metadata between Polynote and SDLB jobs,
and storage which is accessible in the same place on both containers. 
The main problem with storage is that if this is just a mounted volume in the containers, permissions problems arise (files written by one container are not readable/writable in the other).

Polynote-lab is therefore composed of the following components, each running in its own container:
- Polynote
- Metastore: a Derby database storing its data persistently under polynote-lab/data/_metastore
- S3 Storage: S3proxy serving polynote-lab/data as bucket for Polynote and SDLB jobs.

## Setup

Copy SDLB config files to polynote-lab/config folder

Copy project jar file to polynote-lab/lib folder

Run podman-compose.sh to start Metastore and S3 container in background, and then Polynote in foreground.  

Add project jar file to your Notebook dependencies as type scala/jvm: `file:///mnt/lib/xyz.jar`

## Known Errors

### Cannot update notebook files

Exception:
```
Uncaught exception: Catastrophe! An error occurred updating notebook. Editing will now be disabled. (java.lang.Exception)
| polynote.server.KernelPublisher$.$anonfun$apply$19(KernelPublisher.scala:372)
| scala.util.Either.fold(Either.scala:192)
| zio.ZIO$FoldCauseMFailureFn.apply(ZIO.scala:4486)
| zio.ZIO$FoldCauseMFailureFn.apply(ZIO.scala:4483)
| zio.internal.FiberContext.evaluateNow(FiberContext.scala:914)
| zio.internal.FiberContext.$anonfun$evaluateLater$1(FiberContext.scala:776)
| java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
| java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
| java.lang.Thread.run(Thread.java:750)
```

Solution:
make sure that folder polynote-lab/polynote/notebooks is writeable (777)