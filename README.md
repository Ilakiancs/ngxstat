# ngxstat

Query nginx access logs with SQL-like precision.

```
$ ngxstat url status --since 1d --where url=/api/% --limit 10
URL                    STATUS  #REQS
/api/users            200     1.2K
/api/posts            404     890
/api/auth             200     567
```

## Install

```bash
go install github.com/ilakianpuvanendra/ngxstat@latest
```

## Usage

Basic request counts:
```bash
ngxstat                           # last hour
ngxstat --since 1d                # last day
ngxstat --since 2h --until 1h     # specific window
```

Group by dimensions:
```bash
ngxstat url                       # top URLs
ngxstat ip                        # top IPs
ngxstat status                    # response codes
ngxstat user_agent url            # combinations
```

Filter with WHERE:
```bash
ngxstat -w status=404             # only 404s
ngxstat -w url=/blog/%            # URL patterns
ngxstat -w ip=192.168.1.1         # specific IP
ngxstat -w status!=200            # exclude 200s
```

Time units: `s`, `m`, `h`, `d`, `w`, `M`

## How It Works

Parses nginx logs into SQLite on first run. Subsequent runs are incremental.

Default log path: `/var/log/nginx/access.log*`
Default DB path: `./ngxstat.db`

## Config

Set via environment:

- `NGXSTAT_LOGS_PATH` - log file pattern
- `NGXSTAT_LOG_FORMAT` - nginx format string  
- `NGXSTAT_DB` - database location
- `NGXSTAT_DEBUG` - enable logging

## Fields

Available for grouping and filtering:

`url`, `ip`, `status`, `method`, `user_agent`, `referer`, `host`, `os`, `device`, `ua_type`

Derived fields like `os` and `device` are parsed from user agents automatically.