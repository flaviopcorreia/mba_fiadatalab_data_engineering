FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git make
RUN go install github.com/minio/mc@latest

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /go/bin/mc /usr/bin/mc

# O entrypoint padrão será apenas o chamador do programa
ENTRYPOINT ["mc"]