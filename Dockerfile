# Build the go application into a binary
FROM golang:alpine AS builder
RUN apk --update add ca-certificates
# Install missing Cloudflare and SSL.com CA certificates
# This fixes the issue: x509: certificate signed by unknown authority
RUN wget -O /etc/ssl/certs/cloudflare-tls-ecc-issuing-ca-1.crt \
    https://ssl-tools.net/certificates/b4d9bf55ed18bda0ed3e6e6278f85a50dc0db6f9.pem && \
    wget -O /etc/ssl/certs/ssl-com-transit-ecc-ca-r2.crt \
    https://ssl-tools.net/certificates/5cd5961e1efd90ec72bbccc99a0f66ab1f61d464.pem
WORKDIR /app
COPY . ./
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .

# Run Tests inside docker image if you don't have a configured go environment
#RUN apk update && apk add --virtual build-dependencies build-base gcc
#RUN go test ./... -mod vendor

# Run the binary on an empty container
FROM scratch
COPY --from=builder /app/gatus .
COPY --from=builder /app/config.yaml ./config/config.yaml
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /etc/ssl/certs/cloudflare-tls-ecc-issuing-ca-1.crt /etc/ssl/certs/cloudflare-tls-ecc-issuing-ca-1.crt
COPY --from=builder /etc/ssl/certs/ssl-com-transit-ecc-ca-r2.crt /etc/ssl/certs/ssl-com-transit-ecc-ca-r2.crt
ENV GATUS_CONFIG_PATH=""
ENV GATUS_LOG_LEVEL="INFO"
ENV PORT="8080"
EXPOSE ${PORT}
ENTRYPOINT ["/gatus"]
