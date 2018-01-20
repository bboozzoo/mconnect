package logger

import (
	"context"
)

type loggerKeyType int

const (
	loggerContextKey loggerKeyType = 1
)

func FromContext(ctx context.Context) Logger {
	if logger, _ := ctx.Value(loggerContextKey).(Logger); logger != nil {
		return logger
	}
	return New()
}

func WithContext(ctx context.Context, logger Logger) context.Context {
	return context.WithValue(ctx, loggerContextKey, logger)
}
