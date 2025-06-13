(ns example.frontend.app
  (:require [reagent.core :as r]
            [reagent.dom.client :as rdom]))

(defn app []
  (let [counter (r/atom 0)]
    (fn []
      [:div
       [:p "The atom " [:code "click-count"] " has value " @counter "."]
       [:button {:type "button"
                 :on-click #(swap! counter inc)}
        "Click!"]])))

(defn ^:dev/after-load run []
  (-> (js/document.getElementById "app")
      (rdom/create-root)
      (rdom/render [app])))
