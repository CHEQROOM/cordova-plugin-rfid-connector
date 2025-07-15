package cordova.plugin.rfidconnector;

import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;


public class RFIDConnector extends CordovaPlugin {
    static String details = "EMPTY";
    static String deviceType = "TSL";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        ScannerDevice scannerDevice = ScannerDeviceFactory.getInstance(this, "TSL");

        if ("getDeviceList".equals(action)) {
            scannerDevice.getDeviceList(callbackContext);
        } else if ("connect".equals(action)) {
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
}
