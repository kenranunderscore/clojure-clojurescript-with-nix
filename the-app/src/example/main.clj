(ns example.main
  (:require [ring.adapter.jetty :as jetty]))

(defn handler [_request]
  {:status 200
   :headers {"Content-Type" "text/html"}
   :body "Hello World"})

(defn -main []
  (println "Running server on port 3000...")
  (jetty/run-jetty handler
                   {:port 3000
                    :join? false}))
