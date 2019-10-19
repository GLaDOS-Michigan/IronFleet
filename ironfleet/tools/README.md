# NuBuild tool  -- Mac/Linux
This guide will walk through building and verifying dafny files using the NuBuild tool on Mac or Linux Machines.
You will need to make sure that Dafny and z3 are already downloaded, and will install Bazel by following these  instructions. 


# Setup

 1. Follow the same Setup for ironfleet ([https://github.com/microsoft/Ironclad/tree/master/ironfleet#setup](https://github.com/microsoft/Ironclad/tree/master/ironfleet#setup))
 2. Intall Bazel and follow instructions here: (https://docs.bazel.build/versions/master/install.html)
 3. Open and edit ````Ironclad/ironfleet/tools/Dafny/dafny````
 4. Set the ````DAFNY```` variable to the path where the Dafny executable is installed locally on your computer. 
	  (ie ````DAFNY="Home/BASE-DIRECTORY/dafny/Binaries/Dafny.exe"````)

# Building the NuBuild tool

 1. Navigate to the Ironclad/ironfleet directory
 2. Run the following script : ````./buildBazel.sh```` 
				 a. This will create a directory in ./tools/NuBuild called bazel-bin
				 b. There will be two executables in ./tools/NuBuild/bazel-bin/NuBuild; Nubuild.bash and Nubuild.exe

(Optional) -- Building NuBuild tool manually

 1. Navigate to ````Ironclad/ironfleet/tools/NuBuild````
 2. Run ````bazel build --spawn_strategy=standalone //NuBuild:NuBuild````

# Verifying Files

 1. Navigate to the Ironclad/ironfleet directory
 2. To execute the NuBuild Executable run: ````./tools/NuBuild/bazel-bin/NuBuild/NuBuild.bash````
			 a. This command is equivalent to ````./bin_tools/NuBuild/NuBuild.exe```` in (https://github.com/microsoft/Ironclad/tree/master/ironfleet#verification)
			
To verify an individual Dafny file (and all of its dependencies), run:
````./tools/NuBuild/bazel-bin/NuBuild/NuBuild.bash --no-cloudcache -j 3 DafnyVerifyTree src/Dafny/Distributed/Impl/SHT/AppInterface.i.dfy````
			 

> **Note:** Always use --no-cloudcache. This version of NuBuild does not support clusters of cloud VMs to parallelize verification

## Possible Errors/Issues

 - non-CRLF line endings in source file ... 
	 - 
	 - The NuBuild tool is still built from C Sharp source code. As such, any files verified with this tool need to have CRLF line endings. This is the standard on Windows machines, but not always the case on Mac/Linux. There is a simple included script that can help convert files to the right format.
	 - Use ````Ironclad/ironfleet/CRLFify.sh```` to convert file line endings to the correct encoding. 
			 - Takes two arguments: ````./CRLFify.sh [sourceFile] [outputFile]````
			 - ````[sourceFile]```` file path to file with non-CRLF line endings
			 - ````[outputFile]```` file path to new file with CRLF line ending encoding
**Note:** This does not modify the ````[sourceFile]```` in any way, rather produces a copy of that file with CRLF line encoding.

## [IMPORTANT] DAFNY VERSION
Due to "https://github.com/dafny-lang/dafny/issues/301" Inorder to run fully and succesfully follow the advice from this post and make sure to build Dafny manually from the e9f5c05d59919eb7a23e10ad47318a8692843551 commit 

