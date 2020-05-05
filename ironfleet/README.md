# About

This directory contains experimental verified IronFleet code,
as described in:

>  [_IronFleet: Proving Practical Distributed Systems Correct_](http://research.microsoft.com/apps/pubs/default.aspx?id=255833)
>  Chris Hawblitzel, Jon Howell, Manos Kapritsos, Jacob R. Lorch, 
>  Bryan Parno, Michael L. Roberts, Srinath Setty, and Brian Zill.
>  In Proceedings of the ACM Symposium on Operating Systems Principles (SOSP).
>  October 5, 2015.

As a brief summary, we are motivated by the fact that distributed systems are notorious
for harboring subtle bugs.  Verification can, in principle, eliminate these bugs a priori,
but verification has historically been difficult to apply at full-program scale, much less
distributed-system scale.

We developed a methodology for building practical and provably correct distributed systems
based on a unique blend of TLA-style state-machine refinement and Hoare-logic
verification.  In this code release, we demonstrate the methodology on a complex
implementation of a Paxos-based replicated state machine library (IronRSL) and a
lease-based sharded key-value store (IronKV).  We prove that each obeys a concise safety
specification, as well as desirable liveness requirements.  Each implementation achieves
performance competitive with a reference system.  With our methodology and lessons
learned, we aim to raise the standard for distributed systems from "tested" to "correct."

See http://research.microsoft.com/ironclad for more details.

# License

IronFleet is licensed under the MIT license included in the [LICENSE](./LICENSE) file.

# Setup

In the examples below, we'll assume you're using Cygwin, but other shells (e.g.,
Powershell) should work as well.  

To use Dafny interactively, you'll need Visual Studio 2012 or newer, Vim, or Emacs.
Each has a plugin:
  - For Vim, we suggest the vim-loves-dafny plugin:
      https://github.com/mlr-msft/vim-loves-dafny
  - For Emacs, we suggest the Emacs packages boogie-mode and dafny-mode:
      https://github.com/boogie-org/boogie-friends
  - For Visual Studio, open:
      `./tools/Dafny/DafnyIroncladVsPlugin.vsix`
    to install the Dafny plugin with our default settings.
    If you're running on Windows Server, and you see an error message that says Z3 has crashed,
    then you may need to install the [Microsoft Visual C++ runtime](http://www.microsoft.com/en-us/download/details.aspx?id=5555).
    
These instructions assume you're running on Windows.  However, Dafny, and all of its
dependencies, also run on Linux.  You can obtain Dafny sources from:

  https://github.com/Microsoft/dafny/

Dafny's INSTALL file contains instructions for building on Linux with Mono.  Note that we have
not yet tested building our build tool, NuBuild, on Linux, so your mileage may vary.

# Verification

To perform our definitive verifications, we use our NuBuild tool, which handles dependency
tracking, caches intermediate verification results locally and in the cloud, and can
utilize a cluster of cloud VMs to parallelize verification.  To enable cloud features,
you'll need an Azure account and an Azure storage account.  Once you have an Azure storage
account, put your storage account's connection string into the
`bin_tools/NuBuild/Nubuild.exe.config` file.  This will let you make use of the cloud
cache capabilities.  To use the cloud build functionality, you'll need to add your
subscription Id and Certificate (base64 encoded) to
`bin_tools/NuBuild/AzureManage.exe.config`, which will then let you manage a cluster of
VMs to serve as workers.

You can still use NuBuild without cloud support, however, by passing the `--no-cloudcache` option.

To verify an individual Dafny file (and all of its dependencies), run:

  `./bin_tools/NuBuild/NuBuild.exe --no-cloudcache -j 3 DafnyVerifyTree src/Dafny/Distributed/Impl/SHT/AppInterface.i.dfy`

which uses the `-j` flag to add 3-way local parallelism.

To verify a forest of Dafny files (e.g., all of the IronFleet files), run:

  `./bin_tools/NuBuild/NuBuild.exe -j 3 BatchDafny src/Dafny/Distributed/apps.dfy.batch`

Expect this to take up to several hours, depending on your machine and how many cores you
have available.  Also note that the prover's time limits are based on wall clock time, so
if you run the verification on a slow machine, you may see a few time outs not present in
our build.

# Compilation

To build a runnable, verification application, use:

  `./bin_tools/NuBuild/NuBuild.exe --no-cloudcache -j 3 IronfleetApp src/Dafny/Distributed/Services/RSL/Main.i.dfy`

The will produce an executable:
  `./nuobj/Dafny/Distributed/Services/RSL/Main_i.exe`

To produce an executable without performing verification use NuBuild's `--no-verify` flag.
Note that in this case the resulting executable will be named `Main_i.unverified.exe`.

For maximum performance, be sure to turn off performance profiling.  The easiest way
to do this is to comment out the body of the RecordTimingSeq method in  

  `./src/Dafny/Distributed/Impl/Common/Util.i.dfy`

To build the unverified C# clients for IronRSL and IronKV, open and build (in Release mode):

  `./src/IronfleetClient/IronfleetClient.sln`
  `./src/IronKVClient/IronfleetClient.sln`

# Running

## IronLock

IronLock is the simplest of the protocols we have verified, so it may be a good starting point.
It consists of N processes passing around a lock. To run it, you need to supply each process
with the IP-port pairs of all processes, as well as its own IP-pair. For example, this is a 
configuration with three processes:

```
  ./nuobj/Dafny//Distributed/Services/Lock/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4002
  ./nuobj/Dafny//Distributed/Services/Lock/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4003
  ./nuobj/Dafny//Distributed/Services/Lock/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4001
```

It is important that you start the "first" process last, as it initially holds the lock and will
immediately start passing it around. As this is a toy example, message retransmission is not implemented.
Therefore, if the other processes are not running by the time the first process sends a grant message, 
the message will be lost and the protocol will stop. 

If started properly, the processes will pass the lock among them as fast as they can, printing a message 
everytime they accept or grant the lock.

## IronRSL

To run IronRSL, you should ideally use four different machines, but in a pinch you can use
four separate windows on the same machine. Both the client and server executables expect a
list of IP-port pairs that identifies all of the replicas in the system (in this example
we're using 3, but more is feasible).  Each server instance also needs to be told which
IP-port pair belongs to it.  The client also needs to know it's own IP, how many threads
to use when generating requests, and how long to run for (in seconds).

```
  ./nuobj/Dafny/Distributed/Services/RSL/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4001
  ./nuobj/Dafny/Distributed/Services/RSL/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4002
  ./nuobj/Dafny/Distributed/Services/RSL/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4003
  ./src/IronfleetClient/IronfleetClient/bin/Release/IronfleetClient.exe 127.0.0.1 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 1 10
```

The client will print out a GUID, but all of its interesting output goes to:

  `/tmp/IronfleetOutput/Job-GUID/client.txt`

which primarily logs the time needed for each request.

Note that the servers use non-blocking network receives, so they may be slow to respond to Ctrl-C.

## IronKV

To run IronKV, you could use one or more machines for the server and
one machine for the client. Like IronRSL, IronKV executables also
require a list of IP-port pairs. Additionally, the IronKV client also
needs a few parameters to generate a stream of Get/Set requests
(details below).

  `./nuobj/Dafny/Distributed/Services/SHT/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4001`
  `./nuobj/Dafny/Distributed/Services/SHT/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4002`
  `./nuobj/Dafny/Distributed/Services/SHT/Main_i.exe 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 127.0.0.1 4003`

  `./src/IronKVClient/IronfleetClient/bin/Release/IronfleetClient.exe 127.0.0.1 127.0.0.1 4001 127.0.0.1 4002 127.0.0.1 4003 1 10 [OPERATION] [NUM-KEYS] [VAL-SIZE]`
where OPERATION specifies the workload to use (e.g., g for Gets or s
Sets), and NUMKEYS tells the client to preload the server with an
initial set of values (of size VALSIZE bytes) for keys from 0 to
NUMKEYS-1,

Like in IronRSL, the client will print out a GUID, but all of it's
interesting output goes to:

  `/tmp/IronfleetOutput/Job-GUID/client.txt`

which primarily logs the time needed for each request.


# Code Layout

See the [CODE](./CODE.md) file for more details on the various files in the repository.

# Contributing

See the [CONTRIBUTING](./CONTRIBUTING.md) file for more details.

# Version History
- v0.1:   Initial code release
