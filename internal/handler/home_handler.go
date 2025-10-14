package handler

import (
	"html/template"
	"net/http"

	"github.com/sirupsen/logrus"
)

// HomeHandler 渲染首页HTML
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	tmpl, err := template.ParseFiles("frontend/dist/index.html")
	if err != nil {
		logrus.Errorf("Error parsing template: %v", err)
		sendError(w, http.StatusInternalServerError, "Internal server error: could not load UI")
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := tmpl.Execute(w, nil); err != nil {
		logrus.Errorf("Error executing template: %v", err)
		sendError(w, http.StatusInternalServerError, "Internal server error: could not render UI")
	}
}