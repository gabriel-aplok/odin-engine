package logger

import "core:fmt"
import "core:os"
import "core:time"

Level :: enum {
	Debug,
	Info,
	Warn,
	Error,
}

Logger :: struct {
	level:    Level,
	file:     ^os.File,
	has_file: bool,
}

DEFAULT_LEVEL :: Level.Info

make_logger :: proc(level: Level = DEFAULT_LEVEL) -> Logger {
	return Logger{level = level}
}

open_file :: proc(l: ^Logger, path: string) -> bool {
	handle, err := os.open(path, {.Write, .Create, .Append})
	if err != nil {
		return false
	}
	if l.has_file {
		os.close(l.file)
	}
	l.file = handle
	l.has_file = true
	return true
}

close_logger :: proc(l: ^Logger) {
	if l.has_file {
		os.close(l.file)
		l.has_file = false
	}
}

should_write :: proc(l: ^Logger, level: Level) -> bool {
	return level >= l.level
}

write :: proc(l: ^Logger, level: Level, category: string, message: string) {
	if !should_write(l, level) {
		return
	}
	now := time.now()
	hour, min, sec := time.clock(now)
	buf := fmt.aprintf(
		"%04d-%02d-%02d %02d:%02d:%02d [%s] [%s] %s\n",
		time.year(now),
		time.month(now),
		time.day(now),
		hour,
		min,
		sec,
		level,
		category,
		message,
	)
	defer delete(buf)
	if l.has_file {
		os.write_string(l.file, buf)
	}
}

debug :: proc(l: ^Logger, category, message: string) {
	write(l, .Debug, category, message)
}

info :: proc(l: ^Logger, category, message: string) {
	write(l, .Info, category, message)
}

warn :: proc(l: ^Logger, category, message: string) {
	write(l, .Warn, category, message)
}

error :: proc(l: ^Logger, category, message: string) {
	write(l, .Error, category, message)
}

// one shared logger. small games do not need more than one.
@(private)
g_logger: Logger

init :: proc(level: Level = DEFAULT_LEVEL) {
	g_logger = make_logger(level)
}

shutdown :: proc() {
	close_logger(&g_logger)
}

set_level :: proc(level: Level) {
	g_logger.level = level
}

open_log_file :: proc(path: string) -> bool {
	return open_file(&g_logger, path)
}

debug_msg :: proc(category, message: string) {
	debug(&g_logger, category, message)
}

info_msg :: proc(category, message: string) {
	info(&g_logger, category, message)
}

warn_msg :: proc(category, message: string) {
	warn(&g_logger, category, message)
}

error_msg :: proc(category, message: string) {
	error(&g_logger, category, message)
}
