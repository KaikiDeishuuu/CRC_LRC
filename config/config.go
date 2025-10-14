package config

import (
	"fmt"
	"time"

	"github.com/spf13/viper"
)

// AppConfig 应用程序的配置结构体
type AppConfig struct {
	Server struct {
		Port           int           `mapstructure:"port"`
		ReadTimeout    time.Duration `mapstructure:"readTimeout"`
		WriteTimeout   time.Duration `mapstructure:"writeTimeout"`
		IdleTimeout    time.Duration `mapstructure:"idleTimeout"`
		MaxHeaderBytes int           `mapstructure:"maxHeaderBytes"`
	} `mapstructure:"server"`
	Log struct {
		Level string `mapstructure:"level"`
	} `mapstructure:"log"`
	Checksum struct {
		MaxInputLengthBytes int `mapstructure:"maxInputLengthBytes"`
		MaxFileUploadSizeMB int `mapstructure:"maxFileUploadSizeMB"`
	} `mapstructure:"checksum"`
}

var Cfg AppConfig

// LoadConfig 从文件加载配置
func LoadConfig() error {
	viper.SetConfigName("config") // 配置文件名 (不带扩展名)
	viper.SetConfigType("yaml")   // 配置文件类型
	viper.AddConfigPath("./config") // 搜索 config 目录

	// 设置默认值
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.readTimeout", "5s")
	viper.SetDefault("server.writeTimeout", "10s")
	viper.SetDefault("server.idleTimeout", "15s")
	viper.SetDefault("server.maxHeaderBytes", 1048576) // 1MB

	viper.SetDefault("log.level", "info")

	viper.SetDefault("checksum.maxInputLengthBytes", 1048576) // 1MB
	viper.SetDefault("checksum.maxFileUploadSizeMB", 11)      // 10MB + 1MB for header/metadata

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// 配置文件未找到，使用默认值
			fmt.Println("Config file not found, using default settings.")
		} else {
			return fmt.Errorf("failed to read config file: %w", err)
		}
	}

	if err := viper.Unmarshal(&Cfg); err != nil {
		return fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return nil
}