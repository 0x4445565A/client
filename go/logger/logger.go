package logger

import (
	"os"
	"path"
	"sync"
	//"syscall"

	logging "github.com/op/go-logging"
)

const (
	fancyFormat = "%{color}%{time:15:04:05.000000} ▶ %{level:.4s} %{id:03x}%{color:reset} %{message}"
	plainFormat = "%{level:.4s} %{id:03x} %{message}"
	niceFormat  = "%{color}▶ %{level:.4s} %{message} %{color:reset}"
)

const permDir os.FileMode = 0700

type Logger struct {
	logging.Logger
	filename       string
	rotateMutex    sync.Mutex
	configureMutex sync.Mutex
}

func New() *Logger {
	log := logging.MustGetLogger("keybase")
	ret := &Logger{Logger: *log}
	ret.initLogging()
	return ret
}

func (log *Logger) initLogging() {
	logBackend := logging.NewLogBackend(os.Stderr, "", 0)
	logging.SetBackend(logBackend)
	logging.SetLevel(logging.INFO, "keybase")
}

func (log *Logger) Profile(fmts string, arg ...interface{}) {
	log.Debug(fmts, arg...)
}

func (log *Logger) Errorf(fmt string, arg ...interface{}) {
	log.Error(fmt, arg...)
}

func (log *Logger) PlainLogging() {
	log.configureMutex.Lock()
	defer log.configureMutex.Unlock()
	logging.SetFormatter(logging.MustStringFormatter(plainFormat))
}

func (log *Logger) Configure(plain, debug bool, filename string) {
	log.configureMutex.Lock()
	defer log.configureMutex.Unlock()

	log.filename = filename

	fmt := niceFormat
	if plain {
		fmt = plainFormat
	} else if debug {
		fmt = fancyFormat
	}

	if debug {
		logging.SetLevel(logging.DEBUG, "keybase")
	}

	logging.SetFormatter(logging.MustStringFormatter(fmt))
}

func (log *Logger) RotateLogFile() error {
	/* NOTE COMMENTED OUT TEMP FOR TESTING */
	/*
			log.rotateMutex.Lock()
			defer log.rotateMutex.Unlock()
			log.Info("Rotating log file; closing down old file")
			_, file, err := OpenLogFile(log.filename)
			if err != nil {
				return err
			}
			err = PickFirstError(
				syscall.Close(1),
				syscall.Close(2),
				syscall.Dup2(int(file.Fd()), 1),
				syscall.Dup2(int(file.Fd()), 2),
				file.Close(),
			)
			log.Info("Rotated log file; opening up new file")

		return err
	*/
	return nil
}

func OpenLogFile(filename string) (name string, file *os.File, err error) {
	name = filename
	if err = MakeParentDirs(name); err != nil {
		return
	}
	file, err = os.OpenFile(name, (os.O_APPEND | os.O_WRONLY | os.O_CREATE), 0600)
	if err != nil {
		return
	}
	return
}

func FileExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func MakeParentDirs(filename string) error {
	dir, _ := path.Split(filename)
	exists, err := FileExists(dir)
	if err != nil {
		return err
	}

	if !exists {
		err = os.MkdirAll(dir, permDir)
		if err != nil {
			return err
		}
	}
	return nil
}

func PickFirstError(errors ...error) error {
	for _, e := range errors {
		if e != nil {
			return e
		}
	}
	return nil
}
