package cordova.plugin.rfidconnector;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.zebra.rfid.api3.HANDHELD_TRIGGER_EVENT_TYPE;
import com.zebra.rfid.api3.InvalidUsageException;
import com.zebra.rfid.api3.OperationFailureException;
import com.zebra.rfid.api3.RFIDReader;
import com.zebra.rfid.api3.ReaderDevice;
import com.zebra.rfid.api3.RfidEventsListener;
import com.zebra.rfid.api3.RfidReadEvents;
import com.zebra.rfid.api3.RfidStatusEvents;
import com.zebra.rfid.api3.STATUS_EVENT_TYPE;
import com.zebra.rfid.api3.TagData;
import com.zebra.scannercontrol.DCSScannerInfo;
import com.zebra.scannercontrol.FirmwareUpdateEvent;
import com.zebra.scannercontrol.IDcsSdkApiDelegate;

import android.content.Context;
import android.widget.Toast;


class ZebraEventHandler implements IDcsSdkApiDelegate, RfidEventsListener {
    private static final String UNPARSABLE_DATA_ERROR = "Unparsable data in barcode!";
    ReaderDevice readerDevice;
    Context context;
    CallbackContext asyncCallbackContext;
    CallbackContext callbackContext;
    private String tagIDForSearch;
    private boolean search;
    private boolean isSync;
    private boolean useASCII;
    private static final String EPC = "id";
    private ZebraScannerDevice scannerInstance;

    public ZebraEventHandler(ReaderDevice readerDevice, Context context, CallbackContext callbackContext, CallbackContext asyncCallbackContext,
                    String tagIDForSerch, boolean isSync, boolean useASCII) {
        this.asyncCallbackContext = asyncCallbackContext;
        this.readerDevice = readerDevice;
        this.context = context;
        this.callbackContext = callbackContext;
        this.tagIDForSearch = tagIDForSerch;
        this.isSync = isSync;
        this.useASCII = useASCII;
        if (tagIDForSearch != null) {
            search = true;
        }
    }

    @Override
    public void eventReadNotify(RfidReadEvents rfidReadEvents) {
        if (readerDevice != null) {
            try {
                JSONObject resultObject = new JSONObject();
                resultObject.put("status", true);
                resultObject.put("errorMsg", "");
                JSONArray data = new JSONArray();
                StringBuffer tagString = new StringBuffer();
                TagData[] myTags = readerDevice.getRFIDReader().Actions.getReadTags(100);
                if (myTags != null) {
                    for (TagData tag : myTags) {
                        if (!search) {
                            putTagID(data, tagString, tag);
                        } else {
                            isTagIDMatched(data, tagString, tag);
                        }
                    }
                    resultObject.put("data", data);
                    if (isSync) {
                        callbackContext.success(resultObject);
                        isSync = false;
                    } else {
                        PluginResult pluginResult2 = new PluginResult(PluginResult.Status.OK, resultObject);
                        pluginResult2.setKeepCallback(true);
                        asyncCallbackContext.sendPluginResult(pluginResult2);
                    }

                }
            } catch (JSONException ex) {
                callbackContext.error("Error: " + ex.getMessage());
            }
        } else {
            Toast.makeText(context, "No Device Found", Toast.LENGTH_SHORT).show();
        }

    }

    /**
     * @param data
     * @param tagString
     * @param tag
     * @param useASCII
     * @param tagIDForSearch
     */
    private void putTagID(JSONArray data, StringBuffer tagString, TagData tag) {
        Boolean isNew = true;
        String epc;
        JSONObject tagInfo = null;
        int rssi;
        try {
            if (useASCII) {
                epc = ConversionUtil.hexToAscii(tag.getTagID());

            } else {
                epc = tag.getTagID();
            }

            for (int i = 0; i < data.length(); i++) {
                JSONObject availableData = data.getJSONObject(i);
                String availableID = (String) availableData.get(EPC);

                if (epc.equalsIgnoreCase(availableID)) {
                    isNew = false;
                }

            }

            if (isNew) {
                rssi = tag.getPeakRSSI();
                tagInfo = JSONUtil.createRFIDJSONObject(epc, rssi);
                data.put(tagInfo);
            }

        } catch (JSONException ex) {
            callbackContext.error("Error: " + ex.getMessage());
        }
    }

    private void isTagIDMatched(JSONArray data, StringBuffer tagString, TagData tag) {
        String epc;
        JSONObject tagInfo = null;
        int rssi;
        try {
            String tempTag;
            if (useASCII) {
                tempTag = ConversionUtil.hexToAscii(tag.getTagID());
            } else {
                tempTag = tag.getTagID();
            }
            if (tempTag.equalsIgnoreCase(tagIDForSearch)) {
                epc = tempTag;
                rssi = tag.getPeakRSSI();
                tagInfo = JSONUtil.createRFIDJSONObject(epc, rssi);
                data.put(tagInfo);
            }
        } catch (JSONException ex) {
            callbackContext.error("Error: " + ex.getMessage());
        }
    }

