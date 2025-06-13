(ns example.backend.main
  (:require [ring.adapter.jetty :as jetty]
            [ring.middleware.resource :as resource]
            [ring.middleware.content-type :as content-type]
            [ring.middleware.not-modified :as not-modified]))

(def app
  (-> (fn [_request] {:status 404})
      (resource/wrap-resource ".")
      (content-type/wrap-content-type)
      (not-modified/wrap-not-modified)))

(defn -main []
  (println "Running server on port 3000...")
  (jetty/run-jetty
   app
   {:port 3000 :join? false}))
