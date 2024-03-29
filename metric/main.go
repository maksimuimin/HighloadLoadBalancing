package main

import (
	"fmt"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/log"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func main() {
	cpuUsage := promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "cpu_usage",
		})

	go func() {
		for {
			contents, err := ioutil.ReadFile("/proc/stat")
			if err != nil {
				fmt.Println("Unable to read /proc/stat")
				continue
			}
			lines := strings.Split(string(contents), "\n")
			var total, idle uint64
			for _, line := range lines {
				fields := strings.Fields(line)
				if fields[0] == "cpu" {
					numFields := len(fields)
					for i := 1; i < numFields; i++ {
						val, err := strconv.ParseUint(fields[i], 10, 64)
						if err != nil {
							fmt.Println("Unable to parse field", i, "=", fields[i], "error:", err)
						}
						total += val // tally up all the numbers to get total ticks
						if i == 4 {  // idle is the 5th field in the cpu line
							idle = val
						}
					}
					break
				}
			}
			cpuUsage.Set((float64(total - idle) / float64(total)) * 100)
			time.Sleep(1000 * time.Millisecond)
		}
	}()

	http.Handle("/stats/prometheus", promhttp.Handler())
	log.Fatal(http.ListenAndServe(":8010", nil))
}
