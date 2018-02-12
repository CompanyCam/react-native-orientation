var Orientation = require('react-native').NativeModules.Orientation;
var DeviceEventEmitter = require('react-native').DeviceEventEmitter;
var NativeEventEmitter = require('react-native').NativeEventEmitter;
var Platform = require('react-native').Platform;

var OrientationEmitter = new NativeEventEmitter(Orientation);

var listeners = {};
var orientationDidChangeEvent = 'orientationDidChange';
var specificOrientationDidChangeEvent = 'specificOrientationDidChange';
var CCCameraOrientationChange = 'CCCameraOrientationChange';

var id = 0;
var META = '__listener_id';

function getKey(listener) {
  if (!listener.hasOwnProperty(META)) {
    if (!Object.isExtensible(listener)) {
      return 'F';
    }

    Object.defineProperty(listener, META, {
      value: 'L' + ++id,
    });
  }

  return listener[META];
};

module.exports = {
  getOrientation(cb) {
    Orientation.getOrientation((error, orientation) => {
      cb(error, orientation);
    });
  },

  getSpecificOrientation(cb) {
    Orientation.getSpecificOrientation((error, orientation) => {
      cb(error, orientation);
    });
  },

  lockToPortrait() {
    Orientation.lockToPortrait();
  },

  lockToLandscape() {
    Orientation.lockToLandscape();
  },

  lockToLandscapeRight() {
    Orientation.lockToLandscapeRight();
  },

  lockToLandscapeLeft() {
    Orientation.lockToLandscapeLeft();
  },

  unlockAllOrientations() {
    Orientation.unlockAllOrientations();
  },

  addOrientationListener(cb) {
    if (Platform.OS === 'ios') {
      var key = getKey(cb);

      listeners[key] = OrientationEmitter.addListener(orientationDidChangeEvent,
        (body) => {
          cb(body.orientation);
        });
    } else {
      var key = getKey(cb);
      listeners[key] = DeviceEventEmitter.addListener(orientationDidChangeEvent,
        (body) => {
          cb(body.orientation);
        });
    }
  },

  removeOrientationListener(cb) {
    var key = getKey(cb);

    if (!listeners[key]) {
      return;
    }

    listeners[key].remove();
    listeners[key] = null;
  },

  addSpecificOrientationListener(cb) {
    if (Platform.OS === 'ios') {
      var key = getKey(cb);

      listeners[key] = OrientationEmitter.addListener(specificOrientationDidChangeEvent,
        (body) => {
          cb(body.orientation);
        });
    } else {
      var key = getKey(cb);

      listeners[key] = DeviceEventEmitter.addListener(specificOrientationDidChangeEvent,
        (body) => {
          cb(body.specificOrientation);
        });
    }
  },

  removeSpecificOrientationListener(cb) {
    var key = getKey(cb);

    if (!listeners[key]) {
      return;
    }

    listeners[key].remove();
    listeners[key] = null;
  },

  addCCCameraOrientationListener(cb) {
    if (Platform.OS === 'ios') {
      var key = getKey(cb);

      listeners[key] = OrientationEmitter.addListener(CCCameraOrientationChange,
        (body) => {
          cb(body.orientation);
        });
    } else {
      var key = getKey(cb);

      listeners[key] = DeviceEventEmitter.addListener(CCCameraOrientationChange,
        (body) => {
          cb(body.orientation);
        });
    }
  },

  removeCCCameraOrientationListener(cb) {
    var key = getKey(cb);

    if (!listeners[key]) {
      return;
    }

    listeners[key].remove();
    listeners[key] = null;
  },

  getInitialOrientation() {
    return Orientation.initialOrientation;
  },

  getOrientations() {
    return Orientation.orientationEnum;
  }
}
