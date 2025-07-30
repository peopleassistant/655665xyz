package main

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"time"
)

func main() {
	exitOnError := func(err error) {
		if err != nil {
			fmt.Println(err)
			os.Exit(0)
		}
	}
	config := struct {
		listenAddr string
		closeWait  time.Duration
	}{"0.0.0.0:80", 10}
	for i := 1; i < len(os.Args); i++ {
		switch os.Args[i] {
		case "-laddr":
			config.listenAddr = os.Args[i+1]
			i++
		case "-cwait":
			closeWait, err := strconv.Atoi(os.Args[i+1])
			exitOnError(err)
			config.closeWait = time.Second * time.Duration(closeWait)
			i++
		default:
			fmt.Println("Usage: " + os.Args[0] + " [-laddr <listen addr(default: 0.0.0.0:80)>] [-cwait <close wait seconds(default: 10)>]")
			return
		}
	}
	config.closeWait *= time.Second
	httpListener, err := net.Listen("tcp", config.listenAddr)
	exitOnError(err)
	resp := []byte{}
	genResp := func() []byte {
		html := `<!DOCTYPE html>
<html>
	<head>
		<script type="text/javascript">
			location.protocol = 'https:';
		</script>
	</head>
	<body></body>
</html>
`
		return []byte("HTTP/1.1 200 OK\r\n" +
			"Content-Type: text/html\r\n" +
			"Content-Length: " + strconv.Itoa(len(html)) + "\r\n" +
			"Connection: close\r\n\r\n" + html)
	}
	resp = genResp()
	for {
		conn, err := httpListener.Accept()
		if err != nil {
			continue
		}
		go func() {
			conn.Write(resp)
			time.Sleep(config.closeWait)
			conn.Close()
		}()
	}
}
