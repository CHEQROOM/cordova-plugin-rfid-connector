package cordova.plugin.rfidconnector;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


import com.uk.tsl.rfid.asciiprotocol.AsciiCommander;
import com.uk.tsl.rfid.asciiprotocol.commands.BarcodeCommand;
import com.uk.tsl.rfid.asciiprotocol.commands.BatteryStatusCommand;
import com.uk.tsl.rfid.asciiprotocol.commands.InventoryCommand;
import com.uk.tsl.rfid.asciiprotocol.commands.VersionInformationCommand;
import com.uk.tsl.rfid.asciiprotocol.device.IAsciiTransport;
import com.uk.tsl.rfid.asciiprotocol.device.Reader;
import com.uk.tsl.rfid.asciiprotocol.device.ReaderManager;
import com.uk.tsl.rfid.asciiprotocol.device.ObservableReaderList;
import com.uk.tsl.rfid.asciiprotocol.device.TransportType;
import com.uk.tsl.rfid.asciiprotocol.enumerations.Databank;
import com.uk.tsl.rfid.asciiprotocol.enumerations.QuerySession;
import com.uk.tsl.rfid.asciiprotocol.enumerations.QueryTarget;
import com.uk.tsl.rfid.asciiprotocol.enumerations.SelectAction;
import com.uk.tsl.rfid.asciiprotocol.enumerations.SelectTarget;
import com.uk.tsl.rfid.asciiprotocol.enumerations.TriState;
import com.uk.tsl.rfid.asciiprotocol.responders.IAsciiCommandResponder;
import com.uk.tsl.rfid.asciiprotocol.responders.IBarcodeReceivedDelegate;
import com.uk.tsl.rfid.asciiprotocol.responders.ITransponderReceivedDelegate;
import com.uk.tsl.rfid.asciiprotocol.responders.TransponderData;
import com.uk.tsl.rfid.asciiprotocol.device.ConnectionState;
import com.uk.tsl.utils.Observable;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

public class TSLScannerDevice implements ScannerDevice {

    private static final String ERROR_LABEL = "Error: ";
    private static final String DEVICE_IS_ALREADY_CONNECTED = "Device is already connected.";
    private static final String SCAN_POWER = "dScanPower";
    private static final String ANTENNA_MAX = "antennaMax";
    private static final String ANTENNA_MIN = "antennaMin";
    private static final String SERIAL_NUMBER = "serialNumber";
    private static final String MANUFACTURER = "manufacturer";
    private static final String FIRMWARE_VERSION = "firmwareVersion";
    private static final String HARDWARE_VERSION = "hardwareVersion";
    private static final String BATTERY_STATUS = "batteryStatus";
    private static final String BATTERY_LEVEL = "batteryLevel";
    private static final String DEVICE_NAME = "deviceName";
    private static final String DEVICE_IS_NOT_CONNECTED = "Device is not connected.";
    final CordovaPlugin rfidConnector;
    final Context context;
    private static CallbackContext dataAvailableCallback;
    private static InventoryCommand mInventoryCommand;
    private static InventoryCommand inventoryResponder;
    private static BarcodeCommand barcodeResponder;
    
    private static InventoryCommand inventorySearchResponder;
    private static CallbackContext searchCallback;
    private static CallbackContext connectCallback;
    private static CallbackContext disconnectCallback;
	
    // The Reader currently in use
    private Reader mReader = null;
    private Reader mLastUserDisconnectedReader = null;

    public TSLScannerDevice(final CordovaPlugin rfidConnector) {
        this.rfidConnector = rfidConnector;
        this.context = rfidConnector.cordova.getActivity().getApplicationContext();

        AsciiCommander.createSharedInstance(this.context);

        mInventoryCommand = getInventoryInstance();

        ReaderManager.create(this.context);

        // Add observers for changes
        getReaderManager().getReaderList().readerAddedEvent().addObserver(mAddedObserver);
        getReaderManager().getReaderList().readerUpdatedEvent().addObserver(mUpdatedObserver);
        getReaderManager().getReaderList().readerRemovedEvent().addObserver(mRemovedObserver);
    }

    @Override
    public void onDestroy() {
        getReaderManager().getReaderList().readerAddedEvent().removeObserver(mAddedObserver);
        getReaderManager().getReaderList().readerUpdatedEvent().removeObserver(mUpdatedObserver);
        getReaderManager().getReaderList().readerRemovedEvent().removeObserver(mRemovedObserver);
    }

