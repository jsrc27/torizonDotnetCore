# .NET Core w/ Visual Studio Code on TorizonCore

### Prerequisites: 
* Toradex device with the [TorizonCore with Docker runtime](https://www.youtube.com/watch?v=hwCXSckISXM) image installed
* Linux development machine with [Visual Studio Code](https://code.visualstudio.com/docs/setup/linux) installed
* [C#](https://marketplace.visualstudio.com/items?itemName=ms-vscode.csharp) and [Docker](https://marketplace.visualstudio.com/items?itemName=PeterJausovec.vscode-docker) Visual Studio code extensions installed and enabled
* [.Net Core SDK](https://dotnet.microsoft.com/download) installed on development machine
* [Docker hub](https://hub.docker.com/) account created to store built containers

### Creating Hello World Project
* Open empty project folder in Visual Studio Code (VSC)
* Use the terminal to create hello world starting files with `dotnet new console`
* Test project works on dev machine with `dotnet run`

### Creating Device Container
* Create a new file in the project folder called `Dockerfile` with the following contents:
```
FROM microsoft/dotnet:2.2-sdk AS build-env
WORKDIR /app

# copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# copy and build everything else
COPY . ./
RUN dotnet publish -c Release -o out

FROM microsoft/dotnet:2.2-sdk-bionic-arm32v7
COPY --from=build-env /app/out /out

ENTRYPOINT ["dotnet", "/out/dotnetTest.dll"]
```
***NOTE***: my project folder is called dotnetTest so my application as you can see in the last line is called `dotnetTest.dll`, so adjust yours accordingly.
* Right click Dockerfile in the file explorer and click on `Build Image`. This will bring up a prompt as to what you want to name your container as. Make sure you name it with your docker registry account you created prior i.e. (jeremiascordoba/dotnettest:latest).
* Once the container is built bring up the command palette in VSC (ctrl + shift + p). Search for and execute the `Docker: Push` command and choose the name of the container you just built. This will push this image to your docker registry account.
* Connect to your Torizon device and execute the following command `docker run <YOUR_CONTAINER_NAME>` This will pull your container on the device (will take a while initially). The container should automatically execute your hello world application, confirm that this works before proceeding.

### Remote Debugging 
* Modify your hello world application so that it is long running persistent application. Easy way would be to wrap the Hello World in an infinite loop. Add some dummy variables to debug too if you’d like.
* Install QEMU user with `apt-get install qemu-user`, this will allow visual studio to build a debugging container for an arm device.
* Copy the following binary `/usr/bin/qemu-arm-static` to the same folder as your Visual Studio Code project.
* Create a new file in the project called `Dockerfile.debug` with the following contents:
```
FROM microsoft/dotnet:2.2-sdk-bionic-arm32v7 AS base

COPY qemu-arm-static /usr/bin

RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip procps && \
    curl -sSL https://aka.ms/getvsdbgsh | bash /dev/stdin -v latest -l ~/vsdbg && \
    rm -rf /var/lib/apt/lists/*

FROM microsoft/dotnet:2.2-sdk AS build-env
WORKDIR /app

COPY *.csproj ./
RUN dotnet restore
COPY . ./
RUN dotnet publish -c Debug -o out

FROM base

COPY --from=build-env /app/out /out

ENTRYPOINT ["dotnet", "/out/dotnetTest.dll"]
```
* Repeat the process of building and pushing containers but with `Dockerfile.debug`. Make sure to name it something distinct from the other container i.e (jeremiascordoba/dotnettest:debug)
* In your VSC project folder there should be a file called `launch.json` replace the contents with the following:
```
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CSharpFunction Remote Debug (.NET Core)",
      "type": "coreclr",
      "request": "attach",
      "processId": "${command:pickRemoteProcess}",
      "pipeTransport": {
        "pipeProgram": "ssh",
        "pipeArgs": [
          "-T",
          "torizon@10.12.1.42",
          "docker exec -i Test ${debuggerCommand}"
        ],
        "debuggerPath": "/root/vsdbg/vsdbg",
        "pipeCwd": "${workspaceFolder}",
        "quoteArgs": true
      },
      "sourceFileMap": {
        "/out": "${workspaceFolder}"
      },
      "justMyCode": true
    }
  ]
}
```
***NOTE***: Make sure to replace the above ip address with your own device’s ip
* Set up a passwordless SSH between your development machine and the Torizon device
* Now on the device run the following command `docker run –name Test <YOUR_DEBUG_CONTAINER_NAME>`
* On VSC place some breakpoints and start debugging. You’ll be prompted to select a process to debug. Your application process should be easy to find.
* Have fun debugging!

### Other Notes
* On the dotnet source container images from Microsoft make sure the versions match both in the container and what's on your dev machine
* This is an unoptimized but quick getting started guide the container images created from these dockerfiles will be large. For a more optimized container image consider using the dotnet runtime and not the full sdk in the container

### Other References
[1](https://code.visualstudio.com/docs/other/dotnet)
[2](https://docs.microsoft.com/en-us/dotnet/core/docker/build-container)
[3](https://github.com/OmniSharp/omnisharp-vscode/wiki/Remote-Debugging-On-Linux-Arm)
