

FROM registry.access.redhat.com/ubi8/nodejs-14 AS builder
USER 0
COPY . /tmp/src
RUN chown -R 1001:0 /tmp/src
USER 1001

# Instal OJET Cli globally
RUN npm install -g @oracle/ojet-cli

WORKDIR /tmp/src

# Start the build process in release mode
RUN ojet build --release


FROM registry.access.redhat.com/ubi8/nginx-118
USER 0

# Inside builder image a file is created named inside scripts/hooks/after_build.js
# Keep those names synchronized !!!
COPY --from=builder /tmp/src/my-archive.zip /tmp/application.zip

RUN mkdir /tmp/src && cd /tmp/src && unzip /tmp/application.zip && rm /tmp/application.zip
RUN chown -R 1001:0 /tmp/src
USER 1001
# Let the assemble script to install the dependencies
RUN /usr/libexec/s2i/assemble

EXPOSE 8080

# Run script uses standard ways to run the application
CMD /usr/libexec/s2i/run



# create scripts/hooks/after_build.js
#/**
#  Copyright (c) 2015, 2021, Oracle and/or its affiliates.
#  Licensed under The Universal Permissive License (UPL), Version 1.0
#  as shown at https://oss.oracle.com/licenses/upl/
#*/
#
#'use strict';
#const fs = require('fs');
#const archiver = require('archiver');
#module.exports = function (configObj) {
#  return new Promise((resolve, reject) => {
#   console.log("Running after_build hook.");
#
#    //change the extension of the my-archive.xxx file from .war to .zip as needed
#    const output = fs.createWriteStream('my-archive.zip');
#    //leave unchanged, compression is the same for WAR or Zip file
#    const archive = archiver('zip');
#
#    output.on('close', () => {
#      console.log('Files were successfully archived.');
#      resolve();
#    });
#
#    archive.on('warning', (error) => {
#      console.warn(error);
#    });
#
#    archive.on('error', (error) => {
#      reject(error);
#    });
#
#    archive.pipe(output);
#    archive.directory('web', false);
#    archive.finalize();
#  });
#};
#

