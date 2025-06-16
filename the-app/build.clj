(ns build
  (:require [clojure.tools.build.api :as b]))

(def uberjar "target/app.jar")
(def class-dir "target/classes")
(def basis
  (delay
    (b/create-basis {:project "deps.edn"
                     :aliases [:backend]})))

(defn clean [_]
  (b/delete {:path "target"})
  (b/delete {:path "public/app"})
  (b/delete {:path ".shadow-cljs"}))

(defn- process
  "Start a sub-process with `args` (like `clojure.tools.build.api/process`), but
  fail whenever its exit code signals failure."
  [args]
  (let [{exit :exit :as process-result} (b/process args)]
    (when (> exit 0)
      (println "Process failed:" process-result)
      (System/exit exit))))

(defn- shadow-cljs
  "Call shadow-cljs and perform `task` on the frontend code."
  [task]
  (let [frontend-basis (b/create-basis
                        {:project "deps.edn"
                         :aliases [:frontend]})]
    (process (b/java-command
              {:basis frontend-basis
               :main 'clojure.main
               :main-args ["-m"
                           "shadow.cljs.devtools.cli"
                           (str task)
                           "frontend"]}))))

(defn watch [_]
  (shadow-cljs "watch"))

(defn uber [_]
  (clean nil)
  (shadow-cljs "release")
  (b/copy-dir {:src-dirs ["public"]
               :target-dir class-dir})
  (b/compile-clj {:basis @basis
                  :ns-compile '[example.backend.main]
                  :class-dir class-dir})
  (b/uber {:basis @basis
           :class-dir class-dir
           :uber-file uberjar
           :main 'example.backend.main}))
