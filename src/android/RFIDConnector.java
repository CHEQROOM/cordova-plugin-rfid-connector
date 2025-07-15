package cordova.plugin.rfidconnector;

import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.os.Build;
import androidx.core.content.ContextCompat;
import android.Manifest;
import android.content.pm.PackageManager;

public class RFIDConnector extends CordovaPlugin {
    static String details = "EMPTY";
    static String deviceType = "TSL";

    private static final int BLUETOOTH_PERMISSIONS_REQUEST = 1;
    private CallbackContext permissionCallbackContext;
    private String pendingAction;
    private JSONArray pendingArgs;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        ScannerDevice scannerDevice = ScannerDeviceFactory.getInstance(this, "TSL");

         if ("getDeviceList".equals(action)) {
            if (!hasBluetoothPermissions()) {
                requestBluetoothPermissions(callbackContext, action, args);
                return true;
            }
            scannerDevice.getDeviceList(callbackContext);
        } else if ("connect".equals(action)) {
            if (!hasBluetoothPermissions()) {
                requestBluetoothPermissions(callbackContext, action, args);
                return true;
            }
            scannerDevice.connect(args.getString(1), callbackContext);
        } else if ("isConnected".equals(action)) {
            scannerDevice.isConnected(callbackContext);
        } else if ("disconnect".equals(action)) {
            scannerDevice.disconnect(callbackContext);
        } else if ("getDeviceInfo".equals(action)) {
            scannerDevice.getDeviceInfo(callbackContext);
        } else if ("scanRFIDs".equals(action)) {
            scannerDevice.scanRFIDs(args.getBoolean(0), callbackContext);
        } else if ("search".equals(action)) {
            scannerDevice.search(args.getString(0), args.getBoolean(1), callbackContext);
        } else if ("setOutputPower".equals(action)) {
            scannerDevice.setOutputPower(args.getInt(0), callbackContext);
        } else if ("subscribeScanner".equals(action)) {
            scannerDevice.subscribeScanner(args.getBoolean(0), callbackContext);
        } else if ("unsubscribeScanner".equals(action)) {
            scannerDevice.unsubscribeScanner(callbackContext);
        } else if ("startSearch".equals(action)) {
            scannerDevice.startSearch(args.getString(0), args.getBoolean(1), callbackContext);
        } else if ("stopSearch".equals(action)) {
            scannerDevice.stopSearch(callbackContext);
        } else {
            callbackContext.error("RFID Connector error: UNSUPPORTED_COMMAND");
            return false;
        }
        return true;
    }

     /**
     * Check if BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions are granted
     */
    private boolean hasBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            boolean hasScanPermission = ContextCompat.checkSelfPermission(cordova.getActivity(), 
                Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
            boolean hasConnectPermission = ContextCompat.checkSelfPermission(cordova.getActivity(), 
                Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
            return hasScanPermission && hasConnectPermission;
        }
        return true; // Permissions not required for Android < 12
    }

    /**
     * Request BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
     */
    private void requestBluetoothPermissions(CallbackContext callbackContext, String action, JSONArray args) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
             // Store the callback context and action for later use
            this.permissionCallbackContext = callbackContext;
            this.pendingAction = action;
            this.pendingArgs = args;

            String[] permissions = {
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            };
            cordova.requestPermissions(this, BLUETOOTH_PERMISSIONS_REQUEST, permissions);
        }
    }

    /**
     * Handle permission request result
     */
    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == BLUETOOTH_PERMISSIONS_REQUEST) {
            boolean allGranted = grantResults.length > 0;
            
            // Check if all permissions were granted
            for (int grantResult : grantResults) {
                if (grantResult != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            
            if (allGranted) {
                // All permissions granted, you can now perform Bluetooth operations
                cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            ScannerDevice scannerDevice = ScannerDeviceFactory.getInstance(RFIDConnector.this, "TSL");
                            
                            if ("getDeviceList".equals(pendingAction)) {
                                scannerDevice.getDeviceList(permissionCallbackContext);
                            } else if ("connect".equals(pendingAction)) {
                                scannerDevice.connect(pendingArgs.getString(1), permissionCallbackContext);
                            }
                        } catch (JSONException e) {
                            permissionCallbackContext.error("Error executing action after permission grant: " + e.getMessage());
                        }
                    }
                });
            } else {
                // Some permissions were denied
                cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        permissionCallbackContext.error("Bluetooth permissions are required for this operation");
                    }
                });
            }

            // Clear the stored callback and action
            this.permissionCallbackContext = null;
            this.pendingAction = null;
            this.pendingArgs = null;
        }
    }
}
