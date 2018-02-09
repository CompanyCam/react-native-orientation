package com.github.yamill.orientation;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.util.Log;
import android.view.OrientationEventListener;
import android.view.Surface;

import com.facebook.common.logging.FLog;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.ReactConstants;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nullable;

public class OrientationModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
    final BroadcastReceiver receiver;

    private OrientationEventListener mOrientationListener;

    public static final int CC_CAMERA_ORIENTATION_PORTRAIT = 0;
    public static final int CC_CAMERA_ORIENTATION_LANDSCAPE_LEFT = 1;
    public static final int CC_CAMERA_ORIENTATION_LANDSCAPE_RIGHT = 2;
    public static final int CC_CAMERA_ORIENTATION_PORTRAIT_UPSIDEDOWN = 3;

    private int mDeviceOrientation = CC_CAMERA_ORIENTATION_PORTRAIT;

    public OrientationModule(ReactApplicationContext reactContext) {
        super(reactContext);
        final ReactApplicationContext ctx = reactContext;

        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Configuration newConfig = intent.getParcelableExtra("newConfig");
                Log.d("receiver", String.valueOf(newConfig.orientation));

                String orientationValue = newConfig.orientation == 1 ? "PORTRAIT" : "LANDSCAPE";

                WritableMap params = Arguments.createMap();
                params.putString("orientation", orientationValue);
                if (ctx.hasActiveCatalystInstance()) {
                    ctx.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("orientationDidChange",
                            params);
                }
            }
        };
        ctx.addLifecycleEventListener(this);

        initOrientationListener(ctx);
    }

    // DETAILED EXPLANATION:
    // -------------------------------------------------------------------------------------
    // Value from OrientationEventListener:
    //   This is the physical rotation of the device, regardless of how the UI is oriented.
    //   e.g.: Whether locked or not, if the device is physically held so that the
    //   "natural left side" is upward, the value will be around 90.
    //
    // Value from getDefaultDisplay().getRotation():
    //   "The angle is the rotation of the drawn graphics on the screen, which is the
    //   opposite direction of the physical rotation of the device."
    //   e.g.: Regardless of how the device is being held, if rotation is unlocked and the UI is
    //   rotated so the top is along the "natural left side", the value is ROTATION_270.
    //
    // Final value of mDeviceOrientation:
    //   By adding the two, we get the degrees of physical rotation relative to the device's
    //   current UI orientation.  So e.g. "PORTRAIT" isn't necessarily portrait--it just means the
    //   device is being held in the same orientation as the UI orientation.
    // -------------------------------------------------------------------------------------

    private void initOrientationListener(ReactApplicationContext context) {
        final ReactApplicationContext rctContext = context;

        mOrientationListener = new OrientationEventListener(rctContext) {
            public void onOrientationChanged(int physOrientation) {

                int nextDeviceOrientation = mDeviceOrientation;
                if (physOrientation != OrientationEventListener.ORIENTATION_UNKNOWN) {

                    Activity activity = rctContext.getCurrentActivity();
                    int uiRotation = (activity == null)
                            ? Surface.ROTATION_0
                            : activity.getWindowManager().getDefaultDisplay().getRotation();
                    int uiDegrees = 0;
                    switch (uiRotation) {
                        case Surface.ROTATION_0:    uiDegrees = 0;    break;
                        case Surface.ROTATION_90:   uiDegrees = 90;   break;
                        case Surface.ROTATION_180:  uiDegrees = 180;  break;
                        case Surface.ROTATION_270:  uiDegrees = 270;  break;
                    }

                    int relOrientation = (physOrientation + uiDegrees) % 360;
                    if (relOrientation >= 325 || relOrientation < 35) {
                        nextDeviceOrientation = CC_CAMERA_ORIENTATION_PORTRAIT;
                    } else if (relOrientation < 305 && relOrientation >= 235) {
                        nextDeviceOrientation = CC_CAMERA_ORIENTATION_LANDSCAPE_LEFT;
                    } else if (relOrientation < 125 && relOrientation >= 55) {
                        nextDeviceOrientation = CC_CAMERA_ORIENTATION_LANDSCAPE_RIGHT;
                    } else if (relOrientation < 215 && relOrientation >= 145) {
                         nextDeviceOrientation = CC_CAMERA_ORIENTATION_PORTRAIT_UPSIDEDOWN;
                    }

                    System.out.println("[OrientationModule] Activity null? " + (activity == null ? "YES" : "NO"));
                    System.out.println("[OrientationModule] UI degrees: " + uiDegrees + ", Phys degrees: " + physOrientation + ", FINAL: " + relOrientation);
                }

                if (nextDeviceOrientation != mDeviceOrientation) {
                    System.out.println("CCCameraOrientationChange: " + mDeviceOrientation + " -> " + nextDeviceOrientation);
                    mDeviceOrientation = nextDeviceOrientation;

                    WritableMap params = Arguments.createMap();
                    params.putInt("orientation", mDeviceOrientation);
                    if (rctContext.hasActiveCatalystInstance()) {
                        rctContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                .emit("CCCameraOrientationChange", params);
                    }
                }
            }
        };

        mOrientationListener.enable();
    }

    @Override
    public String getName() {
        return "Orientation";
    }

    @ReactMethod
    public void getOrientation(Callback callback) {
        final int orientationInt = getReactApplicationContext().getResources().getConfiguration().orientation;

        String orientation = this.getOrientationString(orientationInt);

        if (orientation == "null") {
            callback.invoke(orientationInt, null);
        } else {
            callback.invoke(null, orientation);
        }
    }

    @ReactMethod
    public void lockToPortrait() {
        final Activity activity = getCurrentActivity();
        if (activity == null) {
            return;
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    }

    @ReactMethod
    public void lockToLandscape() {
        final Activity activity = getCurrentActivity();
        if (activity == null) {
            return;
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
    }

    @ReactMethod
    public void lockToLandscapeLeft() {
        final Activity activity = getCurrentActivity();
        if (activity == null) {
            return;
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
    }

    @ReactMethod
    public void lockToLandscapeRight() {
        final Activity activity = getCurrentActivity();
        if (activity == null) {
            return;
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
    }

    @ReactMethod
    public void unlockAllOrientations() {
        final Activity activity = getCurrentActivity();
        if (activity == null) {
            return;
        }
        activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
    }

    @Override
    public @Nullable Map<String, Object> getConstants() {
        HashMap<String, Object> constants = new HashMap<String, Object>();
        int orientationInt = getReactApplicationContext().getResources().getConfiguration().orientation;

        String orientation = this.getOrientationString(orientationInt);
        if (orientation == "null") {
            constants.put("initialOrientation", null);
        } else {
            constants.put("initialOrientation", orientation);
        }

        HashMap<String, Object> directionalConstants = new HashMap<String, Object>();
        directionalConstants.put("portrait", CC_CAMERA_ORIENTATION_PORTRAIT);
        directionalConstants.put("landscapeleft", CC_CAMERA_ORIENTATION_LANDSCAPE_LEFT);
        directionalConstants.put("landscaperight", CC_CAMERA_ORIENTATION_LANDSCAPE_RIGHT);
        directionalConstants.put("portraitupsidedown", CC_CAMERA_ORIENTATION_PORTRAIT_UPSIDEDOWN);

        constants.put("orientationEnum", directionalConstants);

        return constants;
    }

    private String getOrientationString(int orientation) {
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            return "LANDSCAPE";
        } else if (orientation == Configuration.ORIENTATION_PORTRAIT) {
            return "PORTRAIT";
        } else if (orientation == Configuration.ORIENTATION_UNDEFINED) {
            return "UNKNOWN";
        } else {
            return "null";
        }
    }

    @Override
    public void onHostResume() {
        final Activity activity = getCurrentActivity();

        if (activity == null) {
            FLog.e(ReactConstants.TAG, "no activity to register receiver");
            return;
        }
        activity.registerReceiver(receiver, new IntentFilter("onConfigurationChanged"));
    }

    @Override
    public void onHostPause() {
        final Activity activity = getCurrentActivity();
        if (activity == null)
            return;
        try {
            activity.unregisterReceiver(receiver);
        } catch (java.lang.IllegalArgumentException e) {
            FLog.e(ReactConstants.TAG, "receiver already unregistered", e);
        }
    }

    @Override
    public void onHostDestroy() {

    }
}
