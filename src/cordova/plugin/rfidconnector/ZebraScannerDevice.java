package cordova.plugin.rfidconnector;

import java.util.ArrayList;
import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import com.zebra.rfid.api3.Antennas;
import com.zebra.rfid.api3.Antennas.AntennaRfConfig;
import com.zebra.rfid.api3.InvalidUsageException;
import com.zebra.rfid.api3.OperationFailureException;
import com.zebra.rfid.api3.RFIDReader;
import com.zebra.rfid.api3.ReaderDevice;
import com.zebra.rfid.api3.RfidReadEvents;
import com.zebra.scannercontrol.DCSSDKDefs;
import com.zebra.scannercontrol.DCSSDKDefs.DCSSDK_RESULT;
import com.zebra.scannercontrol.DCSScannerInfo;
import com.zebra.scannercontrol.SDKHandler;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;


public class ZebraScannerDevice implements ScannerDevice {
    private static final String BARCODE_SCANNER_CONNECTION_ERROR = "Barcode Scanner Connection Failed!";
    private static final String BATTERY_STATUS = "batteryStatus";
    private static final String BATTERY_LEVEL = "batteryLevel";
    private static final String DEVICE_NAME = "deviceName";
    private static final String DEVICE_IS_NOT_CONNECTED = "Device is not connected.";
    private static final String SCAN_POWER = "scanPower";
    private static final String ANTENNA_MAX = "antennaMax";
    private static final String ANTENNA_MIN = "antennaMin";
    private static final String SERIAL_NUMBER = "serialNumber";
    private static final String MANUFACTURER = "manufacturer";
    private static final String FIRMWARE_VERSION = "firmwareVersion";
    private static final String HARDWARE_VERSION = "hardwareVersion";
    private static final String DEVICE_IS_ALREADY_CONNECTED = "Device is already connected";
    private CordovaPlugin rfidConnector;
    private static ReaderDevice readerDevice;
    private static RFIDReader rfidReader;
    private static String deviceName;
    private BluetoothAdapter bluetoothAdapter;
    private Context context;
    private static ZebraEventHandler event;
    public static Integer batteryLevel = null;
    public static Boolean isCharging = null;
    private static SDKHandler sdkHandler;
    private static ArrayList<DCSScannerInfo> mScannerInfoList = new ArrayList<DCSScannerInfo>();
    public static CallbackContext asyncCallbackContext = null;

    public ZebraScannerDevice(final CordovaPlugin rfidConnector) {
        this.rfidConnector = rfidConnector;
        this.context = rfidConnector.cordova.getActivity().getBaseContext();

    }

    private void startBluetoothDevice(final String deviceAddress) {
        BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
    }

    @Override
    public void connect(final String deviceAddress, final CallbackContext callbackContext) {
        startBluetoothDevice(deviceAddress);

        Handler handler = new Handler(Looper.getMainLooper());

        if (isDeviceOn(deviceAddress)) {
            BluetoothDevice bluetoothDevice = bluetoothAdapter.getRemoteDevice(deviceAddress);
            deviceName = bluetoothDevice.getName();
            readerDevice = new ReaderDevice(deviceName, deviceAddress);
            rfidReader = new RFIDReader(deviceName, 0, 0, "ASCII", "BLUETOOTH");
            readerDevice = new ReaderDevice(deviceName, deviceAddress, rfidReader);
            rfidReader.setHostName(bluetoothDevice.getName());

            handler.post(new Runnable() {

                @Override
                public void run() {
                    if (deviceAddress != null && deviceAddress.length() > 0) {
                        if (rfidReader.isConnected()) {
                            callbackContext.error("Device connected already.");
                            return;
                        } else {
                            tryAndConnect(deviceAddress, callbackContext);
                            return;
                        }
                    } else {
                        callbackContext.error("Expected one non-empty string argument for device address.");
                        rfidReader = null;
                        readerDevice = null;
                        deviceName = null;
                    }
                }
            });

        } else {
            callbackContext.error("Please check, if device bluetooth is ON or Device might be already connected");
        }

    }

