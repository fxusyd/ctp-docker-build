FROM debian:stable-slim as build

RUN apt-get update && apt-get -y install \
 curl \
 unzip

ARG TARGETARCH

RUN if [ "${TARGETARCH}" = "amd64" ]; then export IMAGEIO="linux-x86_64.zip"; else export IMAGEIO="ImageIOJars.zip"; fi \
 && curl -LOsS https://raw.githubusercontent.com/johnperry/CTP/master/products/CTP-installer.jar \
 && curl -o ImageIO-arch.zip -LsS https://raw.githubusercontent.com/RSNA/mirc.rsna.org/main/ImageIO/${IMAGEIO}

RUN mkdir -p /JavaPrograms/ext /JavaPrograms/lib \
 && unzip ImageIO-arch.zip -d /JavaPrograms/ext \
 && mv /JavaPrograms/ext/*.so /JavaPrograms/lib ||: \
 && unzip CTP-installer.jar -d /JavaPrograms


FROM debian:stable-slim

RUN apt-get update && apt-get -y install \
 openjdk-17-jre-headless \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /JavaPrograms/ /JavaPrograms/

COPY ./ /

RUN ln -sfr /JavaPrograms/config/config.xml /JavaPrograms/CTP/config.xml \
 && ln -sfr /JavaPrograms/config/index.html /JavaPrograms/CTP/ROOT/index.html \
 && ln -sfr /JavaPrograms/config/keystore /JavaPrograms/CTP/keystore \
 && ln -sfr /JavaPrograms/config/users.xml /JavaPrograms/CTP/users.xml

# java -XshowSettings:properties -version
ENV CLASSPATH="/JavaPrograms/CTP/libraries:/JavaPrograms/ext" \
 LD_LIBRARY_PATH="/JavaPrograms/lib" \
 TZ="UTC"

WORKDIR /JavaPrograms/CTP
EXPOSE 8080/tcp
CMD ["java","-jar","Runner.jar"]