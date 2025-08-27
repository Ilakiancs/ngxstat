# ngxstat

ngxstat is a command-line program to query request counts from nginx's access.log files.

```
$ ngxstat url user_agent --since 1d --where url=/blog/% --where status=200 --limit 5
PATH                                             USER_AGENT     #REQS
/blog/deconstructing-the-role-playing-videogame/ Safari         120
/blog/on-ai-assistance/                          Go-http-client 101
/blog/a-note-on-essential-complexity/            Safari         91
/blog/deconstructing-the-role-playing-videogame/ Chrome         84
/blog/from-rss-to-my-kindle/                     Safari         79
```

## Installation

Download the [latest release binary](https://github.com/ilakianpuvanendra/ngxstat/releases/latest) for your platform, for example:

    $ wget https://github.com/ilakianpuvanendra/ngxstat/releases/latest/download/ngxstat-linux-arm64  \
        -O ngxstat && chmod +x ngxstat && mv ngxstat /usr/local/bin

Alternatively, install with go:

    $ go install github.com/ilakianpuvanendra/ngxstat@latest

## Usage examples

Count requests from the last hour:

    $ ngxstat --since 1h
    $ ngxstat -s 1h
    $ ngxstat

Count requests from the last second, minute, day, week, or month:

    $ ngxstat -s 1s
    $ ngxstat -s 1m
    $ ngxstat -s 1d
    $ ngxstat -s 1w
    $ ngxstat -s 1M

Count requests from the day before:

    $ ngxstat --since 2d --until 1d
    $ ngxstat -s 2d -u 1d

Show the top 5 urls in the last hour:

    $ ngxstat url
    $ ngxstat path

Show the top 5 urls in the last minute:

    $ ngxstat url -s 1m

Show the top 10 urls in the last hour:

    $ ngxstat url --limit 10
    $ ngxstat url -l 10

Count total requests to a specific url in the last hour:

	$ ngxstat --where url=/blog/code-is-run-more-than-read
	$ ngxstat --where path=/blog/code-is-run-more-than-read
	$ ngxstat -w url=/blog/code-is-run-more-than-read

Count total requests to urls matching a pattern:

	$ ngxstat -w url=/blog/%

Count total requests to urls excluding a value or pattern:

	$ ngxstat -w url!=/feed.xml
	$ ngxstat -w url!=/feed%

Count total requests to one of mutliple urls (one OR another):

	$ ngxstat -w url=/blog/code-is-run-more-than-read -w url=/blog/a-note-on-essential-complexity

Count total requests to a specific urls AND referer:

	$ ngxstat -w url=/blog/code-is-run-more-than-read -w referer=news.ycombinator.com

Show the top visited urls matching a pattern:

	$ ngxstat url -w url=/blog/%

Show the top requesting ips:

    $ ngxstat ip

Show the top url visits by ip:

    $ ngxstat url -w ip=77.16.76.86

Show the top user agents by url:

    $ ngxstat user_agent -w url=/blog/code-is-run-more-than-read
    $ ngxstat ua -w url=/blog/code-is-run-more-than-read

Show the top urls by user agent details (parsed with [mileusna/useagent](https://pkg.go.dev/github.com/mileusna/useragent)):

    $ ngxstat url -w ua=Firefox
    $ ngxstat url -w ua_type=bot
    $ ngxstat url -w device=iPhone
    $ ngxstat url -w os=Linux

Show the top referers for a url pattern:

    $ ngxstat referer -w url=/blog/%

Show the top user agent and referer combination

    $ ngxstat ua referer

Show the top user agent and referer combination for a specific url

    $ ngxstat ua referer -w url=/blog/code-is-run-more-than-read

Count total 404 status responses:

    $ ngxstat -w status=404

Count non successful responses:

    $ ngxstat status -w status=4% -w status=5%

## How it works

- Whenever the program is run, it looks for the nginx access.logs, parses them and stores the data into an SQLite DB.
  - By default, the logs are looked up at `/var/log/nginx/access.log*`, which can be overridden with the `NGXSTAT_LOGS_PATH` environment variable.
  - By default, the logs are assumed to have the [nginx combined log format](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format). The format can be customized with `NGXSTAT_LOG_FORMAT`.
    - This could likely be made to work with non nginx logs, although that hasn't been tested.
  - Subsequent runs of the program only parse and store the logs up until the time of the previous run.
  - The SQLite DB is stored at `./ngxstat.db`, which can be overridden with the `NGXSTAT_DB` environment variable.
- The command line arguments express a filtering criteria, used to build the SQL query that counts the requests.
  - For instance, the command `ngxstat url -w url=/blog/%` produces:
    ```sql
    SELECT path,count(1) '#reqs' FROM access_logs
    WHERE time > ? AND time < ? AND (path LIKE ?)
    GROUP BY 1
    ORDER BY count(1)
    DESC LIMIT 5
    ```

## Configuration

The command-line arguments and flags are intended exclusively to express a requests count query. The configuration, which isn't expected to change across command invocations, is left to environment variables:

- `NGXSTAT_LOGS_PATH`: path pattern to find the nginx access logs. Defaults to `/var/log/nginx/access.log*`. The pattern is expanded using Go's [`path/filepath.Glob`](https://pkg.go.dev/path/filepath#Glob).
- `NGXSTAT_LOG_FORMAT`: The [nginx log_format](https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format "
") specification to parse the log entries. By default combined logs are assumed, which is equivalent to:
  ```
  NGXSTAT_LOG_FORMAT='$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
  ```
- `NGXSTAT_DEBUG`: when set, internal logs will be printed to standard output.
- `NGXSTAT_DB`: location of the SQLite db where the parsed logs are stored. Defaults to `./ngxstat.db`.