    /**
     * @param deviceAddress
     */
    private boolean isDeviceOn(final String deviceAddress) {
        Boolean status = false;
        Set<BluetoothDevice> listOfBondedDevices = bluetoothAdapter.getBondedDevices();
        for (BluetoothDevice device : listOfBondedDevices) {
            String address = device.getAddress();
            if (deviceAddress.equalsIgnoreCase(address)) {
                status = true;
            }
        }
        return status;
    }

    /**
     * @param deviceAddress
     * @throws InvalidUsageException
     * @throws OperationFailureException
     */
    private void tryAndConnect(final String deviceAddress, final CallbackContext callbackContext) {

        if (!rfidReader.isConnected()) {
            try {
                rfidReader.setTimeout(3000);
                rfidReader.connect();
                callbackContext.success("true");
                rfidReader.Events.setBatteryEvent(true);
            } catch (InvalidUsageException e) {
                callbackContext.error("Please check, if device bluetooth is ON." + e.getInfo());
                rfidReader = null;
                readerDevice = null;
                deviceName = null;
            } catch (OperationFailureException e) {
                callbackContext.error("Please check, if device bluetooth is ON." + e.getResults().toString() + " : " + e.getStatusDescription()
                                + " : " + e.getVendorMessage());
                rfidReader = null;
                readerDevice = null;
                deviceName = null;
            }
        }
        callbackContext.error(DEVICE_IS_ALREADY_CONNECTED);
    }

    @Override
    public void isConnected(final CallbackContext callbackContext) {
        if (readerDevice == null) {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
            return;
        }
        callbackContext.success("true");
    }

    @Override
    public void disconnect(final CallbackContext callbackContext) {
        try {
            if (rfidReader == null) {
                callbackContext.error(DEVICE_IS_NOT_CONNECTED);
                return;
            }
            rfidReader.disconnect();
            rfidReader = null;
            readerDevice = null;
            deviceName = null;
            callbackContext.success("true");
        } catch (InvalidUsageException e) {
            callbackContext.error("Unexpexted error occured. " + e.getMessage());
        } catch (OperationFailureException e) {
            callbackContext.error("Unexpexted error occured. " + e.getMessage());
        }
    }

    /**
     * @param callbackContext
     */
    @Override
    public void getDeviceInfo(final CallbackContext callbackContext) {
        final JSONObject resultObject = new JSONObject();
        final JSONObject deviceInfo = new JSONObject();
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    callbackContext.success(DEVICE_IS_NOT_CONNECTED);
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                } catch (OperationFailureException e) {
                    callbackContext.success(DEVICE_IS_NOT_CONNECTED);
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            }

            Handler handler = new Handler(Looper.getMainLooper());