    @Override
    public void eventStatusNotify(RfidStatusEvents rfidStatusEvents) {
        try {
            if (rfidStatusEvents != null) {

                STATUS_EVENT_TYPE statusEventType = rfidStatusEvents.StatusEventData.getStatusEventType();
                if (statusEventType != null && statusEventType.toString().equalsIgnoreCase("BATTERY_EVENT")) {
                    getDeviceInfo(rfidStatusEvents);

                }
                RfidReadEvents rfidReadEvents = new RfidReadEvents(readerDevice.getRFIDReader().Actions.Inventory);
                HANDHELD_TRIGGER_EVENT_TYPE handheldEvent = rfidStatusEvents.StatusEventData.HandheldTriggerEventData.getHandheldEvent();
                try {
                    if (handheldEvent != null && handheldEvent.toString().equalsIgnoreCase("HANDHELD_TRIGGER_PRESSED")) {

                        /*
                         * after perform(), stop() has to be called to save tags in memory. then we
                         * can read the tags from memory when eventReadNotify() is called after
                         * stop()
                         */
                        readerDevice.getRFIDReader().Actions.Inventory.perform();

                    }
                    if (handheldEvent != null && handheldEvent.toString().equalsIgnoreCase("HANDHELD_TRIGGER_RELEASED")) {
                        readerDevice.getRFIDReader().Actions.Inventory.stop();
                    }
                } catch (InvalidUsageException e) {
                    e.printStackTrace();
                } catch (OperationFailureException e) {
                    e.printStackTrace();
                }

                if (rfidReadEvents != null) {
                    eventReadNotify(rfidReadEvents);
                }

            }

        } catch (Exception ex) {
            callbackContext.error("Error: " + ex.getMessage());
        }

    }

    /**
     * @param rfidStatusEvents
     */
    private void getDeviceInfo(RfidStatusEvents rfidStatusEvents) {

        try {
            JSONObject resultObject = new JSONObject();

            if (readerDevice != null && rfidStatusEvents != null) {
                RFIDReader rfidReader;
                if (!readerDevice.getRFIDReader().isConnected()) {
                    try {
                        rfidReader = readerDevice.getRFIDReader();
                        rfidReader.setTimeout(1000);
                        rfidReader.reconnect();
                    } catch (InvalidUsageException e) {
                        resultObject.put("status", false);
                        resultObject.put("errorMsg", "Device is not connected due to " + e.getInfo());
                    } catch (OperationFailureException e) {
                        resultObject.put("status", false);
                        resultObject.put("errorMsg", "Device is not connected due to " + e.getResults());
                    }
                }
                boolean chargingInfo = rfidStatusEvents.StatusEventData.BatteryData.getCharging();
                int batteryLevel = rfidStatusEvents.StatusEventData.BatteryData.getLevel();
                String causeInfo = rfidStatusEvents.StatusEventData.BatteryData.getCause();
                if (causeInfo.equalsIgnoreCase("User Request")) {
                    rfidReader = readerDevice.getRFIDReader();
                    ZebraScannerDevice.batteryLevel = batteryLevel;
                    ZebraScannerDevice.isCharging = chargingInfo;
                }
            }
        } catch (Exception e) {
            callbackContext.success("Device is not connected." + e.getMessage());
        }
    }

    // ----------------------Scanner Implementation--------------------------------
    @Override
    public void dcssdkEventScannerAppeared(DCSScannerInfo var1) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventScannerDisappeared(int var1) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventCommunicationSessionEstablished(DCSScannerInfo var1) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventCommunicationSessionTerminated(int var1) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventBarcode(byte[] barcodeData, int barcodeType, int fromScannerID) {
        JSONObject resultObject = new JSONObject();
        JSONArray data = new JSONArray();
        System.out.println("Zebra Scanner barcode data has appeared");
        PluginResult pluginResult;
        try {
            final String barcodeDataString = new String(barcodeData);
            JSONObject barcodeJSONObject = JSONUtil.createBarcodeJSONObject(barcodeDataString);
            data.put(barcodeJSONObject);
            resultObject.put("data", data);
            pluginResult = new PluginResult(PluginResult.Status.OK, resultObject);
            pluginResult.setKeepCallback(true);
            asyncCallbackContext.sendPluginResult(pluginResult);
        } catch (Exception e) {
            pluginResult = new PluginResult(PluginResult.Status.ERROR, UNPARSABLE_DATA_ERROR);
            pluginResult.setKeepCallback(true);
            asyncCallbackContext.sendPluginResult(pluginResult);
        }

    }

    @Override
    public void dcssdkEventImage(byte[] var1, int var2) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventVideo(byte[] var1, int var2) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventFirmwareUpdate(FirmwareUpdateEvent var1) {
        // TODO Auto-generated method stub

    }

    @Override
    public void dcssdkEventAuxScannerAppeared(DCSScannerInfo var1, DCSScannerInfo var2) {
        // TODO Auto-generated method stub

    }
}