    @Override
    public void onPause() {
        // Stop observing events from the AsciiCommander
        getCommander().stateChangedEvent().removeObserver(mConnectionStateObserver);

        // Disconnect from the reader to allow other Apps to use it
        // unless pausing when USB device attached or using the DeviceListActivity to select a Reader
        if( ! getReaderManager().didCauseOnPause() && mReader != null)
        {
            mReader.disconnect();
        }

        getReaderManager().onPause();
    }

    @Override
    public void onResume() {
        // Observe events from the AsciiCommander
        getCommander().stateChangedEvent().addObserver(mConnectionStateObserver);

        // Remember if the pause/resume was caused by ReaderManager - this will be cleared when ReaderManager.onResume() is called
        boolean readerManagerDidCauseOnPause = getReaderManager().didCauseOnPause();

        // The ReaderManager needs to know about Activity lifecycle changes
        getReaderManager().onResume();

        // The Activity may start with a reader already connected (perhaps by another App)
        // Update the ReaderList which will add any unknown reader, firing events appropriately
        getReaderManager().updateList();

        // Locate a Reader to use when necessary
        AutoSelectReader(!readerManagerDidCauseOnPause);
    }

    public AsciiCommander getCommander() {
        return AsciiCommander.sharedInstance();
    }

    public ReaderManager getReaderManager() {
        return ReaderManager.sharedInstance();
    }

