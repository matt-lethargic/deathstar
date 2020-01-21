FROM nodered/node-red:latest
RUN for addonnodes in \
node-red-node-pi-gpiod \
node-red-dashboard \
node-red-node-google \
node-red-contrib-influxdb \
node-red-contrib-alexa-local \
; do \
npm install ${addonnodes} ;\
done;
