package router

import (
	"CRC_LRC/internal/handler"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
)

// SetupRouter 配置所有HTTP路由
func SetupRouter() *mux.Router {
	r := mux.NewRouter()

	// 首页和静态文件服务
	r.HandleFunc("/", handler.HomeHandler).Methods("GET")
	// 提供前端构建的静态资源（JS、CSS等）
	r.PathPrefix("/assets/").Handler(http.StripPrefix("/assets/", http.FileServer(http.Dir("frontend/dist/assets"))))

	// API路由 - 新的前端使用
	r.HandleFunc("/api/checksum", handler.ChecksumMultiHandler).Methods("POST")
	r.HandleFunc("/api/crc", handler.CRCHandler).Methods("POST")
	r.HandleFunc("/api/lrc", handler.LRCHandler).Methods("POST")

	// API v1 路由 - 保留旧的API以保持向后兼容
	apiV1 := r.PathPrefix("/api/v1").Subrouter()
	apiV1.HandleFunc("/checksum", handler.ChecksumHandler).Methods("GET")
	apiV1.HandleFunc("/file-checksum", handler.FileChecksumHandler).Methods("POST")

	// 添加日志中间件
	r.Use(loggingMiddleware)

	return r
}

// loggingMiddleware 是一个简单的请求日志中间件
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logrus.WithFields(logrus.Fields{
			"method": r.Method,
			"path":   r.URL.Path,
			"remote": r.RemoteAddr,
		}).Info("Incoming request")
		next.ServeHTTP(w, r)
	})
}
