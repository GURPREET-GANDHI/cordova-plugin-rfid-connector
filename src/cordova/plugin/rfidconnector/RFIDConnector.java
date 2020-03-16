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
    static String deviceType = "Zebra";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("getDeviceList".equals(action)) {
            this.getDeviceList(callbackContext);
            return true;
        }

        if ("connect".equals(action)) {
            deviceType = args.getString(0);
        }

        ScannerDevice scannerDevice = ScannerDeviceFactory.getInstance(this, deviceType);

        if ("connect".equals(action)) {
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

    public void getDeviceList(final CallbackContext callbackContext) {
        final CordovaPlugin that = this;
        final Context context = that.cordova.getActivity().getBaseContext();

        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {

            @Override
            public void run() {
                BluetoothManager bluetoothManager = (BluetoothManager) context.getSystemService(context.BLUETOOTH_SERVICE);
                BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();

                Boolean status = bluetoothAdapter.startDiscovery();

                Set<BluetoothDevice> listOfBondedDevices = bluetoothAdapter.getBondedDevices();
                try {
                    JSONArray deviceList = new JSONArray();
                    for (BluetoothDevice device : listOfBondedDevices) {
                        JSONObject deviceDetail = new JSONObject();
                        deviceDetail.put("name", device.getName());
                        deviceDetail.put("deviceID", device.getAddress());
                        // deviceDetail.put("state", bluetoothDevice.getBondState());
                        // deviceDetail.put("type", bluetoothDevice.getType());
                        deviceList.put(deviceDetail);
                    }
                    JSONObject result = JSONUtil.createJSONObjectSuccessResponse(deviceList);
                    callbackContext.success(result);
                } catch (JSONException ex) {
                    callbackContext.error(ex.getMessage());
                }

            }
        });

    }
}
