## Purpose

Polynote-lab enables you to use Polynote with your SDLB project on your computer.
This needs a metastore to share table metadata between Polynote and SDLB jobs,
and storage which is accessible in the same place on both containers. 
The main problem with storage is that if this is just a mounted volume in the containers, permissions problems arise (files written by one container are not readable/writable in the other).

Polynote-lab is therefore composed of the following components, each running in its own container:
- Polynote
- Metastore: a Derby database storing its data persistently under polynote-lab/data/_metastore
- S3 Storage: S3proxy serving polynote-lab/data as bucket for Polynote and SDLB jobs.

The corresponding Spark configurations are set by default in Polynotes [config.yml](https://github.com/smart-data-lake/polynote-lab/blob/develop/polynote/config.yml).

## Setup

1. Copy SDLB config files to polynote-lab/config folder

1. Copy project jar file to polynote-lab/lib folder

1. Run `./run.sh` to start Metastore and S3 container in background, and Polynote in foreground.
Polynote should then be available on http://localhost:8192.

1. Add project jar file to your Notebook dependencies as type scala/jvm: `file:///mnt/lib/xyz.jar`

1. Run SDLB Jobs using the same metastore and S3 storage using the spark properties defined in [config.yml](https://github.com/smart-data-lake/polynote-lab/blob/develop/polynote/config.yml). When using podman, add parameter "--network polynote-lab" in order to make metastore and s3 storage accessible.

1. Press Ctrl-C to stop Polynote container.

> [!TIP]
> *Spark UI from Polynote*: On the right side of Polynote you find a link to the Spark UI for the current notebooks Spark session. 
> If it doesn't work, try to replace 127.0.0.1 with localhost. If it still doesn't work and you are on Windows/WSL, replace with IP address of WSL (`wsl hostname -I`). 

## Known Errors

For problems regarding Containers and Networking, see https://smartdatalake.ch/docs/getting-started/troubleshooting/docker-on-windows.

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