            handler.post(new Runnable() {

                @Override
                public void run() {
                    try {
                        rfidReader.Config.getDeviceStatus(true, false, false);
                        rfidReader.Config.saveConfig();
                    } catch (InvalidUsageException e11) {
                        e11.printStackTrace();
                    } catch (OperationFailureException e12) {
                        e12.printStackTrace();
                    }

                    event = new ZebraEventHandler(readerDevice, context, callbackContext, asyncCallbackContext, null, true, false);
                    try {
                        rfidReader.Events.setBatteryEvent(true);
                        rfidReader.Events.addEventsListener(event);
                        resultObject.put("status", true);
                        resultObject.put("errorMsg", "");

                        String firwareVersion = rfidReader.ReaderCapabilities.getFirwareVersion();
                        String manufacturerName = rfidReader.ReaderCapabilities.getManufacturerName();
                        String serialNumber = rfidReader.ReaderCapabilities.getSerialNumber();
                        AntennaRfConfig antennaRF = rfidReader.Config.Antennas.getAntennaRfConfig(1);
                        int transmitPowerIndexRF = antennaRF.getTransmitPowerIndex();
                        int[] transmitPowerLevelValues = rfidReader.ReaderCapabilities.getTransmitPowerLevelValues();
                        deviceInfo.put(DEVICE_NAME, rfidReader.getHostName());
                        if (batteryLevel == null && isCharging == null) {
                            batteryLevel = 0;
                            isCharging = false;
                        }
                        deviceInfo.put(BATTERY_LEVEL, batteryLevel);
                        deviceInfo.put(BATTERY_STATUS, isCharging);
                        deviceInfo.put(HARDWARE_VERSION, "N.A.");
                        deviceInfo.put(FIRMWARE_VERSION, firwareVersion == null ? " " : firwareVersion);
                        deviceInfo.put(MANUFACTURER, manufacturerName == null ? " " : manufacturerName);
                        deviceInfo.put(SERIAL_NUMBER, serialNumber == null ? " " : serialNumber);
                        deviceInfo.put(ANTENNA_MIN, transmitPowerLevelValues == null ? " " : transmitPowerLevelValues[0]);
                        deviceInfo.put(ANTENNA_MAX,
                            transmitPowerLevelValues == null ? " " : transmitPowerLevelValues[transmitPowerLevelValues.length - 1]);
                        deviceInfo.put(SCAN_POWER, transmitPowerIndexRF);
                        resultObject.put("deviceInfo", deviceInfo);
                        rfidReader.Events.removeEventsListener(event);

                        callbackContext.success(JSONUtil.createJSONObjectSuccessResponse(deviceInfo));
                    } catch (InvalidUsageException e) {
                        Toast.makeText(context, e.getMessage(), Toast.LENGTH_LONG).show();
                        e.printStackTrace();
                    } catch (OperationFailureException e) {
                        e.printStackTrace();
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }

                }
            });
        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }
    }

    @Override
    public void scanRFIDs(final boolean useASCII, final CallbackContext callbackContext) {
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                } catch (OperationFailureException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            }

            try {
                // ZebraScannerDevice.removeEventHandler();
                event = new ZebraEventHandler(readerDevice, context, callbackContext, asyncCallbackContext, null, true, useASCII);
                rfidReader.Events.addEventsListener(event);
                RfidReadEvents rfidReadEvents = new RfidReadEvents(readerDevice.getRFIDReader().Actions.Inventory);
                readerDevice.getRFIDReader().Events.setInventoryStartEvent(true);
                readerDevice.getRFIDReader().Events.setInventoryStopEvent(true);
                /*
                 * after perform(), stop() has to be called to save tags in memory. then we can read
                 * the tags from memory when eventReadNotify() is called after stop()
                 */
                readerDevice.getRFIDReader().Config.setUniqueTagReport(true);
                readerDevice.getRFIDReader().Actions.Inventory.perform();
                readerDevice.getRFIDReader().Actions.Inventory.stop();
                readerDevice.getRFIDReader().Config.setUniqueTagReport(false);
                rfidReader.Events.removeEventsListener(event);
                event.eventReadNotify(rfidReadEvents);

            } catch (InvalidUsageException e) {
                Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
            } catch (OperationFailureException e) {
                Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
            } finally {
                readerDevice.getRFIDReader().Events.setInventoryStartEvent(false);
                readerDevice.getRFIDReader().Events.setInventoryStopEvent(false);
                addAsyncListners(useASCII, callbackContext);
                // event = new ZebraEventHandler(readerDevice, context, null, asyncCallbackContext,
                // null, false, useASCII);
            }
        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }
    }

    @Override
    public void search(final String tagID, final boolean useAscii, final CallbackContext callbackContext) {
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                } catch (OperationFailureException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            }
            if (tagID == null || tagID.isEmpty()) {
                callbackContext.error("Please provide the tag id to search.");
                return;
            }
            try {
                ZebraScannerDevice.removeEventHandler();
                event = new ZebraEventHandler(readerDevice, context, callbackContext, asyncCallbackContext, tagID, true, useAscii);
                rfidReader.Events.addEventsListener(event);

                RfidReadEvents rfidReadEvents = new RfidReadEvents(readerDevice.getRFIDReader().Actions.Inventory);

                readerDevice.getRFIDReader().Events.setInventoryStartEvent(true);
                readerDevice.getRFIDReader().Events.setInventoryStopEvent(true);
                /*
                 * after perform(), stop() has to be called to save tags in memory. then we can read
                 * the tags from memory when eventReadNotify() is called after stop()
                 */
                readerDevice.getRFIDReader().Config.setUniqueTagReport(true);
                readerDevice.getRFIDReader().Actions.Inventory.perform();
                readerDevice.getRFIDReader().Actions.Inventory.stop();
                readerDevice.getRFIDReader().Config.setUniqueTagReport(false);
                rfidReader.Events.removeEventsListener(event);
                event.eventReadNotify(rfidReadEvents);
                // addAsyncListners(useAscii, callbackContext);
            } catch (InvalidUsageException e) {
                callbackContext.error(e.getMessage());
            } catch (OperationFailureException e) {
                callbackContext.error(e.getMessage());
            }
        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }

    }

    @Override
    public void setOutputPower(final int power, final CallbackContext callbackContext) {

        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                } catch (OperationFailureException e) {
                    Toast.makeText(context, e.getVendorMessage() + " : " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            }
            int[] transmitPowerLevelValues = rfidReader.ReaderCapabilities.getTransmitPowerLevelValues();
            if (transmitPowerLevelValues[0] > power || transmitPowerLevelValues[transmitPowerLevelValues.length - 1] < power) {
                callbackContext.error("Power is only allowed between " + transmitPowerLevelValues[0] + " - "
                                + transmitPowerLevelValues[transmitPowerLevelValues.length - 1]);
                return;
            }
            try {
                rfidReader = readerDevice.getRFIDReader();
                Handler handler = new Handler(Looper.getMainLooper());

                handler.post(new Runnable() {

                    @Override
                    public void run() {
                        try {
                            Antennas.AntennaRfConfig antennaRfConfig = rfidReader.Config.Antennas.getAntennaRfConfig(1);
                            int oldPower = antennaRfConfig.getTransmitPowerIndex();
                            antennaRfConfig.setrfModeTableIndex(antennaRfConfig.getrfModeTableIndex());
                            antennaRfConfig.setTari(antennaRfConfig.getTari());
                            antennaRfConfig.setTransmitPowerIndex(power);
                            rfidReader.Config.Antennas.setAntennaRfConfig(1, antennaRfConfig);
                            rfidReader.Config.saveConfig();
                            callbackContext.success("Scan power set from " + oldPower + " to " + power);
                        } catch (Exception e) {
                            callbackContext.error("Error occured.");
                        }
                    }
                });
            } catch (Exception e) {
                callbackContext.error("Error occured.");
            }
        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }
    }

    @Override
    public void subscribeScanner(final boolean useASCII, final CallbackContext callbackContext) {
        asyncCallbackContext = callbackContext;
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    Toast.makeText(context, e.getMessage(), Toast.LENGTH_LONG).show();
                    e.printStackTrace();
                } catch (OperationFailureException e) {
                    e.printStackTrace();
                }
            }
            addAsyncListners(useASCII, callbackContext);
            event = new ZebraEventHandler(readerDevice, context, null, asyncCallbackContext, null, false, useASCII);

            try {

                rfidReader.Events.addEventsListener(event);
            } catch (InvalidUsageException e) {
                e.printStackTrace();
            } catch (OperationFailureException e) {
                e.printStackTrace();
            }
            sdkHandler = new SDKHandler(context);
            if (sdkHandler != null) {
                // DCSSDKDefs.DCSSDK_RESULT result = DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_FAILURE;
                sdkHandler.dcssdkSetDelegate(event);
                sdkHandler.dcssdkSetOperationalMode(DCSSDKDefs.DCSSDK_MODE.DCSSDK_OPMODE_BT_NORMAL);
                sdkHandler.dcssdkSetOperationalMode(DCSSDKDefs.DCSSDK_MODE.DCSSDK_OPMODE_BT_LE);
                // We would like to subscribe to all scanner available/not-available events
                int notifications_mask = DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SCANNER_APPEARANCE.value
                                | DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SCANNER_DISAPPEARANCE.value;
                // We would like to subscribe to all scanner connection events
                notifications_mask |= DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SESSION_ESTABLISHMENT.value
                                | DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SESSION_TERMINATION.value;
                // We would like to subscribe to all barcode events
                notifications_mask |= DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_BARCODE.value;
                // subscribe to events set in notification mask
                sdkHandler.dcssdkSubsribeForEvents(notifications_mask);
                notifications_mask = DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_BARCODE.value;
                sdkHandler.dcssdkSubsribeForEvents(notifications_mask);

                // enable scanner detection
                sdkHandler.dcssdkEnableAvailableScannersDetection(true);
                // subscribe to events set in notification mask
                sdkHandler.dcssdkSubsribeForEvents(notifications_mask);
                // Need to check both available & active scanners at this point
                sdkHandler.dcssdkGetAvailableScannersList(mScannerInfoList);
                sdkHandler.dcssdkGetActiveScannersList(mScannerInfoList);
                final DCSScannerInfo dcsScannerInfo = mScannerInfoList.get(0);
                DCSSDK_RESULT result = sdkHandler.dcssdkEstablishCommunicationSession(dcsScannerInfo.getScannerID());
                if (result == DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_FAILURE) {
                    callbackContext.error(BARCODE_SCANNER_CONNECTION_ERROR);
                }
            } else {
                callbackContext.error(BARCODE_SCANNER_CONNECTION_ERROR);
            }

        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }
    }

    /**
     * @param useASCII
     * @param callbackContext
     */
    private void addAsyncListners(final boolean useASCII, final CallbackContext callbackContext) {
        if (!rfidReader.Events.isHandheldEventSet()) {
            rfidReader.Events.setHandheldEvent(true);
        }
        if (!rfidReader.Events.isBatchModeEventSet()) {
            rfidReader.Events.setBatchModeEvent(true);
        }
    }

    @Override
    public void unsubscribeScanner(final CallbackContext callbackContext) {

        boolean success = ZebraScannerDevice.removeEventHandler();
        if (rfidReader.Events.isHandheldEventSet()) {
            rfidReader.Events.setHandheldEvent(false);
        }
        if (rfidReader.Events.isBatterySet()) {
            rfidReader.Events.setBatteryEvent(false);
        }
        callbackContext.success("true");
    }

    @Override
    public void startSearch(String tagID, boolean useAscii, CallbackContext callbackContext) {
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    e.printStackTrace();
                } catch (OperationFailureException e) {
                    e.printStackTrace();
                }
            }

            if (tagID == null || tagID.isEmpty()) {
                callbackContext.error("Please provide the tag id to search.");
                return;
            }

            if (!rfidReader.Events.isHandheldEventSet()) {
                rfidReader.Events.setHandheldEvent(true);

                event = new ZebraEventHandler(readerDevice, context, callbackContext, asyncCallbackContext, tagID, true, useAscii);

                try {
                    rfidReader.Events.addEventsListener(event);
                } catch (InvalidUsageException e) {
                    e.printStackTrace();
                } catch (OperationFailureException e) {
                    e.printStackTrace();
                }

            } else {
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Subscribe in Progress");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            }
        } else {
            callbackContext.error(DEVICE_IS_NOT_CONNECTED);
        }

    }

    @Override
    public void stopSearch(CallbackContext callbackContext) {

        ZebraScannerDevice.removeEventHandler();
        if (rfidReader.Events.isHandheldEventSet()) {
            rfidReader.Events.setHandheldEvent(false);
        }
        if (rfidReader.Events.isBatterySet()) {
            rfidReader.Events.setBatteryEvent(false);
        }
        callbackContext.success("true");
    }

    public static boolean removeEventHandler() {
        Boolean success = false;
        if (readerDevice != null) {
            if (!readerDevice.getRFIDReader().isConnected()) {
                try {
                    rfidReader = readerDevice.getRFIDReader();
                    rfidReader.setTimeout(1000);
                    rfidReader.reconnect();
                } catch (InvalidUsageException e) {
                    e.printStackTrace();
                } catch (OperationFailureException e) {
                    e.printStackTrace();
                }
            }

            try {
                rfidReader.Events.removeEventsListener(event);
                success = true;
            } catch (InvalidUsageException e) {
                success = false;
            } catch (OperationFailureException e) {
                success = false;
            }

        }
        return success;
    }

}
