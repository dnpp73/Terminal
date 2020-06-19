hterm.defaultStorage = new lib.Storage.Memory();

const onTerminalReady = () => {
    // JavaScript -> Native
    const native = new Proxy({}, {
        get(obj, prop) {
            return (...args) => {
                if (args.length == 0) {
                    args = null;
                } else if (args.length == 1) {
                    args = args[0];
                }
                if (window.webkit) {
                    webkit.messageHandlers[prop].postMessage(args);
                }
            };
        },
    });

    window.native_log = (obj) => {
        native.log(obj + "");
    }

    // Native -> JavaScript
    window.exports = {};

    const io  = term.io.push();
    term.reset();

    exports.write = (data) => {
        io.writeUTF16(data); // same as `io.print(data);`
        // io.writeUTF8(data); // writeUTF8() is legacy in hterm.
    };

    io.sendString = (str) => {
        native.htermHandleSendString(str);
    };

    io.onVTKeyStroke = (str) => {
        native.htermHandleOnVTKeyStroke(str);
    };

    io.onTerminalResize = (cols, rows) => {
        if (term.prompt) {
            term.prompt.resize();
        }
        native.htermHandleOnTerminalResize(cols, rows);
    };

    exports.syncTerminalSize = () => {
        // We don't use `hterm.Terminal.prototype.realizeSize_` because it will fire new `onTerminalResize_` notification.
        // first: height
        const rows = term.screen_.getHeight() // don't trust `this.screenSize`
        term.realizeHeight_(rows);

        // next: width
        const cols = term.screen_.getWidth()
        term.realizeWidth_(cols);

        return [cols, rows]
    };

    term.scrollPort_.getScreenNode().contentEditable = false;

    term.scrollPort_.getScreenNode().addEventListener('focus', (e) => {
        native.htermDidFocusScreen();
    }, {capture: false});

    term.scrollPort_.getScreenNode().addEventListener('blur', (e) => {
        native.htermDidBlurScreen();
    }, {capture: false});

    term.scrollPort_.onTouch = (e) => {
        if (e.type == 'touchstart') {
            native.htermScrollPortDidTouchStart();
        } else if (e.type == 'touchmove') {
            native.htermScrollPortDidTouchMove();
        } else if (e.type == 'touchend') {
            native.htermScrollPortDidTouchEnd();
        } else if (e.type == 'touchcancel') {
            native.htermScrollPortDidTouchCancel();
        }
    };

    exports.clearSelection = () => {
        window.getSelection().removeAllRanges();
    };

    // css string. Default: '"DejaVu Sans Mono", "Noto Sans Mono", "Everson Mono", FreeMono, Menlo, Terminal, monospace'. See hterm_all.js@L9932
    exports.setFontFamily = (fontFamily) => {
        term.getPrefs().set('font-family', fontFamily);
        // `terminal.syncFontFamily();` will automatically fire. in hterm_all.js@L14032 `this.prefs_.addObservers()`
    };

    // true or false or null. Null to autodetect. default null
    exports.setEnableBold = (enabled) => {
        term.getPrefs().set('enable-bold', enabled);
    };

    // true or false. default true
    exports.setEnableBoldAsBright = (enabled) => {
        term.getPrefs().set('enable-bold-as-bright', enabled);
    };

    exports.getCharacterSize = () => {
        return [term.scrollPort_.characterSize.width, term.scrollPort_.characterSize.height];
    };

    exports.setUserGesture = () => {
        term.accessibilityReader_.hasUserGesture = true;
    };

    hterm.openUrl = (url) => {
        native.htermDidHandleURL(url);
    };

    term.setCursorShape(hterm.Terminal.cursorShape.BEAM);

    native.htermDidLoad();
};


const htermSetup = () => {
    window.term = new hterm.Terminal();

    const css = `
        x-screen {
            background: transparent !important;
        }
        x-screen::-webkit-scrollbar {
            display: none;
        }
    `;

    const p = term.getPrefs();
    p.set('background-color', 'transparent');
    p.set('foreground-color', 'transparent');
    p.set('cursor-color', 'transparent');

    p.set('terminal-encoding', 'raw'); // or 'iso-2022'

    p.set('font-family', 'Menlo');
    p.set('font-size', 9);

    p.set('enable-resize-status', false);
    p.set('copy-on-select', false);
    p.set('enable-clipboard-notice', false);
    p.set('user-css-text', css);

    p.set('audible-bell-sound', '');
    p.set('receive-encoding', 'raw');
    p.set('allow-images-inline', true);

    p.set('scroll-wheel-may-send-arrow-keys', true);

    term.decorate(document.getElementById('terminal'));

    // term.installKeyboard();

    term.onTerminalReady = onTerminalReady;
};

window.onload = () => {
    lib.init(htermSetup);
};
