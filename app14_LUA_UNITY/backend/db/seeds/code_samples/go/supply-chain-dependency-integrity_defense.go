// SECURE pattern
// WHY: go.sum pins the exact expected hash of every dependency; -mod=readonly refuses to build
// if go.mod/go.sum would need to change, catching a tampered or unexpectedly-updated dependency
// GOFLAGS=-mod=readonly GOSUMDB=sum.golang.org go build ./...
