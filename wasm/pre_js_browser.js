/********************************************************************/
/*  pre_js_browser.js  Emscripten pre-js for browser (raycaster).   */
/*  Same as seed7 pre_js.js but preserves Module if already set     */
/*  (so index.html can set Module.arguments and Module.preRun).    */
/********************************************************************/

var mapIdToWindow = {};
var mapIdToCanvas = {};
var mapIdToContext = {};
var currentWindowId = 0;
var reloadPageFunction = null;
var deregisterWindowFunction = null;
var callbackList = [];
function registerCallback (callback) {
    callbackList.push(callback);
}
function executeCallbacks () {
    for (let i = 0; i < callbackList.length; i++) {
        callbackList[i](1114511);
    }
    callbackList = [];
}
var callbackList2 = [];
function registerCallback2 (callback) {
    callbackList2.push(callback);
}
function executeCallbacks2 () {
    for (let i = 0; i < callbackList2.length; i++) {
        callbackList2[i](["", null]);
    }
    callbackList2 = [];
}

if (typeof window !== "undefined" && typeof document !== "undefined") {
  var seed7OriginalOpen = window.open;
  window.open = function(url, name, features) {
    var openedWindow = null;
    if (typeof seed7OriginalOpen === "function") {
      openedWindow = seed7OriginalOpen.call(window, url, name, features);
    }
    return openedWindow || window;
  };
}

if (typeof document !== "undefined") {
  var scripts = document.getElementsByTagName('script');
  var myScript = null;
  for (var index = 0; index < scripts.length; index++) {
    if (scripts[index].src !== "undefined" && scripts[index].src !== "") {
      myScript = scripts[index];
    }
  }
  if (myScript) {
    var src = myScript.src;
    var bslash = String.fromCharCode(92);
    var questionMarkPos = src.search(bslash + '?');
    var programPath = myScript.src;
    var queryString = '';
    if (questionMarkPos !== -1) {
      queryString = programPath.substring(questionMarkPos + 1);
      programPath = programPath.substring(0, questionMarkPos);
    }
    var arguments = queryString.split('&');
    for (var i = 0; i < arguments.length; i++) {
      arguments[i] = decodeURIComponent(arguments[i]);
    }
    /* Preserve existing Module (e.g. from index.html with preRun and arguments) */
    if (typeof Module === "undefined" || !Module.preRun || Module.preRun.length === 0) {
      Module = {
        'thisProgram': programPath,
        'arguments': arguments
      };
    }
  }
} else if (typeof Module !== "undefined") {
}
