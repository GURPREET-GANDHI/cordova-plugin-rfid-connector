package cordova.plugin.rfidconnector;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


public class JSONUtil {
    private static final String RFID = "rfid";
    private static final String ID = "id";
    private static final String BARCODE = "barcode";
    private static final String TYPE = "type";
    private static final String RSSI = "RSSI";
    private static final String EPC = ID;

    private JSONUtil() {

    }

    public static JSONObject createJSONObjectResponse(boolean status, final String errorMsg, Object json) throws JSONException {
        JSONObject result = new JSONObject();
        result.put("status", status);
        result.put("errorMsg", errorMsg);
        result.put("data", json);
        return result;
    }

    public static JSONObject createJSONObjectResponse(boolean status, final String message) throws JSONException {
        return createJSONObjectResponse(status, message, new JSONArray());
    }

    public static JSONObject createJSONObjectSuccessResponse(final Object json) throws JSONException {
        return createJSONObjectResponse(true, " ", json);
    }

    public static JSONObject createJSONObjectErrorResponse(final String errorMsg) throws JSONException {
        return createJSONObjectResponse(false, errorMsg, new JSONArray());
    }

    public static JSONObject createBarcodeJSONObject(final String barCode) throws JSONException {
        JSONObject barCodeObject = new JSONObject();
        barCodeObject.put(TYPE, BARCODE);
        barCodeObject.put(ID, barCode);
        return barCodeObject;
    }

    public static JSONObject createRFIDJSONObject(final String epc, final Integer rssi) throws JSONException {
        JSONObject rfidObject = new JSONObject();
        rfidObject.put(TYPE, RFID);
        rfidObject.put(EPC, epc);
        rfidObject.put(RSSI, rssi == null ? "" : rssi);
        return rfidObject;
    }

}
