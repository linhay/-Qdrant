# 1
FROM swiftlang/swift:nightly-5.9-jammy
WORKDIR /app
COPY . .

# 2
RUN apt-get update && apt-get install libsqlite3-dev

# 3
RUN swift package clean
RUN swift build

# 4
RUN mkdir /app/bin
RUN mv `swift build --show-bin-path` /app/bin

# 5
EXPOSE 8080
ENTRYPOINT ./bin/debug/Run serve --env local --hostname 0.0.0.0

# docker build . --file development.Dockerfile --tag til-app-dev