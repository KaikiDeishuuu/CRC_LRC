package main

import (
	"CRC_LRC/config"
	"CRC_LRC/internal/router"
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/sirupsen/logrus"
)

func main() {
	// 1. 加载配置
	if err := config.LoadConfig(); err != nil {
		logrus.Fatalf("Failed to load configuration: %v", err)
	}

	// 2. 配置日志
	logrus.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
	})
	logLevel, err := logrus.ParseLevel(config.Cfg.Log.Level)
	if err != nil {
		logrus.Warnf("Invalid log level '%s', defaulting to info", config.Cfg.Log.Level)
		logLevel = logrus.InfoLevel
	}
	logrus.SetLevel(logLevel)

	logrus.Info("Application configuration loaded successfully.")

	// 3. 设置HTTP服务器
	r := router.SetupRouter()
	srv := &http.Server{
		Addr:           fmt.Sprintf(":%d", config.Cfg.Server.Port),
		Handler:        r,
		ReadTimeout:    config.Cfg.Server.ReadTimeout,
		WriteTimeout:   config.Cfg.Server.WriteTimeout,
		IdleTimeout:    config.Cfg.Server.IdleTimeout,
		MaxHeaderBytes: config.Cfg.Server.MaxHeaderBytes,
	}

	// 4. 优雅关机
	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGTERM) // 监听中断信号

	go func() {
		logrus.Infof("Server starting on port %d...", config.Cfg.Server.Port)
		logrus.Infof("Access web UI at: http://localhost:%d", config.Cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logrus.Fatalf("Could not listen on %s: %v\n", srv.Addr, err)
		}
	}()

	<-done // 阻塞直到接收到中断信号
	logrus.Info("Server Shutting Down...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logrus.Fatalf("Server Shutdown Failed:%+v", err)
	}
	logrus.Info("Server Exited Properly")
}
