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

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.support.v4.content.LocalBroadcastManager;


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
    private static AsciiCommander commander;
    private CordovaPlugin rfidConnector;
    final Context context;
    private static CallbackContext dataAvailableCallback;
    private static InventoryCommand mInventoryCommand;
    private static InventoryCommand inventoryResponder;
    private static BarcodeCommand barcodeResponder;

    private static InventoryCommand inventorySearchResponder;
    private static CallbackContext searchCallback;
    private static CallbackContext connectCallback;
    private static CallbackContext disconnectCallback;
	

    public TSLScannerDevice(final CordovaPlugin rfidConnector) {
        this.rfidConnector = rfidConnector;
        this.context = rfidConnector.cordova.getActivity().getBaseContext();
        this.commander = getCommander();
        mInventoryCommand = getInventoryInstance();
    }

    public AsciiCommander getCommander() {
        if (commander == null) {
            commander = new AsciiCommander(context);
        }
        return commander;
    }

    //
    // Handle the messages broadcast from the AsciiCommander
    //
    private BroadcastReceiver mCommanderMessageReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {

            switch (commander.getConnectionState()) {
                case CONNECTED:
                    if (connectCallback != null) {
                        removeAsyncAndAddSyncResponder();
                             if (commander.isConnected()) {
                                    VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                                    commander.executeCommand(versionInfoCommand);
                            if (versionInfoCommand.getManufacturer() == null || !(versionInfoCommand.getManufacturer()
                                                                                                    .toString()
                                                                                                    .contains("TSL")
                                            || versionInfoCommand.getManufacturer()
                                                                 .toString()
                                                                 .contains("Technology Solutions"))) {
                                        commander.disconnect();
                                        connectCallback.error("Not a recognised device!");
                                    }else{
                                        InventoryCommand inventoryCommand = getInventoryInstance();
                                        inventoryCommand.setTakeNoAction(TriState.YES);
                                        commander.executeCommand(inventoryCommand);
                                        removeSyncAndAddAsyncResponder();
                                        connectCallback.success("true");
                                        connectCallback = null;
                                    }
                                    
                                }else{
                                connectCallback.error("Commander is not connected!");
                                }
                          }
                    break;
                case DISCONNECTED:
                    if (connectCallback != null) {
                        connectCallback.error(commander.getConnectionState().name());
                        connectCallback = null;
                    }
                    if (disconnectCallback != null) {
                        disconnectCallback.success("true");
                    }
                    break;
                default:
                    break;
            }
        }
    };

    @Override
    public void connect(final String deviceID, final CallbackContext callbackContext) {
        connectCallback = callbackContext;
        // Register to receive notifications from the AsciiCommander
        LocalBroadcastManager.getInstance(context).registerReceiver(mCommanderMessageReceiver,
            new IntentFilter(AsciiCommander.STATE_CHANGED_NOTIFICATION));
        // printResponders(callbackContext, "Before connect");
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                if (deviceID != null && deviceID.length() > 0) {
                    if (commander.isConnected()) {
                        callbackContext.error(DEVICE_IS_ALREADY_CONNECTED);
                    } else {
                        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(context.BLUETOOTH_SERVICE);
                        BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();

                        Boolean status = bluetoothAdapter.startDiscovery();
                        Set<BluetoothDevice> listOfBondedDevices = bluetoothAdapter.getBondedDevices();

                        for (BluetoothDevice device : listOfBondedDevices) {
                            if (deviceID.equals(device.getAddress()) || deviceID.equals(device.getName())) {
                                BluetoothDevice bluetoothDevice = bluetoothAdapter.getRemoteDevice(device.getAddress());
                                commander.connect(bluetoothDevice);
                                // printResponders(callbackContext, "After connect");

                                // PluginResult pluginResult = new
                                // PluginResult(PluginResult.Status.OK,
                                // "Trying to connect " + deviceID + "(" + bluetoothDevice.getName()
                                // + ")");
                                // pluginResult.setKeepCallback(true);
                                // callbackContext.sendPluginResult(pluginResult);
                                return;
                            }
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
        if (commander.isConnected()) {
                 VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                commander.executeCommand(versionInfoCommand);
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
        if (commander.isConnected()) {
            removeAsyncResponders();

            inventorySearchResponder = null;
            searchCallback = null;

            inventoryResponder = null;
            barcodeResponder = null;
            dataAvailableCallback = null;
            commander.disconnect();
        }

        // PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Trying to
        // disconnect");
        // pluginResult.setKeepCallback(true);
        // callbackContext.sendPluginResult(pluginResult);
        LocalBroadcastManager.getInstance(context).unregisterReceiver(mCommanderMessageReceiver);

    }

    @Override
    public void getDeviceInfo(final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before getDeviceInfo");
        try {
            removeAsyncAndAddSyncResponder();
            if (commander.isConnected()) {
                JSONObject deviceInfo = new JSONObject();
                BatteryStatusCommand status = BatteryStatusCommand.synchronousCommand();
                commander.executeCommand(status);

                deviceInfo.put(DEVICE_NAME, commander.getConnectedDeviceName());
                deviceInfo.put(BATTERY_LEVEL, status.getBatteryLevel());
                deviceInfo.put(BATTERY_STATUS, status.getChargeStatus() == null ? " " : status.getChargeStatus().getDescription());

                VersionInformationCommand versionInfoCommand = VersionInformationCommand.synchronousCommand();
                commander.executeCommand(versionInfoCommand);

                deviceInfo.put(HARDWARE_VERSION, "N.A.");
                deviceInfo.put(FIRMWARE_VERSION, versionInfoCommand.getFirmwareVersion() == null ? " " : versionInfoCommand.getFirmwareVersion());
                deviceInfo.put(MANUFACTURER, versionInfoCommand.getManufacturer() == null ? " " : versionInfoCommand.getManufacturer());
                deviceInfo.put(SERIAL_NUMBER, versionInfoCommand.getSerialNumber() == null ? " " : versionInfoCommand.getSerialNumber());
                deviceInfo.put(ANTENNA_MIN, commander.getDeviceProperties().getMinimumCarrierPower());
                deviceInfo.put(ANTENNA_MAX, commander.getDeviceProperties().getMaximumCarrierPower());
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
    public void scanRFIDs(final boolean useAscii, final CallbackContext callbackContext) {
        // printResponders(callbackContext, "Before scanRFIDs");
        try {
            removeAsyncAndAddSyncResponder();
            if (commander.isConnected()) {
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

                commander.executeCommand(inventoryCommand);

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
            if (commander.isConnected() && tagID != null) {
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

                commander.executeCommand(inventoryCommand);
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
            if (commander.isConnected() && searchCallback == null) {
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

                    commander.addResponder(inventorySearchResponder);
                    // commander.executeCommand(inventorySearchResponder);
                }

                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "SEARCH ACTIVATED");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            } else if (commander.isConnected()) {
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
            if (commander.isConnected()) {
                if (inventorySearchResponder != null) {
                    commander.removeResponder(inventorySearchResponder);
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
            if (commander.isConnected()) {
                int minPower = commander.getDeviceProperties().getMinimumCarrierPower();
                int maxPower = commander.getDeviceProperties().getMaximumCarrierPower();

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

                    commander.executeCommand(mInventoryCommand);

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
            if (commander.isConnected() && dataAvailableCallback == null) {
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

                    commander.addResponder(inventoryResponder);
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
                    commander.addResponder(barcodeResponder);
                }
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "SUBSCRIBED TO SCANNER.");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            } else if (commander.isConnected()) {
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
            if (commander.isConnected()) {
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
        commander.addSynchronousResponder();
    }

    private void removeSyncAndAddAsyncResponder() {
        commander.removeSynchronousResponder();
        addAsyncResponders();
    }

    private void removeAsyncResponders() {
        if (dataAvailableCallback != null) {
            if (inventoryResponder != null) {
                commander.removeResponder(inventoryResponder);
            }
            if (barcodeResponder != null) {
                commander.removeResponder(barcodeResponder);
            }
        }
    }

    private void addAsyncResponders() {
        if (dataAvailableCallback != null) {
            if (inventoryResponder != null) {
                commander.addResponder(inventoryResponder);
            }
            if (barcodeResponder != null) {
                commander.addResponder(barcodeResponder);
            }
        }
    }

    private void printResponders(final CallbackContext callbackContext, final String message) {
        for (IAsciiCommandResponder responder : commander.getResponderChain()) {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message + " ***RRRR*** " + responder.toString());
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);
        }
    }
}
