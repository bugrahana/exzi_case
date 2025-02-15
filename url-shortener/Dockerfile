# First Stage: Build Stage
FROM golang:1.22 AS builder

WORKDIR /app
COPY . .

RUN go mod tidy
RUN go build -o myapp .

# Second Stage: Runtime Stage
FROM alpine:latest

WORKDIR /root/

# Copy the compiled binary from the build stage
COPY --from=builder /app/myapp .

CMD ["/root/myapp"]