    @Override
    public void connect(final String deviceID, final CallbackContext callbackContext) {
        connectCallback = callbackContext;
        
        rfidConnector.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (deviceID != null && deviceID.length() > 0) {
                    if (getCommander().isConnected()) {
                        callbackContext.error(DEVICE_IS_ALREADY_CONNECTED);
                    } else {
                        ArrayList<Reader> mReaders = getReaderManager().getReaderList().list();
                        if (mReaders.size() == 1) {
                            mReader = mReaders.get(0);
                        } else {
                            for (Reader reader : mReaders) {
                                if (reader.getDisplayName().equals(deviceID)) {
                                    mReader = reader;
                                }
                            }
                        }

                        if(mReader != null){
                            mReader.connect();
                            getCommander().setReader(mReader);
                            return;
                        }

                        callbackContext.error("Device not found " + deviceID);
                    }
                } else {
                    callbackContext.error("Expected one non-empty string argument for device ID.");
                }
            }
        });
    }

    @Override
    public void isConnected(final CallbackContext callbackContext) {
    
        removeAsyncAndAddSyncResponder();
        if (getCommander().isConnected()) {
                 VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                getCommander().executeCommand(versionInfoCommand);
                 if(versionInfoCommand.getManufacturer() == null || !versionInfoCommand.getManufacturer().toString().contains("TSL")){
                    callbackContext.error("This not a recognised device!");
                 }else{
                    callbackContext.success("true");
                 }
               removeSyncAndAddAsyncResponder(); 
            }else{
               callbackContext.error("Commander is not connected!");
             }
          
    }

    @Override
    public void disconnect(final CallbackContext callbackContext) {
        disconnectCallback = callbackContext;
        if (getCommander().isConnected()) {
            removeAsyncResponders();

            inventorySearchResponder = null;
            searchCallback = null;

            inventoryResponder = null;
            barcodeResponder = null;
            dataAvailableCallback = null;
            getCommander().getReader().disconnect();
        }
    }

    @Override
    public void getDeviceInfo(final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before getDeviceInfo");
        try {
            removeAsyncAndAddSyncResponder();
            if (getCommander().isConnected()) {
                JSONObject deviceInfo = new JSONObject();
                BatteryStatusCommand status = BatteryStatusCommand.synchronousCommand();
                getCommander().executeCommand(status);

                deviceInfo.put(DEVICE_NAME, getCommander().getConnectedDeviceName());
                deviceInfo.put(BATTERY_LEVEL, status.getBatteryLevel());
                deviceInfo.put(BATTERY_STATUS, status.getChargeStatus() == null ? " " : status.getChargeStatus().getDescription());

                VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                getCommander().executeCommand(versionInfoCommand);

                deviceInfo.put(HARDWARE_VERSION, "N.A.");
                deviceInfo.put(FIRMWARE_VERSION, versionInfoCommand.getFirmwareVersion() == null ? " " : versionInfoCommand.getFirmwareVersion());
                deviceInfo.put(MANUFACTURER, versionInfoCommand.getManufacturer() == null ? " " : versionInfoCommand.getManufacturer());
                deviceInfo.put(SERIAL_NUMBER, versionInfoCommand.getSerialNumber() == null ? " " : versionInfoCommand.getSerialNumber());
                deviceInfo.put(ANTENNA_MIN, getCommander().getDeviceProperties().getMinimumCarrierPower());
                deviceInfo.put(ANTENNA_MAX, getCommander().getDeviceProperties().getMaximumCarrierPower());
                deviceInfo.put(SCAN_POWER, getInventoryInstance().getOutputPower());

                callbackContext.success(JSONUtil.createJSONObjectSuccessResponse(deviceInfo));
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }

        } catch (JSONException ex) {
            callbackContext.error(ex.getMessage());
        } finally {
            removeSyncAndAddAsyncResponder();
        }
        // printResponders(callbackContext, "After getDeviceInfo");
    }

    @Override
    public void getDeviceList(final CallbackContext callbackContext) {
        try{
            getReaderManager().updateList();

            ArrayList<Reader> mReaders = getReaderManager().getReaderList().list();
            JSONArray deviceList = new JSONArray();
            for (Reader reader : mReaders) {
                JSONObject deviceDetail = new JSONObject();
                deviceDetail.put("name", reader.getDisplayName());

                // also use displayname as deviceId for now
                deviceDetail.put("deviceID", reader.getDisplayName());
                deviceList.put(deviceDetail);
            }
            callbackContext.success(JSONUtil.createJSONObjectSuccessResponse(deviceList));
         } catch (JSONException ex) {
            callbackContext.error(ex.getMessage());
         }
    }

    @Override
    public void scanRFIDs(final boolean useAscii, final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before scanRFIDs");
        try {
            removeAsyncAndAddSyncResponder();
            if (getCommander().isConnected()) {
                final JSONArray data = new JSONArray();

                InventoryCommand inventoryCommand = getInventoryInstance();
                inventoryCommand.setTakeNoAction(TriState.NO);

                inventoryCommand.setTransponderReceivedDelegate(new ITransponderReceivedDelegate() {

                    @Override
                    public void transponderReceived(TransponderData transponder, boolean moreAvailable) {
                        // PluginResult pluginResult = new PluginResult(PluginResult.Status.OK,
                        // "TTTTTT scanRFIDs transponderReceived");
                        // pluginResult.setKeepCallback(true);
                        // callbackContext.sendPluginResult(pluginResult);
                        try {
                            String epc = transponder.getEpc();
                            if (useAscii) {
                                epc = ConversionUtil.hexToAscii(epc);
                            }

                            data.put(JSONUtil.createRFIDJSONObject(epc, transponder.getRssi()));
                        } catch (JSONException ex) {
                            // Handle tag failure response
                        }
                    }
                });

                getCommander().executeCommand(inventoryCommand);

                callbackContext.success(JSONUtil.createJSONObjectSuccessResponse(data));

            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        } finally {
            removeSyncAndAddAsyncResponder();
        }
        // printResponders(callbackContext, "After scanRFIDs");
    }

    @Override
    public void search(final String tagID, final boolean useAscii, final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before search");
        try {
            removeAsyncAndAddSyncResponder();
            if (getCommander().isConnected() && tagID != null) {
                final JSONArray data = new JSONArray();

                InventoryCommand inventoryCommand = getInventoryInstance();
                inventoryCommand.setTakeNoAction(TriState.NO);

                inventoryCommand.setInventoryOnly(TriState.YES);

                // inventoryCommand.setQueryTarget(QueryTarget.TARGET_B);
                // inventoryCommand.setQuerySession(QuerySession.SESSION_0);
                // inventoryCommand.setSelectAction(SelectAction.DEASSERT_SET_B_NOT_ASSERT_SET_A);
                // inventoryCommand.setSelectTarget(SelectTarget.SESSION_0);

                // inventoryCommand.setSelectBank(Databank.ELECTRONIC_PRODUCT_CODE);

                String tagIDTemp = tagID;
                if (useAscii) {
                    tagIDTemp = ConversionUtil.asciiToHex(tagID);
                }
                // inventoryCommand.setSelectData(tagIDTemp);
                // inventoryCommand.setSelectLength(40);
                // inventoryCommand.setSelectOffset(0020);
                inventoryCommand.setCaptureNonLibraryResponses(true);

                // Toast.makeText(context, "adding search tag- " + tagID, Toast.LENGTH_SHORT);

                inventoryCommand.setTransponderReceivedDelegate(new ITransponderReceivedDelegate() {

                    @Override
                    public void transponderReceived(TransponderData transponder, boolean moreAvailable) {
                        // PluginResult pluginResult = new PluginResult(PluginResult.Status.OK,
                        // "TTTTTT search transponderReceived");
                        // pluginResult.setKeepCallback(true);
                        // callbackContext.sendPluginResult(pluginResult);
                        String epc = transponder.getEpc();
                        if (useAscii) {
                            epc = ConversionUtil.hexToAscii(epc);
                        }
                        if (!epc.equals(tagID)) {
                            return;
                        }

                        // if (tagID.equals(epc)) {
                        try {
                            data.put(JSONUtil.createRFIDJSONObject(epc, transponder.getRssi()));
                        } catch (JSONException ex) {

                        }
                        // }
                    }
                });

                getCommander().executeCommand(inventoryCommand);
                callbackContext.success(JSONUtil.createJSONObjectSuccessResponse(data));

            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse("Device is not connected/ No tag is given for searching."));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        } finally {
            removeSyncAndAddAsyncResponder();
        }
        // printResponders(callbackContext, "After search");
    }

    @Override
    public void startSearch(final String tagID, final boolean useAscii, final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before startSearch");
        try {
            if (getCommander().isConnected() && searchCallback == null) {
                searchCallback = callbackContext;
                removeAsyncResponders();
                // Inventory responder
                if (inventorySearchResponder == null) {
                    final List<JSONObject> dataList = new ArrayList<JSONObject>();
                    inventorySearchResponder = new InventoryCommand();
                    inventorySearchResponder.setTakeNoAction(TriState.NO);

                    inventorySearchResponder.setInventoryOnly(TriState.YES);

                    inventorySearchResponder.setQueryTarget(QueryTarget.TARGET_B);
                    inventorySearchResponder.setQuerySession(QuerySession.SESSION_0);
                    inventorySearchResponder.setSelectAction(SelectAction.DEASSERT_SET_B_NOT_ASSERT_SET_A);
                    inventorySearchResponder.setSelectTarget(SelectTarget.SESSION_0);

                    inventorySearchResponder.setSelectBank(Databank.ELECTRONIC_PRODUCT_CODE);

                    String tagIDTemp = tagID;
                    if (useAscii) {
                        tagIDTemp = ConversionUtil.asciiToHex(tagID);
                    }
                    inventorySearchResponder.setSelectData(tagIDTemp);
                    inventorySearchResponder.setSelectLength(40);
                    inventorySearchResponder.setSelectOffset(0020);
                    inventorySearchResponder.setCaptureNonLibraryResponses(true);

                    // PluginResult pluginResult1 = new PluginResult(PluginResult.Status.OK, "TTTTTT
                    // " + inventorySearchResponder.getCommandLine());
                    // pluginResult1.setKeepCallback(true);
                    // callbackContext.sendPluginResult(pluginResult1);

                    inventorySearchResponder.setTransponderReceivedDelegate(new ITransponderReceivedDelegate() {

                        @Override
                        public void transponderReceived(TransponderData transponder, boolean moreAvailable) {
                            String epc = transponder.getEpc();
                            if (useAscii) {
                                epc = ConversionUtil.hexToAscii(epc);
                            }
                            if (!epc.equals(tagID)) {
                                return;
                            }

                            try {
                                dataList.add(JSONUtil.createRFIDJSONObject(epc, transponder.getRssi()));
                                final JSONArray data = new JSONArray();
                                for (JSONObject rfidObject : dataList) {
                                    data.put(rfidObject);
                                }
                                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, JSONUtil.createJSONObjectSuccessResponse(data));
                                pluginResult.setKeepCallback(true);
                                searchCallback.sendPluginResult(pluginResult);
                                dataList.clear();
                            } catch (JSONException ex) {
                                // Handle tag failure response
                            }
                        }
                    });

                    getCommander().addResponder(inventorySearchResponder);
                    // commander.executeCommand(inventorySearchResponder);
                }

                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "SEARCH ACTIVATED");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            } else if (getCommander().isConnected()) {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse("SEARCH IS ALREADY ACTIVATED"));
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        }
        // printResponders(callbackContext, "After startSearch");
    }

    @Override
    public void stopSearch(final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before stopSearch");
        try {
            if (getCommander().isConnected()) {
                if (inventorySearchResponder != null) {
                    getCommander().removeResponder(inventorySearchResponder);
                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "REMOVING SEARCH RESPONDER");
                    pluginResult.setKeepCallback(true);
                    callbackContext.sendPluginResult(pluginResult);
                }
                inventorySearchResponder = null;
                searchCallback = null;
                addAsyncResponders();

                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "SEARCH DEACTIVATED");
                // pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        }
        // printResponders(callbackContext, "After stopSearch");
    }

    @Override
    public void setOutputPower(final int powerValue, final CallbackContext callbackContext) {
        try {
            removeAsyncAndAddSyncResponder();
            if (getCommander().isConnected()) {
                int minPower = getCommander().getDeviceProperties().getMinimumCarrierPower();
                int maxPower = getCommander().getDeviceProperties().getMaximumCarrierPower();

                if (powerValue >= minPower && powerValue <= maxPower) {
                    InventoryCommand mInventoryCommand = getInventoryInstance();
                    int oldPower = mInventoryCommand.getOutputPower();

                    // mInventoryCommand.setResetParameters(TriState.YES);
                    // Configure the type of inventory
                    mInventoryCommand.setIncludeTransponderRssi(TriState.YES);
                    // mInventoryCommand.setIncludeChecksum(TriState.YES);
                    // mInventoryCommand.setIncludePC(TriState.YES);
                    // mInventoryCommand.setIncludeDateTime(TriState.YES);
                    mInventoryCommand.setTakeNoAction(TriState.YES);
                    mInventoryCommand.setOutputPower(powerValue);

                    getCommander().executeCommand(mInventoryCommand);

                    callbackContext.success("Scan power set from " + oldPower + " to " + powerValue);
                } else {
                    callbackContext.error("Scan power " + powerValue + " is not in device range(" + minPower + " to " + maxPower + ")");
                }
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        } finally {
            removeSyncAndAddAsyncResponder();
        }
    }

    @Override
    public void subscribeScanner(final boolean useASCII, final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before subscribeScanner");
        try {
            if (getCommander().isConnected() && dataAvailableCallback == null) {
                dataAvailableCallback = callbackContext;

                // Inventory responder
                if (inventoryResponder == null) {
                    final List<JSONObject> dataList = new ArrayList<JSONObject>();
                    inventoryResponder = new InventoryCommand();
                    inventoryResponder.setTakeNoAction(TriState.NO);
                    inventoryResponder.setIncludeTransponderRssi(TriState.YES);
                    inventoryResponder.setCaptureNonLibraryResponses(true);
                    inventoryResponder.setTransponderReceivedDelegate(new ITransponderReceivedDelegate() {
                        @Override
                        public void transponderReceived(TransponderData transponder, boolean moreAvailable) {
                            String epc = transponder.getEpc();
                            if (useASCII) {
                                epc = ConversionUtil.hexToAscii(epc);
                            }
                            try {
                                dataList.add(JSONUtil.createRFIDJSONObject(epc, transponder.getRssi()));
                                if (!moreAvailable) {
                                    final JSONArray data = new JSONArray();
                                    for (JSONObject rfidObject : dataList) {
                                        data.put(rfidObject);
                                    }
                                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK,
                                                    JSONUtil.createJSONObjectSuccessResponse(data));
                                    pluginResult.setKeepCallback(true);
                                    dataAvailableCallback.sendPluginResult(pluginResult);
                                    dataList.clear();
                                }
                            } catch (JSONException ex) {
                                // Handle tag failure response
                            }
                        }
                    });

                    getCommander().addResponder(inventoryResponder);
                }

                if (barcodeResponder == null) {
                    barcodeResponder = new BarcodeCommand();
                    barcodeResponder.setCaptureNonLibraryResponses(true);
                    barcodeResponder.setUseEscapeCharacter(TriState.YES);
                    barcodeResponder.setBarcodeReceivedDelegate(new IBarcodeReceivedDelegate() {
                        @Override
                        public void barcodeReceived(String barCode) {
                            try {
                                JSONArray data = new JSONArray();
                                data.put(JSONUtil.createBarcodeJSONObject(barCode));

                                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, JSONUtil.createJSONObjectSuccessResponse(data));
                                pluginResult.setKeepCallback(true);
                                dataAvailableCallback.sendPluginResult(pluginResult);
                            } catch (JSONException ex) {
                                // Handle tag failure response
                            }
                        };
                    });
                    getCommander().addResponder(barcodeResponder);
                }
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "SUBSCRIBED TO SCANNER.");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            } else if (getCommander().isConnected()) {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse("DEVICE IS ALREADY SUBSCRIBED."));
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        }
        // printResponders(callbackContext, "After subscribeScanner");
    }

    @Override
    public void unsubscribeScanner(final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before unsubscribeScanner");
        try {
            if (getCommander().isConnected()) {
                removeAsyncResponders();
                inventoryResponder = null;
                barcodeResponder = null;
                dataAvailableCallback = null;
                callbackContext.success("RESPONDERS REMOVED.");
            } else {
                callbackContext.error(JSONUtil.createJSONObjectErrorResponse(DEVICE_IS_NOT_CONNECTED));
            }
        } catch (JSONException ex) {
            callbackContext.error(ERROR_LABEL + ex.getMessage());
        }
        // printResponders(callbackContext, "After unsubscribeScanner");
    }

    private InventoryCommand getInventoryInstance() {

        // This is the command that will be used to perform configuration changes and inventories
        if (mInventoryCommand == null) {
            mInventoryCommand = InventoryCommand.synchronousCommand();
        }
        // mInventoryCommand.setResetParameters(TriState.YES);
        // Configure the type of inventory
        mInventoryCommand.setIncludeTransponderRssi(TriState.YES);
        mInventoryCommand.setIncludeChecksum(TriState.YES);
        mInventoryCommand.setIncludePC(TriState.YES);
        mInventoryCommand.setIncludeDateTime(TriState.YES);

        return mInventoryCommand;
    }

    private void removeAsyncAndAddSyncResponder() {
        removeAsyncResponders();
        getCommander().addSynchronousResponder();
    }

    private void removeSyncAndAddAsyncResponder() {
        getCommander().removeSynchronousResponder();
        addAsyncResponders();
    }

    private void removeAsyncResponders() {
        if (dataAvailableCallback != null) {
            if (inventoryResponder != null) {
                getCommander().removeResponder(inventoryResponder);
            }
            if (barcodeResponder != null) {
                getCommander().removeResponder(barcodeResponder);
            }
        }
    }

    private void addAsyncResponders() {
        if (dataAvailableCallback != null) {
            if (inventoryResponder != null) {
                getCommander().addResponder(inventoryResponder);
            }
            if (barcodeResponder != null) {
                getCommander().addResponder(barcodeResponder);
            }
        }
    }

    private void printResponders(final CallbackContext callbackContext, final String message) {
        for (IAsciiCommandResponder responder : getCommander().getResponderChain()) {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message + " ***RRRR*** " + responder.toString());
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);
        }
    }

    //----------------------------------------------------------------------------------------------
    // ReaderList Observers
    //----------------------------------------------------------------------------------------------
    Observable.Observer<Reader> mAddedObserver = new Observable.Observer<Reader>()
    {
        @Override
        public void update(Observable<? extends Reader> observable, Reader reader)
        {
            // See if this newly added Reader should be used
            AutoSelectReader(true);
        }
    };

    Observable.Observer<Reader> mUpdatedObserver = new Observable.Observer<Reader>()
    {
        @Override
        public void update(Observable<? extends Reader> observable, Reader reader)
        {
            // Is this a change to the last actively disconnected reader
            if( reader == mLastUserDisconnectedReader )
            {
                // Things have changed since it was actively disconnected so
                // treat it as new
                mLastUserDisconnectedReader = null;
            }

            // Was the current Reader disconnected i.e. the connected transport went away or disconnected
            if( reader == mReader && !reader.isConnected() )
            {
                // No longer using this reader
                mReader = null;

                // Stop using the old Reader
                getCommander().setReader(mReader);
            }
            else
            {
                // See if this updated Reader should be used
                // e.g. the Reader's USB transport connected
                AutoSelectReader(true);
            }
        }
    };

    Observable.Observer<Reader> mRemovedObserver = new Observable.Observer<Reader>()
    {
        @Override
        public void update(Observable<? extends Reader> observable, Reader reader)
        {
            // Is this a change to the last actively disconnected reader
            if( reader == mLastUserDisconnectedReader )
            {
                // Things have changed since it was actively disconnected so
                // treat it as new
                mLastUserDisconnectedReader = null;
            }

            // Was the current Reader removed
            if( reader == mReader)
            {
                mReader = null;

                // Stop using the old Reader
                getCommander().setReader(mReader);
            }
        }
    };


    private void AutoSelectReader(boolean attemptReconnect)
    {
        ObservableReaderList readerList = getReaderManager().getReaderList();
        Reader usbReader = null;
        if( readerList.list().size() >= 1)
        {
            // Currently only support a single USB connected device so we can safely take the
            // first CONNECTED reader if there is one
            for (Reader reader : readerList.list())
            {
                if (reader.hasTransportOfType(TransportType.USB))
                {
                    usbReader = reader;
                    break;
                }
            }
        }

        if( mReader == null )
        {
            if( usbReader != null && usbReader != mLastUserDisconnectedReader)
            {
                // Use the Reader found, if any
                mReader = usbReader;
                getCommander().setReader(mReader);
            }
        }
        else
        {
            // If already connected to a Reader by anything other than USB then
            // switch to the USB Reader
            IAsciiTransport activeTransport = mReader.getActiveTransport();
            if ( activeTransport != null && activeTransport.type() != TransportType.USB && usbReader != null)
            {
                mReader.disconnect();

                mReader = usbReader;

                // Use the Reader found, if any
                getCommander().setReader(mReader);
            }
        }

        // Reconnect to the chosen Reader
        if( mReader != null
                && !mReader.isConnecting()
                && (mReader.getActiveTransport()== null || mReader.getActiveTransport().connectionStatus().value() == ConnectionState.DISCONNECTED))
        {
            // Attempt to reconnect on the last used transport unless the ReaderManager is cause of OnPause (USB device connecting)
            if( attemptReconnect )
            {
                if( mReader.allowMultipleTransports() || mReader.getLastTransportType() == null )
                {
                    // Reader allows multiple transports or has not yet been connected so connect to it over any available transport
                    mReader.connect();
                }
                else
                {
                    // Reader supports only a single active transport so connect to it over the transport that was last in use
                    mReader.connect(mReader.getLastTransportType());
                }
            }
        }
    }

     //----------------------------------------------------------------------------------------------
    // AsciiCommander message handling
    //----------------------------------------------------------------------------------------------

    //
    // Handle the connection state change events from the AsciiCommander
    //
    private final Observable.Observer<String> mConnectionStateObserver = (observable, reason) ->
    {
        ConnectionState commanderConnectionState = getCommander().getConnectionState();
        if(commanderConnectionState == ConnectionState.DISCONNECTED)
        {
            if (connectCallback != null) {
                connectCallback.error(getCommander().getConnectionState().name());
                connectCallback = null;
            }
            if (disconnectCallback != null) {
                disconnectCallback.success("true");
            }
            
            // A manual disconnect will have cleared mReader
            if( mReader != null )
            {
                // See if this is from a failed connection attempt
                if (!mReader.wasLastConnectSuccessful())
                {
                    // Unable to connect so have to choose reader again
                    mReader = null;
                }
            }
        }
        else if( commanderConnectionState == ConnectionState.CONNECTED)
        {
      
            if (connectCallback != null) {
                removeAsyncAndAddSyncResponder();
                    if (getCommander().isConnected()) {
                    VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                    getCommander().executeCommand(versionInfoCommand);
                    
                        if (versionInfoCommand.getManufacturer() == null || !(versionInfoCommand.getManufacturer()
                                                                                            .toString()
                                                                                            .contains("TSL")
                                    || versionInfoCommand.getManufacturer()
                                                            .toString()
                                                            .contains("Technology Solutions"))) {
                            getCommander().getReader().disconnect();
                            connectCallback.error("Not a recognised device!");
                        }else{
                            InventoryCommand inventoryCommand = getInventoryInstance();
                            inventoryCommand.setTakeNoAction(TriState.YES);
                            getCommander().executeCommand(inventoryCommand);
                            removeSyncAndAddAsyncResponder();
                            connectCallback.success("true");
                            connectCallback = null;
                        }
                            
                    }else{
                        connectCallback.error("Commander is not connected!");
                    }
            }



        }
    };
}
