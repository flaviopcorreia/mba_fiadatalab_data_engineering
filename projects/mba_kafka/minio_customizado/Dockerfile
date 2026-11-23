FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git make
RUN go install github.com/minio/minio@latest

FROM alpine:latest
RUN apk add --no-cache ca-certificates curl
COPY --from=builder /go/bin/minio /usr/bin/minio
ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]