package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "leeroooooy app running in target: %s!!\n", os.Getenv("TARGET"))
}

func main() {
	log.Printf("leeroy app server ready, runnning in target: %s", os.Getenv("TARGET"))
	http.HandleFunc("/", handler)
	http.ListenAndServe(":50051", nil)
}
