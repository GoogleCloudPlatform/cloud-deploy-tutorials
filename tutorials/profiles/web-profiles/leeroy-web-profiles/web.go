// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"io"
	"net/http"

	"log"
)

func handler(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://leeroy-app-profiles:50051")
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	if _, err := io.Copy(w, resp.Body); err != nil {
		panic(err)
	}
}

func main() {
	log.Print("leeroy web server ready")
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
