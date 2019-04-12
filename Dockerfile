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