.PHONY: pull run db test build clean

pull:
	rsync -chavzP --stats $(SSH):/var/log/nginx/ logs/

run:
	NGXSTAT_LOGS_PATH=./logs/access.log* go run .

test:
	go test ./...

build:
	go build -o ngxstat

clean:
	rm -f ngxstat ngxstat.db

db:
	sqlite3 -cmd ".open ngxstat.db"

install:
	go install

fmt:
	go fmt ./...
